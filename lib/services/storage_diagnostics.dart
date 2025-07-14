import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'dart:convert';

/// A comprehensive storage diagnostics utility for debugging Supabase storage issues
class StorageDiagnostics {
  static const String bucketName = 'profile-images';
  static const String testFileName = 'diagnostic-test.txt';
  
  /// Runs a comprehensive diagnostic test of the storage system
  static Future<Map<String, dynamic>> runFullDiagnostic() async {
    final results = <String, dynamic>{
      'bucketExists': false,
      'canAccessBucket': false,
      'canListFiles': false,
      'canUpload': false,
      'canDownload': false,
      'canDelete': false,
      'errors': <String>[],
      'warnings': <String>[],
      'suggestions': <String>[],
    };

    try {
      final supabase = Supabase.instance.client;
      
      // Test 1: Check if bucket exists
      try {
        await supabase.storage.getBucket(bucketName);
        results['bucketExists'] = true;
        print('✓ Bucket exists: $bucketName');
      } catch (e) {
        results['errors'].add('Bucket does not exist or cannot be accessed: $e');
        results['suggestions'].add('Create the "$bucketName" bucket in Supabase dashboard');
        print('✗ Bucket test failed: $e');
      }

      // Test 2: Try to access bucket
      if (results['bucketExists']) {
        try {
          final bucket = supabase.storage.from(bucketName);
          results['canAccessBucket'] = true;
          print('✓ Can access bucket');
        } catch (e) {
          results['errors'].add('Cannot access bucket: $e');
          print('✗ Bucket access failed: $e');
        }
      }

      // Test 3: Try to list files
      if (results['canAccessBucket']) {
        try {
          final files = await supabase.storage.from(bucketName).list();
          results['canListFiles'] = true;
          print('✓ Can list files (found ${files.length} files)');
        } catch (e) {
          results['errors'].add('Cannot list files: $e');
          results['suggestions'].add('Check bucket permissions for listing files');
          print('✗ List files failed: $e');
        }
      }

      // Test 4: Try to upload a test file
      if (results['canAccessBucket']) {
        try {
          final testData = Uint8List.fromList(utf8.encode('Storage diagnostic test'));
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final testPath = 'diagnostics/test-$timestamp.txt';
          
          await supabase.storage.from(bucketName).uploadBinary(
            testPath,
            testData,
            fileOptions: const FileOptions(
              cacheControl: '0',
              upsert: true,
            ),
          );
          
          results['canUpload'] = true;
          results['_testPath'] = testPath; // Store for cleanup
          print('✓ Can upload files');
        } catch (e) {
          results['errors'].add('Cannot upload files: $e');
          results['suggestions'].add('Check bucket permissions for uploading files');
          print('✗ Upload test failed: $e');
        }
      }

      // Test 5: Try to download the test file
      if (results['canUpload'] && results['_testPath'] != null) {
        try {
          final downloadedData = await supabase.storage
              .from(bucketName)
              .download(results['_testPath']);
          
          if (downloadedData.isNotEmpty) {
            results['canDownload'] = true;
            print('✓ Can download files');
          } else {
            results['warnings'].add('Download succeeded but returned empty data');
            print('⚠ Download returned empty data');
          }
        } catch (e) {
          results['errors'].add('Cannot download files: $e');
          results['suggestions'].add('Check bucket permissions for downloading files');
          print('✗ Download test failed: $e');
        }
      }

      // Test 6: Try to delete the test file
      if (results['canUpload'] && results['_testPath'] != null) {
        try {
          await supabase.storage.from(bucketName).remove([results['_testPath']]);
          results['canDelete'] = true;
          print('✓ Can delete files');
        } catch (e) {
          results['errors'].add('Cannot delete files: $e');
          results['suggestions'].add('Check bucket permissions for deleting files');
          results['warnings'].add('Test file may remain in storage: ${results['_testPath']}');
          print('✗ Delete test failed: $e');
        }
      }

      // Additional checks and suggestions
      _addAdditionalSuggestions(results);

    } catch (e) {
      results['errors'].add('General diagnostic error: $e');
      results['suggestions'].add('Check Supabase connection and configuration');
      print('✗ General diagnostic error: $e');
    }

    // Clean up the test path from results
    results.remove('_testPath');

    return results;
  }

