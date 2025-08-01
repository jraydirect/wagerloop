import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';

class BaseballGamesWidget extends StatefulWidget {
  final String apiKey;
  final String? date;
  final int? league;
  final int? season;
  final String theme;
  final int refresh;
  final bool showToolbar;
  final bool showLogos;
  final bool modalGame;
  final bool modalStandings;
  final bool modalShowLogos;
  final bool showErrors;

  const BaseballGamesWidget({
    Key? key,
    required this.apiKey,
    this.date,
    this.league,
    this.season,
    this.theme = '',
    this.refresh = 15,
    this.showToolbar = true,
    this.showLogos = true,
    this.modalGame = true,
    this.modalStandings = true,
    this.modalShowLogos = true,
    this.showErrors = false,
  }) : super(key: key);

  @override
  State<BaseballGamesWidget> createState() => _BaseballGamesWidgetState();
}

class _BaseballGamesWidgetState extends State<BaseballGamesWidget> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    try {
      _controller = WebViewController();
      
      // Set JavaScript mode only if not on web platform
      if (!kIsWeb) {
        _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      }
      
      // Set navigation delegate only if not on web platform
      if (!kIsWeb) {
        _controller.setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() {
                _isLoading = true;
                _error = null;
              });
            },
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
              });
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                _error = 'Failed to load widget: ${error.description}';
                _isLoading = false;
              });
            },
          ),
        );
      } else {
        // For web platform, set loading to false after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      }
      
      // Load the HTML content
      _controller.loadHtmlString(_generateWidgetHTML());
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize WebView: $e';
        _isLoading = false;
      });
    }
  }

  String _generateWidgetHTML() {
    final dateParam = widget.date ?? '';
    final leagueParam = widget.league?.toString() ?? '';
    final seasonParam = widget.season?.toString() ?? '';
    
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            margin: 0;
            padding: 0;
            background: transparent;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }
        .widget-container {
            width: 100%;
            min-height: 400px;
            background: transparent;
        }
        .loading {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 200px;
            color: #4CAF50;
            font-size: 16px;
        }
        .error {
            color: #FF5722;
            text-align: center;
            padding: 20px;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="widget-container">
        <div id="wg-api-baseball-games"
             data-host="api-baseball.p.rapidapi.com"
             data-key="${widget.apiKey}"
             data-date="$dateParam"
             data-league="$leagueParam"
             data-season="$seasonParam"
             data-theme="${widget.theme}"
             data-refresh="${widget.refresh}"
             data-show-toolbar="${widget.showToolbar}"
             data-show-errors="${widget.showErrors}"
             data-show-logos="${widget.showLogos}"
             data-modal-game="${widget.modalGame}"
             data-modal-standings="${widget.modalStandings}"
             data-modal-show-logos="${widget.modalShowLogos}">
        </div>
    </div>
    <script
        type="module"
        src="https://widgets.api-sports.io/2.0.3/widgets.js">
    </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    // Add error boundary to prevent rendering issues
    try {
      // Check if WebView is supported on this platform
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF424242),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.destructiveRed.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: CupertinoColors.destructiveRed,
              size: 24,
            ),
            const SizedBox(height: 8),
            const Text(
              'WebView not supported',
              style: TextStyle(
                color: Color(0xFFBDBDBD),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Baseball widget requires web platform',
              style: TextStyle(
                color: Color(0xFFBDBDBD),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF424242),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.destructiveRed.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: CupertinoColors.destructiveRed,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFBDBDBD),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(8),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _initializeWebView();
              },
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF525252).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 600,
          width: double.infinity,
          child: Stack(
            children: [
              SizedBox(
                height: 600,
                width: double.infinity,
                child: WebViewWidget(controller: _controller),
              ),
              if (_isLoading)
                Container(
                  height: 600,
                  width: double.infinity,
                  color: const Color(0xFF424242).withOpacity(0.8),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CupertinoActivityIndicator(
                          color: Color(0xFF4CAF50),
                          radius: 20,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading baseball games...',
                          style: TextStyle(
                            color: Color(0xFFBDBDBD),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF424242),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.destructiveRed.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: CupertinoColors.destructiveRed,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              'Widget error: $e',
              style: const TextStyle(
                color: Color(0xFFBDBDBD),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }


} 