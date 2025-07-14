import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase Flutter SDK for storage operations
import 'dart:typed_data'; // Import Dart typed data library for Uint8List operations
import 'dart:convert'; // Import Dart convert library for base64 and UTF-8 encoding/decoding

/// A comprehensive storage diagnostics utility for debugging Supabase storage issues
class StorageDiagnostics { // Define StorageDiagnostics class as a utility for debugging storage operations
  static const String bucketName = 'profile-images'; // Define constant for the storage bucket name
  static const String testFileName = 'diagnostic-test.txt'; // Define constant for test file name
  
  /// Runs a comprehensive diagnostic test of the storage system
  static Future<Map<String, dynamic>> runFullDiagnostic() async { // Define static async method to run comprehensive storage diagnostics
    final results = <String, dynamic>{ // Initialize results map with default values
      'bucketExists': false, // Flag for bucket existence test
      'canAccessBucket': false, // Flag for bucket access test
      'canListFiles': false, // Flag for file listing test
      'canUpload': false, // Flag for file upload test
      'canDownload': false, // Flag for file download test
      'canDelete': false, // Flag for file deletion test
      'errors': <String>[], // List to store error messages
      'warnings': <String>[], // List to store warning messages
      'suggestions': <String>[], // List to store suggestion messages
    }; // End of results map initialization

    try { // Begin try block for overall error handling
      final supabase = Supabase.instance.client; // Get Supabase client instance
      
      // Test 1: Check if bucket exists
      try { // Begin try block for bucket existence test
        await supabase.storage.getBucket(bucketName); // Attempt to get bucket information
        results['bucketExists'] = true; // Set bucket exists flag to true
        print('✓ Bucket exists: $bucketName'); // Log successful bucket existence check
      } catch (e) { // Catch bucket existence check errors
        results['errors'].add('Bucket does not exist or cannot be accessed: $e'); // Add error message to results
        results['suggestions'].add('Create the "$bucketName" bucket in Supabase dashboard'); // Add suggestion to create bucket
        print('✗ Bucket test failed: $e'); // Log bucket test failure
      } // End of bucket existence test

      // Test 2: Try to access bucket
      if (results['bucketExists']) { // Check if bucket exists before testing access
        try { // Begin try block for bucket access test
          final bucket = supabase.storage.from(bucketName); // Get bucket reference
          results['canAccessBucket'] = true; // Set bucket access flag to true
          print('✓ Can access bucket'); // Log successful bucket access
        } catch (e) { // Catch bucket access errors
          results['errors'].add('Cannot access bucket: $e'); // Add error message to results
          print('✗ Bucket access failed: $e'); // Log bucket access failure
        } // End of bucket access test
      } // End of bucket exists check

      // Test 3: Try to list files
      if (results['canAccessBucket']) { // Check if bucket can be accessed before testing file listing
        try { // Begin try block for file listing test
          final files = await supabase.storage.from(bucketName).list(); // Attempt to list files in bucket
          results['canListFiles'] = true; // Set file listing flag to true
          print('✓ Can list files (found ${files.length} files)'); // Log successful file listing with count
        } catch (e) { // Catch file listing errors
          results['errors'].add('Cannot list files: $e'); // Add error message to results
          results['suggestions'].add('Check bucket permissions for listing files'); // Add suggestion for permissions
          print('✗ List files failed: $e'); // Log file listing failure
        } // End of file listing test
      } // End of bucket access check

      // Test 4: Try to upload a test file
      if (results['canAccessBucket']) { // Check if bucket can be accessed before testing upload
        try { // Begin try block for file upload test
          final testData = Uint8List.fromList(utf8.encode('Storage diagnostic test')); // Create test data as UTF-8 encoded bytes
          final timestamp = DateTime.now().millisecondsSinceEpoch; // Get current timestamp for unique filename
          final testPath = 'diagnostics/test-$timestamp.txt'; // Create unique test file path
          
          await supabase.storage.from(bucketName).uploadBinary( // Upload test file to storage
            testPath, // Specify the file path
            testData, // Provide the test data
            fileOptions: const FileOptions( // Set file upload options
              cacheControl: '0', // Disable caching for test file
              upsert: true, // Allow overwriting existing files
            ), // End of FileOptions
          ); // End of uploadBinary call
          
          results['canUpload'] = true; // Set upload flag to true
          results['_testPath'] = testPath; // Store test path for cleanup
          print('✓ Can upload files'); // Log successful file upload
        } catch (e) { // Catch file upload errors
          results['errors'].add('Cannot upload files: $e'); // Add error message to results
          results['suggestions'].add('Check bucket permissions for uploading files'); // Add suggestion for permissions
          print('✗ Upload test failed: $e'); // Log upload test failure
        } // End of file upload test
      } // End of bucket access check

      // Test 5: Try to download the test file
      if (results['canUpload'] && results['_testPath'] != null) { // Check if upload succeeded and test path exists
        try { // Begin try block for file download test
          final downloadedData = await supabase.storage // Download the test file
              .from(bucketName) // From the specified bucket
              .download(results['_testPath']); // Using the stored test path
          
          if (downloadedData.isNotEmpty) { // Check if downloaded data is not empty
            results['canDownload'] = true; // Set download flag to true
            print('✓ Can download files'); // Log successful file download
          } else { // If downloaded data is empty
            results['warnings'].add('Download succeeded but returned empty data'); // Add warning about empty data
            print('⚠ Download returned empty data'); // Log warning about empty data
          } // End of data emptiness check
        } catch (e) { // Catch file download errors
          results['errors'].add('Cannot download files: $e'); // Add error message to results
          results['suggestions'].add('Check bucket permissions for downloading files'); // Add suggestion for permissions
          print('✗ Download test failed: $e'); // Log download test failure
        } // End of file download test
      } // End of upload success check

      // Test 6: Try to delete the test file
      if (results['canUpload'] && results['_testPath'] != null) { // Check if upload succeeded and test path exists
        try { // Begin try block for file deletion test
          await supabase.storage.from(bucketName).remove([results['_testPath']]); // Delete the test file
          results['canDelete'] = true; // Set deletion flag to true
          print('✓ Can delete files'); // Log successful file deletion
        } catch (e) { // Catch file deletion errors
          results['errors'].add('Cannot delete files: $e'); // Add error message to results
          results['suggestions'].add('Check bucket permissions for deleting files'); // Add suggestion for permissions
          results['warnings'].add('Test file may remain in storage: ${results['_testPath']}'); // Add warning about remaining test file
          print('✗ Delete test failed: $e'); // Log deletion test failure
        } // End of file deletion test
      } // End of upload success check

      // Additional checks and suggestions
      _addAdditionalSuggestions(results); // Call method to add additional suggestions based on results

    } catch (e) { // Catch any general diagnostic errors
      results['errors'].add('General diagnostic error: $e'); // Add general error message to results
      results['suggestions'].add('Check Supabase connection and configuration'); // Add suggestion for connection check
      print('✗ General diagnostic error: $e'); // Log general diagnostic error
    } // End of overall try-catch block

    // Clean up the test path from results
    results.remove('_testPath'); // Remove internal test path from results

    return results; // Return the diagnostic results
  } // End of runFullDiagnostic method

