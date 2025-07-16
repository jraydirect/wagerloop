/// Weather data model for OpenWeatherMap API responses.
/// 
/// Represents current weather conditions and forecast data for a specific location.
/// Used throughout the weather feature to display weather information for MLB team locations.
class Weather {
  final double temperature;
  final double feelsLike;
  final double humidity;
  final double pressure;
  final double windSpeed;
  final double windDirection;
  final double visibility;
  final double uvIndex;
  final int cloudiness;
  final String description;
  final String mainCondition;
  final String iconCode;
  final DateTime dateTime;
  final String location;
  final double? precipitation;

  Weather({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.windDirection,
    required this.visibility,
    required this.uvIndex,
    required this.cloudiness,
    required this.description,
    required this.mainCondition,
    required this.iconCode,
    required this.dateTime,
    required this.location,
    this.precipitation,
  });

  /// Creates a Weather object from OpenWeatherMap API JSON response
  factory Weather.fromJson(Map<String, dynamic> json, String locationName) {
    final main = json['main'] ?? {};
    final weather = (json['weather'] as List).isNotEmpty 
        ? json['weather'][0] 
        : {};
    final wind = json['wind'] ?? {};
    final rain = json['rain'];
    final snow = json['snow'];

    return Weather(
      temperature: (main['temp'] ?? 0).toDouble(),
      feelsLike: (main['feels_like'] ?? 0).toDouble(),
      humidity: (main['humidity'] ?? 0).toDouble(),
      pressure: (main['pressure'] ?? 0).toDouble(),
      windSpeed: (wind['speed'] ?? 0).toDouble(),
      windDirection: (wind['deg'] ?? 0).toDouble(),
      visibility: (json['visibility'] ?? 0).toDouble() / 1000, // Convert to km
      uvIndex: (json['uvi'] ?? 0).toDouble(),
      cloudiness: (json['clouds']?['all'] ?? 0).toInt(),
      description: weather['description'] ?? 'Unknown',
      mainCondition: weather['main'] ?? 'Unknown',
      iconCode: weather['icon'] ?? '01d',
      dateTime: DateTime.fromMillisecondsSinceEpoch((json['dt'] ?? 0) * 1000),
      location: locationName,
      precipitation: _getPrecipitation(rain, snow),
    );
  }

  /// Extracts precipitation data from rain or snow objects
  static double? _getPrecipitation(dynamic rain, dynamic snow) {
    if (rain != null && rain['1h'] != null) {
      return (rain['1h'] as num).toDouble();
    }
    if (snow != null && snow['1h'] != null) {
      return (snow['1h'] as num).toDouble();
    }
    return null;
  }

  /// Converts Weather object to JSON map
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'feels_like': feelsLike,
      'humidity': humidity,
      'pressure': pressure,
      'wind_speed': windSpeed,
      'wind_direction': windDirection,
      'visibility': visibility,
      'uv_index': uvIndex,
      'cloudiness': cloudiness,
      'description': description,
      'main_condition': mainCondition,
      'icon_code': iconCode,
      'date_time': dateTime.millisecondsSinceEpoch,
      'location': location,
      'precipitation': precipitation,
    };
  }

  /// Gets weather icon URL from OpenWeatherMap
  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';

  /// Returns wind direction as compass direction
  String get windDirectionCompass {
    if (windDirection >= 337.5 || windDirection < 22.5) return 'N';
    if (windDirection >= 22.5 && windDirection < 67.5) return 'NE';
    if (windDirection >= 67.5 && windDirection < 112.5) return 'E';
    if (windDirection >= 112.5 && windDirection < 157.5) return 'SE';
    if (windDirection >= 157.5 && windDirection < 202.5) return 'S';
    if (windDirection >= 202.5 && windDirection < 247.5) return 'SW';
    if (windDirection >= 247.5 && windDirection < 292.5) return 'W';
    if (windDirection >= 292.5 && windDirection < 337.5) return 'NW';
    return 'N';
  }

  /// Returns formatted temperature string with unit
  String getTemperatureString({bool isCelsius = true}) {
    final unit = isCelsius ? '°C' : '°F';
    final temp = isCelsius ? temperature : (temperature * 9/5) + 32;
    return '${temp.round()}$unit';
  }

  /// Returns formatted wind speed string
  String getWindSpeedString({bool isMetric = true}) {
    final unit = isMetric ? 'm/s' : 'mph';
    final speed = isMetric ? windSpeed : windSpeed * 2.237;
    return '${speed.toStringAsFixed(1)} $unit';
  }

  /// Returns UV index risk level
  String get uvIndexRisk {
    if (uvIndex <= 2) return 'Low';
    if (uvIndex <= 5) return 'Moderate';
    if (uvIndex <= 7) return 'High';
    if (uvIndex <= 10) return 'Very High';
    return 'Extreme';
  }

  /// Returns weather condition emoji
  String get conditionEmoji {
    switch (mainCondition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'drizzle':
        return '🌦️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌤️';
    }
  }
}

/// Weather forecast data model for multi-day forecasts
class WeatherForecast {
  final List<Weather> dailyForecast;
  final Weather currentWeather;
  final String location;
  final DateTime lastUpdated;

  WeatherForecast({
    required this.dailyForecast,
    required this.currentWeather,
    required this.location,
    required this.lastUpdated,
  });

  /// Creates WeatherForecast from OpenWeatherMap One Call API response
  factory WeatherForecast.fromJson(Map<String, dynamic> json, String locationName) {
    final current = Weather.fromJson(json['current'] ?? {}, locationName);
    
    final dailyData = json['daily'] as List? ?? [];
    final daily = dailyData.map((day) => Weather.fromJson(day, locationName)).toList();

    return WeatherForecast(
      currentWeather: current,
      dailyForecast: daily,
      location: locationName,
      lastUpdated: DateTime.now(),
    );
  }
} 