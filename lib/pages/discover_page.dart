import 'package:flutter/material.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({Key? key}) : super(key: key);

  @override
  _DiscoverPageState createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  // Small square tools for horizontal scrolling (organized in pairs for 2 rows)
  final List<List<Map<String, dynamic>>> _toolRows = [
    [
      {'name': 'Injury Watch', 'icon': Icons.medical_services, 'color': Colors.red},
      {'name': 'Coaches', 'icon': Icons.person, 'color': Colors.blue},
      {'name': 'Stadium Info', 'icon': Icons.stadium, 'color': Colors.orange},
      {'name': 'Referees', 'icon': Icons.sports, 'color': Colors.purple},
      {'name': 'Weather', 'icon': Icons.wb_sunny, 'color': Colors.yellow},
      {'name': 'Schedule', 'icon': Icons.schedule, 'color': Colors.teal},
    ],
    [
      {'name': 'Stats', 'icon': Icons.bar_chart, 'color': Colors.indigo},
      {'name': 'Teams', 'icon': Icons.groups, 'color': Colors.pink},
      {'name': 'Players', 'icon': Icons.sports_basketball, 'color': Colors.cyan},
      {'name': 'Odds', 'icon': Icons.trending_up, 'color': Colors.lime},
      {'name': 'News', 'icon': Icons.newspaper, 'color': Colors.amber},
      {'name': 'Videos', 'icon': Icons.play_circle, 'color': Colors.deepOrange},
    ],
  ];

  // Long rectangular features for vertical scrolling
  final List<Map<String, dynamic>> _features = [
    {'name': 'WagerGPT', 'icon': Icons.smart_toy, 'description': 'AI-powered betting insights', 'gradient': [Colors.green, Colors.teal]},
    {'name': 'Momentum Tracker', 'icon': Icons.trending_up, 'description': 'Track game momentum changes', 'gradient': [Colors.blue, Colors.indigo]},
    {'name': 'Leaderboards', 'icon': Icons.leaderboard, 'description': 'Top performers and rankings', 'gradient': [Colors.orange, Colors.red]},
    {'name': 'Communities', 'icon': Icons.forum, 'description': 'Connect with fellow fans', 'gradient': [Colors.purple, Colors.pink]},
    {'name': 'Live Analysis', 'icon': Icons.analytics, 'description': 'Real-time game analysis', 'gradient': [Colors.teal, Colors.cyan]},
    {'name': 'Prediction Hub', 'icon': Icons.psychology, 'description': 'Make and track predictions', 'gradient': [Colors.indigo, Colors.blue]},
    {'name': 'Expert Picks', 'icon': Icons.star, 'description': 'Professional predictions', 'gradient': [Colors.amber, Colors.orange]},
    {'name': 'Betting Calculator', 'icon': Icons.calculate, 'description': 'Calculate potential payouts', 'gradient': [Colors.green, Colors.lightGreen]},
  ];

  Widget _buildToolCard(Map<String, dynamic> tool) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[700]!,
            Colors.grey[800]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[600]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle tool tap
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${tool['name']} tapped'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tool['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  tool['icon'],
                  size: 28,
                  color: tool['color'],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tool['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.grey[700]!,
            Colors.grey[800]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[600]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle feature tap
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${feature['name']} tapped'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: feature['gradient'] as List<Color>,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (feature['gradient'] as List<Color>)[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    feature['icon'],
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        feature['description'],
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[600]!.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolsGrid() {
    return Container(
      height: 240, // Increased height for 2 rows
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6, // Number of columns to show
        itemBuilder: (context, columnIndex) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Column(
              children: [
                // First row
                if (columnIndex < _toolRows[0].length)
                  _buildToolCard(_toolRows[0][columnIndex]),
                const SizedBox(height: 12),
                // Second row
                if (columnIndex < _toolRows[1].length)
                  _buildToolCard(_toolRows[1][columnIndex]),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Discover',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Tools section with enhanced styling (moved up, no search bar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                const Text(
                  'Quick Tools',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Two-row horizontally scrollable tools
          _buildToolsGrid(),

          const SizedBox(height: 32),

          // Features section header with enhanced styling
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Features',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Vertically scrollable features section (now has more room)
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _features.length,
              itemBuilder: (context, index) => _buildFeatureCard(_features[index], index),
            ),
          ),
        ],
      ),
    );
  }
}
