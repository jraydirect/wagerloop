# CORS Fix Implementation for ESPN API Calls

## Problem
The WagerLoop app was experiencing XMLHttpRequest errors when trying to fetch data from ESPN APIs in the web platform. This was due to CORS (Cross-Origin Resource Sharing) restrictions that prevent web browsers from making direct requests to external APIs.

## Solution
Implemented a CORS proxy solution that routes ESPN API calls through a proxy service when running on web platform, while maintaining direct API calls for mobile platforms.

## Changes Made

### 1. Sports API Service (`lib/services/sports_api_service.dart`)
- Added `kIsWeb` detection for web platform
- Modified `_fetchGamesFromESPN()` method to use CORS proxy for web
- Uses `https://api.allorigins.win/raw?url=` as the CORS proxy service

### 2. ESPN Odds Service (`lib/services/espn_odds_service.dart`)
- Updated all ESPN API calls to use CORS proxy for web platform
- Modified `_fetchOddsFromAllProviders()` method
- Updated site API, core API, and ESPN BET API calls

### 3. Scores Page (`lib/pages/scores_page.dart`)
- Added `flutter/foundation.dart` import for `kIsWeb`
- Updated `fetchSportScores()` method to use CORS proxy for web

### 4. Game Details Page (`lib/pages/game_details_page.dart`)
- Added `flutter/foundation.dart` import for `kIsWeb`
- Updated `_fetchESPNGameDetails()` method
- Updated `_fetchTeamRoster()` method

## CORS Proxy Service
Using `https://api.allorigins.win/raw?url=` as the CORS proxy service because:
- It's reliable and free
- No rate limiting issues
- Simple URL encoding format
- Supports JSON responses

## Platform Detection
The solution uses Flutter's `kIsWeb` constant to detect when the app is running on web platform:
```dart
if (kIsWeb) {
  // Use CORS proxy
  final targetUrl = 'https://site.api.espn.com/apis/site/v2/sports/$sportCode/scoreboard';
  uri = Uri.parse('https://api.allorigins.win/raw?url=${Uri.encodeComponent(targetUrl)}');
} else {
  // Direct API call for mobile
  uri = Uri.https(_baseUrl, '/apis/site/v2/sports/$sportCode/scoreboard');
}
```

## Benefits
- Eliminates XMLHttpRequest errors in web platform
- Maintains functionality on mobile platforms
- No changes to API response handling
- Transparent to the rest of the application

## Testing
To test the fix:
1. Run the app on web platform
2. Navigate to scores page or pick slip feature
3. Verify that ESPN API calls succeed without falling back to mock data
4. Check browser console for successful API responses

## Fallback
If the CORS proxy fails, the app will still fall back to mock data as before, ensuring the app remains functional even if the proxy service is unavailable. 