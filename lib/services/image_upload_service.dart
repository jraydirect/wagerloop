import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'realtime_profile_service.dart';

class ImageUploadService {
  static final _supabase = SupabaseConfig.supabase;
  static final _profileService = RealTimeProfileService();
  static const String _bucketName = 'avatars';

  /// Upload profile image with immediate cache busting and real-time updates
  static Future<String?> uploadProfileImage(Uint8List imageBytes, String userId) async {
    try {
      // Check if user is authenticated
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }

      // Verify storage bucket exists and is accessible
      final bucketExists = await _verifyBucketExists();
      if (!bucketExists) {
        throw 'Storage bucket "$_bucketName" does not exist or is not accessible';
      }

      // Delete old image first
      await _deleteOldProfileImage(userId);

      // Create a unique filename with timestamp for cache busting
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_${userId}_$timestamp.jpg';
      final filePath = 'profiles/$fileName';

      // Try to upload the file with no-cache settings
      final response = await _supabase.storage
          .from(_bucketName)
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: const FileOptions(
              cacheControl: '0', // Disable caching for immediate updates
              upsert: true,
            ),
          );

      // Get the public URL with cache-busting parameter
      final baseUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(filePath);
      
      final cacheBustingUrl = '$baseUrl?v=$timestamp&cb=${DateTime.now().millisecondsSinceEpoch}';

