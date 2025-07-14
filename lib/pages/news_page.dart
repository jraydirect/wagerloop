import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Still good for Colors, etc.
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:xml/xml.dart';
import 'package:url_launcher/url_launcher.dart';

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
          final imageUrl = item.findElements('enclosure').isNotEmpty
              ? item.findElements('enclosure').first.getAttribute('url')
              : null;

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
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF424242), // Same gray background as Colors.grey[800]
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF424242), // Same gray background
        border: null, // Remove default border
        middle: Image.asset(
          'assets/9d514000-7637-4e02-bc87-df46fcb2fe36_removalai_preview.png',
          height: 40,
          fit: BoxFit.contain,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // League Filter
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: leagues.length,
                itemBuilder: (context, index) {
                  final league = leagues[index];
                  final isSelected = league == selectedLeague;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      borderRadius: BorderRadius.circular(20),
                      color: isSelected
                          ? const Color(0xFF4CAF50) // Same green as Colors.green
                          : const Color(0xFF616161), // Same as Colors.grey[700]
                      onPressed: () {
                        setState(() {
                          selectedLeague = league;
                          fetchNews();
                        });
                      },
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
                              color: isSelected ? Colors.white : const Color(0xFF4CAF50),
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // News List
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CupertinoActivityIndicator(
                        color: Color(0xFF4CAF50), // Same green
                        radius: 15,
                      ),
                    )
                  : error.isNotEmpty
                      ? Center(
                          child: Text(
                            error,
                            style: const TextStyle(
                              color: CupertinoColors.destructiveRed,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            CupertinoSliverRefreshControl(
                              onRefresh: fetchNews,
                            ),
                            newsArticles.isEmpty
                                ? SliverFillRemaining(
                                    child: Center(
                                      child: Text(
                                        'No news found for $selectedLeague',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  )
                                : SliverPadding(
                                    padding: const EdgeInsets.all(16),
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
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> article) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showArticleDetails(context, article),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF616161), // Same as Colors.grey[700]
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Ensure main column content is left-aligned
            children: [
              // Article Image
              if (article['imageUrl'] != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    article['imageUrl']!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: const Color(0xFF757575), // Same as Colors.grey[600]
                        child: const Icon(
                          CupertinoIcons.sportscourt,
                          size: 50,
                          color: Color(0xFF9E9E9E), // Same as Colors.grey[400]
                        ),
                      );
                    },
                  ),
                ),
              // Article Content (Title and CBS Sports)
              Padding(
                padding: const EdgeInsets.all(16), // Consistent padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Ensure nested column content is left-aligned
                  mainAxisSize: MainAxisSize.min, // Allow column to shrink wrap its content vertically
                  children: [
                    // Title - No maxLines or overflow.ellipsis here!
                    Text(
                      article['title'] ?? 'No title',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.start, // Explicitly set to start
                      softWrap: true,
                    ),
                    const SizedBox(height: 10), // Space between title and "CBS Sports"
                    // Add "CBS Sports" in the bottom right corner
                    // Use a Row with Spacer to push CBS Sports to the right
                    Row(
                      children: [
                        Spacer(), // This pushes the following widget to the right
                        Text(
                          'CBS Sports',
                          style: TextStyle(
                            color: Color(0xFFBDBDBD), // A lighter grey for subtle branding
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
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

    // A more aggressive regex to strip out all HTML tags and entities.
    // This is crucial for cleaning the description.
    String cleanDescription = (article['description'] as String?)
            ?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '') // Strip HTML tags and entities
            .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with a single space
            .trim() ??
        ''; // Trim leading/trailing whitespace

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF424242), // Match app background
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF424242), // Match app background
        middle: const Text(
          'Article Details',
          style: TextStyle(color: Colors.white), // Title for the modal screen
        ),
        leading: CupertinoNavigationBarBackButton(
          color: const Color(0xFF4CAF50), // Green back button
          onPressed: () => Navigator.of(context).pop(),
        ),
        border: null, // Remove default border
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Ensure column content is left-aligned
            children: [
              // Article Image
              if (article['imageUrl'] != null)
                Image.network(
                  article['imageUrl']!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      color: const Color(0xFF757575),
                      child: const Icon(
                        CupertinoIcons.sportscourt,
                        size: 70,
                        color: Color(0xFF9E9E9E),
                      ),
                    );
                  },
                ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Ensure nested column content is left-aligned
                  children: [
                    // Title
                    Text(
                      article['title'] ?? 'No title',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        decoration: TextDecoration.none, // Explicitly ensure no decoration
                      ),
                      textAlign: TextAlign.start, // Explicitly set to start
                      softWrap: true,
                    ),
                    const SizedBox(height: 12),
                    // Description (Full)
                    if (cleanDescription.isNotEmpty) // Use the cleaned description
                      Text(
                        cleanDescription,
                        style: const TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 16,
                          height: 1.5,
                          decoration: TextDecoration.none, // Explicitly ensure no decoration
                        ),
                        textAlign: TextAlign.start, // Explicitly set to start
                        softWrap: true,
                      ),
                    const SizedBox(height: 20),
                    // Footer with date and author
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.clock,
                              size: 18,
                              color: Color(0xFF4CAF50),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(article['pubDate'] ?? ''),
                              style: const TextStyle(
                                color: Color(0xFFBDBDBD),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        if (article['creator'] != null)
                          Flexible(
                            child: Text(
                              'by ${article['creator']}',
                              style: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Button to open original article
                    Center(
                      child: CupertinoTheme(
                        data: CupertinoTheme.of(context).copyWith(
                          primaryColor: const Color(0xFF4CAF50), // Green for the button
                        ),
                        child: CupertinoButton.filled(
                          onPressed: () {
                            _openArticleExternal(article['link'], context);
                          },
                          child: const Text('Read Full Article on CBS Sports'),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          borderRadius: BorderRadius.circular(20),
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
}