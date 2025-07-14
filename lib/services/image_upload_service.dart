// Import Dart typed data library for handling binary data - provides Uint8List for image bytes
import 'dart:typed_data';
// Import Supabase Flutter SDK for storage operations - provides storage bucket and file management
import 'package:supabase_flutter/supabase_flutter.dart';
// Import local Supabase configuration - provides access to Supabase client
import 'supabase_config.dart';
// Import real-time profile service for live updates - enables immediate profile updates
import 'realtime_profile_service.dart';

// Service class for handling image uploads to Supabase storage - manages profile image uploads and deletions
class ImageUploadService {
  // Static instance of Supabase client from configuration - provides access to storage operations
  static final _supabase = SupabaseConfig.supabase;
  // Static instance of real-time profile service - enables live profile updates
  static final _profileService = RealTimeProfileService();
  // Constant for the storage bucket name - defines the storage bucket for avatar images
  static const String _bucketName = 'avatars';

  /// Upload profile image with immediate cache busting and real-time updates
  static Future<String?> uploadProfileImage(Uint8List imageBytes, String userId) async {
    try {
      // Check if user is authenticated - verifies user is logged in before upload
      final user = _supabase.auth.currentUser;
      // Throw error if user is not authenticated - prevents unauthorized uploads
      if (user == null) {
        throw 'User not authenticated';
      }

      // Verify storage bucket exists and is accessible - ensures storage is properly configured
      final bucketExists = await _verifyBucketExists();
      // Throw error if bucket doesn't exist - prevents upload to non-existent bucket
      if (!bucketExists) {
        throw 'Storage bucket "$_bucketName" does not exist or is not accessible';
      }

      // Delete old image first to free up storage space - removes previous profile image
      await _deleteOldProfileImage(userId);

      // Create a unique filename with timestamp for cache busting - ensures unique filenames
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Generate filename with user ID and timestamp - creates unique identifier for image
      final fileName = 'profile_${userId}_$timestamp.jpg';
      // Set file path within the bucket - organizes images in profiles subfolder
      final filePath = 'profiles/$fileName';

      // Print debug information about upload - logs upload details for debugging
      print('Uploading image to: $filePath');
      print('Image size: ${imageBytes.length} bytes');
      
      // Try to upload the file with no-cache settings - uploads image with cache control
      final response = await _supabase.storage
          .from(_bucketName)
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: const FileOptions(
              cacheControl: '0', // Disable caching for immediate updates - prevents cached images
              upsert: true,
            ),
          );

      // Print upload response for debugging - logs upload result
      print('Upload response: $response');
      
      // Get the public URL with cache-busting parameter - generates accessible URL for image
      final baseUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(filePath);
      
      // Add cache-busting parameters to URL - ensures fresh image loading
      final cacheBustingUrl = '$baseUrl?v=$timestamp&cb=${DateTime.now().millisecondsSinceEpoch}';

      // Print generated URL for debugging - logs the final URL
      print('Generated cache-busting URL: $cacheBustingUrl');
      
      // Update profile in database with new URL - stores image URL in user profile
      await _supabase
          .from('profiles')
          .update({
            'avatar_url': cacheBustingUrl,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);

      // Force refresh the profile in real-time service - triggers immediate UI updates
      await _profileService.refreshProfile(userId);
      
      // Clear any cached profile data - ensures fresh data is loaded
      _profileService.clearProfileCache(userId);
      
      // Print success message - logs successful upload
      print('Profile image updated successfully with real-time notification');
      
      // Test the URL immediately to catch 400 errors - verifies image is accessible
      final isAccessible = await _testUrlImmediately(cacheBustingUrl);
      // Check if URL is accessible - handles cases where RLS policies block access
      if (!isAccessible) {
        // Print warning about RLS policies - alerts about potential configuration issues
        print('Warning: URL returned 400 error, this usually means RLS policies need to be set up');
        print('Please run the storage_setup_simple.sql script in your Supabase SQL Editor');
        
        // Try the fallback method - attempts alternative upload approach
        print('Trying fallback upload method...');
        final fallbackUrl = await uploadProfileImageFallback(imageBytes, userId);
        // Return fallback URL if available - provides alternative URL if main method fails
        if (fallbackUrl != null) {
          return fallbackUrl;
        }
        
        // If fallback also fails, return the original URL anyway - provides URL for manual fix
        // The user can fix the RLS policies and the image should work
        print('Returning original URL - user needs to fix RLS policies');
        return cacheBustingUrl;
      }
      
      // Return the cache-busting URL - provides the final image URL
      return cacheBustingUrl;
    } on StorageException catch (e) {
      // Handle storage-specific errors - catches Supabase storage errors
      print('Storage error: ${e.message}');
      print('Storage error details: ${e.error}');
      throw 'Storage error: ${e.message}';
    } catch (e) {
      // Handle general upload errors - catches any other upload errors
      print('Error uploading image: $e');
      throw 'Failed to upload image: $e';
    }
  }

