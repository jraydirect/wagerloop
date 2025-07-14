# WagerLoop Flutter Documentation Summary

This document summarizes the comprehensive documentation added to the WagerLoop Flutter codebase, focusing on betting functionality, social features, and user interactions.

## Documentation Standards Applied

All documentation follows Dart-style guidelines with WagerLoop-specific context:

```dart
/// Brief description focusing on WagerLoop functionality.
/// 
/// Parameters:
///   - paramName: Description with WagerLoop context
/// 
/// Returns:
///   Description of return value and its use in the app.
///
/// Throws:
///   - Exception: When this might occur in betting/social context
```

## Core Services Documented

### 1. AuthService (`lib/services/auth_service.dart`)
**Purpose**: Manages user authentication and session handling for WagerLoop.

**Key Methods Documented**:
- `updateFavoriteTeams()` - Updates user's favorite sports teams for personalized betting experience
- `debugAuthState()` - Debug method for troubleshooting authentication issues
- `signUp()` - Registers new users with email/password and creates profiles
- `signInWithGoogle()` - Handles Google OAuth for seamless authentication
- `getCurrentUserProfile()` - Retrieves user profile data with automatic profile creation
- `updateProfile()` - Updates user information including username, bio, and favorite teams
- `completeOnboarding()` - Marks user onboarding as complete
- `signOut()` - Handles sign-out for both web and mobile platforms
- `getFollowers()` - Retrieves follower lists for social features
- `getFollowing()` - Retrieves following lists for social features
- `isFollowing()` - Checks follow status between users
- `followUser()` - Enables following other users
- `unfollowUser()` - Enables unfollowing users

### 2. SportsOddsService (`lib/services/sports_odds_service.dart`)
**Purpose**: Manages sports betting odds data integration with The Odds API.

**Key Methods Documented**:
- `setApiKey()` - Configures API key for The Odds API
- `fetchOddsForGame()` - Retrieves real-time betting odds for specific games
- `fetchOddsForSport()` - Fetches odds for all games in a sport
- `getBestOddsForGame()` - Finds best available odds across sportsbooks
- `_getSportApiCode()` - Converts WagerLoop sport names to API codes

**Features**:
- Caching system to minimize API calls
- Support for moneyline, spread, and totals betting
- FanDuel sportsbook integration
- Odds format conversion (American/Decimal)

### 3. SocialFeedService (`lib/services/social_feed_service.dart`)
**Purpose**: Manages social media functionality including posts, likes, comments, and reposts.

**Key Methods Documented**:
- `fetchPosts()` - Retrieves social feed posts with user personalization
- `_mapPosts()` - Converts raw database data to typed Post/PickPost objects
- `fetchUserPosts()` - Gets posts for specific user profiles
- `createPost()` - Creates text posts in the social feed
- `createPickPost()` - Creates betting pick posts with embedded picks
- `addComment()` - Enables commenting on posts
- `fetchComments()` - Retrieves comments for posts
- `toggleLike()` - Handles like/unlike functionality
- `toggleRepost()` - Handles repost/unrepost functionality
- `deletePost()` - Removes posts and associated data

## Data Models Documented

### 1. Pick Class (`lib/models/pick_post.dart`)
**Purpose**: Represents individual betting picks with comprehensive data structure.

**Key Features**:
- Support for moneyline, spread, totals, and player props
- Odds tracking and stake amounts
- User reasoning for picks
- Display text generation for UI
- JSON serialization/deserialization

**Enums Documented**:
- `PickType` - Types of bets (moneyline, spread, total, playerProp)
- `PickSide` - Bet sides (home, away, over, under, draw)

### 2. PickPost Class (`lib/models/pick_post.dart`)
**Purpose**: Social media posts containing betting picks with interaction features.

**Key Features**:
- Extends regular posts with betting pick data
- Social interactions (likes, comments, reposts)
- Parlay bet detection
- Stake amount calculation
- Complete JSON serialization

**Key Methods Documented**:
- `hasPicks` - Checks if post contains betting picks
- `pickCount` - Returns number of picks in post
- `isParlay` - Determines if post is a parlay bet
- `totalStake` - Calculates total wagered amount
- `toJson()` - Converts to JSON for database storage
- `fromJson()` - Creates object from JSON data

## Utility Classes Documented

### 1. LoadingUtils (`lib/utils/loading_utils.dart`)
**Purpose**: Manages loading states throughout the WagerLoop app.

**Key Methods Documented**:
- `showLoading()` - Displays loading dialogs for operations
- `hideLoading()` - Dismisses loading dialogs
- `getButtonLoader()` - Provides consistent button loading indicators
- `getFullScreenLoader()` - Creates full-screen loading states
- `showLoadingSnackBar()` - Shows non-intrusive loading indicators

**Extensions**:
- `DiceLoadingUtils` - Dice-themed loading animations for betting operations

### 2. TeamLogoUtils (`lib/utils/team_logo_utils.dart`)
**Purpose**: Manages team logos and branding for consistent visual presentation.

**Key Methods Documented**:
- `getTeamLogo()` - Retrieves team logo asset paths
- `getSportLogo()` - Gets sport/league logos for navigation
- `getTeamColors()` - Provides team brand colors for UI theming

**Features**:
- Comprehensive team logo mapping for NFL, NBA, MLB, NHL
- Sport-specific league branding
- Team color schemes for consistent theming
- Support for user favorite teams display

## WagerLoop-Specific Features Documented

### Betting Functionality
- **Odds Integration**: Real-time odds fetching from The Odds API
- **Pick Creation**: Comprehensive betting pick data structure
- **Parlay Support**: Multi-pick betting with odds calculation
- **Sportsbook Integration**: FanDuel odds with best odds comparison

### Social Features
- **Post Types**: Both regular text posts and betting pick posts
- **Interactions**: Like, comment, repost functionality
- **User Following**: Social networking features for bettors
- **Profile Management**: User profiles with favorite teams

### User Experience
- **Loading States**: Consistent loading indicators across betting operations
- **Team Branding**: Visual consistency with team logos and colors
- **Authentication**: Secure user management with Google OAuth
- **Personalization**: Favorite teams and feed customization

## Documentation Benefits

1. **Developer Onboarding**: Clear understanding of WagerLoop's betting-specific functionality
2. **Code Maintenance**: Comprehensive parameter and return value documentation
3. **Error Handling**: Documented exceptions and error conditions
4. **Integration Guidance**: Clear API usage patterns and data flow
5. **Feature Understanding**: Context-aware documentation for betting and social features

## Next Steps

- Add documentation to remaining page components
- Document widget classes for UI components
- Add inline comments for complex betting calculations
- Document database schema relationships
- Add API endpoint documentation for external integrations

This documentation provides a solid foundation for maintaining and extending WagerLoop's Flutter codebase while ensuring new developers understand the betting-specific context and social features of the application.