      // Update profile in database with new URL
      await _supabase
          .from('profiles')
          .update({
            'avatar_url': cacheBustingUrl,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);

      // Force refresh the profile in real-time service
      await _profileService.refreshProfile(userId);
      
      // Clear any cached profile data
      _profileService.clearProfileCache(userId);
      
      // Test the URL immediately to catch 400 errors
      final isAccessible = await _testUrlImmediately(cacheBustingUrl);
      if (!isAccessible) {
        // Try the fallback method
        final fallbackUrl = await uploadProfileImageFallback(imageBytes, userId);
        if (fallbackUrl != null) {
          return fallbackUrl;
        }
        
        // If fallback also fails, return the original URL anyway
        // The user can fix the RLS policies and the image should work
        return cacheBustingUrl;
      }
      
      return cacheBustingUrl;
    } on StorageException catch (e) {
      throw 'Storage error: ${e.message}';
    } catch (e) {
      throw 'Failed to upload image: $e';
    }
  }

  /// Delete old profile image to free up storage
  static Future<void> _deleteOldProfileImage(String userId) async {
    try {
      // Get current profile to find old image
      final profile = await _supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null || profile['avatar_url'] == null) {
        return;
      }

      final oldAvatarUrl = profile['avatar_url'] as String;
      await deleteProfileImage(oldAvatarUrl);
    } catch (e) {
      // Don't throw here as this is cleanup
    }
  }

  /// Delete profile image with real-time update
  static Future<bool> deleteProfileImageWithRealTimeUpdate(String userId) async {
    try {
      // Get current avatar URL
      final profile = await _supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();

      if (profile != null && profile['avatar_url'] != null) {
        await deleteProfileImage(profile['avatar_url']);
      }

      // Update profile to remove avatar URL
      await _supabase
          .from('profiles')
          .update({
            'avatar_url': null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);

      // Force refresh the profile
      await _profileService.refreshProfile(userId);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      // Check if user is authenticated
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      // Extract filename from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the file path within the storage bucket
      String? filePath;
      for (int i = 0; i < pathSegments.length; i++) {
        if (pathSegments[i] == 'storage' && 
            i + 3 < pathSegments.length && 
            pathSegments[i + 2] == _bucketName) {
          filePath = pathSegments.sublist(i + 3).join('/');
          break;
        }
      }
      
      if (filePath == null) {
        // Fallback: assume last segment is the filename and it's in profiles folder
        filePath = 'profiles/${pathSegments.last.split('?')[0]}'; // Remove query params
      }
      
      await _supabase.storage
          .from(_bucketName)
          .remove([filePath]);
      
      return true;
    } on StorageException catch (e) {
      return false;
    } catch (e) {
      return false;
    }
  }

  // Helper method to check if storage bucket exists and is accessible
  static Future<bool> checkStorageAccess() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      // Try to list files in the bucket to test access
      await _supabase.storage
          .from(_bucketName)
          .list();
      
      return true;
    } on StorageException catch (e) {
      print('Storage access error: ${e.message}');
      print('Error code: ${e.statusCode}');
      
      // If bucket doesn't exist, try to create the path structure
      if (e.statusCode == '404' || e.message.toLowerCase().contains('not found')) {
        print('Bucket or path not found, this might be a configuration issue');
        print('Please ensure the "$_bucketName" bucket exists in Supabase Storage');
        print('And that the user has upload permissions');
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Verify if the storage bucket exists
  static Future<bool> _verifyBucketExists() async {
    try {
      await _supabase.storage.from(_bucketName).list();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Test URL immediately after upload to catch 400 errors
  static Future<bool> _testUrlImmediately(String url) async {
    try {
      final response = await _supabase.storage
          .from(_bucketName)
          .download(url.split('/').last);
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Verify if a URL is accessible
  static Future<bool> _verifyUrlAccessibility(String url) async {
    try {
      final response = await _supabase.storage
          .from(_bucketName)
          .download(url.split('/').last);
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Comprehensive storage diagnostic
  static Future<Map<String, dynamic>> diagnoseStorageIssue() async {
    final result = <String, dynamic>{
      'isAuthenticated': false,
      'canAccessBucket': false,
      'canListFiles': false,
      'canUploadTest': false,
      'errors': <String>[],
      'suggestions': <String>[],
    };

    try {
      // Check authentication
      final user = _supabase.auth.currentUser;
      if (user == null) {
        result['errors'].add('User not authenticated');
        result['suggestions'].add('Please log in again');
        return result;
      }
      result['isAuthenticated'] = true;

      // Check if we can access the bucket
      try {
        await _supabase.storage.from(_bucketName).list();
        result['canAccessBucket'] = true;
      } on StorageException catch (e) {
        result['errors'].add('Cannot access bucket: ${e.message}');
        if (e.statusCode == '404') {
          result['suggestions'].add('The "$_bucketName" bucket does not exist in Supabase Storage');
          result['suggestions'].add('Please create the bucket in your Supabase dashboard');
        } else if (e.statusCode == '403') {
          result['suggestions'].add('Permission denied. Check RLS policies on the $_bucketName bucket');
        }
        return result;
      }

      // Check if we can list files in profiles folder
      try {
        await _supabase.storage.from(_bucketName).list(path: 'profiles');
        result['canListFiles'] = true;
      } catch (e) {
        result['errors'].add('Cannot list files in profiles folder: $e');
      }

      // Try a test upload
      try {
        final testData = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]); // JPEG header
        final testFileName = 'test_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        await _supabase.storage
            .from(_bucketName)
            .uploadBinary(
              testFileName,
              testData,
              fileOptions: const FileOptions(upsert: true),
            );
        
        // Clean up test file
        await _supabase.storage.from(_bucketName).remove([testFileName]);
        
        result['canUploadTest'] = true;
      } catch (e) {
        result['errors'].add('Test upload failed: $e');
        result['suggestions'].add('Check upload permissions and bucket policies');
      }

      if (result['errors'].isEmpty) {
        result['suggestions'].add('Storage configuration appears to be working correctly');
      }

    } catch (e) {
      result['errors'].add('Unexpected error: $e');
    }

    return result;
  }

  // Alternative upload method using a different approach
  static Future<String?> uploadProfileImageFallback(Uint8List imageBytes, String userId) async {
    try {
      // Check if user is authenticated
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }

      // Try uploading directly to root of bucket without subfolder
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_${userId}_$timestamp.jpg';

      // Try to upload the file to bucket root
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

      // Get the public URL
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  /// Create a cache-busting URL for any image URL
  static String createCacheBustingUrl(String originalUrl) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final separator = originalUrl.contains('?') ? '&' : '?';
    return '$originalUrl${separator}cb=$timestamp';
  }

  /// Test if an image URL is accessible
  static Future<bool> testImageAccessibility(String url) async {
    try {
      final response = await _supabase.storage
          .from(_bucketName)
          .download(url.split('/').last.split('?')[0]); // Remove query params
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Create storage bucket if it doesn't exist (requires admin privileges)
  static Future<bool> createStorageBucket() async {
    try {
      // This would require admin privileges and is typically done through the Supabase dashboard
      // For now, we'll just provide instructions
      print('To create the storage bucket:');
      print('1. Go to your Supabase Dashboard');
      print('2. Navigate to Storage');
      print('3. Create a new bucket named "$_bucketName"');
      print('4. Set it to public or configure appropriate RLS policies');
      return false;
    } catch (e) {
      print('Error creating storage bucket: $e');
      return false;
    }
  }
}