  /// Delete old profile image to free up storage space
  static Future<void> _deleteOldProfileImage(String userId) async {
    try {
      // Get current profile to find old image - retrieves existing avatar URL
      final profile = await _supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();

      // Return early if no profile or no avatar URL - handles cases with no existing image
      if (profile == null || profile['avatar_url'] == null) {
        return;
      }

      // Get the old avatar URL - extracts URL from profile data
      final oldAvatarUrl = profile['avatar_url'] as String;
      // Delete the old profile image - removes previous image from storage
      await deleteProfileImage(oldAvatarUrl);
    } catch (e) {
      // Print error but don't throw as this is cleanup - logs errors without failing upload
      print('Error deleting old profile image: $e');
      // Don't throw here as this is cleanup - allows upload to continue even if cleanup fails
    }
  }

  /// Delete profile image with real-time update
  static Future<bool> deleteProfileImageWithRealTimeUpdate(String userId) async {
    try {
      // Get current avatar URL from profile - retrieves existing avatar URL
      final profile = await _supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();

      // Delete the image file if avatar URL exists - removes image from storage
      if (profile != null && profile['avatar_url'] != null) {
        await deleteProfileImage(profile['avatar_url']);
      }

      // Update profile to remove avatar URL - clears avatar URL from profile
      await _supabase
          .from('profiles')
          .update({
            'avatar_url': null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);

      // Force refresh the profile - triggers immediate UI updates
      await _profileService.refreshProfile(userId);
      
      // Print success message - logs successful removal
      print('Profile image removed with real-time notification');
      return true;
    } catch (e) {
      // Print error and return false - logs errors and indicates failure
      print('Error removing profile image: $e');
      return false;
    }
  }

  // Method to delete a profile image from storage
  static Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      // Check if user is authenticated - verifies user is logged in before deletion
      final user = _supabase.auth.currentUser;
      // Return false if user is not authenticated - prevents unauthorized deletions
      if (user == null) {
        print('User not authenticated for deletion');
        return false;
      }

      // Extract filename from URL - parses URL to get file path
      final uri = Uri.parse(imageUrl);
      // Get path segments from URI - extracts path components from URL
      final pathSegments = uri.pathSegments;
      
      // Find the file path within the storage bucket - locates file in storage structure
      String? filePath;
      // Loop through path segments to find storage path - searches for storage path pattern
      for (int i = 0; i < pathSegments.length; i++) {
        if (pathSegments[i] == 'storage' && 
            i + 3 < pathSegments.length && 
            pathSegments[i + 2] == _bucketName) {
          // Extract file path from storage URL - builds file path from URL segments
          filePath = pathSegments.sublist(i + 3).join('/');
          break;
        }
      }
      
      // Fallback: assume last segment is the filename and it's in profiles folder - handles URL parsing edge cases
      if (filePath == null) {
        // Remove query parameters and assume profiles folder - creates fallback file path
        filePath = 'profiles/${pathSegments.last.split('?')[0]}'; // Remove query params
      }
      
      // Print debug message with file path - logs which file is being deleted
      print('Deleting file: $filePath');
      
      // Remove the file from storage - deletes file from Supabase storage
      await _supabase.storage
          .from(_bucketName)
          .remove([filePath]);
      
      // Print success message - logs successful deletion
      print('File deleted successfully');
      return true;
    } on StorageException catch (e) {
      // Handle storage-specific errors - catches Supabase storage errors
      print('Storage error deleting file: ${e.message}');
      return false;
    } catch (e) {
      // Handle general deletion errors - catches any other deletion errors
      print('Error deleting image: $e');
      return false;
    }
  }

  // Helper method to check if storage bucket exists and is accessible
  static Future<bool> checkStorageAccess() async {
    try {
      // Get current authenticated user - verifies user is logged in
      final user = _supabase.auth.currentUser;
      // Return false if user is not authenticated - prevents access check without auth
      if (user == null) {
        print('User not authenticated');
        return false;
      }

      // Try to list files in the bucket to test access - verifies bucket accessibility
      await _supabase.storage
          .from(_bucketName)
          .list();
      
      // Print success message - logs successful access check
      print('Storage access check passed');
      return true;
    } on StorageException catch (e) {
      // Handle storage-specific errors - catches Supabase storage errors
      print('Storage access error: ${e.message}');
      print('Error code: ${e.statusCode}');
      
      // If bucket doesn't exist, try to create the path structure - provides helpful error messages
      if (e.statusCode == '404' || e.message.toLowerCase().contains('not found')) {
        print('Bucket or path not found, this might be a configuration issue');
        print('Please ensure the "$_bucketName" bucket exists in Supabase Storage');
        print('And that the user has upload permissions');
      }
      
      return false;
    } catch (e) {
      // Handle general storage access errors - catches any other access errors
      print('Storage access check failed: $e');
      return false;
    }
  }

  // Verify if the storage bucket exists
  static Future<bool> _verifyBucketExists() async {
    try {
      // Try to list files in the bucket to verify it exists - tests bucket accessibility
      await _supabase.storage.from(_bucketName).list();
      return true;
    } catch (e) {
      // Print error if bucket verification fails - logs bucket verification errors
      print('Bucket verification failed: $e');
      return false;
    }
  }

  // Test URL immediately after upload to catch 400 errors
  static Future<bool> _testUrlImmediately(String url) async {
    try {
      // Try to download the file to test if URL is accessible - verifies image accessibility
      final response = await _supabase.storage
          .from(_bucketName)
          .download(url.split('/').last);
      // Return true if response is not empty - indicates successful access
      return response.isNotEmpty;
    } catch (e) {
      // Print error if URL test fails - logs URL accessibility test errors
      print('URL immediate test failed: $e');
      return false;
    }
  }

  // Verify if a URL is accessible
  static Future<bool> _verifyUrlAccessibility(String url) async {
    try {
      // Try to download the file to verify accessibility - tests image accessibility
      final response = await _supabase.storage
          .from(_bucketName)
          .download(url.split('/').last);
      // Return true if response is not empty - indicates successful access
      return response.isNotEmpty;
    } catch (e) {
      // Print error if URL accessibility check fails - logs accessibility check errors
      print('URL accessibility check failed: $e');
      return false;
    }
  }

  // Comprehensive storage diagnostic
  static Future<Map<String, dynamic>> diagnoseStorageIssue() async {
    // Initialize result map with default values - creates diagnostic result structure
    final result = <String, dynamic>{
      'isAuthenticated': false,
      'canAccessBucket': false,
      'canListFiles': false,
      'canUploadTest': false,
      'errors': <String>[],
      'suggestions': <String>[],
    };

    try {
      // Check authentication - verifies user is logged in
      final user = _supabase.auth.currentUser;
      // Check if user is authenticated - handles unauthenticated users
      if (user == null) {
        result['errors'].add('User not authenticated');
        result['suggestions'].add('Please log in again');
        return result;
      }
      // Set authentication status to true - marks user as authenticated
      result['isAuthenticated'] = true;
      print('[OK] User authenticated: ${user.id}');

      // Check if we can access the bucket - tests bucket accessibility
      try {
        // Try to list files in the bucket - verifies bucket access
        await _supabase.storage.from(_bucketName).list();
        result['canAccessBucket'] = true;
        print('[OK] Can access bucket: $_bucketName');
      } on StorageException catch (e) {
        // Handle storage-specific errors - provides specific error messages and suggestions
        result['errors'].add('Cannot access bucket: ${e.message}');
        if (e.statusCode == '404') {
          result['suggestions'].add('The "$_bucketName" bucket does not exist in Supabase Storage');
          result['suggestions'].add('Please create the bucket in your Supabase dashboard');
        } else if (e.statusCode == '403') {
          result['suggestions'].add('Permission denied. Check RLS policies on the $_bucketName bucket');
        }
        return result;
      }

      // Check if we can list files in profiles folder - tests subfolder access
      try {
        // Try to list files in the profiles subfolder - verifies subfolder accessibility
        await _supabase.storage.from(_bucketName).list(path: 'profiles');
        result['canListFiles'] = true;
        print('[OK] Can list files in profiles folder');
      } catch (e) {
        // Handle error if cannot list files - logs subfolder access issues
        result['errors'].add('Cannot list files in profiles folder: $e');
        print('[ERROR] Cannot list files in profiles folder, but bucket exists');
      }

      // Try a test upload - tests upload functionality
      try {
        // Create test JPEG data - creates minimal JPEG header for testing
        final testData = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]); // JPEG header
        // Generate test filename with timestamp - creates unique test filename
        final testFileName = 'test_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        // Try to upload test file - tests upload functionality
        await _supabase.storage
            .from(_bucketName)
            .uploadBinary(
              testFileName,
              testData,
              fileOptions: const FileOptions(upsert: true),
            );
        
        // Clean up test file - removes test file after upload test
        await _supabase.storage.from(_bucketName).remove([testFileName]);
        
        result['canUploadTest'] = true;
        print('[OK] Test upload successful');
      } catch (e) {
        // Handle test upload errors - provides upload error information
        result['errors'].add('Test upload failed: $e');
        result['suggestions'].add('Check upload permissions and bucket policies');
      }

      // Add success suggestion if no errors - provides positive feedback
      if (result['errors'].isEmpty) {
        result['suggestions'].add('Storage configuration appears to be working correctly');
      }

    } catch (e) {
      // Handle unexpected errors - catches any unexpected diagnostic errors
      result['errors'].add('Unexpected error: $e');
    }

    return result;
  }

  // Alternative upload method using a different approach
  static Future<String?> uploadProfileImageFallback(Uint8List imageBytes, String userId) async {
    try {
      // Check if user is authenticated - verifies user is logged in
      final user = _supabase.auth.currentUser;
      // Throw error if user is not authenticated - prevents unauthorized uploads
      if (user == null) {
        throw 'User not authenticated';
      }

      // Try uploading directly to root of bucket without subfolder - attempts alternative upload path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Generate filename without subfolder - creates filename for root upload
      final fileName = 'profile_${userId}_$timestamp.jpg';

      // Print debug message for fallback upload - logs fallback upload attempt
      print('Fallback: Uploading image to root: $fileName');
      
      // Try to upload the file to bucket root - uploads to bucket root instead of subfolder
      final response = await _supabase.storage
          .from(_bucketName)
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Print fallback upload response - logs fallback upload result
      print('Fallback upload response: $response');
      
      // Get the public URL - generates public URL for fallback upload
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(fileName);

      // Print fallback public URL - logs the fallback URL
      print('Fallback public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      // Print error if fallback upload fails - logs fallback upload errors
      print('Fallback upload also failed: $e');
      return null;
    }
  }

  /// Create a cache-busting URL for any image URL
  static String createCacheBustingUrl(String originalUrl) {
    // Get current timestamp for cache busting - creates unique cache-busting parameter
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Determine separator based on whether URL already has query parameters - handles existing query params
    final separator = originalUrl.contains('?') ? '&' : '?';
    // Return URL with cache-busting parameter - adds cache-busting to URL
    return '$originalUrl${separator}cb=$timestamp';
  }

  /// Test if an image URL is accessible
  static Future<bool> testImageAccessibility(String url) async {
    try {
      // Try to download the image to test accessibility - verifies image can be accessed
      final response = await _supabase.storage
          .from(_bucketName)
          .download(url.split('/').last.split('?')[0]); // Remove query params
      // Return true if response is not empty - indicates successful access
      return response.isNotEmpty;
    } catch (e) {
      // Print error if image accessibility test fails - logs accessibility test errors
      print('Image accessibility test failed: $e');
      return false;
    }
  }

  // Create storage bucket if it doesn't exist (requires admin privileges)
  static Future<bool> createStorageBucket() async {
    try {
      // This would require admin privileges and is typically done through the Supabase dashboard
      // For now, we'll just provide instructions - provides setup instructions
      print('To create the storage bucket:');
      print('1. Go to your Supabase Dashboard');
      print('2. Navigate to Storage');
      print('3. Create a new bucket named "$_bucketName"');
      print('4. Set it to public or configure appropriate RLS policies');
      return false;
    } catch (e) {
      // Print error if creating storage bucket fails - logs bucket creation errors
      print('Error creating storage bucket: $e');
      return false;
    }
  }
}
