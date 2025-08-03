import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sports/game.dart';
import '../models/pick_post.dart';
import 'ocr_webview_wrapper.dart';

/// TheOddsAPI Odds Widget
/// 
/// Displays live odds using TheOddsAPI widget in a WebView
/// Provides reliable, real-time odds data from multiple sportsbooks
class AllGamesOddsWidget extends StatefulWidget {
  final Function(Map<String, dynamic>)? onPickSelected;
  
  const AllGamesOddsWidget({
    Key? key,
    this.onPickSelected,
  }) : super(key: key);

  @override
  State<AllGamesOddsWidget> createState() => _AllGamesOddsWidgetState();
}

class _AllGamesOddsWidgetState extends State<AllGamesOddsWidget> {
  WebViewController? _webViewController;
  String _selectedSport = 'NFL';
  String _selectedBookmaker = 'draftkings';
  bool _isLoading = true;
  String? _errorMessage;
  bool _useOCRMode = false;
  
  // Sports mapping to TheOddsAPI sport keys
  final Map<String, String> _sportKeys = {
    'NFL': 'americanfootball_nfl',
    'NBA': 'basketball_nba',
    'MLB': 'baseball_mlb',
    'NHL': 'icehockey_nhl',
    'NCAAF': 'americanfootball_ncaaf',
    'NCAAB': 'basketball_ncaab',
  };

  // Available bookmakers
  final Map<String, String> _bookmakers = {
    'draftkings': 'DraftKings',
    'fanduel': 'FanDuel',
    'betmgm': 'BetMGM',
    'caesars': 'Caesars',
    'bovada': 'Bovada',
    'betrivers': 'BetRivers',
  };

  String? get _apiKey => dotenv.env['ODDS_API_WIDGET_KEY'];

  @override
  void initState() {
    super.initState();
    _initializeWidget();
  }

  void _initializeWidget() {
    if (_apiKey == null || _apiKey!.isEmpty) {
      setState(() {
        _errorMessage = 'Odds API key not configured. Please add ODDS_API_WIDGET_KEY to your .env file.';
        _isLoading = false;
      });
      return;
    }

    // For web platform, still try to show widget in-app first
    // Only show fallback if WebView completely fails
    if (kIsWeb) {
      // Try to initialize anyway, fallback will trigger on error
      debugPrint('Web platform detected - attempting WebView initialization');
    }

    // For mobile platforms, try WebView
    _initializeWebView();
  }

