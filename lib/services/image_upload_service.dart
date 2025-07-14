import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class ImageUploadService {
  static final _supabase = SupabaseConfig.supabase;
  static const String _bucketName = 'avatars';

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

      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_${userId}_$timestamp.jpg';
      final filePath = 'profiles/$fileName';

      print('Uploading image to: $filePath');
      print('Image size: ${imageBytes.length} bytes');
      
      // Try to upload the file
      final response = await _supabase.storage
          .from(_bucketName)
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      print('Upload response: $response');
      
      // Get the public URL
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      print('Public URL: $publicUrl');
      
      // Test the URL immediately to catch 400 errors
      final isAccessible = await _testUrlImmediately(publicUrl);
      if (!isAccessible) {
        print('Warning: URL returned 400 error, this usually means RLS policies need to be set up');
        print('Please run the storage_setup_simple.sql script in your Supabase SQL Editor');
        
        // Try the fallback method
        print('Trying fallback upload method...');
        final fallbackUrl = await uploadProfileImageFallback(imageBytes, userId);
        if (fallbackUrl != null) {
          return fallbackUrl;
        }
        
        // If fallback also fails, return the original URL anyway
        // The user can fix the RLS policies and the image should work
        print('Returning original URL - user needs to fix RLS policies');
        return publicUrl;
      }
      
      return publicUrl;
    } on StorageException catch (e) {
      print('Storage error: ${e.message}');
      print('Storage error details: ${e.error}');
      throw 'Storage error: ${e.message}';
    } catch (e) {
      print('Error uploading image: $e');
      throw 'Failed to upload image: $e';
    }
  }

  static Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      // Check if user is authenticated
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('User not authenticated for deletion');
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
        filePath = 'profiles/${pathSegments.last}';
      }
      
      print('Deleting file: $filePath');
      
      await _supabase.storage
          .from(_bucketName)
          .remove([filePath]);
      
      print('File deleted successfully');
      return true;
    } on StorageException catch (e) {
      print('Storage error deleting file: ${e.message}');
      return false;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  // Helper method to check if storage bucket exists and is accessible
  static Future<bool> checkStorageAccess() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('User not authenticated');
        return false;
      }

      // Try to list files in the bucket to test access
      await _supabase.storage
          .from(_bucketName)
          .list();
      
      print('Storage access check passed');
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
      print('Storage access check failed: $e');
      return false;
    }
  }

  // Verify if the storage bucket exists
  static Future<bool> _verifyBucketExists() async {
    try {
      await _supabase.storage.from(_bucketName).list();
      return true;
    } catch (e) {
      print('Bucket verification failed: $e');
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
      print('URL immediate test failed: $e');
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
      print('URL accessibility check failed: $e');
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
      print('[OK] User authenticated: ${user.id}');

      // Check if we can access the bucket
      try {
        await _supabase.storage.from(_bucketName).list();
        result['canAccessBucket'] = true;
        print('[OK] Can access bucket: $_bucketName');
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
        print('[OK] Can list files in profiles folder');
      } catch (e) {
        result['errors'].add('Cannot list files in profiles folder: $e');
        print('[ERROR] Cannot list files in profiles folder, but bucket exists');
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
        print('[OK] Test upload successful');
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

      print('Fallback: Uploading image to root: $fileName');
      
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

      print('Fallback upload response: $response');
      
      // Get the public URL
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(fileName);

      print('Fallback public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Fallback upload also failed: $e');
      return null;
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