  /// Adds additional suggestions based on the diagnostic results
  static void _addAdditionalSuggestions(Map<String, dynamic> results) { // Define static method to add contextual suggestions
    if (!results['bucketExists']) { // Check if bucket doesn't exist
      results['suggestions'].add('Verify bucket name matches your Supabase configuration'); // Add suggestion to verify bucket name
      results['suggestions'].add('Check that you have the correct project URL and anon key'); // Add suggestion to check configuration
    } // End of bucket exists check

    if (results['bucketExists'] && !results['canAccessBucket']) { // Check if bucket exists but cannot be accessed
      results['suggestions'].add('Check if user is authenticated'); // Add suggestion to check authentication
      results['suggestions'].add('Verify bucket permissions in Supabase dashboard'); // Add suggestion to check permissions
    } // End of bucket access check

    if (results['canAccessBucket'] && !results['canListFiles']) { // Check if bucket can be accessed but files cannot be listed
      results['suggestions'].add('Enable "List" permission for authenticated users'); // Add suggestion to enable list permission
    } // End of file listing check

    if (results['canListFiles'] && !results['canUpload']) { // Check if files can be listed but cannot be uploaded
      results['suggestions'].add('Enable "Insert" permission for authenticated users'); // Add suggestion to enable insert permission
      results['suggestions'].add('Check file size limits and formats'); // Add suggestion to check file limits
    } // End of upload check

    if (results['canUpload'] && !results['canDownload']) { // Check if files can be uploaded but cannot be downloaded
      results['suggestions'].add('Enable "Select" permission for authenticated users'); // Add suggestion to enable select permission
    } // End of download check

    if (results['canDownload'] && !results['canDelete']) { // Check if files can be downloaded but cannot be deleted
      results['suggestions'].add('Enable "Delete" permission for authenticated users'); // Add suggestion to enable delete permission
    } // End of delete check

    // Check for authentication
    final user = Supabase.instance.client.auth.currentUser; // Get current authenticated user
    if (user == null) { // Check if user is not authenticated
      results['warnings'].add('User is not authenticated - some operations may fail'); // Add warning about authentication
      results['suggestions'].add('Ensure user is logged in before testing storage'); // Add suggestion to log in
    } else { // If user is authenticated
      print('✓ User is authenticated: ${user.email}'); // Log authenticated user email
    } // End of authentication check
  } // End of _addAdditionalSuggestions method

