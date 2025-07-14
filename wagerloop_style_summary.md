# WagerLoop Dart Style Agent

## Overview
The WagerLoop Dart Style Agent is a comprehensive code quality and style enforcement tool designed specifically for WagerLoop's Flutter codebase. It monitors file changes and applies consistent styling patterns while suggesting improvements for better code maintainability.

## Features

### 🔧 Auto-Fix Capabilities
- **Dart Format**: Applies `dart format` with 80-character line limit
- **Unused Import Removal**: Automatically removes unused imports and variables
- **Const Constructor Addition**: Adds `const` keyword to static widget constructors
- **Hardcoded Color Replacement**: Replaces hardcoded colors with theme references

### 📊 Code Analysis
- **File Complexity Assessment**: Measures code complexity using control flow patterns
- **Widget Extraction Suggestions**: Identifies large widgets that should be extracted
- **Naming Convention Validation**: Ensures consistent naming patterns
- **Theme Usage Verification**: Checks for proper theme usage throughout the app

### 🎯 WagerLoop-Specific Patterns
- **Page Naming**: Enforces `*Page` suffix for screen components
- **Widget Naming**: Enforces `*Widget` suffix for reusable components
- **Build Method Organization**: Suggests `_build*()` methods for complex UI sections
- **Consistent Spacing**: Maintains consistent spacing in card layouts

## Current Codebase Analysis

### 📁 File Structure Analysis
```
lib/
├── pages/
│   ├── social_feed_page.dart (1396 lines) ⚠️ TOO LARGE
│   ├── profile_page.dart (1535 lines) ⚠️ TOO LARGE
│   ├── scores_page.dart (408 lines) ✅ GOOD SIZE
│   ├── news_page.dart (587 lines) ⚠️ LARGE
│   ├── discover_page.dart (363 lines) ✅ GOOD SIZE
│   ├── user_profile_page.dart (843 lines) ⚠️ LARGE
│   └── picks/
│       └── create_pick_page.dart (992 lines) ⚠️ TOO LARGE
├── widgets/
│   ├── profile_avatar.dart (169 lines) ✅ GOOD SIZE
│   ├── picks_display_widget.dart (280 lines) ✅ GOOD SIZE
│   └── dice_loading_widget.dart (139 lines) ✅ GOOD SIZE
└── services/ (good separation)
```

### 🚨 Critical Issues Identified

#### 1. **Large File Sizes**
- `social_feed_page.dart`: 1396 lines (Target: <500 lines)
- `profile_page.dart`: 1535 lines (Target: <500 lines)
- `create_pick_page.dart`: 992 lines (Target: <500 lines)

#### 2. **Missing Widget Extraction**
- Social feed components should be extracted into separate widgets
- Betting/pick widgets should be modularized
- Large build methods need to be broken down

#### 3. **Theme Inconsistencies**
- Hardcoded colors found in main.dart and other files
- Need consistent theme usage throughout the app

### 🎯 Specific Recommendations

#### For `social_feed_page.dart`:
```dart
// Current: Large monolithic file
// Recommended: Extract into separate components

// Extract these widgets:
- PostCardWidget
- CommentSectionWidget  
- LikeButtonWidget
- RepostButtonWidget
- UserAvatarWidget
- PostCreationWidget
```

#### For `profile_page.dart`:
```dart
// Extract these widgets:
- ProfileHeaderWidget
- ProfileStatsWidget
- UserPostsWidget
- EditProfileWidget
- TeamSelectionWidget
```

#### For Theme Consistency:
```dart
// Current hardcoded colors in main.dart:
Colors.grey[800] // Replace with theme
Colors.green    // Replace with theme

// Recommended:
Theme.of(context).scaffoldBackgroundColor
Theme.of(context).primaryColor
```

### 🔄 Auto-Fix Examples

#### Before:
```dart
class SocialFeedPage extends StatefulWidget {
  SocialFeedPage({Key? key}) : super(key: key);
}

Container(
  color: Colors.grey[800],
  child: Column(
    children: [
      // ... 50+ lines of widgets
    ],
  ),
)
```

#### After (Auto-fixed):
```dart
class SocialFeedPage extends StatefulWidget {
  const SocialFeedPage({Key? key}) : super(key: key);
}

Container(
  color: Theme.of(context).scaffoldBackgroundColor,
  child: Column(
    children: [
      _buildPostsList(),
    ],
  ),
)

Widget _buildPostsList() {
  // Extracted widget code
}
```

## Implementation Guide

### 1. **Install the Style Agent**
```bash
# Make the script executable
chmod +x dart_style_agent.dart

# Run the agent
./dart_style_agent.dart /path/to/wagerloop/project
```

### 2. **Configuration**
The agent creates a `wagerloop_style_config.json` file:
```json
{
  "autoFix": {
    "dartFormat": true,
    "removeUnusedImports": true,
    "addConstConstructors": true,
    "fixHardcodedColors": true
  },
  "wagerLoopPatterns": {
    "pageNamingSuffix": "Page",
    "widgetNamingSuffix": "Widget",
    "buildMethodPrefix": "_build",
    "primaryColor": "Colors.green",
    "backgroundColor": "Colors.grey[800]"
  }
}
```

### 3. **Usage Workflow**
1. **File Save**: Agent automatically applies safe fixes
2. **Analysis**: Provides suggestions for complex refactors
3. **Report**: Generates detailed analysis reports
4. **Monitoring**: Continuously watches for file changes

## Benefits

### 📈 Code Quality Improvements
- **Reduced Complexity**: Breaking large files into smaller components
- **Better Maintainability**: Consistent patterns and naming
- **Improved Performance**: Proper const constructors and optimizations
- **Enhanced Readability**: Consistent formatting and structure

### 🎨 Design Consistency
- **Theme Integration**: Proper use of app themes
- **Color Consistency**: Unified color scheme throughout
- **Component Reusability**: Extracted widgets for common patterns
- **Spacing Standards**: Consistent padding and margins

### 🚀 Developer Experience
- **Auto-fixes**: Immediate correction of common issues
- **Smart Suggestions**: Context-aware improvement recommendations
- **Real-time Feedback**: Instant style validation on save
- **Comprehensive Reports**: Detailed analysis and metrics

## Getting Started

1. **Setup**: Place the style agent scripts in your project root
2. **Configure**: Customize the config file for your specific needs
3. **Run**: Execute the agent to start monitoring your codebase
4. **Review**: Check the generated analysis reports
5. **Iterate**: Apply suggested improvements gradually

## Next Steps

1. **Extract Large Widgets**: Start with social_feed_page.dart
2. **Implement Theme System**: Replace hardcoded colors
3. **Standardize Naming**: Apply consistent naming patterns
4. **Add Error Handling**: Improve async/await patterns
5. **Create Component Library**: Build reusable widget components

The WagerLoop Dart Style Agent will help maintain code quality and consistency as your Flutter application grows, ensuring a maintainable and scalable codebase for both betting and social features.