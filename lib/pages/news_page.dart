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
    return Scaffold(
      backgroundColor: Colors.grey[800], // Gray background
      appBar: AppBar(
        backgroundColor: Colors.grey[800], // Gray background
        title: Image.asset(
          'assets/9d514000-7637-4e02-bc87-df46fcb2fe36_removalai_preview.png',
          height: 40, // Adjust height as needed
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // League Filter
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: leagues.length,
              itemBuilder: (context, index) {
                final league = leagues[index];
                final isSelected = league == selectedLeague;

                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
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
                            color: isSelected ? Colors.white : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    onSelected: (selected) {
                      setState(() {
                        selectedLeague = league;
                        fetchNews();
                      });
                    },
                    selectedColor: Colors.green, // Green when selected
                    backgroundColor: Colors.grey[700], // Dark gray when unselected
                  ),
                );
              },
            ),
          ),

          // News List
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.green))
                : error.isNotEmpty
                    ? Center(
                        child: Text(
                          error,
                          style: TextStyle(color: Colors.red),
                        ),
                      )
                    : RefreshIndicator(
                        color: Colors.green,
                        onRefresh: fetchNews,
                        child: newsArticles.isEmpty
                            ? Center(
                                child: Text(
                                  'No news found for $selectedLeague',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.all(16),
                                itemCount: newsArticles.length,
                                itemBuilder: (context, index) {
                                  final article = newsArticles[index];
                                  return _buildNewsCard(article);
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> article) {
    return GestureDetector(
      onTap: () => _openArticle(article['link']),
      child: Card(
        color: Colors.grey[700], // Dark gray card background
        margin: EdgeInsets.only(bottom: 16),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article Image
            if (article['imageUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  article['imageUrl']!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[600],
                      child: Icon(
                        Icons.sports,
                        size: 50,
                        color: Colors.grey[400],
                      ),
                    );
                  },
                ),
              ),
            // Article Content
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    article['title'] ?? 'No title',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Description
                  if (article['description'] != null)
                    Text(
                      article['description'],
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 16),
                  // Footer with date and author
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.green,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatDate(article['pubDate'] ?? ''),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (article['creator'] != null)
                        Text(
                          'by ${article['creator']}',
                          style: TextStyle(
                            color: Colors.green,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open article'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
