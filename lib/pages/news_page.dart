import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
      onPressed: () => _openArticle(article['link']),
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
              // Article Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      article['title'] ?? 'No title',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Description
                    if (article['description'] != null)
                      Text(
                        article['description'],
                        style: const TextStyle(
                          color: Color(0xFFE0E0E0), // Same as Colors.grey[300]
                          fontSize: 14,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 16),
                    // Footer with date and author
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.clock,
                          size: 16,
                          color: Color(0xFF4CAF50), // Same green
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDate(article['pubDate'] ?? ''),
                            style: const TextStyle(
                              color: Color(0xFFBDBDBD), // Same as Colors.grey[400]
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (article['creator'] != null)
                          Text(
                            'by ${article['creator']}',
                            style: const TextStyle(
                              color: Color(0xFF4CAF50), // Same green
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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

  Future<void> _openArticle(String? url) async {
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Show Cupertino-style alert dialog instead of SnackBar
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
