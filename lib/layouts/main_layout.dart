// Main layout widget that provides the primary navigation structure for authenticated users - creates the main app interface
import 'package:flutter/material.dart';
// Import scores page for sports scores and betting - provides live sports data
import '../pages/scores_page.dart';
// Import news page for sports news and updates - provides sports journalism
import '../pages/news_page.dart';
// Import social feed page for community interactions - provides social media features
import '../pages/social_feed_page.dart';
// Import profile page for user account management - provides user settings and data
import '../pages/profile_page.dart';
// Import discover page for finding new content - provides content discovery features
import '../pages/discover_page.dart';

// Main layout widget that manages the primary app navigation - creates the main app shell
class MainLayout extends StatefulWidget {
  // Constructor with optional key parameter - creates new MainLayout widget
  const MainLayout({super.key});

  // Override createState to return the state class - creates the widget's state
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

// State class for MainLayout widget - manages navigation state and page switching
class _MainLayoutState extends State<MainLayout> {
  // Current selected tab index - tracks which page is currently active
  int _currentIndex = 0;

  // List of all main app pages - defines the available navigation destinations
  final List<Widget> _pages = [
    ScoresPage(), // Sports scores and live betting data
    NewsPage(), // Sports news and updates
    const DiscoverPage(), // Content discovery and recommendations
    const SocialFeedPage(), // Social media feed and interactions
    ProfilePage(), // User profile and account management
  ];

  // Build the widget UI - creates the main app interface with navigation
  @override
  Widget build(BuildContext context) {
    // Return scaffold with body and bottom navigation - creates the main app structure
    return Scaffold(
      // Body contains the current page using IndexedStack - displays active page
      body: IndexedStack(
        index: _currentIndex, // Show page at current index - displays selected page
        children: _pages, // All available pages - provides page switching capability
      ),
      // Bottom navigation bar for tab switching - provides main navigation interface
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // Highlight current tab - shows active page
        onTap: (index) => setState(() => _currentIndex = index), // Handle tab selection - updates active page
        type: BottomNavigationBarType.fixed, // Fixed type for consistent layout - ensures stable navigation
        backgroundColor: Colors.grey[850], // Dark gray background - matches app theme
        selectedItemColor: Colors.white, // White color for selected tab - provides contrast
        unselectedItemColor: Colors.white54, // Semi-transparent white for unselected tabs - shows inactive state
        items: const [
          // Scores tab - provides access to sports scores and betting
          BottomNavigationBarItem(
            icon: Icon(Icons.scoreboard), // Scoreboard icon - represents scores page
            label: 'Scores', // Tab label - describes page content
          ),
          // News tab - provides access to sports news and updates
          BottomNavigationBarItem(
            icon: Icon(Icons.article), // Article icon - represents news page
            label: 'News', // Tab label - describes page content
          ),
          // Discover tab - provides access to content discovery
          BottomNavigationBarItem(
            icon: Icon(Icons.search), // Search icon - represents discover page
            label: 'Discover', // Tab label - describes page content
          ),
          // Social tab - provides access to social media features
          BottomNavigationBarItem(
            icon: Icon(Icons.people), // People icon - represents social page
            label: 'Social', // Tab label - describes page content
          ),
          // Profile tab - provides access to user account management
          BottomNavigationBarItem(
            icon: Icon(Icons.person), // Person icon - represents profile page
            label: 'Profile', // Tab label - describes page content
          ),
        ],
      ),
    );
  }
}
