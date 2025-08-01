import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/article_summary_service.dart';

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List<Map<String, dynamic>> newsArticles = [];
  bool isLoading = true;
  String error = '';
  String selectedLeague = 'NBA';

  // RSS feed URLs for different sports
  final Map<String, String> rssFeeds = {
    'NBA': 'https://www.cbssports.com/rss/headlines/nba/',
    'NFL': 'https://www.cbssports.com/rss/headlines/nfl/',
    'MLB': 'https://www.cbssports.com/rss/headlines/mlb/',
    'NHL': 'https://www.cbssports.com/rss/headlines/nhl/',
  };

  final List<String> leagues = ['NBA', 'NFL', 'MLB', 'NHL'];

  // Helper method to get league logo path
  String getLeagueLogoPath(String league) {
    final Map<String, String> leagueLogos = {
      'NBA': 'assets/leagueLogos/nba.png',
      'NFL': 'assets/leagueLogos/nfl.png',
      'MLB': 'assets/leagueLogos/mlb.png',
      'NHL': 'assets/leagueLogos/nhl.png',
    };
    return leagueLogos[league] ?? '';
  }

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final rssUrl = rssFeeds[selectedLeague];
      if (rssUrl == null) {
        throw Exception('No RSS feed found for $selectedLeague');
      }

      print('Fetching news for $selectedLeague from: $rssUrl'); // Debug log
      final response = await http.get(Uri.parse(rssUrl));

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        List<Map<String, dynamic>> articles = [];

        for (final item in items) {
          final title = item.findElements('title').first.innerText;
          final description = item.findElements('description').first.innerText;
          final link = item.findElements('link').first.innerText;
          final pubDate = item.findElements('pubDate').first.innerText;
          final creator = item.findElements('dc:creator').isNotEmpty
              ? item.findElements('dc:creator').first.innerText
              : 'CBS Sports';
          
          // Enhanced image extraction for different RSS feed sources
          String? imageUrl;
          
          // First, try standard enclosure method (works for CBS Sports)
          if (item.findElements('enclosure').isNotEmpty) {
            imageUrl = item.findElements('enclosure').first.getAttribute('url');
          }
          
          // For ESPN feeds, try media:content and media:thumbnail
          if (imageUrl == null && item.findElements('media:content').isNotEmpty) {
            imageUrl = item.findElements('media:content').first.getAttribute('url');
          }
          
          if (imageUrl == null && item.findElements('media:thumbnail').isNotEmpty) {
            imageUrl = item.findElements('media:thumbnail').first.getAttribute('url');
          }
          
          // Try content:encoded which sometimes contains images
          if (imageUrl == null && item.findElements('content:encoded').isNotEmpty) {
            final content = item.findElements('content:encoded').first.innerText;
            final imgRegex = RegExp(r'<img[^>]+src="([^"]+)"');
            final match = imgRegex.firstMatch(content);
            if (match != null) {
              imageUrl = match.group(1);
            }
          }
          
          // Extract images from description as fallback
          if (imageUrl == null) {
            final imgRegex = RegExp(r'<img[^>]+src="([^"]+)"');
            final match = imgRegex.firstMatch(description);
            if (match != null) {
              imageUrl = match.group(1);
            }
          }

          articles.add({
            'title': title,
            'description': description,
            'link': link,
            'pubDate': pubDate,
            'creator': creator,
            'imageUrl': imageUrl,
          });
        }

        setState(() {
          newsArticles = articles;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load RSS feed: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = 'Error loading news: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF111827), // Dark blue-gray at top
              const Color(0xFF0F172A), // Darker slate in middle
              const Color(0xFF0C1220), // Even darker at bottom
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with app logo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Text(
                      'News',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                      ),
                      child: Text(
                        'LIVE',
                        style: TextStyle(
                          color: const Color(0xFF10B981),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // League Filter - Enhanced with modern styling
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: leagues.length,
                    itemBuilder: (context, index) {
                      final league = leagues[index];
                      final isSelected = league == selectedLeague;

                      return Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? 8 : 0,
                          right: index == leagues.length - 1 ? 8 : 12
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedLeague = league;
                                fetchNews();
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.green
                                    : const Color(0xFF374151),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.green
                                      : Colors.green.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    getLeagueLogoPath(league),
                                    height: 20,
                                    width: 20,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    league,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.green,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // News List with enhanced styling
              Expanded(
                child: isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.green,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading $selectedLeague news...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : error.isNotEmpty
                      ? Center(
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2937).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Unable to load news',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  error,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: fetchNews,
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Text(
                                        'Try Again',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            newsArticles.isEmpty
                                ? SliverFillRemaining(
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(40),
                                            ),
                                            child: Icon(
                                              Icons.article_outlined,
                                              size: 40,
                                              color: Colors.green.withOpacity(0.7),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No news found',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'No $selectedLeague news available right now',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final article = newsArticles[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 16),
                                            child: _buildNewsCard(article),
                                          );
                                        },
                                        childCount: newsArticles.length,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> article) {
    // Clean title to remove any HTML formatting
    String cleanTitle = (article['title'] as String?)
            ?.replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
            .replaceAll(RegExp(r'&[^;]+;'), '') // Remove HTML entities
            .trim() ??
        'No title';
        
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showArticleDetails(context, article),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937).withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.green.withOpacity(0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Article Image with enhanced styling
                if (article['imageUrl'] != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.network(
                          article['imageUrl']!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF374151),
                                    const Color(0xFF1F2937),
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.sports,
                                  size: 60,
                                  color: Colors.green,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Subtle gradient overlay for better text readability
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.15),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                // Article Content with enhanced styling
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title with improved typography and proper constraints
                      Text(
                        cleanTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          letterSpacing: -0.3,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.start,
                        softWrap: true,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      // Enhanced footer with date and source
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF374151).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Date with icon
                            Flexible(
                              flex: 2,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _formatDate(article['pubDate'] ?? ''),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Source badge
                            Flexible(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  article['creator'] ?? 'Sports News',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // NEW: ArticleDetailModal is now pushed as a full-screen route
  void _showArticleDetails(BuildContext context, Map<String, dynamic> article) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true, // Makes it a full-screen modal presentation
        builder: (context) => ArticleDetailModal(article: article),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else {
        // You might want to format this more robustly for older dates, e.g., 'MMM dd, yyyy'
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return dateString;
    }
  }

  // Renamed _openArticle to _openArticleExternal to clarify its purpose
  Future<void> _openArticleExternal(String? url) async {
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        showCupertinoDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: const Text('Error'),
              content: const Text('Could not open article'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }
}

// Separate StatefulWidget for the Article Detail Modal to match app theme
class ArticleDetailModal extends StatefulWidget {
  final Map<String, dynamic> article;

  const ArticleDetailModal({Key? key, required this.article}) : super(key: key);

  @override
  _ArticleDetailModalState createState() => _ArticleDetailModalState();
}

class _ArticleDetailModalState extends State<ArticleDetailModal> {
  final _summaryService = ArticleSummaryService.instance;
  String? _aiSummary;
  bool _isLoadingSummary = false;
  String? _summaryError;

  @override
  void initState() {
    super.initState();
    _initializeAndGenerateSummary();
  }

  void _initializeAndGenerateSummary() async {
    try {
      if (!_summaryService.isInitialized) {
        _summaryService.initialize();
      }
      await _generateAISummary();
    } catch (e) {
      print('Error initializing summary service: $e');
      setState(() {
        _summaryError = 'AI summary temporarily unavailable';
      });
    }
  }

  Future<void> _generateAISummary() async {
    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
    });

    try {
      final articleUrl = widget.article['link'] ?? '';
      final title = widget.article['title'] ?? '';
      final description = widget.article['description'] ?? '';

      final summary = await _summaryService.summarizeArticle(
        articleUrl,
        title,
        description,
      );

      setState(() {
        _aiSummary = summary;
        _isLoadingSummary = false;
      });
    } catch (e) {
      setState(() {
        _summaryError = 'Failed to generate AI summary';
        _isLoadingSummary = false;
      });
    }
  }

  // Helper to format date, copied from NewsPage for self-containment
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return dateString;
    }
  }

  // Helper to open external link
  Future<void> _openArticleExternal(String? url, BuildContext context) async {
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        showCupertinoDialog(
          context: context,
          builder: (BuildContext dialogContext) { // Use dialogContext to avoid conflicts
            return CupertinoAlertDialog(
              title: const Text('Error'),
              content: const Text('Could not open article'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;

    // Clean HTML tags and entities from description
    String cleanDescription = (widget.article['description'] as String?)
            ?.replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
            .replaceAll(RegExp(r'&[^;]+;'), '') // Remove HTML entities
            .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
            .trim() ??
        '';
    
    // Also clean the title to remove any HTML formatting
    String cleanTitle = (widget.article['title'] as String?)
            ?.replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
            .replaceAll(RegExp(r'&[^;]+;'), '') // Remove HTML entities
            .trim() ??
        'No title';

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF363636),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF363636),
        middle: Text(
          'Article Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.back,
                color: Color(0xFF4CAF50),
                size: 18,
              ),
            ),
          ),
        ),
        border: null,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Image Section (without text overlay)
              if (widget.article['imageUrl'] != null)
                Container(
                  height: 250,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                    child: Image.network(
                      widget.article['imageUrl']!,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(20),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF525252),
                                const Color(0xFF363636),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              CupertinoIcons.photo,
                              size: 64,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              
              // Article Content - moved below image
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Article Title
                    Text(
                      cleanTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.5,
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.start,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Author and Date Information
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF4CAF50).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Author info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Author',
                                  style: const TextStyle(
                                    color: Color(0xFF8E8E93),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.article['creator'] ?? 'CBS Sports',
                                  style: const TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Publication date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Published',
                                  style: const TextStyle(
                                    color: Color(0xFF8E8E93),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(widget.article['pubDate'] ?? ''),
                                  style: const TextStyle(
                                    color: Color(0xFFE5E5E7),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // AI-Powered Article Summary
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF4CAF50).withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // AI Summary header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF4CAF50),
                                      const Color(0xFF45A049),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  CupertinoIcons.sparkles,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI-Powered Summary',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    Text(
                                      'Generated by Gemini AI',
                                      style: const TextStyle(
                                        color: Color(0xFF8E8E93),
                                        fontSize: 12,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isLoadingSummary)
                                const CupertinoActivityIndicator(
                                  color: Color(0xFF4CAF50),
                                  radius: 10,
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // AI Summary content
                          if (_isLoadingSummary)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3C3C3E),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  const CupertinoActivityIndicator(
                                    color: Color(0xFF4CAF50),
                                    radius: 16,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Our AI is reading the full article and generating a comprehensive summary...',
                                    style: const TextStyle(
                                      color: Color(0xFF8E8E93),
                                      fontSize: 16,
                                      decoration: TextDecoration.none,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          else if (_summaryError != null)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3C3C3E),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.exclamationmark_triangle,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _summaryError!,
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (cleanDescription.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      cleanDescription,
                                      style: const TextStyle(
                                        color: Color(0xFFE5E5E7),
                                        fontSize: 16,
                                        height: 1.5,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          if (_aiSummary != null)
                            Text(
                              _aiSummary!,
                              style: const TextStyle(
                                color: Color(0xFFE5E5E7),
                                fontSize: 17,
                                height: 1.6,
                                letterSpacing: -0.2,
                                decoration: TextDecoration.none,
                              ),
                              textAlign: TextAlign.start,
                            )
                          else if (cleanDescription.isNotEmpty)
                            Text(
                              cleanDescription,
                              style: const TextStyle(
                                color: Color(0xFFE5E5E7),
                                fontSize: 17,
                                height: 1.6,
                                letterSpacing: -0.2,
                                decoration: TextDecoration.none,
                              ),
                              textAlign: TextAlign.start,
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Read Full Article Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF4CAF50),
                            const Color(0xFF45A049),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.circular(16),
                        onPressed: () {
                          _openArticleExternal(widget.article['link'], context);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                CupertinoIcons.arrow_up_right_square_fill,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Read Full Article',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}