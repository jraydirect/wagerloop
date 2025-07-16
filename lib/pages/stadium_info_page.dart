import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class StadiumInfoPage extends StatefulWidget {
  const StadiumInfoPage({Key? key}) : super(key: key);

  @override
  _StadiumInfoPageState createState() => _StadiumInfoPageState();
}

class _StadiumInfoPageState extends State<StadiumInfoPage> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedSport = 'MLB';
  List<dynamic> _stadiumData = [];
  bool _isLoading = true;
  String? _error;

  final List<Map<String, dynamic>> _sportsOptions = [
    {
      'name': 'MLB',
      'icon': Icons.sports_baseball,
      'color': Colors.orange,
      'available': true,
      'fileName': 'lib/mlbBallparkInfo.json',
    },
    {
      'name': 'NFL',
      'icon': Icons.sports_football,
      'color': Colors.purple,
      'available': true,
      'fileName': 'lib/nflStadiumInfo.json',
    },
    {
      'name': 'NBA',
      'icon': Icons.sports_basketball,
      'color': Colors.blue,
      'available': true,
      'fileName': 'lib/nbaStadiumInfo.json',
    },
    {
      'name': 'NHL',
      'icon': Icons.sports_hockey,
      'color': Colors.teal,
      'available': true,
      'fileName': 'lib/nhlStadiumInfo.json',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadStadiumData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadStadiumData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Find the selected sport's file name
      final selectedSport = _sportsOptions.firstWhere(
        (sport) => sport['name'] == _selectedSport,
        orElse: () => _sportsOptions.first,
      );
      
      if (!selectedSport['available']) {
        setState(() {
          _stadiumData = [];
          _isLoading = false;
        });
        return;
      }
      
      final String fileName = selectedSport['fileName'] as String;
      if (fileName.isEmpty) {
        throw Exception('No data file specified for $_selectedSport');
      }
      
      final String jsonString = await rootBundle.loadString(fileName);
      final List<dynamic> data = json.decode(jsonString);
      
      setState(() {
        _stadiumData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load stadium data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Widget _buildSportSelector() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _sportsOptions.length,
        itemBuilder: (context, index) {
          final sport = _sportsOptions[index];
          final isSelected = _selectedSport == sport['name'];
          final isAvailable = sport['available'] as bool;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isAvailable
                    ? () {
                        setState(() {
                          _selectedSport = sport['name'];
                        });
                        _loadStadiumData();
                      }
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${sport['name']} data coming soon!'),
                            backgroundColor: Colors.orange.withOpacity(0.9),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              sport['color'],
                              (sport['color'] as Color).withOpacity(0.8),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey[700]!.withOpacity(0.8),
                              Colors.grey[800]!.withOpacity(0.9),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (sport['color'] as Color).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sport['icon'],
                        color: isAvailable
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sport['name'],
                        style: TextStyle(
                          color: isAvailable
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (!isAvailable) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.lock,
                          size: 16,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStadiumCard(Map<String, dynamic> stadium, int index) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 300 + (index * 50)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, opacity, child) {
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - opacity)),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey[700]!.withOpacity(0.95),
                      Colors.grey[800]!.withOpacity(0.9),
                      Colors.grey[850]!.withOpacity(0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showStadiumDetails(stadium),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange.withOpacity(0.8),
                                      Colors.orange.withOpacity(0.6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.stadium,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stadium['stadium_name'] ?? 'Unknown Stadium',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      stadium['team'] ?? 'Unknown Team',
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withOpacity(0.7),
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoChip(
                                  Icons.location_on,
                                  stadium['location'] ?? 'Unknown',
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildInfoChip(
                                  Icons.people,
                                  '${stadium['crowd_capacity']?.toString() ?? '0'}',
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoChip(
                                  Icons.volume_up,
                                  '${stadium['decibel_average_dBA'] ?? 'N/A'} dB',
                                  Colors.purple,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildInfoChip(
                                  Icons.terrain,
                                  '${stadium['elevation_feet']?.toString() ?? '0'} ft',
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: child,
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showStadiumDetails(Map<String, dynamic> stadium) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StadiumDetailsSheet(stadium: stadium),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.8),
                    Colors.orange.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.stadium,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Stadium Info',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Column(
              children: [
                _buildSportSelector(),
                if (_isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    ),
                  )
                else if (_error != null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading data',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadStadiumData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_stadiumData.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No stadium data available',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _stadiumData.length,
                      itemBuilder: (context, index) {
                        return _buildStadiumCard(_stadiumData[index], index);
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class StadiumDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> stadium;

  const StadiumDetailsSheet({Key? key, required this.stadium}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[800]!,
            Colors.grey[850]!,
            Colors.grey[900]!,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.withOpacity(0.8),
                              Colors.orange.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.stadium,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stadium['stadium_name'] ?? 'Unknown Stadium',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stadium['team'] ?? 'Unknown Team',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailSection(
                    'Location',
                    stadium['location'] ?? 'Unknown',
                    Icons.location_on,
                    Colors.blue,
                  ),
                  _buildDetailSection(
                    'Capacity',
                    '${stadium['crowd_capacity']?.toString() ?? '0'} fans',
                    Icons.people,
                    Colors.green,
                  ),
                  _buildDetailSection(
                    'Average Noise Level',
                    '${stadium['decibel_average_dBA'] ?? 'N/A'} dB',
                    Icons.volume_up,
                    Colors.purple,
                  ),
                  _buildDetailSection(
                    'Elevation',
                    '${stadium['elevation_feet']?.toString() ?? '0'} feet above sea level',
                    Icons.terrain,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
