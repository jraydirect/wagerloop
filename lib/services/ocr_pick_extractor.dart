import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class OCRPickExtractor {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract pick information from a screenshot at the given click coordinates
  static Future<Map<String, dynamic>?> extractPickFromImage({
    required Uint8List imageBytes,
    required Offset clickPosition,
    required Size imageSize,
  }) async {
    try {
      debugPrint('🔍 Starting OCR extraction at position: $clickPosition');
      
      // Create InputImage from bytes
      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: Size(imageSize.width, imageSize.height),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: (imageSize.width * 4).toInt(),
        ),
      );

      // Perform text recognition
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      debugPrint('📝 OCR found ${recognizedText.blocks.length} text blocks');

      // Find text elements near the click position
      final nearbyElements = _findNearbyTextElements(
        recognizedText.blocks,
        clickPosition,
        radius: 100, // 100 pixel radius around click
      );

      if (nearbyElements.isEmpty) {
        debugPrint('❌ No text found near click position');
        return null;
      }

      // Extract pick information from nearby text
      final pickData = _parsePickData(nearbyElements, clickPosition);
      
      debugPrint('✅ Extracted pick data: $pickData');
      return pickData;

    } catch (e) {
      debugPrint('❌ OCR extraction failed: $e');
      return null;
    }
  }

  /// Find text elements within radius of click position
  static List<TextElement> _findNearbyTextElements(
    List<TextBlock> blocks,
    Offset clickPosition,
    {double radius = 100}
  ) {
    List<TextElement> nearbyElements = [];

    for (final block in blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          final rect = element.boundingBox;
          final center = Offset(
            rect.left + rect.width / 2,
            rect.top + rect.height / 2,
          );

          final distance = (center - clickPosition).distance;
          if (distance <= radius) {
            nearbyElements.add(element);
            debugPrint('📍 Found nearby text: "${element.text}" at distance $distance');
          }
        }
      }
    }

    return nearbyElements;
  }

  /// Parse pick data from text elements
  static Map<String, dynamic> _parsePickData(
    List<TextElement> elements,
    Offset clickPosition,
  ) {
    // Sort elements by distance from click
    elements.sort((a, b) {
      final distanceA = (_getElementCenter(a) - clickPosition).distance;
      final distanceB = (_getElementCenter(b) - clickPosition).distance;
      return distanceA.compareTo(distanceB);
    });

    String? clickedOdds;
    String? team1, team2;
    String? marketType;
    List<String> allText = [];

    // Extract all text for context
    for (final element in elements) {
      allText.add(element.text);
    }

    debugPrint('🔤 All nearby text: ${allText.join(" | ")}');

    // Find the clicked odds (closest element)
    if (elements.isNotEmpty) {
      clickedOdds = elements.first.text;
      
      // Clean up odds format
      clickedOdds = _cleanOddsText(clickedOdds);
    }

    // Extract team names from context
    final teamInfo = _extractTeamNames(allText);
    team1 = teamInfo['team1'];
    team2 = teamInfo['team2'];

    // Determine market type from context
    marketType = _determineMarketType(allText, clickedOdds);

    // Generate game text
    String gameText = '';
    if (team1 != null && team2 != null) {
      gameText = '$team1 vs $team2';
    } else {
      // Use surrounding context
      gameText = allText.take(5).join(' ').replaceAll(RegExp(r'[^\w\s-+.]'), ' ');
      gameText = gameText.replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    return {
      'gameText': gameText.isNotEmpty ? gameText : 'OCR Extracted Game',
      'oddsText': clickedOdds ?? 'N/A',
      'odds': clickedOdds ?? 'N/A',
      'team1': team1 ?? '',
      'team2': team2 ?? '',
      'marketType': marketType ?? 'unknown',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'extractionMethod': 'OCR',
      'clickPosition': '(${clickPosition.dx.toInt()}, ${clickPosition.dy.toInt()})',
    };
  }

  /// Get center point of text element
  static Offset _getElementCenter(TextElement element) {
    final rect = element.boundingBox;
    return Offset(
      rect.left + rect.width / 2,
      rect.top + rect.height / 2,
    );
  }

  /// Clean odds text to standard format
  static String _cleanOddsText(String text) {
    // Remove extra characters, keep only odds-like patterns
    final oddsPattern = RegExp(r'[+-]?\d+(?:\.\d+)?');
    final match = oddsPattern.firstMatch(text);
    return match?.group(0) ?? text;
  }

  /// Extract team names from text context
  static Map<String, String?> _extractTeamNames(List<String> textElements) {
    String? team1, team2;
    
    // Look for team name patterns
    for (int i = 0; i < textElements.length - 1; i++) {
      final text = textElements[i];
      final nextText = textElements[i + 1];
      
      // Common team name patterns
      if (_looksLikeTeamName(text) && _looksLikeTeamName(nextText)) {
        team1 = text;
        team2 = nextText;
        break;
      }
    }

    // Alternative: look for "vs" or "@" patterns
    final fullText = textElements.join(' ');
    final vsMatch = RegExp(r'([A-Za-z\s]+?)\s+(?:vs|@)\s+([A-Za-z\s]+)', caseSensitive: false).firstMatch(fullText);
    if (vsMatch != null && team1 == null) {
      team1 = vsMatch.group(1)?.trim();
      team2 = vsMatch.group(2)?.trim();
    }

    return {'team1': team1, 'team2': team2};
  }

  /// Check if text looks like a team name
  static bool _looksLikeTeamName(String text) {
    // Team names are usually 3+ characters, mostly letters
    if (text.length < 3) return false;
    
    // Should be mostly alphabetic
    final alphaCount = text.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    return alphaCount >= text.length * 0.7; // At least 70% letters
  }

  /// Determine market type from context
  static String _determineMarketType(List<String> textElements, String? clickedOdds) {
    final contextText = textElements.join(' ').toLowerCase();
    
    // Look for market type keywords
    if (contextText.contains('moneyline') || contextText.contains('ml')) {
      return 'moneyline';
    }
    
    if (contextText.contains('spread') || contextText.contains('point')) {
      return 'spread';
    }
    
    if (contextText.contains('total') || contextText.contains('over') || contextText.contains('under') || contextText.contains('o/u')) {
      return 'total';
    }

    // Guess based on odds format
    if (clickedOdds != null) {
      if (clickedOdds.contains('.') && (clickedOdds.contains('+') || clickedOdds.contains('-'))) {
        return 'spread'; // Likely point spread like +3.5
      }
      
      if (clickedOdds.contains('+') || clickedOdds.contains('-')) {
        return 'moneyline'; // Likely moneyline like +150, -110
      }
    }

    return 'unknown';
  }

  /// Dispose of resources
  static void dispose() {
    _textRecognizer.close();
  }
}