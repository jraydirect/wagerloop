// Import Cupertino design components for iOS-style UI
import 'package:flutter/cupertino.dart';
// Import Material Design components for additional UI elements
import 'package:flutter/material.dart'; // Still good for Colors, etc.
// Import HTTP library for making API requests
import 'package:http/http.dart' as http;
// Import dart:convert for JSON parsing
import 'dart:convert';
// Import XML library for parsing RSS feeds
import 'package:xml/xml.dart';
// Import URL launcher for opening external links
import 'package:url_launcher/url_launcher.dart';

// NewsPage class definition - a stateful widget for displaying sports news
class NewsPage extends StatefulWidget {
  // Override createState method to return the state class instance
  @override
  _NewsPageState createState() => _NewsPageState();
}

// Private state class that manages the news page's state and functionality
class _NewsPageState extends State<NewsPage> {
  // List to store news articles
  List<Map<String, dynamic>> newsArticles = [];
  // Boolean flag to track loading state
  bool isLoading = true;
  // String to store error message
  String error = '';
  // Currently selected league (default to NBA)
  String selectedLeague = 'NBA';

  // RSS feed URLs for different sports
  // Map of league names to their RSS feed URLs
  final Map<String, String> rssFeeds = {
    'NBA': 'https://www.cbssports.com/rss/headlines/nba/',
    'NFL': 'https://www.cbssports.com/rss/headlines/nfl/',
    'MLB': 'https://www.cbssports.com/rss/headlines/mlb/',
    'NHL': 'https://www.cbssports.com/rss/headlines/nhl/',
  };

  // List of available leagues for filtering
  final List<String> leagues = ['NBA', 'NFL', 'MLB', 'NHL'];

  // Helper method to get league logo path
  String getLeagueLogoPath(String league) {
    // Map of league names to their logo asset paths
    final Map<String, String> leagueLogos = {
      'NBA': 'assets/leagueLogos/nba.png',
      'NFL': 'assets/leagueLogos/nfl.png',
      'MLB': 'assets/leagueLogos/mlb.png',
      'NHL': 'assets/leagueLogos/nhl.png',
    };
    // Return logo path or empty string if not found
    return leagueLogos[league] ?? '';
  }

  // Override initState to initialize the widget state
  @override
  void initState() {
    // Call parent initState
    super.initState();
    // Fetch news on initialization
    fetchNews();
  }

