import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Sketchfab3DWidget extends StatefulWidget {
  final double size;
  final double? top;
  final double? right;
  final double? left;
  final double? bottom;
  final String sketchfabUrl;

  const Sketchfab3DWidget({
    Key? key,
    this.size = 80.0,
    this.top,
    this.right,
    this.left,
    this.bottom,
    required this.sketchfabUrl,
  }) : super(key: key);

  @override
  _Sketchfab3DWidgetState createState() => _Sketchfab3DWidgetState();
}

class _Sketchfab3DWidgetState extends State<Sketchfab3DWidget> {
  late WebViewController _webController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.sketchfabUrl));
  }

  Widget _buildLoadingFallback() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withOpacity(0.8),
            const Color(0xFF059669).withOpacity(0.6),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(
                Icons.view_in_ar,
                color: Colors.white,
                size: widget.size * 0.3,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            if (!_isLoading) ...[
              const SizedBox(height: 4),
              Text(
                '3D',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.7),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _build3DEmbed() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            WebViewWidget(controller: _webController),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF10B981).withOpacity(0.8),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🔥 Building Sketchfab3DWidget - isLoading: $_isLoading, size: ${widget.size}');
    print('🔥 Position - top: ${widget.top}, right: ${widget.right}');
    
    // For now, always show a super obvious test widget
    Widget content = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.red, // Bright red for maximum visibility
        shape: BoxShape.circle,
        border: Border.all(color: Colors.yellow, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.blue,
            blurRadius: 20,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_in_ar,
              color: Colors.white,
              size: 30,
            ),
            Text(
              '3D',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.top != null || widget.right != null || widget.left != null || widget.bottom != null) {
      return Positioned(
        top: widget.top,
        right: widget.right,
        left: widget.left,
        bottom: widget.bottom,
        child: content,
      );
    }

    return content;
  }
}