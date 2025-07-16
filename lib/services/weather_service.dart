import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather.dart';

/// Weather service for fetching weather data from OpenWeatherMap API.
/// 
/// Integrates with OpenWeatherMap API to fetch current weather conditions
/// and forecasts for MLB team locations. Handles caching, error handling,
/// and provides formatted weather data for the weather feature.
/// 
/// Uses singleton pattern to ensure consistent weather data across the app.
class WeatherService {
  // Singleton pattern
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  // OpenWeatherMap API base URL
  final String _baseUrl = 'api.openweathermap.org';
  
  // API key from environment variables
  String? get _apiKey => dotenv.env['OPENWEATHER_API_KEY'];

  // Cache for weather data to avoid frequent API calls
  final Map<String, Weather> _weatherCache = {};
  final Map<String, WeatherForecast> _forecastCache = {};
  DateTime? _lastFetchTime;
  final Duration _cacheValidity = const Duration(minutes: 10);

  /// Gets the API key for OpenWeatherMap API from environment variables.
  /// 
  /// The API key is automatically loaded from the .env file.
  /// Make sure OPENWEATHER_API_KEY is set in your .env file.
  String? getApiKey() {
    return _apiKey;
  }

  /// Fetches current weather data for a specific location.
  /// 
  /// Uses caching to minimize API calls and improve performance.
  /// 
  /// Parameters:
  ///   - location: Location name (e.g., "New York, NY" or "Boston, MA")
  /// 
  /// Returns:
  ///   Weather object containing current weather data
  /// 
  /// Throws:
  ///   - Exception: If API key is missing or API request fails
  Future<Weather> getCurrentWeather(String location) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('OpenWeatherMap API key not configured. Please set OPENWEATHER_API_KEY in your .env file.');
    }

    // Check cache first
    final cacheKey = location.toLowerCase();
    final now = DateTime.now();
    
    if (_weatherCache.containsKey(cacheKey) && 
        _lastFetchTime != null && 
        now.difference(_lastFetchTime!) < _cacheValidity) {
      return _weatherCache[cacheKey]!;
    }

    try {
      // First get coordinates from location name
      final coordinates = await _getCoordinates(location);
      
      // Fetch current weather using coordinates
      final queryParams = {
        'lat': coordinates['lat'].toString(),
        'lon': coordinates['lon'].toString(),
        'appid': _apiKey!,
        'units': 'metric', // Use Celsius
        'lang': 'en',
      };
      
      final uri = Uri.https(_baseUrl, '/data/2.5/weather', queryParams);
      
      if (kDebugMode) {
        print('Fetching weather for $location: $uri');
      }
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = Weather.fromJson(data, location);
        
        // Cache the response
        _weatherCache[cacheKey] = weather;
        _lastFetchTime = now;
        
        return weather;
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Weather API error: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching weather for $location: $e');
      }
      rethrow;
    }
  }

  /// Fetches 5-day weather forecast for a specific location.
  /// 
  /// Uses caching to minimize API calls and improve performance.
  /// 
  /// Parameters:
  ///   - location: Location name (e.g., "New York, NY" or "Boston, MA")
  /// 
  /// Returns:
  ///   WeatherForecast object containing current weather and 5-day forecast
  /// 
  /// Throws:
  ///   - Exception: If API key is missing or API request fails
  Future<WeatherForecast> getWeatherForecast(String location) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('OpenWeatherMap API key not configured. Please set OPENWEATHER_API_KEY in your .env file.');
    }

    // Check cache first
    final cacheKey = location.toLowerCase();
    final now = DateTime.now();
    
    if (_forecastCache.containsKey(cacheKey) && 
        _lastFetchTime != null && 
        now.difference(_lastFetchTime!) < _cacheValidity) {
      return _forecastCache[cacheKey]!;
    }

    try {
      // First get coordinates from location name
      final coordinates = await _getCoordinates(location);
      
      // Fetch forecast using One Call API
      final queryParams = {
        'lat': coordinates['lat'].toString(),
        'lon': coordinates['lon'].toString(),
        'appid': _apiKey!,
        'units': 'metric', // Use Celsius
        'lang': 'en',
        'exclude': 'minutely,hourly,alerts', // We only need current and daily
      };
      
      final uri = Uri.https(_baseUrl, '/data/3.0/onecall', queryParams);
      
      if (kDebugMode) {
        print('Fetching forecast for $location: $uri');
      }
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final forecast = WeatherForecast.fromJson(data, location);
        
        // Cache the response
        _forecastCache[cacheKey] = forecast;
        _lastFetchTime = now;
        
        return forecast;
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Weather API error: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching forecast for $location: $e');
      }
      rethrow;
    }
  }

  /// Gets coordinates (latitude, longitude) from location name using Geocoding API.
  /// 
  /// Parameters:
  ///   - location: Location name (e.g., "New York, NY")
  /// 
  /// Returns:
  ///   Map containing 'lat' and 'lon' keys with coordinate values
  /// 
  /// Throws:
  ///   - Exception: If location not found or API request fails
  Future<Map<String, double>> _getCoordinates(String location) async {
    // Format location for better geocoding accuracy
    String formattedLocation = _formatLocationForGeocoding(location);
    
    final queryParams = {
      'q': formattedLocation,
      'limit': '1',
      'appid': _apiKey!,
    };
    
    final uri = Uri.https(_baseUrl, '/geo/1.0/direct', queryParams);
    
    if (kDebugMode) {
      print('Making geocoding request for: $location');
      print('Formatted location: $formattedLocation');
      print('API Key available: ${_apiKey != null && _apiKey!.isNotEmpty}');
      print('Request URI: $uri');
    }
    
    final response = await http.get(uri);
    
    if (kDebugMode) {
      print('Geocoding response status: ${response.statusCode}');
      print('Geocoding response body: ${response.body}');
    }
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      
      if (data.isEmpty) {
        throw Exception('Location not found: $location');
      }
      
      final locationData = data.first;
      return {
        'lat': (locationData['lat'] as num).toDouble(),
        'lon': (locationData['lon'] as num).toDouble(),
      };
    } else {
      // Parse error response for better debugging
      String errorMessage = 'Failed to get coordinates for location: $location';
      try {
        final errorData = json.decode(response.body);
        errorMessage += ' - API Error: ${errorData['message'] ?? 'Unknown error'}';
      } catch (e) {
        errorMessage += ' - HTTP ${response.statusCode}: ${response.body}';
      }
      throw Exception(errorMessage);
    }
  }

  /// Fetches weather for multiple MLB team locations in batch.
  /// 
  /// Efficiently fetches weather data for multiple locations using
  /// concurrent requests with proper rate limiting.
  /// 
  /// Parameters:
  ///   - locations: List of location names
  /// 
  /// Returns:
  ///   Map of location names to Weather objects
  Future<Map<String, Weather>> getWeatherForLocations(List<String> locations) async {
    final Map<String, Weather> results = {};
    
    // Process locations in batches to avoid rate limiting
    const batchSize = 5;
    for (int i = 0; i < locations.length; i += batchSize) {
      final batch = locations.skip(i).take(batchSize).toList();
      
      final futures = batch.map((location) async {
        try {
          final weather = await getCurrentWeather(location);
          return MapEntry(location, weather);
        } catch (e) {
          if (kDebugMode) {
            print('Failed to fetch weather for $location: $e');
            print('Using mock weather data as fallback for $location');
          }
          // Return mock weather data as fallback instead of null
          final mockWeather = getMockWeather(location);
          return MapEntry(location, mockWeather);
        }
      });
      
      final batchResults = await Future.wait(futures);
      
      for (final result in batchResults) {
        // All results should now have data (either real or mock)
        results[result.key] = result.value;
      }
      
      // Add delay between batches to respect rate limits
      if (i + batchSize < locations.length) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    
    return results;
  }

  /// Formats location strings for better geocoding accuracy with OpenWeatherMap API.
  /// 
  /// Converts locations like "Phoenix, AZ" to "Phoenix,AZ,US" for better results.
  /// Handles special cases like "Washington, D.C." and international locations.
  String _formatLocationForGeocoding(String location) {
    // Remove extra whitespace
    String formatted = location.trim();
    
    // Handle special cases first
    if (formatted.contains('D.C.') || formatted.contains('DC')) {
      return 'Washington,DC,US';
    }
    
    // If already contains "Canada", keep as is
    if (formatted.toLowerCase().contains('canada')) {
      return formatted.replaceAll(', ON, Canada', ',Ontario,CA');
    }
    
    // Check if it's a US location (contains state code pattern like ", XX")
    final usStatePattern = RegExp(r',\s*([A-Z]{2})$');
    final match = usStatePattern.firstMatch(formatted);
    
    if (match != null) {
      // It's a US location, format as "City,State,US"
      final stateCode = match.group(1)!;
      final cityPart = formatted.substring(0, match.start);
      return '$cityPart,$stateCode,US';
    }
    
    // If no state code pattern found, return as is
    return formatted;
  }

  /// Clears the weather cache.
  /// 
  /// Useful for forcing fresh data retrieval or managing memory usage.
  void clearCache() {
    _weatherCache.clear();
    _forecastCache.clear();
    _lastFetchTime = null;
  }

  /// Checks if the API key is configured.
  /// 
  /// Returns true if the OpenWeatherMap API key is available.
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// Generates mock weather data for development/testing purposes.
  /// 
  /// Used when API key is not configured or for offline testing.
  /// Creates varied, realistic weather data based on location hash.
  Weather getMockWeather(String location) {
    // Use location hash for consistent but varied data per location
    final locationHash = location.hashCode.abs();
    final random = locationHash % 1000;
    
    // Generate realistic temperature ranges
    final baseTemp = 15.0 + (random % 25); // 15-40°C
    final tempVariation = (random % 6) - 3; // -3 to +3
    
    return Weather(
      temperature: baseTemp,
      feelsLike: baseTemp + tempVariation,
      humidity: 45.0 + (random % 40), // 45-85%
      pressure: 1005.0 + (random % 40), // 1005-1045 hPa
      windSpeed: (random % 12).toDouble(), // 0-12 m/s
      windDirection: (random % 360).toDouble(), // 0-360°
      visibility: 8.0 + (random % 5), // 8-13 km
      uvIndex: (random % 9).toDouble(), // 0-9
      cloudiness: random % 100, // 0-100%
      description: [
        'Clear sky', 'Partly cloudy', 'Cloudy', 'Light rain', 
        'Sunny', 'Overcast', 'Light breeze'
      ][random % 7],
      mainCondition: ['Clear', 'Clouds', 'Rain', 'Sunny'][random % 4],
      iconCode: ['01d', '02d', '03d', '10d', '04d'][random % 5],
      dateTime: DateTime.now(),
      location: location,
      precipitation: random % 3 == 0 ? (random % 3).toDouble() : null,
    );
  }


} 