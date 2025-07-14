import 'dart:typed_data'; // Import Dart typed data library for Uint8List operations
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase Flutter SDK for storage operations
import 'supabase_config.dart'; // Import local Supabase configuration file
import 'realtime_profile_service.dart'; // Import real-time profile service for immediate updates

class ImageUploadService { // Define ImageUploadService class to handle image upload operations
  static final _supabase = SupabaseConfig.supabase; // Get Supabase client instance from configuration
  static final _profileService = RealTimeProfileService(); // Get real-time profile service instance
  static const String _bucketName = 'avatars'; // Define constant for the storage bucket name

  /// Upload profile image with immediate cache busting and real-time updates
  static Future<String?> uploadProfileImage(Uint8List imageBytes, String userId) async { // Define static async method to upload profile image
    try { // Begin try block for upload error handling
      // Check if user is authenticated
      final user = _supabase.auth.currentUser; // Get current authenticated user
      if (user == null) { // Check if user is not authenticated
        throw 'User not authenticated'; // Throw authentication error
      } // End of authentication check

      // Verify storage bucket exists and is accessible
      final bucketExists = await _verifyBucketExists(); // Check if storage bucket exists
      if (!bucketExists) { // Check if bucket doesn't exist
        throw 'Storage bucket "$_bucketName" does not exist or is not accessible'; // Throw bucket access error
      } // End of bucket existence check

      // Delete old image first
      await _deleteOldProfileImage(userId); // Delete user's old profile image before uploading new one

      // Create a unique filename with timestamp for cache busting
      final timestamp = DateTime.now().millisecondsSinceEpoch; // Get current timestamp for unique filename
      final fileName = 'profile_${userId}_$timestamp.jpg'; // Create unique filename with user ID and timestamp
      final filePath = 'profiles/$fileName'; // Create full file path in profiles folder

      print('Uploading image to: $filePath'); // Log the upload file path
      print('Image size: ${imageBytes.length} bytes'); // Log the image size in bytes
      
      // Try to upload the file with no-cache settings
      final response = await _supabase.storage // Upload file to Supabase storage
          .from(_bucketName) // From the specified bucket
          .uploadBinary( // Upload binary data
            filePath, // Specify the file path
            imageBytes, // Provide the image bytes
            fileOptions: const FileOptions( // Set file upload options
              cacheControl: '0', // Disable caching for immediate updates
              upsert: true, // Allow overwriting existing files
            ), // End of FileOptions
          ); // End of uploadBinary call

      print('Upload response: $response'); // Log the upload response
      
      // Get the public URL with cache-busting parameter
      final baseUrl = _supabase.storage // Get public URL for the uploaded file
          .from(_bucketName) // From the specified bucket
          .getPublicUrl(filePath); // Get public URL for the file path
      
      final cacheBustingUrl = '$baseUrl?v=$timestamp&cb=${DateTime.now().millisecondsSinceEpoch}'; // Create cache-busting URL with timestamp parameters

      print('Generated cache-busting URL: $cacheBustingUrl'); // Log the generated cache-busting URL
      
      // Update profile in database with new URL
      await _supabase // Update profile table in database
          .from('profiles') // Target the profiles table
          .update({ // Update with new values
            'avatar_url': cacheBustingUrl, // Set avatar URL to new cache-busting URL
            'updated_at': DateTime.now().toUtc().toIso8601String(), // Set updated timestamp
          }) // End of update values
          .eq('id', userId); // Filter by user ID

      // Force refresh the profile in real-time service
      await _profileService.refreshProfile(userId); // Refresh profile in real-time service for immediate updates
      
      // Clear any cached profile data
      _profileService.clearProfileCache(userId); // Clear cached profile data for the user
      
      print('Profile image updated successfully with real-time notification'); // Log successful update with real-time notification
      
      // Test the URL immediately to catch 400 errors
      final isAccessible = await _testUrlImmediately(cacheBustingUrl); // Test if the uploaded image URL is accessible
      if (!isAccessible) { // Check if URL is not accessible
        print('Warning: URL returned 400 error, this usually means RLS policies need to be set up'); // Log RLS policy warning
        print('Please run the storage_setup_simple.sql script in your Supabase SQL Editor'); // Log setup instruction
        
        // Try the fallback method
        print('Trying fallback upload method...'); // Log fallback attempt
        final fallbackUrl = await uploadProfileImageFallback(imageBytes, userId); // Try fallback upload method
        if (fallbackUrl != null) { // Check if fallback succeeded
          return fallbackUrl; // Return fallback URL
        } // End of fallback success check
        
        // If fallback also fails, return the original URL anyway
        // The user can fix the RLS policies and the image should work
        print('Returning original URL - user needs to fix RLS policies'); // Log return of original URL
        return cacheBustingUrl; // Return original cache-busting URL
      } // End of URL accessibility check
      
      return cacheBustingUrl; // Return successful cache-busting URL
    } on StorageException catch (e) { // Catch Supabase storage-specific exceptions
      print('Storage error: ${e.message}'); // Log storage error message
      print('Storage error details: ${e.error}'); // Log storage error details
      throw 'Storage error: ${e.message}'; // Throw formatted storage error
    } catch (e) { // Catch any other exceptions
      print('Error uploading image: $e'); // Log general upload error
      throw 'Failed to upload image: $e'; // Throw formatted upload error
    } // End of upload try-catch block
  } // End of uploadProfileImage method

