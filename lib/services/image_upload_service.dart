import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class ImageUploadService {
  static final _supabase = SupabaseConfig.supabase;

  static Future<String?> uploadProfileImage(Uint8List imageBytes, String userId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_$userId\_$timestamp.jpg';
      
      // Upload to Supabase storage
      final path = await _supabase.storage
          .from('avatars')
          .uploadBinary(fileName, imageBytes);

      // Get public URL
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  static Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      // Extract filename from URL
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;
      
      await _supabase.storage
          .from('avatars')
          .remove([fileName]);
      
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
}
