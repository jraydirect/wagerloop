# Baseball Widget Setup

This document explains how to set up the new baseball widget that replaces the ESPN API for MLB games on the scores page.

## Overview

The baseball widget uses the API-Sports Baseball API from RapidAPI to display live baseball games, standings, and detailed game information. The widget is embedded using a WebView and provides a rich, interactive experience.

## Setup Instructions

### 1. Get Your API Key

1. Go to [RapidAPI](https://rapidapi.com/api-sports/api/api-baseball/)
2. Subscribe to the API-Sports Baseball API
3. Copy your API key from the RapidAPI dashboard

### 2. Configure Environment Variables

1. Create or update the `assets/.env` file in your project
2. Add your baseball API key:

```env
# Baseball API Key for RapidAPI
BASEBALL_API_KEY=your_actual_api_key_here

# Other existing API keys...
GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE
OPENWEATHER_API_KEY=YOUR_OPENWEATHER_API_KEY_HERE
THE_ODDS_API_KEY=YOUR_THE_ODDS_API_KEY_HERE
ESPN_API_KEY=YOUR_ESPN_API_KEY_HERE
GOOGLE_VISION_API_KEY=YOUR_GOOGLE_VISION_API_KEY_HERE

# Supabase Configuration
SUPABASE_URL=YOUR_SUPABASE_URL_HERE
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY_HERE
```

### 3. Widget Features

The baseball widget includes the following features:

- **Live Games**: Real-time updates of ongoing baseball games
- **Game Details**: Click on games to see detailed statistics and information
- **Standings**: View current league standings
- **Team Logos**: Display team logos and player images
- **Toolbar**: Navigate between live, finished, and upcoming games
- **Date Selection**: Choose specific dates to view games
- **Auto-refresh**: Automatically updates data every 30 seconds

### 4. Widget Configuration

The widget is configured with the following settings:

- **Theme**: Dark theme to match your app's design
- **Refresh Rate**: 30 seconds
- **League**: MLB (league ID: 1)
- **Season**: Current year
- **Features**: All features enabled (toolbar, logos, modals, standings)

### 5. Files Modified

The following files were added or modified:

- `lib/widgets/baseball_games_widget.dart` - New widget implementation
- `lib/pages/scores_page.dart` - Updated to use baseball widget for MLB
- `pubspec.yaml` - Added webview_flutter dependency
- `assets/.env` - Added BASEBALL_API_KEY environment variable

### 6. Dependencies Added

- `webview_flutter: ^4.7.0` - For embedding the web-based widget

### 7. Security Notes

- The API key will be visible in the widget HTML
- Consider setting up domain restrictions in your RapidAPI dashboard
- The widget uses the RapidAPI host: `api-baseball.p.rapidapi.com`

### 8. Troubleshooting

**Widget not loading:**
- Check that your API key is correctly set in the .env file
- Verify your RapidAPI subscription is active
- Check the console for any error messages

**API key error:**
- Ensure the BASEBALL_API_KEY is set in assets/.env
- Restart the app after adding the API key
- Check that the .env file is included in pubspec.yaml assets

**Widget styling issues:**
- The widget uses a dark theme by default
- You can modify the theme in the `_buildBaseballWidget()` method
- Available themes: '', 'grey', 'dark'

### 9. API Usage

The widget will consume API requests from your RapidAPI quota. Monitor your usage in the RapidAPI dashboard to ensure you don't exceed your plan limits.

### 10. Customization

You can customize the widget by modifying the parameters in the `BaseballGamesWidget` constructor in `lib/pages/scores_page.dart`:

```dart
BaseballGamesWidget(
  apiKey: apiKey,
  date: '', // Specific date (YYYY-MM-DD) or empty for current
  league: 1, // League ID (1 for MLB)
  season: DateTime.now().year, // Season year
  theme: 'dark', // Theme: '', 'grey', 'dark'
  refresh: 30, // Refresh rate in seconds
  showToolbar: true, // Show navigation toolbar
  showLogos: true, // Show team logos
  modalGame: true, // Enable game detail modals
  modalStandings: true, // Enable standings modals
  modalShowLogos: true, // Show logos in modals
  showErrors: false, // Show error messages for debugging
)
```

## Support

If you encounter any issues with the baseball widget, check the following:

1. API key configuration
2. Network connectivity
3. RapidAPI subscription status
4. Console error messages
5. Widget HTML generation

The widget provides built-in error handling and will display helpful error messages when issues occur. 