  /// Delete old profile image to free up storage
  static Future<void> _deleteOldProfileImage(String userId) async { // Define private static async method to delete old profile image
    try { // Begin try block for deletion error handling
      // Get current profile to find old image
      final profile = await _supabase // Query profiles table
          .from('profiles') // From the profiles table
          .select('avatar_url') // Select only avatar_url column
          .eq('id', userId) // Filter by user ID
          .maybeSingle(); // Get single result or null

      if (profile == null || profile['avatar_url'] == null) { // Check if profile or avatar URL doesn't exist
        return; // Return early if no old image to delete
      } // End of profile existence check

      final oldAvatarUrl = profile['avatar_url'] as String; // Get old avatar URL as string
      await deleteProfileImage(oldAvatarUrl); // Delete the old profile image
    } catch (e) { // Catch any deletion errors
      print('Error deleting old profile image: $e'); // Log deletion error
      // Don't throw here as this is cleanup
    } // End of deletion cleanup try-catch
  } // End of _deleteOldProfileImage method

  /// Delete profile image with real-time update
  static Future<bool> deleteProfileImageWithRealTimeUpdate(String userId) async { // Define static async method to delete profile image with real-time updates
    try { // Begin try block for deletion error handling
      // Get current avatar URL
      final profile = await _supabase // Query profiles table
          .from('profiles') // From the profiles table
          .select('avatar_url') // Select only avatar_url column
          .eq('id', userId) // Filter by user ID
          .maybeSingle(); // Get single result or null

      if (profile != null && profile['avatar_url'] != null) { // Check if profile and avatar URL exist
        await deleteProfileImage(profile['avatar_url']); // Delete the profile image file
      } // End of avatar URL existence check

      // Update profile to remove avatar URL
      await _supabase // Update profiles table
          .from('profiles') // From the profiles table
          .update({ // Update with new values
            'avatar_url': null, // Set avatar URL to null
            'updated_at': DateTime.now().toUtc().toIso8601String(), // Set updated timestamp
          }) // End of update values
          .eq('id', userId); // Filter by user ID

      // Force refresh the profile
      await _profileService.refreshProfile(userId); // Refresh profile in real-time service
      
      print('Profile image removed with real-time notification'); // Log successful removal with real-time notification
      return true; // Return success
    } catch (e) { // Catch any deletion errors
      print('Error removing profile image: $e'); // Log removal error
      return false; // Return failure
    } // End of deletion try-catch
  } // End of deleteProfileImageWithRealTimeUpdate method

