# 🎲 WagerLoop Splash Screens

I've created three different splash screen options for your app. Each has a unique style and animation approach:

## Splash Screen Options

### 1. **SplashScreen** (`splash_screen.dart`)
- **Style**: Modern with gradient background
- **Features**: 
  - Bouncing app icon with glow effect
  - Your dice loading animation
  - Smooth fade-in animations
  - App tagline: "Sports • Bets • Community"

### 2. **BouncySplashScreen** (`bouncy_splash_screen.dart`)
- **Style**: Figma-inspired bouncy loader
- **Features**:
  - 5 colored bouncing balls
  - Sequential bounce animation
  - Dark gradient background
  - Clean, minimalist design

### 3. **DiceBouncySplashScreen** (`dice_bouncy_splash_screen.dart`) ⭐ **Currently Active**
- **Style**: WagerLoop-themed with dice focus
- **Features**:
  - Rotating 3D-style dice with dots
  - Shimmer effect on app name
  - Bouncing dot loader
  - Radial gradient background
  - Tagline: "Roll the dice on sports"

## How to Switch Between Splash Screens

In `main.dart`, change this line:

```dart
'/splash': (context) => const DiceBouncySplashScreen(), // Current
```

To one of these:

```dart
'/splash': (context) => const SplashScreen(),           // Option 1
'/splash': (context) => const BouncySplashScreen(),     // Option 2  
'/splash': (context) => const DiceBouncySplashScreen(), // Option 3 (current)
```

## Customization Options

### Timing
- **Splash Duration**: Currently 4 seconds (change in each file's `_startAnimation()` method)
- **Animation Speed**: Modify the `Duration` in each `AnimationController`

### Colors & Branding
- **Background**: Change gradient colors in the `Container` decoration
- **App Icon**: Currently using `Icons.casino` - you can replace with your custom logo
- **Text**: Modify app name, tagline, and loading messages

### Navigation
All splash screens automatically navigate to the main app (`'/'` route) after completion.

## Technical Details

### Dependencies Used
- `flutter_animate`: For smooth, declarative animations
- Built-in Flutter animations: `AnimationController`, `Tween`, `CurvedAnimation`

### Performance
- All animations are optimized for 60fps
- Controllers are properly disposed to prevent memory leaks
- Uses hardware acceleration where possible

## Recommendation

I recommend **DiceBouncySplashScreen** as it:
- ✅ Matches your dice theme perfectly
- ✅ Has professional-looking animations
- ✅ Incorporates your brand colors (blue gradient)
- ✅ Sets the right mood for a sports betting app
- ✅ Has multiple animation layers for visual interest

## Making It Your Own

To match your Figma design exactly:
1. Replace the dice icon with your custom logo asset
2. Adjust colors to match your brand palette
3. Modify the tagline to match your messaging
4. Fine-tune animation timing to your preference

The splash screen will show for 4 seconds then automatically navigate to your authentication flow. Perfect for giving users a polished first impression! 🎲✨