  /// Prints diagnostic results in a formatted way to the console
  static void printDiagnosticResults(Map<String, dynamic> results) { // Define static method to print formatted diagnostic results
    print('\n' + '=' * 50); // Print header separator
    print('STORAGE DIAGNOSTICS RESULTS'); // Print header title
    print('=' * 50); // Print header separator

    // Print test results
    print('\nTest Results:'); // Print test results section header
    print('  Bucket Exists: ${_formatResult(results['bucketExists'])}'); // Print bucket existence result
    print('  Can Access Bucket: ${_formatResult(results['canAccessBucket'])}'); // Print bucket access result
    print('  Can List Files: ${_formatResult(results['canListFiles'])}'); // Print file listing result
    print('  Can Upload: ${_formatResult(results['canUpload'])}'); // Print upload result
    print('  Can Download: ${_formatResult(results['canDownload'])}'); // Print download result
    print('  Can Delete: ${_formatResult(results['canDelete'])}'); // Print deletion result

    // Print errors
    final errors = results['errors'] as List<String>; // Cast errors to string list
    if (errors.isNotEmpty) { // Check if there are any errors
      print('\nErrors Found:'); // Print errors section header
      for (int i = 0; i < errors.length; i++) { // Iterate through each error
        print('  ${i + 1}. ${errors[i]}'); // Print numbered error message
      } // End of errors loop
    } // End of errors check

    // Print warnings
    final warnings = results['warnings'] as List<String>; // Cast warnings to string list
    if (warnings.isNotEmpty) { // Check if there are any warnings
      print('\nWarnings:'); // Print warnings section header
      for (int i = 0; i < warnings.length; i++) { // Iterate through each warning
        print('  ${i + 1}. ${warnings[i]}'); // Print numbered warning message
      } // End of warnings loop
    } // End of warnings check

    // Print suggestions
    final suggestions = results['suggestions'] as List<String>; // Cast suggestions to string list
    if (suggestions.isNotEmpty) { // Check if there are any suggestions
      print('\nSuggestions:'); // Print suggestions section header
      for (int i = 0; i < suggestions.length; i++) { // Iterate through each suggestion
        print('  ${i + 1}. ${suggestions[i]}'); // Print numbered suggestion message
      } // End of suggestions loop
    } // End of suggestions check

    // Overall status
    final allPassed = results['bucketExists'] && // Check if bucket exists
                     results['canAccessBucket'] && // Check if bucket can be accessed
                     results['canListFiles'] && // Check if files can be listed
                     results['canUpload'] && // Check if files can be uploaded
                     results['canDownload'] && // Check if files can be downloaded
                     results['canDelete']; // Check if files can be deleted

    print('\nOverall Status: ${allPassed ? '✓ ALL TESTS PASSED' : '✗ SOME TESTS FAILED'}'); // Print overall status based on all tests
    
    if (!allPassed) { // Check if not all tests passed
      print('\nRecommended Actions:'); // Print recommended actions header
      print('  1. Review the errors and warnings above'); // Print first recommendation
      print('  2. Check bucket permissions in Supabase dashboard'); // Print second recommendation
      print('  3. Verify user authentication status'); // Print third recommendation
      print('  4. Ensure bucket name matches configuration'); // Print fourth recommendation
    } // End of failed tests check

    print('=' * 50 + '\n'); // Print footer separator
  } // End of printDiagnosticResults method

  /// Formats a boolean result for display
  static String _formatResult(bool result) { // Define static method to format boolean results for display
    return result ? '✓ PASS' : '✗ FAIL'; // Return formatted result string
  } // End of _formatResult method