  /// Adds additional suggestions based on the diagnostic results
  static void _addAdditionalSuggestions(Map<String, dynamic> results) {
    if (!results['bucketExists']) {
      results['suggestions'].add('Verify bucket name matches your Supabase configuration');
      results['suggestions'].add('Check that you have the correct project URL and anon key');
    }

    if (results['bucketExists'] && !results['canAccessBucket']) {
      results['suggestions'].add('Check if user is authenticated');
      results['suggestions'].add('Verify bucket permissions in Supabase dashboard');
    }

    if (results['canAccessBucket'] && !results['canListFiles']) {
      results['suggestions'].add('Enable "List" permission for authenticated users');
    }

    if (results['canListFiles'] && !results['canUpload']) {
      results['suggestions'].add('Enable "Insert" permission for authenticated users');
      results['suggestions'].add('Check file size limits and formats');
    }

    if (results['canUpload'] && !results['canDownload']) {
      results['suggestions'].add('Enable "Select" permission for authenticated users');
    }

    if (results['canDownload'] && !results['canDelete']) {
      results['suggestions'].add('Enable "Delete" permission for authenticated users');
    }

    // Check for authentication
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      results['warnings'].add('User is not authenticated - some operations may fail');
      results['suggestions'].add('Ensure user is logged in before testing storage');
    } else {
      print('✓ User is authenticated: ${user.email}');
    }
  }

  /// Prints diagnostic results in a formatted way to the console
  static void printDiagnosticResults(Map<String, dynamic> results) {
    print('\n' + '=' * 50);
    print('STORAGE DIAGNOSTICS RESULTS');
    print('=' * 50);

    // Print test results
    print('\nTest Results:');
    print('  Bucket Exists: ${_formatResult(results['bucketExists'])}');
    print('  Can Access Bucket: ${_formatResult(results['canAccessBucket'])}');
    print('  Can List Files: ${_formatResult(results['canListFiles'])}');
    print('  Can Upload: ${_formatResult(results['canUpload'])}');
    print('  Can Download: ${_formatResult(results['canDownload'])}');
    print('  Can Delete: ${_formatResult(results['canDelete'])}');

    // Print errors
    final errors = results['errors'] as List<String>;
    if (errors.isNotEmpty) {
      print('\nErrors Found:');
      for (int i = 0; i < errors.length; i++) {
        print('  ${i + 1}. ${errors[i]}');
      }
    }

    // Print warnings
    final warnings = results['warnings'] as List<String>;
    if (warnings.isNotEmpty) {
      print('\nWarnings:');
      for (int i = 0; i < warnings.length; i++) {
        print('  ${i + 1}. ${warnings[i]}');
      }
    }

    // Print suggestions
    final suggestions = results['suggestions'] as List<String>;
    if (suggestions.isNotEmpty) {
      print('\nSuggestions:');
      for (int i = 0; i < suggestions.length; i++) {
        print('  ${i + 1}. ${suggestions[i]}');
      }
    }

    // Overall status
    final allPassed = results['bucketExists'] && 
                     results['canAccessBucket'] && 
                     results['canListFiles'] && 
                     results['canUpload'] && 
                     results['canDownload'] && 
                     results['canDelete'];

    print('\nOverall Status: ${allPassed ? '✓ ALL TESTS PASSED' : '✗ SOME TESTS FAILED'}');
    
    if (!allPassed) {
      print('\nRecommended Actions:');
      print('  1. Review the errors and warnings above');
      print('  2. Check bucket permissions in Supabase dashboard');
      print('  3. Verify user authentication status');
      print('  4. Ensure bucket name matches configuration');
    }

    print('=' * 50 + '\n');
  }

  /// Formats a boolean result for display
  static String _formatResult(bool result) {
    return result ? '✓ PASS' : '✗ FAIL';
  }

  /// Quick test method for basic storage connectivity
  static Future<bool> quickConnectivityTest() async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.storage.getBucket(bucketName);
      return true;
    } catch (e) {
      print('Quick connectivity test failed: $e');
      return false;
    }
  }

  /// Test specifically for profile image operations
  static Future<Map<String, dynamic>> testProfileImageOperations() async {
    final results = <String, dynamic>{
      'canCreateProfilePath': false,
      'canUploadProfileImage': false,
      'canGenerateSignedUrl': false,
      'canDeleteProfileImage': false,
      'errors': <String>[],
      'suggestions': <String>[],
    };

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user == null) {
        results['errors'].add('User not authenticated');
        return results;
      }

      final userId = user.id;
      final testImagePath = 'profiles/$userId/test-${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Create test image data (1x1 pixel JPEG)
      final testImageData = base64Decode(
        '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwA/wA8='
      );

      // Test profile image upload
      try {
        await supabase.storage.from(bucketName).uploadBinary(
          testImagePath,
          Uint8List.fromList(testImageData),
          fileOptions: const FileOptions(
            cacheControl: '0',
            upsert: true,
          ),
        );
        results['canUploadProfileImage'] = true;
        print('✓ Can upload profile images');
      } catch (e) {
        results['errors'].add('Cannot upload profile images: $e');
        print('✗ Profile image upload failed: $e');
      }

      // Test signed URL generation
      if (results['canUploadProfileImage']) {
        try {
          final signedUrl = await supabase.storage
              .from(bucketName)
              .createSignedUrl(testImagePath, 3600);
          
          if (signedUrl.isNotEmpty) {
            results['canGenerateSignedUrl'] = true;
            print('✓ Can generate signed URLs');
          }
        } catch (e) {
          results['errors'].add('Cannot generate signed URLs: $e');
          print('✗ Signed URL generation failed: $e');
        }
      }

      // Test profile image deletion
      if (results['canUploadProfileImage']) {
        try {
          await supabase.storage.from(bucketName).remove([testImagePath]);
          results['canDeleteProfileImage'] = true;
          print('✓ Can delete profile images');
        } catch (e) {
          results['errors'].add('Cannot delete profile images: $e');
          print('✗ Profile image deletion failed: $e');
        }
      }

    } catch (e) {
      results['errors'].add('Profile image test error: $e');
      print('✗ Profile image test error: $e');
    }

    return results;
  }
}
