// Test file to check if all imports work correctly
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/pick_post.dart';
import '../models/comment.dart';
import '../services/supabase_config.dart';

void main() {
  // This is just a test to verify imports work
  print('All imports successful');
  
  // Test creating a Pick (this should compile without errors)
  // final testPick = Pick(
  //   id: '1',
  //   game: Game(...),
  //   pickType: PickType.moneyline,
  //   pickSide: PickSide.home,
  //   odds: '-110',
  // );
  
  print('Compilation test passed');
}
