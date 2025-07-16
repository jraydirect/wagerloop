# Weather Feature Setup Guide

## Overview

The weather feature in WagerLoop provides real-time weather information for MLB team locations. Users can click the Weather tool in the Discover page to view current weather conditions and forecasts for all MLB team stadiums.

## Features

- **Current Weather Data**: Temperature, humidity, wind speed, visibility, UV index, and more
- **Weather Forecasts**: Multi-day weather forecasts for each location
- **MLB Team Integration**: Weather data for all 30 MLB team stadium locations
- **Intuitive UI**: Same layout pattern as Coaches and Stadium Info pages
- **Offline Fallback**: Mock weather data when API is not configured
- **Caching**: Smart caching to minimize API calls and improve performance

## Setup Instructions

### 1. Get OpenWeatherMap API Key

1. Visit [OpenWeatherMap](https://openweathermap.org/api)
2. Sign up for a free account
3. Navigate to your API keys section
4. Copy your API key

**Free Tier Limits:**
- 1,000 API calls per day
- Current weather data
- 5-day/3-hour forecast
- Basic weather maps

### 2. Configure Environment Variables

Create or update the `assets/.env` file in your project with the following content:

```env
# OpenWeatherMap API Configuration
OPENWEATHER_API_KEY=your_openweathermap_api_key_here

# Replace 'your_openweathermap_api_key_here' with your actual API key
```

**Important Notes:**
- Never commit your `.env` file to version control
- Make sure `assets/.env` is included in your `.gitignore` file
- The API key should be kept secure and not shared publicly

### 3. Verify Setup

1. Run the app
2. Navigate to Discover page
3. Tap on the Weather tool
4. You should see MLB team weather data loading

If the API key is not configured, the app will fall back to mock weather data for development purposes.

## File Structure

The weather feature consists of the following files:

```
lib/
├── models/
│   └── weather.dart                 # Weather data models
├── services/
│   └── weather_service.dart         # OpenWeatherMap API integration
├── pages/
│   ├── discover_page.dart           # Updated with weather navigation
│   └── weather_info_page.dart       # Main weather interface
└── ...
```

## API Integration Details

### OpenWeatherMap APIs Used

1. **Current Weather API** (`/data/2.5/weather`)
   - Real-time weather conditions
   - Temperature, humidity, pressure, wind, etc.

2. **Geocoding API** (`/geo/1.0/direct`)
   - Converts city names to coordinates
   - Required for weather data requests

3. **One Call API 3.0** (`/data/3.0/onecall`) - Optional
   - Extended forecasts
   - Historical data
   - Weather alerts

### Data Processing

- **Location Mapping**: MLB ballpark locations are extracted from `lib/mlbBallparkInfo.json`
- **Coordinate Resolution**: City names are converted to lat/lon coordinates via Geocoding API
- **Batch Processing**: Multiple locations are processed efficiently with rate limiting
- **Caching**: Weather data is cached for 10 minutes to reduce API calls
- **Error Handling**: Graceful fallback to mock data when API calls fail

## Usage Guide

### For Users

1. **Access Weather Data**:
   - Open the app
   - Navigate to the Discover page
   - Tap the Weather tool (sun icon)

2. **View Team Weather**:
   - Browse through MLB teams
   - Each card shows current temperature and conditions
   - Tap any team card for detailed weather information

3. **Detailed Weather View**:
   - Current temperature and "feels like" temperature
   - Weather description and conditions
   - Wind speed and direction
   - Humidity and visibility
   - UV index and pressure
   - Precipitation data (when available)

### For Developers

#### Adding New Sports

To extend weather support to other sports (NFL, NBA, NHL):

1. Update the sports options in `weather_info_page.dart`:
   ```dart
   {
     'name': 'NFL',
     'icon': Icons.sports_football,
     'color': Colors.purple,
     'available': true,  // Change to true
     'fileName': 'lib/nflStadiumInfo.json',
   },
   ```

2. Ensure the stadium/venue JSON files contain location data

#### Customizing Weather Display

The weather UI can be customized by modifying:
- `_buildWeatherCard()` - Individual team weather cards
- `_buildCurrentWeatherSection()` - Detailed weather display
- `_buildDetailSection()` - Weather data sections

#### API Rate Limiting

The service includes built-in rate limiting:
- Batch processing (5 locations at a time)
- 200ms delay between batches
- 10-minute caching
- Mock data fallback

## Troubleshooting

### Common Issues

1. **No Weather Data Displayed**
   - Check if `OPENWEATHER_API_KEY` is set in `assets/.env`
   - Verify the API key is valid
   - Check network connectivity

2. **API Rate Limit Exceeded**
   - Free tier limited to 1,000 calls/day
   - App uses caching to minimize calls
   - Consider upgrading to paid tier for higher limits

3. **Location Not Found Errors**
   - Some team locations may need manual adjustment
   - Check the location format in JSON files
   - Verify geocoding API responses

### Debug Mode

When running in debug mode, the weather service logs detailed information:
- API request URLs
- Response status codes
- Error messages
- Cache hit/miss information

## Future Enhancements

Potential improvements for the weather feature:

1. **Extended Forecasts**: 5-7 day weather forecasts
2. **Weather Alerts**: Severe weather notifications
3. **Historical Data**: Past weather conditions
4. **Weather Maps**: Visual weather overlays
5. **Push Notifications**: Weather-based alerts for games
6. **Advanced Filtering**: Filter teams by weather conditions
7. **Weather Widgets**: Home screen weather widgets

## API Documentation

For detailed API documentation, visit:
- [OpenWeatherMap API Docs](https://openweathermap.org/api)
- [Current Weather API](https://openweathermap.org/current)
- [Geocoding API](https://openweathermap.org/api/geocoding-api)
- [One Call API 3.0](https://openweathermap.org/api/one-call-3)

## Support

For issues with the weather feature:
1. Check this documentation first
2. Verify API key configuration
3. Review debug logs
4. Check OpenWeatherMap service status
5. Contact support with specific error messages

---

**Note**: This feature is designed to work seamlessly with the existing WagerLoop architecture and follows the same patterns as other information pages in the app. 