  // Async method to fetch news from RSS feed
  Future<void> fetchNews() async {
    // Set loading state and clear error
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      // Get RSS feed URL for selected league
      final rssUrl = rssFeeds[selectedLeague];
      if (rssUrl == null) {
        throw Exception('No RSS feed found for $selectedLeague');
      }

      // Make HTTP GET request to RSS feed
      final response = await http.get(Uri.parse(rssUrl));

      // Check if request was successful
      if (response.statusCode == 200) {
        // Parse XML response
        final document = XmlDocument.parse(response.body);
        // Find all item elements in the RSS feed
        final items = document.findAllElements('item');

        // List to store parsed articles
        List<Map<String, dynamic>> articles = [];

        // Process each RSS item
        for (final item in items) {
          // Extract title from XML element
          final title = item.findElements('title').first.innerText;
          // Extract description from XML element
          final description = item.findElements('description').first.innerText;
          // Extract link from XML element
          final link = item.findElements('link').first.innerText;
          // Extract publication date from XML element
          final pubDate = item.findElements('pubDate').first.innerText;
          // Extract creator with fallback to default
          final creator = item.findElements('dc:creator').isNotEmpty
              ? item.findElements('dc:creator').first.innerText
              : 'CBS Sports';
          // Extract image URL if available
          final imageUrl = item.findElements('enclosure').isNotEmpty
              ? item.findElements('enclosure').first.getAttribute('url')
              : null;

          // Add article to list
          articles.add({
            'title': title,
            'description': description,
            'link': link,
            'pubDate': pubDate,
            'creator': creator,
            'imageUrl': imageUrl,
          });
        }

        // Update state with parsed articles
        setState(() {
          newsArticles = articles;
          isLoading = false;
        });
      } else {
        // Throw error if request failed
        throw Exception('Failed to load RSS feed: ${response.statusCode}');
      }
    } catch (e) {
      // Handle error and update state
      setState(() {
        error = 'Error loading news: $e';
        isLoading = false;
      });
    }
  }

  // Override build method to construct the widget tree
  @override
  Widget build(BuildContext context) {
    // Return Cupertino page scaffold for iOS-style design
    return CupertinoPageScaffold(
      // Same gray background as Colors.grey[800]
      backgroundColor: const Color(0xFF424242),
      // Cupertino navigation bar
      navigationBar: CupertinoNavigationBar(
        // Same gray background
        backgroundColor: const Color(0xFF424242),
        // Remove default border
        border: null,
        // App logo in center
        middle: Image.asset(
          'assets/9d514000-7637-4e02-bc87-df46fcb2fe36_removalai_preview.png',
          height: 40,
          fit: BoxFit.contain,
        ),
      ),
      // Safe area body
      child: SafeArea(
        // Column to arrange main content
        child: Column(
          children: [
            // League Filter
            // Container for horizontal league filter
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              // Horizontal list of league filter buttons
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: leagues.length,
                // Builder function for each league filter
                itemBuilder: (context, index) {
                  // Get league at current index
                  final league = leagues[index];
                  // Check if this league is selected
                  final isSelected = league == selectedLeague;

                  // Return padded button
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    // Cupertino button for league filter
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      borderRadius: BorderRadius.circular(20),
                      // Green for selected, gray for unselected
                      color: isSelected
                          ? const Color(0xFF4CAF50) // Same green as Colors.green
                          : const Color(0xFF616161), // Same as Colors.grey[700]
                      // Handle league selection
                      onPressed: () {
                        setState(() {
                          selectedLeague = league;
                          fetchNews();
                        });
                      },
                      // Button content with logo and text
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // League logo
                          Image.asset(
                            getLeagueLogoPath(league),
                            height: 20,
                            width: 20,
                            fit: BoxFit.contain,
                          ),
                          // Spacing between logo and text
                          const SizedBox(width: 8),
                          // League name text
                          Text(
                            league,
                            style: TextStyle(
                              // White for selected, green for unselected
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
            // Expanded area for news content
            Expanded(
              // Conditional rendering based on loading state
              child: isLoading
                  // Show loading indicator when loading
                  ? const Center(
                      child: CupertinoActivityIndicator(
                        // Same green color
                        color: Color(0xFF4CAF50),
                        radius: 15,
                      ),
                    )
                  // Show error message if error occurred
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
                      // Show news list with pull-to-refresh
                      : CustomScrollView(
                          // iOS-style bouncing scroll physics
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            // Pull-to-refresh control
                            CupertinoSliverRefreshControl(
                              onRefresh: fetchNews,
                            ),
                            // Conditional rendering based on articles availability
                            newsArticles.isEmpty
                                // Show empty state if no articles
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
                                // Show articles list if articles exist
                                : SliverPadding(
                                    padding: const EdgeInsets.all(16),
                                    // Sliver list for articles
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        // Builder function for each article card
                                        (context, index) {
                                          // Get article data at current index
                                          final article = newsArticles[index];
                                          // Return padded news card
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

  // Method to build individual news card widget
  Widget _buildNewsCard(Map<String, dynamic> article) {
    // Return clickable news card
    return CupertinoButton(
      // No padding for button
      padding: EdgeInsets.zero,
      // Handle tap to show article details
      onPressed: () => _showArticleDetails(context, article),
      // Card container
      child: Container(
        // Card decoration with background and shadow
        decoration: BoxDecoration(
          // Same as Colors.grey[700]
          color: const Color(0xFF616161),
          borderRadius: BorderRadius.circular(12),
          // Shadow for depth effect
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        // Clipped rounded rectangle for card content
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          // Column to arrange card content vertically
          child: Column(
            // Ensure main column content is left-aligned
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Article Image
              // Show article image if available
              if (article['imageUrl'] != null)
                ClipRRect(
                  // Rounded corners for top of image
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  // Network image with error handling
                  child: Image.network(
                    article['imageUrl']!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    // Error builder for failed image loads
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        // Same as Colors.grey[600]
                        color: const Color(0xFF757575),
                        // Placeholder icon
                        child: const Icon(
                          CupertinoIcons.sportscourt,
                          size: 50,
                          // Same as Colors.grey[400]
                          color: Color(0xFF9E9E9E),
                        ),
                      );
                    },
                  ),
                ),
              // Article Content (Title and CBS Sports)
              // Padded content area
              Padding(
                // Consistent padding
                padding: const EdgeInsets.all(16),
                // Column for article text content
                child: Column(
                  // Ensure nested column content is left-aligned
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // Allow column to shrink wrap its content vertically
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title - No maxLines or overflow.ellipsis here!
                    // Article title text
                    Text(
                      article['title'] ?? 'No title',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      // Explicitly set to start
                      textAlign: TextAlign.start,
                      softWrap: true,
                    ),
                    // Space between title and "CBS Sports"
                    const SizedBox(height: 10),
                    // Add "CBS Sports" in the bottom right corner
                    // Use a Row with Spacer to push CBS Sports to the right
                    Row(
                      children: [
                        // This pushes the following widget to the right
                        Spacer(),
                        // CBS Sports attribution text
                        Text(
                          'CBS Sports',
                          style: TextStyle(
                            // A lighter grey for subtle branding
                            color: Color(0xFFBDBDBD),
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
  // Method to show article details in full-screen modal
  void _showArticleDetails(BuildContext context, Map<String, dynamic> article) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        // Makes it a full-screen modal presentation
        fullscreenDialog: true,
        builder: (context) => ArticleDetailModal(article: article),
      ),
    );
  }

  // Method to format date string to relative time
  String _formatDate(String dateString) {
    try {
      // Parse date string to DateTime
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      // Format based on time difference
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
      // Return original string if parsing fails
      return dateString;
    }
  }

  // Renamed _openArticle to _openArticleExternal to clarify its purpose
  // Method to open article in external browser
  Future<void> _openArticleExternal(String? url) async {
    if (url != null) {
      // Parse URL
      final uri = Uri.parse(url);
      // Check if URL can be launched
      if (await canLaunchUrl(uri)) {
        // Launch URL in external application
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Show error dialog if URL cannot be opened
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
// ArticleDetailModal class definition - a stateful widget for displaying article details
class ArticleDetailModal extends StatefulWidget {
  // Article data to display
  final Map<String, dynamic> article;

  // Constructor with required article parameter
  const ArticleDetailModal({Key? key, required this.article}) : super(key: key);

  // Override createState method to return the state class instance
  @override
  _ArticleDetailModalState createState() => _ArticleDetailModalState();
}

// Private state class for article detail modal
class _ArticleDetailModalState extends State<ArticleDetailModal> {
  // Helper to format date, copied from NewsPage for self-containment
  String _formatDate(String dateString) {
    try {
      // Parse date string to DateTime
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      // Format based on time difference
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
      // Return original string if parsing fails
      return dateString;
    }
  }

  // Helper to open external link
  Future<void> _openArticleExternal(String? url, BuildContext context) async {
    if (url != null) {
      // Parse URL
      final uri = Uri.parse(url);
      // Check if URL can be launched
      if (await canLaunchUrl(uri)) {
        // Launch URL in external application
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Show error dialog if URL cannot be opened
        showCupertinoDialog(
          context: context,
          // Use dialogContext to avoid conflicts
          builder: (BuildContext dialogContext) {
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

  // Override build method to construct the widget tree
  @override
  Widget build(BuildContext context) {
    // Get article data
    final article = widget.article;

    // A more aggressive regex to strip out all HTML tags and entities.
    // This is crucial for cleaning the description.
    String cleanDescription = (article['description'] as String?)
            // Strip HTML tags and entities
            ?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '')
            // Replace multiple spaces with a single space
            .replaceAll(RegExp(r'\s+'), ' ')
            // Trim leading/trailing whitespace
            .trim() ??
        '';

    // Return Cupertino page scaffold for article detail
    return CupertinoPageScaffold(
      // Match app background
      backgroundColor: const Color(0xFF424242),
      // Cupertino navigation bar
      navigationBar: CupertinoNavigationBar(
        // Match app background
        backgroundColor: const Color(0xFF424242),
        // Title for the modal screen
        middle: const Text(
          'Article Details',
          style: TextStyle(color: Colors.white),
        ),
        // Back button
        leading: CupertinoNavigationBarBackButton(
          // Green back button
          color: const Color(0xFF4CAF50),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // Remove default border
        border: null,
      ),
      // Safe area body
      child: SafeArea(
        // Scrollable content
        child: SingleChildScrollView(
          // iOS-style bouncing scroll physics
          physics: const BouncingScrollPhysics(),
          // Column to arrange article content
          child: Column(
            // Ensure column content is left-aligned
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Article Image
              // Show article image if available
              if (article['imageUrl'] != null)
                Image.network(
                  article['imageUrl']!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // Error builder for failed image loads
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
              // Padded content area
              Padding(
                padding: const EdgeInsets.all(20.0),
                // Column for article text content
                child: Column(
                  // Ensure nested column content is left-aligned
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    // Article title text
                    Text(
                      article['title'] ?? 'No title',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        // Explicitly ensure no decoration
                        decoration: TextDecoration.none,
                      ),
                      // Explicitly set to start
                      textAlign: TextAlign.start,
                      softWrap: true,
                    ),
                    // Spacing between title and description
                    const SizedBox(height: 12),
                    // Description (Full)
                    // Use the cleaned description
                    if (cleanDescription.isNotEmpty)
                      Text(
                        cleanDescription,
                        style: const TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 16,
                          height: 1.5,
                          // Explicitly ensure no decoration
                          decoration: TextDecoration.none,
                        ),
                        // Explicitly set to start
                        textAlign: TextAlign.start,
                        softWrap: true,
                      ),
                    // Spacing before footer
                    const SizedBox(height: 20),
                    // Footer with date and author
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Date with clock icon
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
                        // Author information if available
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
                    // Spacing before button
                    const SizedBox(height: 20),
                    // Button to open original article
                    Center(
                      child: CupertinoTheme(
                        data: CupertinoTheme.of(context).copyWith(
                          // Green for the button
                          primaryColor: const Color(0xFF4CAF50),
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