# Custom Odds Display Implementation

This document describes the implementation of a custom odds display system that replaces TheOddsAPI widget with direct API integration.

## Overview

The custom implementation provides users with the ability to:
- View live odds data from TheOddsAPI
- Select odds directly from the interface 
- Add selected odds to a betting slip
- Create pick posts with single bets or parlays

## Components

### 1. TheOddsApiService (`lib/services/the_odds_api_service.dart`)
- Handles direct API communication with TheOddsAPI
- Fetches sports data and odds information
- Implements caching for better performance
- Parses odds data into display-friendly format

**Key Features:**
- Uses user's existing API key (wk_c58c553b857f62e6608a4413267e1376)
- Prioritizes FanDuel as the default bookmaker per user preference
- Supports multiple markets: Moneyline, Spreads, Over/Under
- Implements market name formatting to match user's widget setup

### 2. CustomOddsDisplayWidget (`lib/widgets/custom_odds_display_widget.dart`)
- Replaces the TheOddsAPI widget with a custom Flutter interface
- Displays odds in an organized, user-friendly format
- Provides sport and bookmaker selection controls
- Handles odds selection and communicates with parent components

**Features:**
- Sport selection (NFL, NBA, MLB, NHL, NCAAF, NCAAB, Soccer, UFC)
- Bookmaker selection with FanDuel as default
- Real-time odds display with proper formatting
- Tap-to-select functionality for adding odds to betting slip

### 3. Enhanced Pick Creation (`lib/pages/picks/create_pick_page.dart`)
- Updated to use the new custom odds display
- Maintains existing betting slip functionality
- Supports both single picks and parlays
- Preserves all existing post creation features

## API Configuration

The system uses the direct API key configuration:
- Primary key: `ODDS_API_KEY` 
- User's API key: `ddf55c4ad2fc9459639b2bc3e9c624ed`
- Default bookmaker: FanDuel
- Markets: "h2h:Moneyline,spreads:Spreads,totals:Over/Under"

## Data Flow

1. **Odds Fetching**: CustomOddsDisplayWidget requests odds from TheOddsApiService
2. **Data Processing**: Service fetches from API and parses into display format
3. **User Interaction**: User selects odds from the display interface
4. **Slip Management**: Selected odds are added to the betting slip
5. **Post Creation**: User can create posts with single picks or parlays

## Benefits

- **Direct Control**: No dependency on external widget iframes
- **Better UX**: Native Flutter interface with consistent styling
- **Improved Performance**: Cached data and optimized API calls
- **Enhanced Functionality**: More control over display and interaction
- **Responsive Design**: Works consistently across all platforms

## Market Formatting

The implementation respects the user's preferred market naming:
- `h2h` → "Moneyline"
- `spreads` → "Spreads" 
- `totals` → "Over/Under"

This matches the existing widget configuration for consistency.

## Error Handling

- Graceful fallback when API is unavailable
- Clear error messages for users
- Retry functionality for failed requests
- Loading states during data fetching

## Cache Strategy

- Sports data: Cached for 24 hours
- Odds data: Cached for 5 minutes (frequently updated)
- Manual refresh capability for users
- Automatic cache invalidation

## Future Enhancements

Potential improvements that can be added:
- Live odds updates via WebSocket
- More bookmaker options
- Advanced filtering options
- Odds comparison across bookmakers
- Historical odds tracking
