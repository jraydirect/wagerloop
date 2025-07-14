// lib/layouts/main_layout.dart
import 'package:flutter/material.dart'; // Import Flutter's core material design widgets and framework
import '../pages/scores_page.dart'; // Import the scores page component for displaying game scores
import '../pages/news_page.dart'; // Import the news page component for displaying sports news
import '../pages/social_feed_page.dart'; // Import the social feed page component for social interactions
import '../pages/profile_page.dart'; // Import the profile page component for user profile management
import '../pages/discover_page.dart'; // Import the discover page component for content discovery

class MainLayout extends StatefulWidget { // Define MainLayout as a stateful widget to manage navigation state
  const MainLayout({super.key}); // Constructor for MainLayout with optional key parameter

  @override // Override the createState method from StatefulWidget
  State<MainLayout> createState() => _MainLayoutState(); // Return the state object for this widget
} // End of MainLayout class

class _MainLayoutState extends State<MainLayout> { // Define the state class for MainLayout widget
  int _currentIndex = 0; // Initialize current navigation index to 0 (first tab)

  final List<Widget> _pages = [ // Define a list of pages to display in the bottom navigation
    ScoresPage(), // First page: Scores page for displaying game scores
    NewsPage(), // Second page: News page for displaying sports news
    const DiscoverPage(), // Third page: Discover page for content discovery
    const SocialFeedPage(), // Fourth page: Social feed page for social interactions
    ProfilePage(), // Fifth page: Profile page for user profile management
  ]; // End of pages list

  @override // Override the build method from State class
  Widget build(BuildContext context) { // Build method that returns the widget tree for the main layout
    return Scaffold( // Return a Scaffold widget that provides the basic layout structure
      body: IndexedStack( // Use IndexedStack to maintain state of all pages while showing only one
        index: _currentIndex, // Set the current index to determine which page to display
        children: _pages, // Set the children to the list of pages
      ), // End of IndexedStack
      bottomNavigationBar: BottomNavigationBar( // Define the bottom navigation bar
        currentIndex: _currentIndex, // Set the current index to highlight the active tab
        onTap: (index) => setState(() => _currentIndex = index), // Handle tab selection by updating the current index
        type: BottomNavigationBarType.fixed, // Set navigation bar type to fixed layout
        backgroundColor: Colors.grey[850], // Set background color to dark gray
        selectedItemColor: Colors.white, // Set selected item color to white
        unselectedItemColor: Colors.white54, // Set unselected item color to semi-transparent white
        items: const [ // Define the list of bottom navigation items
          BottomNavigationBarItem( // First navigation item for scores
            icon: Icon(Icons.scoreboard), // Set icon to scoreboard for scores tab
            label: 'Scores', // Set label text to "Scores"
          ), // End of first navigation item
          BottomNavigationBarItem( // Second navigation item for news
            icon: Icon(Icons.article), // Set icon to article for news tab
            label: 'News', // Set label text to "News"
          ), // End of second navigation item
          BottomNavigationBarItem( // Third navigation item for discover
            icon: Icon(Icons.search), // Set icon to search for discover tab
            label: 'Discover', // Set label text to "Discover"
          ), // End of third navigation item
          BottomNavigationBarItem( // Fourth navigation item for social
            icon: Icon(Icons.people), // Set icon to people for social tab
            label: 'Social', // Set label text to "Social"
          ), // End of fourth navigation item
          BottomNavigationBarItem( // Fifth navigation item for profile
            icon: Icon(Icons.person), // Set icon to person for profile tab
            label: 'Profile', // Set label text to "Profile"
          ), // End of fifth navigation item
        ], // End of navigation items list
      ), // End of BottomNavigationBar
    ); // End of Scaffold
  } // End of build method
} // End of _MainLayoutState class