  static Future<bool> deleteProfileImage(String imageUrl) async { // Define static async method to delete profile image by URL
    try { // Begin try block for deletion error handling
      // Check if user is authenticated
      final user = _supabase.auth.currentUser; // Get current authenticated user
      if (user == null) { // Check if user is not authenticated
        print('User not authenticated for deletion'); // Log authentication error
        return false; // Return failure
      } // End of authentication check

      // Extract filename from URL
      final uri = Uri.parse(imageUrl); // Parse the image URL
      final pathSegments = uri.pathSegments; // Get path segments from URL
      
      // Find the file path within the storage bucket
      String? filePath; // Declare variable to store file path
      for (int i = 0; i < pathSegments.length; i++) { // Iterate through path segments
        if (pathSegments[i] == 'storage' && // Check if segment is 'storage'
            i + 3 < pathSegments.length && // Check if there are enough segments remaining
            pathSegments[i + 2] == _bucketName) { // Check if bucket name matches
          filePath = pathSegments.sublist(i + 3).join('/'); // Extract file path from remaining segments
          break; // Exit loop once file path is found
        } // End of storage path check
      } // End of path segments iteration
      
      if (filePath == null) { // Check if file path was not found
        // Fallback: assume last segment is the filename and it's in profiles folder
        filePath = 'profiles/${pathSegments.last.split('?')[0]}'; // Create fallback file path by removing query parameters
      } // End of file path fallback
      
      print('Deleting file: $filePath'); // Log the file path being deleted
      
      await _supabase.storage // Delete file from storage
          .from(_bucketName) // From the specified bucket
          .remove([filePath]); // Remove the file at the specified path
      
      print('File deleted successfully'); // Log successful file deletion
      return true; // Return success
    } on StorageException catch (e) { // Catch Supabase storage-specific exceptions
      print('Storage error deleting file: ${e.message}'); // Log storage deletion error
      return false; // Return failure
    } catch (e) { // Catch any other exceptions
      print('Error deleting image: $e'); // Log general deletion error
      return false; // Return failure
    } // End of deletion try-catch
  } // End of deleteProfileImage method

  // Helper method to check if storage bucket exists and is accessible
  static Future<bool> checkStorageAccess() async { // Define static async method to check storage access
    try { // Begin try block for access check error handling
      final user = _supabase.auth.currentUser; // Get current authenticated user
      if (user == null) { // Check if user is not authenticated
        print('User not authenticated'); // Log authentication error
        return false; // Return failure
      } // End of authentication check

      // Try to list files in the bucket to test access
      await _supabase.storage // Access storage
          .from(_bucketName) // From the specified bucket
          .list(); // List files to test access
      
      print('Storage access check passed'); // Log successful access check
      return true; // Return success
    } on StorageException catch (e) { // Catch Supabase storage-specific exceptions
      print('Storage access error: ${e.message}'); // Log storage access error message
      print('Error code: ${e.statusCode}'); // Log storage error status code
      
      // If bucket doesn't exist, try to create the path structure
      if (e.statusCode == '404' || e.message.toLowerCase().contains('not found')) { // Check if error is due to bucket not found
        print('Bucket or path not found, this might be a configuration issue'); // Log bucket not found issue
        print('Please ensure the "$_bucketName" bucket exists in Supabase Storage'); // Log bucket creation instruction
        print('And that the user has upload permissions'); // Log permission requirement
      } // End of bucket not found check
      
      return false; // Return failure
    } catch (e) { // Catch any other exceptions
      print('Storage access check failed: $e'); // Log general access check failure
      return false; // Return failure
    } // End of access check try-catch
  } // End of checkStorageAccess method

  // Verify if the storage bucket exists
  static Future<bool> _verifyBucketExists() async { // Define private static async method to verify bucket existence
    try { // Begin try block for bucket verification error handling
      await _supabase.storage.from(_bucketName).list(); // Try to list files in bucket to verify existence
      return true; // Return success if bucket exists
    } catch (e) { // Catch any bucket verification errors
      print('Bucket verification failed: $e'); // Log bucket verification failure
      return false; // Return failure
    } // End of bucket verification try-catch
  } // End of _verifyBucketExists method

  // Test URL immediately after upload to catch 400 errors
  static Future<bool> _testUrlImmediately(String url) async { // Define private static async method to test URL accessibility
    try { // Begin try block for URL test error handling
      final response = await _supabase.storage // Access storage
          .from(_bucketName) // From the specified bucket
          .download(url.split('/').last); // Download file using last part of URL as filename
      return response.isNotEmpty; // Return true if response contains data
    } catch (e) { // Catch any URL test errors
      print('URL immediate test failed: $e'); // Log URL test failure
      return false; // Return failure
    } // End of URL test try-catch
  } // End of _testUrlImmediately method

