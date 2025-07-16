import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../services/weather_service.dart';
import '../models/weather.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WeatherInfoPage extends StatefulWidget {
  const WeatherInfoPage({Key? key}) : super(key: key);

  @override
  _WeatherInfoPageState createState() => _WeatherInfoPageState();
}

class _WeatherInfoPageState extends State<WeatherInfoPage> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedSport = 'MLB';
  List<dynamic> _teamData = [];
  Map<String, Weather> _weatherData = {};
  bool _isLoading = true;
  String? _error;
  final WeatherService _weatherService = WeatherService();

  final List<Map<String, dynamic>> _sportsOptions = [
    {
      'name': 'MLB',
      'icon': Icons.sports_baseball,
      'color': Colors.yellow,
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
      'available': false,
      'fileName': 'lib/nbaStadiumInfo.json',
    },
    {
      'name': 'NHL',
      'icon': Icons.sports_hockey,
      'color': Colors.teal,
      'available': false,
      'fileName': 'lib/nhlStadiumInfo.json',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadWeatherData();
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

  Future<void> _loadWeatherData() async {
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
          _teamData = [];
          _weatherData = {};
          _isLoading = false;
        });
        return;
      }
      
      final String fileName = selectedSport['fileName'] as String;
      if (fileName.isEmpty) {
        throw Exception('No data file specified for $_selectedSport');
      }
      
      // Load team/stadium data
      final String jsonString = await rootBundle.loadString(fileName);
      final List<dynamic> data = json.decode(jsonString);
      
      setState(() {
        _teamData = data;
      });

      // Extract locations and fetch weather data
      final locations = data.map((team) {
        final location = team['location'] as String;
        // Clean up location format for weather API
        return location.replaceAll(', ON, Canada', ', Canada')
                      .replaceAll(' County', '')
                      .trim();
      }).toList();

      if (_weatherService.isConfigured) {
        // Fetch weather data for all locations
        final weatherResults = await _weatherService.getWeatherForLocations(
          locations.cast<String>()
        );
        
        setState(() {
          _weatherData = weatherResults;
          _isLoading = false;
        });
      } else {
        // Use mock data when API is not configured
        final Map<String, Weather> mockWeatherData = {};
        for (final location in locations) {
          mockWeatherData[location] = _weatherService.getMockWeather(location);
        }
        
        setState(() {
          _weatherData = mockWeatherData;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load weather data: $e';
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
                        _loadWeatherData();
                      }
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${sport['name']} weather data coming soon!'),
                            backgroundColor: Colors.yellow.withOpacity(0.9),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              Colors.yellow.withOpacity(0.8),
                              Colors.yellow.withOpacity(0.6),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey[700]!.withOpacity(0.8),
                              Colors.grey[800]!.withOpacity(0.6),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.yellow.withOpacity(0.6)
                          : Colors.white.withOpacity(0.1),
                      width: 1.5,
                    ),
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

  Widget _buildWeatherCard(Map<String, dynamic> team, int index) {
    final location = team['location'] as String;
    final cleanLocation = location.replaceAll(', ON, Canada', ', Canada')
                                 .replaceAll(' County', '')
                                 .trim();
    final weather = _weatherData[cleanLocation];

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
                    onTap: () => _showWeatherDetails(team, weather),
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
                                      Colors.yellow.withOpacity(0.8),
                                      Colors.yellow.withOpacity(0.6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.wb_sunny,
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
                                      team['team'] ?? 'Unknown Team',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      location,
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (weather != null) ...[
                                Column(
                                  children: [
                                    Text(
                                      weather.getTemperatureString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      weather.conditionEmoji,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withOpacity(0.7),
                                size: 16,
                              ),
                            ],
                          ),
                          if (weather != null) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoChip(
                                    Icons.remove_red_eye,
                                    '${weather.visibility.toStringAsFixed(1)} km',
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildInfoChip(
                                    Icons.water_drop,
                                    '${weather.humidity.toStringAsFixed(0)}%',
                                    Colors.cyan,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoChip(
                                    Icons.air,
                                    weather.getWindSpeedString(),
                                    Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildInfoChip(
                                    Icons.wb_sunny_outlined,
                                    'UV ${weather.uvIndex.toStringAsFixed(0)}',
                                    Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
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

  void _showWeatherDetails(Map<String, dynamic> team, Weather? weather) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WeatherDetailsSheet(team: team, weather: weather),
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
                    Colors.yellow.withOpacity(0.8),
                    Colors.yellow.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.wb_sunny,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Weather Info',
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
                      child: CircularProgressIndicator(color: Colors.yellow),
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
                            onPressed: _loadWeatherData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_teamData.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No weather data available',
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
                      itemCount: _teamData.length,
                      itemBuilder: (context, index) {
                        return _buildWeatherCard(_teamData[index], index);
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

class WeatherDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> team;
  final Weather? weather;

  const WeatherDetailsSheet({Key? key, required this.team, this.weather}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                              Colors.yellow.withOpacity(0.8),
                              Colors.yellow.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.wb_sunny,
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
                              team['team'] ?? 'Unknown Team',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              team['location'] ?? 'Unknown Location',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (weather != null) ...[
                    // Current weather section
                    _buildCurrentWeatherSection(weather!),
                    const SizedBox(height: 20),
                    
                    // Weather details
                    _buildDetailSection(
                      'Temperature',
                      '${weather!.getTemperatureString()} (feels like ${weather!.feelsLike.round()}°C)',
                      Icons.thermostat,
                      Colors.red,
                    ),
                    _buildDetailSection(
                      'Humidity',
                      '${weather!.humidity.toStringAsFixed(0)}%',
                      Icons.water_drop,
                      Colors.cyan,
                    ),
                    _buildDetailSection(
                      'Wind',
                      '${weather!.getWindSpeedString()} ${weather!.windDirectionCompass}',
                      Icons.air,
                      Colors.green,
                    ),
                    _buildDetailSection(
                      'Visibility',
                      '${weather!.visibility.toStringAsFixed(1)} km',
                      Icons.remove_red_eye,
                      Colors.blue,
                    ),
                    _buildDetailSection(
                      'UV Index',
                      '${weather!.uvIndex.toStringAsFixed(0)} (${weather!.uvIndexRisk})',
                      Icons.wb_sunny_outlined,
                      Colors.orange,
                    ),
                    _buildDetailSection(
                      'Pressure',
                      '${weather!.pressure.toStringAsFixed(0)} hPa',
                      Icons.speed,
                      Colors.purple,
                    ),
                    if (weather!.precipitation != null)
                      _buildDetailSection(
                        'Precipitation',
                        '${weather!.precipitation!.toStringAsFixed(1)} mm/h',
                        Icons.grain,
                        Colors.indigo,
                      ),
                  ] else
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Weather data not available',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherSection(Weather weather) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather.getTemperatureString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  weather.description.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Updated: ${weather.dateTime.hour.toString().padLeft(2, '0')}:${weather.dateTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                weather.conditionEmoji,
                style: const TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.yellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  weather.mainCondition,
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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