  /// Quick test method for basic storage connectivity
  static Future<bool> quickConnectivityTest() async { // Define static async method for quick connectivity test
    try { // Begin try block for connectivity test
      final supabase = Supabase.instance.client; // Get Supabase client instance
      await supabase.storage.getBucket(bucketName); // Attempt to get bucket information
      return true; // Return true if connectivity test succeeds
    } catch (e) { // Catch connectivity test errors
      print('Quick connectivity test failed: $e'); // Log connectivity test failure
      return false; // Return false if connectivity test fails
    } // End of connectivity test try-catch
  } // End of quickConnectivityTest method

  /// Test specifically for profile image operations
  static Future<Map<String, dynamic>> testProfileImageOperations() async { // Define static async method to test profile image operations
    final results = <String, dynamic>{ // Initialize results map for profile image tests
      'canCreateProfilePath': false, // Flag for profile path creation test
      'canUploadProfileImage': false, // Flag for profile image upload test
      'canGenerateSignedUrl': false, // Flag for signed URL generation test
      'canDeleteProfileImage': false, // Flag for profile image deletion test
      'errors': <String>[], // List to store error messages
      'suggestions': <String>[], // List to store suggestion messages
    }; // End of results map initialization

    try { // Begin try block for profile image operations
      final supabase = Supabase.instance.client; // Get Supabase client instance
      final user = supabase.auth.currentUser; // Get current authenticated user
      
      if (user == null) { // Check if user is not authenticated
        results['errors'].add('User not authenticated'); // Add authentication error
        return results; // Return early if not authenticated
      } // End of authentication check

      final userId = user.id; // Get user ID from authenticated user
      final testImagePath = 'profiles/$userId/test-${DateTime.now().millisecondsSinceEpoch}.jpg'; // Create unique test image path
      
      // Create test image data (1x1 pixel JPEG)
      final testImageData = base64Decode( // Decode base64 string to create test image data
        '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxAAPwA/wA8=' // Base64 encoded 1x1 pixel JPEG image
      ); // End of base64 decode

      // Test profile image upload
      try { // Begin try block for profile image upload test
        await supabase.storage.from(bucketName).uploadBinary( // Upload test image to storage
          testImagePath, // Specify the test image path
          Uint8List.fromList(testImageData), // Convert test image data to Uint8List
          fileOptions: const FileOptions( // Set file upload options
            cacheControl: '0', // Disable caching for test file
            upsert: true, // Allow overwriting existing files
          ), // End of FileOptions
        ); // End of uploadBinary call
        results['canUploadProfileImage'] = true; // Set profile image upload flag to true
        print('✓ Can upload profile images'); // Log successful profile image upload
      } catch (e) { // Catch profile image upload errors
        results['errors'].add('Cannot upload profile images: $e'); // Add error message to results
        print('✗ Profile image upload failed: $e'); // Log profile image upload failure
      } // End of profile image upload test

      // Test signed URL generation
      if (results['canUploadProfileImage']) { // Check if profile image upload succeeded
        try { // Begin try block for signed URL generation test
          final signedUrl = await supabase.storage // Generate signed URL for test image
              .from(bucketName) // From the specified bucket
              .createSignedUrl(testImagePath, 3600); // Create signed URL valid for 1 hour
          
          if (signedUrl.isNotEmpty) { // Check if signed URL is not empty
            results['canGenerateSignedUrl'] = true; // Set signed URL generation flag to true
            print('✓ Can generate signed URLs'); // Log successful signed URL generation
          } // End of signed URL emptiness check
        } catch (e) { // Catch signed URL generation errors
          results['errors'].add('Cannot generate signed URLs: $e'); // Add error message to results
          print('✗ Signed URL generation failed: $e'); // Log signed URL generation failure
        } // End of signed URL generation test
      } // End of upload success check

      // Test profile image deletion
      if (results['canUploadProfileImage']) { // Check if profile image upload succeeded
        try { // Begin try block for profile image deletion test
          await supabase.storage.from(bucketName).remove([testImagePath]); // Delete the test image
          results['canDeleteProfileImage'] = true; // Set profile image deletion flag to true
          print('✓ Can delete profile images'); // Log successful profile image deletion
        } catch (e) { // Catch profile image deletion errors
          results['errors'].add('Cannot delete profile images: $e'); // Add error message to results
          print('✗ Profile image deletion failed: $e'); // Log profile image deletion failure
        } // End of profile image deletion test
      } // End of upload success check

    } catch (e) { // Catch any general profile image test errors
      results['errors'].add('Profile image test error: $e'); // Add general error message to results
      print('✗ Profile image test error: $e'); // Log general profile image test error
    } // End of profile image operations try-catch

    return results; // Return the profile image test results
  } // End of testProfileImageOperations method
} // End of StorageDiagnostics class
