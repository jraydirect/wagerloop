// WagerLoop Style Agent Demonstration
// This file shows before/after examples of style fixes

// BEFORE: Missing const constructor
class SocialFeedPage extends StatefulWidget {
  SocialFeedPage({Key? key}) : super(key: key);  // ❌ Missing const

  @override
  _SocialFeedPageState createState() => _SocialFeedPageState();
}

// AFTER: Fixed const constructor
class SocialFeedPage extends StatefulWidget {
  const SocialFeedPage({Key? key}) : super(key: key);  // ✅ Added const

  @override
  _SocialFeedPageState createState() => _SocialFeedPageState();
}

// BEFORE: Hardcoded colors
Widget buildPostCard() {
  return Container(
    color: Colors.grey[800],  // ❌ Hardcoded color
    child: Card(
      color: Colors.white,  // ❌ Hardcoded color
      child: Column(
        children: [
          // ... content
        ],
      ),
    ),
  );
}

// AFTER: Theme-based colors
Widget buildPostCard() {
  return Container(
    color: Theme.of(context).scaffoldBackgroundColor,  // ✅ Theme color
    child: Card(
      color: Theme.of(context).cardColor,  // ✅ Theme color
      child: Column(
        children: [
          // ... content
        ],
      ),
    ),
  );
}

// BEFORE: Large build method (50+ lines)
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        // ... 50+ lines of widget code
        Container(
          padding: EdgeInsets.all(16),
          child: TextField(
            controller: _postController,
            decoration: InputDecoration(
              hintText: 'What\'s on your mind?',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        // ... more widget code
        Expanded(
          child: ListView.builder(
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  title: Text(_posts[index].content),
                  subtitle: Text(_posts[index].timestamp.toString()),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

// AFTER: Extracted build methods
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        _buildPostCreationSection(),
        _buildPostsList(),
      ],
    ),
  );
}

Widget _buildPostCreationSection() {  // ✅ Extracted method
  return Container(
    padding: const EdgeInsets.all(16),
    child: TextField(
      controller: _postController,
      decoration: const InputDecoration(
        hintText: 'What\'s on your mind?',
        border: OutlineInputBorder(),
      ),
    ),
  );
}

Widget _buildPostsList() {  // ✅ Extracted method
  return Expanded(
    child: ListView.builder(
      itemCount: _posts.length,
      itemBuilder: (context, index) => _buildPostCard(_posts[index]),
    ),
  );
}

Widget _buildPostCard(Post post) {  // ✅ Extracted method
  return Card(
    child: ListTile(
      title: Text(post.content),
      subtitle: Text(post.timestamp.toString()),
    ),
  );
}

// BEFORE: Inconsistent error handling
Future<void> _loadPosts() async {
  final posts = await _socialFeedService.fetchPosts();  // ❌ No error handling
  setState(() {
    _posts.addAll(posts);
  });
}

// AFTER: Proper error handling
Future<void> _loadPosts() async {
  try {
    final posts = await _socialFeedService.fetchPosts();  // ✅ Error handling
    setState(() {
      _posts.addAll(posts);
    });
  } catch (e) {
    setState(() {
      _error = 'Could not load posts. Please try again.';
    });
    print('Error loading posts: $e');
  }
}

// SUGGESTED WIDGET EXTRACTION:
// Instead of keeping everything in social_feed_page.dart,
// extract these components:

// lib/widgets/social/post_card_widget.dart
class PostCardWidget extends StatelessWidget {
  final Post post;
  
  const PostCardWidget({Key? key, required this.post}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostHeader(),
          _buildPostContent(),
          _buildPostActions(),
        ],
      ),
    );
  }
  
  Widget _buildPostHeader() { /* ... */ }
  Widget _buildPostContent() { /* ... */ }
  Widget _buildPostActions() { /* ... */ }
}

// lib/widgets/social/post_creation_widget.dart
class PostCreationWidget extends StatefulWidget {
  final Function(String) onPostCreated;
  
  const PostCreationWidget({Key? key, required this.onPostCreated}) : super(key: key);
  
  @override
  _PostCreationWidgetState createState() => _PostCreationWidgetState();
}

// lib/widgets/social/comment_section_widget.dart
class CommentSectionWidget extends StatelessWidget {
  final String postId;
  
  const CommentSectionWidget({Key? key, required this.postId}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Comment section implementation
  }
}

// RESULT: Cleaner, more maintainable code structure
// - social_feed_page.dart: ~300 lines (down from 1396)
// - Reusable components for other pages
// - Consistent theming and styling
// - Better error handling
// - Improved performance with const constructors