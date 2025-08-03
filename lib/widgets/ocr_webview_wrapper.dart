import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/ocr_pick_extractor.dart';

class OCRWebViewWrapper extends StatefulWidget {
  final WebViewController controller;
  final Function(Map<String, dynamic>)? onPickExtracted;

  const OCRWebViewWrapper({
    Key? key,
    required this.controller,
    this.onPickExtracted,
  }) : super(key: key);

  @override
  State<OCRWebViewWrapper> createState() => _OCRWebViewWrapperState();
}

class _OCRWebViewWrapperState extends State<OCRWebViewWrapper> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isProcessing = false;
  Offset? _lastTapPosition;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // WebView wrapped in RepaintBoundary for screenshots
        RepaintBoundary(
          key: _repaintBoundaryKey,
          child: GestureDetector(
            onTapDown: (details) {
              _lastTapPosition = details.localPosition;
              debugPrint('🎯 Tap detected at: ${details.localPosition}');
            },
            onTap: () {
              if (_lastTapPosition != null && !_isProcessing) {
                _extractPickFromTap(_lastTapPosition!);
              }
            },
            child: WebViewWidget(controller: widget.controller),
          ),
        ),
        
        // Processing overlay
        if (_isProcessing)
          Container(
            color: Colors.black26,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'Reading odds...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _extractPickFromTap(Offset tapPosition) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('📸 Capturing screenshot for OCR...');
      
      // Capture screenshot
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('❌ Could not find render boundary');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        debugPrint('❌ Could not convert image to bytes');
        return;
      }

      final imageBytes = byteData.buffer.asUint8List();
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());

      debugPrint('📏 Image size: ${imageSize.width}x${imageSize.height}');
      debugPrint('🎯 Tap position: $tapPosition');

      // Adjust tap position for pixel ratio
      final adjustedPosition = Offset(
        tapPosition.dx * 2.0, // Multiply by pixelRatio
        tapPosition.dy * 2.0,
      );

      debugPrint('🎯 Adjusted position: $adjustedPosition');

      // Extract pick using OCR
      final pickData = await OCRPickExtractor.extractPickFromImage(
        imageBytes: imageBytes,
        clickPosition: adjustedPosition,
        imageSize: imageSize,
      );

      if (pickData != null && widget.onPickExtracted != null) {
        debugPrint('✅ OCR extraction successful');
        widget.onPickExtracted!(pickData);
        
        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OCR detected: ${pickData['oddsText']}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        debugPrint('❌ OCR extraction failed');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not read odds from this area. Try tapping directly on a number.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

    } catch (e) {
      debugPrint('❌ Screenshot/OCR error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR processing failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Don't dispose the global OCR service here as it's used by multiple instances
    super.dispose();
  }
}