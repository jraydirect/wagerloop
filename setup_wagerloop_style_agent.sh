#!/bin/bash

# WagerLoop Dart Style Agent Setup Script
# This script sets up the style agent for your Flutter project

echo "🚀 Setting up WagerLoop Dart Style Agent..."
echo "=" * 50

# Make scripts executable
chmod +x dart_style_agent.dart
chmod +x wagerloop_enhanced_analysis.dart

echo "✅ Made scripts executable"

# Check if dart is available
if ! command -v dart &> /dev/null; then
    echo "⚠️  Dart command not found. Please install Dart SDK first."
    echo "   Visit: https://dart.dev/get-dart"
    exit 1
fi

echo "✅ Dart SDK found"

# Check if this is a Flutter project
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ pubspec.yaml not found. Please run this script in a Flutter project root."
    exit 1
fi

if [ ! -d "lib" ]; then
    echo "❌ lib directory not found. Please run this script in a Flutter project root."
    exit 1
fi

echo "✅ Flutter project detected"

# Create configuration file
cat > wagerloop_style_config.json << 'EOF'
{
  "lastRun": "2024-01-01T00:00:00.000Z",
  "autoFix": {
    "dartFormat": true,
    "removeUnusedImports": true,
    "addConstConstructors": true,
    "fixHardcodedColors": true
  },
  "suggest": {
    "extractWidgets": true,
    "consistentNaming": true,
    "themeUsage": true,
    "stateManagement": true
  },
  "wagerLoopPatterns": {
    "pageNamingSuffix": "Page",
    "widgetNamingSuffix": "Widget",
    "buildMethodPrefix": "_build",
    "primaryColor": "Colors.green",
    "backgroundColor": "Colors.grey[800]"
  }
}
EOF

echo "✅ Created configuration file: wagerloop_style_config.json"

# Run initial analysis
echo ""
echo "🔍 Running initial code analysis..."
dart wagerloop_enhanced_analysis.dart

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Usage:"
echo "  1. Start the style agent: ./dart_style_agent.dart"
echo "  2. Run analysis: dart wagerloop_enhanced_analysis.dart"
echo "  3. View reports: cat wagerloop_analysis_report.md"
echo ""
echo "The agent will now:"
echo "  ✓ Apply dart format on file save"
echo "  ✓ Remove unused imports"
echo "  ✓ Add const constructors"
echo "  ✓ Fix hardcoded colors"
echo "  ✓ Suggest widget extractions"
echo "  ✓ Enforce naming conventions"
echo ""
echo "Happy coding! 🎯"