  // Verify if a URL is accessible
  static Future<bool> _verifyUrlAccessibility(String url) async { // Define private static async method to verify URL accessibility
    try { // Begin try block for URL verification error handling
      final response = await _supabase.storage // Access storage
          .from(_bucketName) // From the specified bucket
          .download(url.split('/').last); // Download file using last part of URL as filename
      return response.isNotEmpty; // Return true if response contains data
    } catch (e) { // Catch any URL verification errors
      print('URL accessibility check failed: $e'); // Log URL accessibility check failure
      return false; // Return failure
    } // End of URL verification try-catch
  } // End of _verifyUrlAccessibility method

  // Comprehensive storage diagnostic
  static Future<Map<String, dynamic>> diagnoseStorageIssue() async { // Define static async method for comprehensive storage diagnostics
    final result = <String, dynamic>{ // Initialize result map with diagnostic flags
      'isAuthenticated': false, // Flag for authentication status
      'canAccessBucket': false, // Flag for bucket access status
      'canListFiles': false, // Flag for file listing status
      'canUploadTest': false, // Flag for test upload status
      'errors': <String>[], // List to store error messages
      'suggestions': <String>[], // List to store suggestion messages
    }; // End of result map initialization

    try { // Begin try block for diagnostic error handling
      // Check authentication
      final user = _supabase.auth.currentUser; // Get current authenticated user
      if (user == null) { // Check if user is not authenticated
        result['errors'].add('User not authenticated'); // Add authentication error to results
        result['suggestions'].add('Please log in again'); // Add login suggestion to results
        return result; // Return early with authentication failure
      } // End of authentication check
      result['isAuthenticated'] = true; // Set authentication flag to true
      print('[OK] User authenticated: ${user.id}'); // Log successful authentication

      // Check if we can access the bucket
      try { // Begin try block for bucket access test
        await _supabase.storage.from(_bucketName).list(); // Try to list files in bucket
        result['canAccessBucket'] = true; // Set bucket access flag to true
        print('[OK] Can access bucket: $_bucketName'); // Log successful bucket access
      } on StorageException catch (e) { // Catch storage-specific exceptions
        result['errors'].add('Cannot access bucket: ${e.message}'); // Add bucket access error to results
        if (e.statusCode == '404') { // Check if error is due to bucket not found
          result['suggestions'].add('The "$_bucketName" bucket does not exist in Supabase Storage'); // Add bucket creation suggestion
          result['suggestions'].add('Please create the bucket in your Supabase dashboard'); // Add dashboard instruction
        } else if (e.statusCode == '403') { // Check if error is due to permission denied
          result['suggestions'].add('Permission denied. Check RLS policies on the $_bucketName bucket'); // Add RLS policy suggestion
        } // End of error code checks
        return result; // Return early with bucket access failure
      } // End of bucket access test

      // Check if we can list files in profiles folder
      try { // Begin try block for file listing test
        await _supabase.storage.from(_bucketName).list(path: 'profiles'); // Try to list files in profiles folder
        result['canListFiles'] = true; // Set file listing flag to true
        print('[OK] Can list files in profiles folder'); // Log successful file listing
      } catch (e) { // Catch file listing errors
        result['errors'].add('Cannot list files in profiles folder: $e'); // Add file listing error to results
        print('[ERROR] Cannot list files in profiles folder, but bucket exists'); // Log file listing error
      } // End of file listing test

      // Try a test upload
      try { // Begin try block for test upload
        final testData = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]); // Create test JPEG header data
        final testFileName = 'test_${DateTime.now().millisecondsSinceEpoch}.jpg'; // Create unique test filename
        
        await _supabase.storage // Upload test file
            .from(_bucketName) // To the specified bucket
            .uploadBinary( // Upload binary data
              testFileName, // With test filename
              testData, // Using test data
              fileOptions: const FileOptions(upsert: true), // Allow overwriting
            ); // End of uploadBinary call
        
        // Clean up test file
        await _supabase.storage.from(_bucketName).remove([testFileName]); // Remove test file after successful upload
        
        result['canUploadTest'] = true; // Set test upload flag to true
        print('[OK] Test upload successful'); // Log successful test upload
      } catch (e) { // Catch test upload errors
        result['errors'].add('Test upload failed: $e'); // Add test upload error to results
        result['suggestions'].add('Check upload permissions and bucket policies'); // Add permissions suggestion
      } // End of test upload

