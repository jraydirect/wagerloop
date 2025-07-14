# WagerLoop Dart Style Agent 🎯

A comprehensive Flutter code style enforcement tool specifically designed for WagerLoop's codebase. This agent automatically applies consistent styling patterns, suggests improvements, and helps maintain code quality across both betting and social features.

## 🚀 Quick Start

```bash
# 1. Run the setup script
./setup_wagerloop_style_agent.sh

# 2. Start the style agent (watches for file changes)
./dart_style_agent.dart

# 3. Or run a one-time analysis
dart wagerloop_enhanced_analysis.dart
```

## 📋 Features

### ✅ Auto-Fix Capabilities
- **Dart Format**: Applies `dart format` with 80-character line limit
- **Unused Imports**: Removes unused imports and variables
- **Const Constructors**: Adds `const` keyword to static widget constructors
- **Theme Colors**: Replaces hardcoded colors with theme references

### 🔍 Code Analysis
- **File Size Monitoring**: Alerts when files exceed 500 lines
- **Complexity Assessment**: Measures code complexity using control flow patterns
- **Widget Extraction**: Suggests extracting large widgets into components
- **Naming Validation**: Ensures consistent naming conventions

### 🎨 WagerLoop-Specific Patterns
- **Page Naming**: Enforces `*Page` suffix for screens
- **Widget Naming**: Enforces `*Widget` suffix for reusable components
- **Build Methods**: Suggests `_build*()` methods for complex UI sections
- **Card Layouts**: Maintains consistent spacing in betting/social cards

## 📊 Current Codebase Analysis

Based on the analysis of your Flutter codebase, here are the key findings:

### 🔥 Files That Need Attention

1. **`social_feed_page.dart`** (1,396 lines) - **TOO LARGE**
   - Extract: `PostCardWidget`, `CommentSectionWidget`, `PostCreationWidget`
   - Break down build methods into smaller `_build*()` methods

2. **`profile_page.dart`** (1,535 lines) - **TOO LARGE**
   - Extract: `ProfileHeaderWidget`, `ProfileStatsWidget`, `UserPostsWidget`
   - Separate team selection logic into dedicated component

3. **`create_pick_page.dart`** (992 lines) - **TOO LARGE**
   - Extract betting-specific widgets into `lib/widgets/betting/`
   - Separate form validation and API calls

### ✅ Well-Structured Files

- `profile_avatar.dart` (169 lines) - Good size
- `picks_display_widget.dart` (280 lines) - Good size
- `dice_loading_widget.dart` (139 lines) - Good size

## 🛠️ Configuration

The agent uses `wagerloop_style_config.json` for configuration:

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

## 🎯 Style Examples

### Before/After: Constructor Fixes

```dart
// ❌ Before
class SocialFeedPage extends StatefulWidget {
  SocialFeedPage({Key? key}) : super(key: key);
}

// ✅ After
class SocialFeedPage extends StatefulWidget {
  const SocialFeedPage({Key? key}) : super(key: key);
}
```

### Before/After: Theme Integration

```dart
// ❌ Before
Container(
  color: Colors.grey[800],
  child: Card(color: Colors.white),
)

// ✅ After
Container(
  color: Theme.of(context).scaffoldBackgroundColor,
  child: Card(color: Theme.of(context).cardColor),
)
```

### Before/After: Widget Extraction

```dart
// ❌ Before: Large build method
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        // ... 50+ lines of widget code
        Container(/* post creation */),
        ListView.builder(/* posts list */),
      ],
    ),
  );
}

// ✅ After: Extracted methods
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        _buildPostCreationSection(),
        _buildPostsList(),
      ],
    ),
  );
}
```

## 📈 Benefits

### Code Quality
- **Reduced Complexity**: Files broken into manageable components
- **Better Maintainability**: Consistent patterns and naming
- **Improved Performance**: Proper const constructors and optimizations
- **Enhanced Readability**: Clean, well-structured code

### Design Consistency
- **Unified Theming**: Consistent color scheme across app
- **Component Reusability**: Extractable widgets for common patterns
- **Spacing Standards**: Consistent padding and margins
- **Button Styling**: Uniform button appearance

### Developer Experience
- **Auto-fixes**: Immediate correction of common issues
- **Smart Suggestions**: Context-aware improvement recommendations
- **Real-time Feedback**: Style validation on every save
- **Comprehensive Reports**: Detailed analysis and metrics

## 🔧 Usage Examples

### Running the Style Agent
```bash
# Start watching for file changes
./dart_style_agent.dart

# Output:
🎯 WagerLoop Dart Style Agent initialized
📁 Watching: /project/lib
📏 Line limit: 80 characters
🔧 Auto-fixes enabled for safe changes

📝 File changed: social_feed_page.dart
  ✓ Applied dart format
  ✓ Fixed hardcoded colors
  > Consider extracting large widgets into separate components (1396 lines)
✅ Style check complete
```

### Running Analysis
```bash
# One-time analysis
dart wagerloop_enhanced_analysis.dart

# Output:
🔍 WagerLoop Enhanced Code Analysis
==================================================

🔥 Most Complex Files:
  1. lib/pages/profile_page.dart
     Lines: 1535, Complexity: 89
     Issues:
       - File too large (1535 lines) - consider breaking into smaller components
       - Build method too long - consider extracting into _build*() methods
```

## 📝 Generated Reports

The agent generates detailed markdown reports (`wagerloop_analysis_report.md`) with:

- File-by-file analysis
- Complexity metrics
- Issue identification
- Improvement suggestions
- Widget extraction recommendations

## 🎨 Recommended Widget Structure

```
lib/
├── widgets/
│   ├── social/
│   │   ├── post_card_widget.dart
│   │   ├── comment_section_widget.dart
│   │   ├── post_creation_widget.dart
│   │   └── user_avatar_widget.dart
│   ├── betting/
│   │   ├── pick_card_widget.dart
│   │   ├── odds_display_widget.dart
│   │   └── bet_button_widget.dart
│   └── common/
│       ├── loading_widget.dart
│       └── error_widget.dart
└── pages/
    ├── social_feed_page.dart (< 500 lines)
    ├── profile_page.dart (< 500 lines)
    └── picks/
        └── create_pick_page.dart (< 500 lines)
```

## 🚀 Getting Started

1. **Setup**: Run `./setup_wagerloop_style_agent.sh`
2. **Configure**: Adjust `wagerloop_style_config.json` if needed
3. **Run**: Start the agent with `./dart_style_agent.dart`
4. **Develop**: Save files and watch the magic happen!
5. **Review**: Check generated reports for improvement suggestions

## 🎯 Next Steps

1. **Extract Large Widgets**: Start with `social_feed_page.dart`
2. **Implement Theme System**: Replace remaining hardcoded colors
3. **Standardize Naming**: Apply consistent patterns across all files
4. **Add Error Handling**: Improve async/await patterns
5. **Create Component Library**: Build reusable widget components

The WagerLoop Dart Style Agent will help you maintain a clean, consistent, and scalable Flutter codebase as your betting and social features continue to grow! 🎉