  void _initializeWebView() {
    if (_apiKey == null || _apiKey!.isEmpty) {
      setState(() {
        _errorMessage = 'Odds API key not configured. Please add ODDS_API_WIDGET_KEY to your .env file.';
        _isLoading = false;
      });
      return;
    }

    try {
      final controller = WebViewController();
      
      // Try to set JavaScript mode first (most basic requirement)
      try {
        controller.setJavaScriptMode(JavaScriptMode.unrestricted);
        
        // Add JavaScript channel for pick selection
        controller.addJavaScriptChannel(
          'PickHandler',
          onMessageReceived: (JavaScriptMessage message) {
            _handlePickSelection(message.message);
          },
        );
      } catch (e) {
        debugPrint('JavaScript mode not supported: $e');
        // Continue without JavaScript if not supported
      }

      // Try to set navigation delegate (optional, may not be supported on all platforms)
      try {
        controller.setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
              }
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = null;
                });
                _injectClickHandlers();
              }
            },
            onWebResourceError: (WebResourceError error) {
              if (mounted) {
                setState(() {
                  _errorMessage = 'Failed to load odds: ${error.description}';
                  _isLoading = false;
                });
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              // Allow TheOddsAPI widget and related domains
              if (request.url.startsWith('https://widget.the-odds-api.com') ||
                  request.url.startsWith('https://the-odds-api.com') ||
                  request.url.contains('odds') && request.url.contains('widget')) {
                return NavigationDecision.navigate;
              }
              // For sportsbook links, open in external browser
              if (request.url.contains('fanduel') || 
                  request.url.contains('draftkings') ||
                  request.url.contains('betmgm') ||
                  request.url.contains('caesars') ||
                  request.url.contains('bovada') ||
                  request.url.contains('betrivers')) {
                _launchURL(request.url);
                return NavigationDecision.prevent;
              }
              // Allow other navigation within widget
              return NavigationDecision.navigate;
            },
          ),
        );
      } catch (e) {
        debugPrint('NavigationDelegate not supported on this platform: $e');
        // Continue without navigation delegate - widget will still work
      }

      // Load the widget URL
      controller.loadRequest(Uri.parse(_buildWidgetUrl()));

      setState(() {
        _webViewController = controller;
        _isLoading = true; // Set loading manually since onPageStarted might not work
      });

      // Set a timer to clear loading state if navigation delegate isn't working
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      });

    } catch (e) {
      debugPrint('WebView initialization error: $e');
      // Check if this is the specific NavigationDelegate error
      if (e.toString().contains('createPlatformNavigationDelegate') || 
          e.toString().contains('NavigationDelegate')) {
        _initializeSimpleWebView();
      } else {
        String friendlyMessage;
        if (e.toString().contains('UnimplementedError')) {
          friendlyMessage = 'WebView not fully supported on this device. The widget will load with basic functionality.';
        } else if (e.toString().contains('PlatformException')) {
          friendlyMessage = 'Platform issue detected. Trying simplified WebView mode.';
        } else {
          friendlyMessage = 'WebView initialization failed: ${e.toString().split(':').last.trim()}';
        }
        
        setState(() {
          _errorMessage = friendlyMessage;
          _isLoading = false;
        });
      }
    }
  }

  void _initializeSimpleWebView() {
    try {
      debugPrint('Initializing simple WebView without NavigationDelegate');
      final controller = WebViewController();
      
      // Only set the most basic settings
      try {
        controller.setJavaScriptMode(JavaScriptMode.unrestricted);
        
        // Add JavaScript channel for pick selection
        controller.addJavaScriptChannel(
          'PickHandler',
          onMessageReceived: (JavaScriptMessage message) {
            _handlePickSelection(message.message);
          },
        );
      } catch (e) {
        debugPrint('JavaScript mode not supported: $e');
      }

      // Load the widget URL directly
      controller.loadRequest(Uri.parse(_buildWidgetUrl()));

      setState(() {
        _webViewController = controller;
        _isLoading = true;
      });

      // Clear loading state and inject handlers after a reasonable delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // Give extra time for widget content to load
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _injectClickHandlers();
            }
          });
        }
      });

    } catch (e) {
      debugPrint('Simple WebView initialization also failed: $e');
      setState(() {
        _errorMessage = 'web_fallback'; // Use fallback interface
        _isLoading = false;
      });
    }
  }

  String _buildWidgetUrl() {
    final sportKey = _sportKeys[_selectedSport] ?? 'americanfootball_nfl';
    final baseUrl = 'https://widget.the-odds-api.com/v1/sports/$sportKey/events/';
    
           final params = {
         'accessKey': _apiKey!,
         'bookmakerKeys': _selectedBookmaker,
         'oddsFormat': 'american',
         'markets': 'h2h,spreads,totals',
         'marketNames': 'h2h:Moneyline,spreads:Spreads,totals:Over/Under',
       };
    
    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '$baseUrl?$queryString';
  }

  void _reloadWidget() {
    if (_webViewController != null) {
      setState(() {
        _isLoading = true;
      });
      
      _webViewController!.loadRequest(Uri.parse(_buildWidgetUrl()));
      
      // Clear loading state after delay (since we might not have navigation delegate)
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } else {
      // If no WebView, reinitialize the widget
      _initializeWidget();
    }
  }

  void _handlePickSelection(String message) {
    try {
      debugPrint('🎯 Received pick selection: $message');
      final data = jsonDecode(message);
      
      // Handle test messages
      if (data['test'] == true) {
        debugPrint('✅ JavaScript test message received: ${data['message']}');
        return;
      }
      
      debugPrint('📊 Pick data parsed: $data');
      
      if (widget.onPickSelected != null) {
        widget.onPickSelected!(data);
        debugPrint('✅ Pick sent to parent widget');
      } else {
        debugPrint('❌ No onPickSelected callback available');
      }
    } catch (e) {
      debugPrint('❌ Error parsing pick selection: $e');
      debugPrint('📝 Raw message: $message');
    }
  }

  void _injectClickHandlers() {
    if (_webViewController == null) return;
    
    // Check if we're on web platform where runJavaScript isn't supported
    if (kIsWeb) {
      debugPrint('🌐 Web platform detected - JavaScript injection not supported');
      debugPrint('💡 Use manual pick entry or Test button for web demo');
      return;
    }
    
    const javascript = r'''
      (function() {
        console.log('🎯 Injecting enhanced pick handlers...');
        
        // Debug: Log the page structure
        console.log('📊 Page title:', document.title);
        console.log('🔍 DOM structure:', document.body.innerHTML.slice(0, 500));
        
        // Function to find game row from clicked element
        function findGameRow(element) {
          // Look for table row or container that has team names
          let current = element;
          while (current && current !== document.body) {
            // Check if this element contains team names
            const text = current.textContent || '';
            if (text.match(/[A-Za-z]{3,}.*[A-Za-z]{3,}/)) { // Contains multiple words (likely teams)
              return current;
            }
            current = current.parentElement;
          }
          return null;
        }
        
        // Function to detect market type from context
        function detectMarketType(element, context) {
          // Check column headers or nearby text
          const pageText = document.body.textContent.toLowerCase();
          const elementText = (element.textContent || '').toLowerCase();
          
          // Find which column we're in
          if (pageText.includes('moneyline') || elementText.includes('moneyline')) {
            const moneylineColumn = document.querySelector('*[text*="Moneyline" i], *[textContent*="Moneyline" i]');
            if (moneylineColumn && isInSameColumn(element, moneylineColumn)) {
              return 'moneyline';
            }
          }
          
          if (pageText.includes('spread') || elementText.includes('spread')) {
            const spreadColumn = document.querySelector('*[text*="Spread" i], *[textContent*="Spread" i]');
            if (spreadColumn && isInSameColumn(element, spreadColumn)) {
              return 'spread';
            }
          }
          
          if (pageText.includes('over') || pageText.includes('under') || pageText.includes('total')) {
            const totalColumn = document.querySelector('*[text*="Over" i], *[textContent*="Over" i], *[textContent*="Under" i]');
            if (totalColumn && isInSameColumn(element, totalColumn)) {
              return 'total';
            }
          }
          
          // Fallback: guess based on odds format
          const oddsValue = element.textContent || '';
          if (oddsValue.match(/[+-]\\d{2,3}/) && !oddsValue.includes('.')) {
            return 'moneyline';
          } else if (oddsValue.includes('.') || oddsValue.match(/[+-]\\d+\\.\\d/)) {
            return 'spread';
          }
          
          return 'unknown';
        }
        
        // Helper to check if elements are in same column
        function isInSameColumn(element1, element2) {
          if (!element1 || !element2) return false;
          const rect1 = element1.getBoundingClientRect();
          const rect2 = element2.getBoundingClientRect();
          return Math.abs(rect1.left - rect2.left) < 50; // Within 50px horizontally
        }
        
        // Enhanced data extraction
        function extractPickData(element) {
          console.log('📝 Extracting data from:', element);
          
          const gameRow = findGameRow(element);
          const oddsText = (element.textContent || '').trim();
          
          // Extract team names from game row
          let team1 = '', team2 = '';
          if (gameRow) {
            const gameText = gameRow.textContent || '';
            console.log('🏈 Game text:', gameText);
            
            // Try various team name patterns
            const teamPatterns = [
              /([A-Za-z\\s]+)\\s+vs\\s+([A-Za-z\\s]+)/,
              /([A-Za-z\\s]+)\\s+@\\s+([A-Za-z\\s]+)/,
              /([A-Za-z\\s]+).*?([A-Za-z\\s]+)(?=\\s*[-+]?\\d|$)/
            ];
            
            for (const pattern of teamPatterns) {
              const match = gameText.match(pattern);
              if (match) {
                team1 = match[1].trim();
                team2 = match[2].trim();
                break;
              }
            }
          }
          
          const marketType = detectMarketType(element, gameRow);
          
          const pickData = {
            gameText: gameRow ? (gameRow.textContent || '').slice(0, 100) : 'Unknown Game',
            oddsText: oddsText.slice(0, 50),
            odds: oddsText,
            team1: team1,
            team2: team2,
            marketType: marketType,
            timestamp: Date.now(),
            elementInfo: {
              tagName: element.tagName,
              className: element.className,
              id: element.id
            }
          };
          
          console.log('✅ Extracted pick data:', pickData);
          return pickData;
        }
        
        // Enhanced click listener setup
        function addClickListeners() {
          console.log('🎯 Adding click listeners...');
          
          // Very broad selectors to catch odds elements
          const selectors = [
            'td', 'div', 'span', 'button', 'a',  // Basic elements
            '*[class*="odd"]', '*[class*="bet"]', '*[class*="line"]',  // Odds-related classes
            '*[data-odd]', '*[data-bet]', '*[data-price]',  // Data attributes
          ];
          
          let clickableCount = 0;
          
          selectors.forEach(selector => {
            document.querySelectorAll(selector).forEach(element => {
              const text = (element.textContent || '').trim();
              
              // Check if element looks like it contains odds
              if (text && (
                text.match(/^[+-]?\\d+$/) ||  // Simple numbers like -110, +150
                text.match(/^[+-]?\\d+\\.\\d+$/) ||  // Decimals like -2.5, +3.5
                (text.length <= 10 && text.match(/[+-]?\\d/))  // Short text with numbers
              )) {
                
                if (!element.hasAttribute('data-pick-handler')) {
                  element.setAttribute('data-pick-handler', 'true');
                  element.style.cursor = 'pointer';
                  element.style.backgroundColor = 'rgba(0, 255, 0, 0.1)'; // Visual feedback
                  
                  element.addEventListener('click', function(e) {
                    console.log('🎯 ODDS CLICKED!', this.textContent);
                    e.preventDefault();
                    e.stopPropagation();
                    
                    const pickData = extractPickData(this);
                    
                    // Send to Flutter
                    if (window.PickHandler) {
                      console.log('📱 Sending to Flutter:', pickData);
                      window.PickHandler.postMessage(JSON.stringify(pickData));
                    } else {
                      console.error('❌ PickHandler not found!');
                    }
                  });
                  
                  clickableCount++;
                }
              }
            });
          });
          
          console.log('✅ Added click handlers to', clickableCount, 'elements');
          
          // Also add a general click listener for debugging
          document.addEventListener('click', function(e) {
            console.log('👆 General click on:', e.target.tagName, e.target.textContent);
          });
        }
        
        // Test the PickHandler
        if (window.PickHandler) {
          console.log('✅ PickHandler is available');
          window.PickHandler.postMessage(JSON.stringify({
            test: true,
            message: 'JavaScript handlers loaded successfully'
          }));
        } else {
          console.log('❌ PickHandler not available');
        }
        
        // Initial setup
        addClickListeners();
        
        // Re-run when DOM changes
        const observer = new MutationObserver(function(mutations) {
          console.log('🔄 DOM changed, re-adding listeners...');
          setTimeout(addClickListeners, 1000);
        });
        
        observer.observe(document.body, {
          childList: true,
          subtree: true
        });
        
        console.log('🎉 Enhanced pick handlers injected successfully!');
      })();
    ''';
    
    try {
      _webViewController!.runJavaScript(javascript);
      debugPrint('Click handlers injected successfully');
    } catch (e) {
      debugPrint('Failed to inject click handlers: $e');
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Failed to launch URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Controls
        _buildControls(),
        
        // Content area
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: Border(
          bottom: BorderSide(color: Colors.grey[600]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live Odds',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
                        const SizedBox(height: 12),
              
              // Web platform notice
              if (kIsWeb) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Web: Use "Demo" for samples or "OCR" to tap on odds directly',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Sport selection
          Row(
            children: [
              const Text(
                'Sport: ',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _sportKeys.keys.map((sport) {
                      final isSelected = _selectedSport == sport;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(sport),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected && sport != _selectedSport) {
                              setState(() {
                                _selectedSport = sport;
                              });
                              _reloadWidget();
                            }
                          },
                          selectedColor: Colors.green.withOpacity(0.3),
                          backgroundColor: Colors.grey[700],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.green : Colors.grey[300],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected ? Colors.green : Colors.grey[600]!,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Bookmaker selection
          Row(
            children: [
              const Text(
                'Sportsbook: ',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedBookmaker,
                  dropdownColor: Colors.grey[700],
                  style: const TextStyle(color: Colors.white),
                  underline: Container(
                    height: 2,
                    color: Colors.green,
                  ),
                  items: _bookmakers.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null && newValue != _selectedBookmaker) {
                      setState(() {
                        _selectedBookmaker = newValue;
                      });
                      _reloadWidget();
                    }
                  },
                ),
                                ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _reloadWidget,
                    icon: const Icon(Icons.refresh, color: Colors.green),
                    tooltip: 'Refresh odds',
                  ),
                  const SizedBox(width: 8),
                  // Test/Demo button for web platforms
                  ElevatedButton(
                    onPressed: () {
                      // Generate unique test picks for web demo
                      final testPicks = [
                        {
                          'gameText': 'Patriots vs Dolphins - Moneyline',
                          'oddsText': '-110',
                          'odds': '-110',
                          'team1': 'Patriots',
                          'team2': 'Dolphins', 
                          'marketType': 'moneyline',
                          'timestamp': DateTime.now().millisecondsSinceEpoch,
                        },
                        {
                          'gameText': 'Eagles vs Commanders - Spread',
                          'oddsText': '-4.5 (-110)',
                          'odds': '-110',
                          'team1': 'Eagles',
                          'team2': 'Commanders',
                          'marketType': 'spread',
                          'timestamp': DateTime.now().millisecondsSinceEpoch + 1,
                        },
                        {
                          'gameText': '49ers vs Seahawks - Over/Under',
                          'oddsText': 'Over 45.5 (-105)',
                          'odds': '-105',
                          'team1': '49ers',
                          'team2': 'Seahawks',
                          'marketType': 'total',
                          'timestamp': DateTime.now().millisecondsSinceEpoch + 2,
                        },
                      ];
                      
                      // Add a random test pick
                      final randomPick = testPicks[DateTime.now().millisecond % testPicks.length];
                      
                      if (widget.onPickSelected != null) {
                        widget.onPickSelected!(randomPick);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kIsWeb ? Colors.green : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      kIsWeb ? 'Demo' : 'Test', 
                      style: const TextStyle(fontSize: 10)
                    ),
                  ),
                  const SizedBox(width: 4),
                  // OCR Mode toggle button
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _useOCRMode = !_useOCRMode;
                      });
                      debugPrint('🔍 OCR Mode: $_useOCRMode');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _useOCRMode ? Colors.purple : Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      _useOCRMode ? 'OCR✓' : 'OCR', 
                      style: const TextStyle(fontSize: 10)
                    ),
                  ),
                  
                  // Only show JS button on non-web platforms  
                  if (!kIsWeb) ...[
                    const SizedBox(width: 4),
                    // Debug injection button (mobile only)
                    ElevatedButton(
                      onPressed: () {
                        debugPrint('🔧 Manual JavaScript injection triggered');
                        _injectClickHandlers();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('JS', style: TextStyle(fontSize: 10)),
                    ),
                  ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      // Handle web platform fallback
      if (_errorMessage == 'web_fallback') {
        return _buildWebFallbackContent();
      }
      
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _errorMessage!.contains('not supported') 
                    ? Icons.open_in_browser 
                    : Icons.error_outline, 
                color: _errorMessage!.contains('not supported') 
                    ? Colors.blue 
                    : Colors.red, 
                size: 48
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: _errorMessage!.contains('not supported') 
                      ? Colors.blue 
                      : Colors.red, 
                  fontSize: 16
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Show different buttons based on error type
              if (_errorMessage!.contains('not supported')) ...[
                ElevatedButton.icon(
                  onPressed: () => _launchURL(_buildWidgetUrl()),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Open Odds in Browser'),
                ),
                const SizedBox(height: 12),
                Text(
                  'The odds widget will open in your default browser',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _isLoading = true;
                    });
                    // Try simple WebView first on retry
                    _initializeSimpleWebView();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_webViewController == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Initializing odds display...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
                    // WebView container with OCR support
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[600]!, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _useOCRMode 
                    ? OCRWebViewWrapper(
                        controller: _webViewController!,
                        onPickExtracted: (pickData) {
                          if (widget.onPickSelected != null) {
                            widget.onPickSelected!(pickData);
                          }
                        },
                      )
                    : WebViewWidget(controller: _webViewController!),
              ),
            ),
        
        // Loading overlay
        if (_isLoading)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[800]!.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'Loading live odds...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWebFallbackContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.sports, color: Colors.blue, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Live Odds Available',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current ${_bookmakers[_selectedBookmaker]} odds for ${_selectedSport}',
                  style: TextStyle(color: Colors.grey[300], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Primary action - open odds
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchURL(_buildWidgetUrl()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_browser, size: 24),
                    label: const Text(
                      'View Live Odds',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Features list
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What you\'ll see:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureRow(Icons.sports_basketball, 'Live game odds'),
                      _buildFeatureRow(Icons.trending_up, 'Moneyline, Spread & Totals'),
                      _buildFeatureRow(Icons.update, 'Real-time updates'),
                      _buildFeatureRow(Icons.link, 'Direct sportsbook links'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Instructions
                Text(
                  'The odds widget will open in a new tab with live betting data',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: Colors.grey[300], fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Dispose OCR resources when this is the last instance
    // Note: OCRPickExtractor.dispose() should only be called when no more instances need it
    super.dispose();
  }
}