      if (result['errors'].isEmpty) { // Check if no errors occurred
        result['suggestions'].add('Storage configuration appears to be working correctly'); // Add success message
      } // End of error check

    } catch (e) { // Catch any unexpected errors
      result['errors'].add('Unexpected error: $e'); // Add unexpected error to results
    } // End of diagnostic try-catch

    return result; // Return diagnostic results
  } // End of diagnoseStorageIssue method

  // Alternative upload method using a different approach
  static Future<String?> uploadProfileImageFallback(Uint8List imageBytes, String userId) async { // Define static async fallback upload method
    try { // Begin try block for fallback upload error handling
      // Check if user is authenticated
      final user = _supabase.auth.currentUser; // Get current authenticated user
      if (user == null) { // Check if user is not authenticated
        throw 'User not authenticated'; // Throw authentication error
      } // End of authentication check

      // Try uploading directly to root of bucket without subfolder
      final timestamp = DateTime.now().millisecondsSinceEpoch; // Get current timestamp
      final fileName = 'profile_${userId}_$timestamp.jpg'; // Create unique filename for root upload

      print('Fallback: Uploading image to root: $fileName'); // Log fallback upload attempt
      
      // Try to upload the file to bucket root
      final response = await _supabase.storage // Upload file to storage
          .from(_bucketName) // To the specified bucket
          .uploadBinary( // Upload binary data
            fileName, // With filename (no subfolder)
            imageBytes, // Using image bytes
            fileOptions: const FileOptions( // Set upload options
              cacheControl: '3600', // Set cache control to 1 hour
              upsert: true, // Allow overwriting
            ), // End of FileOptions
          ); // End of uploadBinary call

      print('Fallback upload response: $response'); // Log fallback upload response
      
      // Get the public URL
      final publicUrl = _supabase.storage // Get public URL
          .from(_bucketName) // From the specified bucket
          .getPublicUrl(fileName); // For the uploaded file

      print('Fallback public URL: $publicUrl'); // Log fallback public URL
      return publicUrl; // Return fallback public URL
    } catch (e) { // Catch fallback upload errors
      print('Fallback upload also failed: $e'); // Log fallback failure
      return null; // Return null on failure
    } // End of fallback upload try-catch
  } // End of uploadProfileImageFallback method

  /// Create a cache-busting URL for any image URL
  static String createCacheBustingUrl(String originalUrl) { // Define static method to create cache-busting URL
    final timestamp = DateTime.now().millisecondsSinceEpoch; // Get current timestamp for cache busting
    final separator = originalUrl.contains('?') ? '&' : '?'; // Determine URL parameter separator
    return '$originalUrl${separator}cb=$timestamp'; // Return URL with cache-busting parameter
  } // End of createCacheBustingUrl method

  /// Test if an image URL is accessible
  static Future<bool> testImageAccessibility(String url) async { // Define static async method to test image accessibility
    try { // Begin try block for accessibility test error handling
      final response = await _supabase.storage // Access storage
          .from(_bucketName) // From the specified bucket
          .download(url.split('/').last.split('?')[0]); // Download file using cleaned filename (remove query params)
      return response.isNotEmpty; // Return true if response contains data
    } catch (e) { // Catch accessibility test errors
      print('Image accessibility test failed: $e'); // Log accessibility test failure
      return false; // Return failure
    } // End of accessibility test try-catch
  } // End of testImageAccessibility method

  // Create storage bucket if it doesn't exist (requires admin privileges)
  static Future<bool> createStorageBucket() async { // Define static async method for bucket creation instructions
    try { // Begin try block for bucket creation
      // This would require admin privileges and is typically done through the Supabase dashboard
      // For now, we'll just provide instructions
      print('To create the storage bucket:'); // Log bucket creation instructions header
      print('1. Go to your Supabase Dashboard'); // Log first instruction step
      print('2. Navigate to Storage'); // Log second instruction step
      print('3. Create a new bucket named "$_bucketName"'); // Log third instruction step with bucket name
      print('4. Set it to public or configure appropriate RLS policies'); // Log fourth instruction step
      return false; // Return false as actual creation is not implemented
    } catch (e) { // Catch bucket creation errors
      print('Error creating storage bucket: $e'); // Log bucket creation error
      return false; // Return failure
    } // End of bucket creation try-catch
  } // End of createStorageBucket method
} // End of ImageUploadService class
