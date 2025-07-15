import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/sports/game.dart';
import '../models/pick_post.dart';
import 'ocr_service.dart';

/// Service for scanning betting slips from images using OCR
/// 
/// This service allows users to upload photos of betting slips
/// and automatically extract game information, odds, and bet details
/// to create pick posts without manual entry.
class ScanService {
  final ImagePicker _picker = ImagePicker();

  /// Opens camera to capture a betting slip image
  Future<dynamic> captureImage() async {
    print('Opening camera...');
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      print('Camera result: ${image?.path ?? 'null'}');
      if (image != null) {
        if (kIsWeb) {
          // For web, return the XFile directly
          print('Web platform - returning XFile');
          return image;
        } else {
          // For mobile, return File object
          final file = File(image.path);
          print('Mobile platform - created file: ${file.path}');
          return file;
        }
      }
      return null;
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  /// Opens gallery to select a betting slip image
  Future<dynamic> pickImageFromGallery() async {
    print('Opening gallery...');
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      print('Gallery result: ${image?.path ?? 'null'}');
      if (image != null) {
        if (kIsWeb) {
          // For web, return the XFile directly
          print('Web platform - returning XFile');
          return image;
        } else {
          // For mobile, return File object
          final file = File(image.path);
          print('Mobile platform - created file: ${file.path}');
          return file;
        }
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Processes the image to extract betting slip information
  /// 
  /// Uses OCR to extract text from betting slips and parses it to identify
  /// teams, odds, and bet types for creating pick posts.
  Future<ScanResult?> processBettingSlip(dynamic imageFile) async {
    String imagePath = '';
    
    if (kIsWeb && imageFile is XFile) {
      // For web, use the blob URL as the path
      imagePath = imageFile.path;
      print('Processing web image: $imagePath');
    } else if (imageFile is File) {
      // For mobile, use the file path
      imagePath = imageFile.path;
      print('Processing mobile image: $imagePath');
    } else {
      print('Unknown image file type: ${imageFile.runtimeType}');
      return ScanResult(
        success: false,
        error: 'Unsupported image format',
      );
    }
    
    try {
      print('Starting OCR processing...');
      
      // Use OCR service to extract text from image
      final ocrService = OcrService();
      final extractedText = await ocrService.extractTextFromImage(imageFile);
      
      if (extractedText == null || extractedText.isEmpty) {
        print('No text extracted from image');
        return ScanResult(
          success: false,
          error: 'Could not extract text from image. Please ensure the betting slip is clearly visible.',
        );
      }
      
      print('Extracted text: $extractedText');
      
      // Parse the extracted text to find betting information
      final extractedBets = ocrService.parseBettingInformation(extractedText);
      
      if (extractedBets.isEmpty) {
        print('No betting information found in extracted text');
        return ScanResult(
          success: false,
          error: 'No betting information found. Please ensure the image contains team names and odds.',
        );
      }
      
      // Convert extracted bets to ExtractedPick objects
      final List<ExtractedPick> extractedPicks = [];
      for (final bet in extractedBets) {
        final sport = ocrService.determineSport(bet.team1, bet.team2);
        final league = ocrService.determineLeague(sport);
        
        final extractedPick = ExtractedPick(
          teamName: bet.team1,
          opponent: bet.team2,
          sport: sport,
          league: league,
          betType: _capitalizeFirst(bet.betType),
          odds: bet.odds,
          confidence: bet.confidence,
        );
        
        extractedPicks.add(extractedPick);
        print('Created extracted pick: ${extractedPick.teamName} vs ${extractedPick.opponent} - ${extractedPick.odds}');
      }
      
      // Calculate total odds (simplified - in real app you'd calculate parlay odds)
      final totalOdds = extractedPicks.length > 1 ? '+${extractedPicks.length * 100}' : extractedPicks.first.odds;
      
      print('Creating scan result with ${extractedPicks.length} picks');
      final result = ScanResult(
        success: true,
        extractedPicks: extractedPicks,
        totalOdds: totalOdds,
        stake: null, // Not extracting stake yet
        potentialWin: null, // Not calculating potential win yet
        imagePath: imagePath,
      );
      
      print('Scan result created successfully');
      return result;
    } catch (e) {
      print('Error processing betting slip: $e');
      final errorResult = ScanResult(
        success: false,
        error: 'Failed to process image. Please try again.',
      );
      print('Returning error result');
      return errorResult;
    }
  }

  /// Helper method to capitalize first letter
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Shows image source selection dialog
  Future<dynamic> showImageSourceDialog(BuildContext context) async {
    print('Showing image source dialog');
    
    // Show the dialog and get the user's choice
    final choice = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[800],
          title: const Text(
            'Select Image Source',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text(
                  'Camera',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  print('Camera option selected');
                  Navigator.of(context).pop('camera');
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text(
                  'Gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  print('Gallery option selected');
                  Navigator.of(context).pop('gallery');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
    
    // Handle the user's choice
    if (choice == 'camera') {
      final image = await captureImage();
      print('Camera image result: ${image?.path ?? 'null'}');
      return image;
    } else if (choice == 'gallery') {
      final image = await pickImageFromGallery();
      print('Gallery image result: ${image?.path ?? 'null'}');
      return image;
    } else {
      print('User cancelled image selection');
      return null;
    }
  }
}

/// Result of scanning a betting slip image
class ScanResult {
  final bool success;
  final List<ExtractedPick>? extractedPicks;
  final String? totalOdds;
  final double? stake;
  final double? potentialWin;
  final String? imagePath;
  final String? error;

  ScanResult({
    required this.success,
    this.extractedPicks,
    this.totalOdds,
    this.stake,
    this.potentialWin,
    this.imagePath,
    this.error,
  });
}

/// Individual pick extracted from the betting slip
class ExtractedPick {
  final String teamName;
  final String opponent;
  final String sport;
  final String league;
  final String betType;
  final String odds;
  final double confidence;

  ExtractedPick({
    required this.teamName,
    required this.opponent,
    required this.sport,
    required this.league,
    required this.betType,
    required this.odds,
    required this.confidence,
  });

  /// Converts to a Pick object for the app
  Pick toPick() {
    // Create a mock Game object - in real implementation this would be matched from database
    final game = Game(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      homeTeam: teamName,
      awayTeam: opponent,
      sport: sport,
      league: league,
      gameTime: DateTime.now().add(const Duration(days: 1)),
      status: 'scheduled',
    );

    // Determine pick type and side based on bet type
    PickType pickType;
    PickSide pickSide;

    switch (betType.toLowerCase()) {
      case 'moneyline':
        pickType = PickType.moneyline;
        pickSide = PickSide.home; // Default, would need logic to determine actual side
        break;
      case 'spread':
        pickType = PickType.spread;
        pickSide = PickSide.home; // Default, would need logic to determine actual side
        break;
      case 'total':
      case 'over/under':
        pickType = PickType.total;
        pickSide = PickSide.over; // Default, would need logic to determine actual side
        break;
      default:
        pickType = PickType.moneyline;
        pickSide = PickSide.home;
    }

    return Pick(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      game: game,
      pickType: pickType,
      pickSide: pickSide,
      odds: odds,
      stake: null, // Would be extracted from slip
    );
  }
} 