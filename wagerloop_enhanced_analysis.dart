#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

class WagerLoopEnhancedAnalysis {
  final String _projectRoot;
  
  WagerLoopEnhancedAnalysis(this._projectRoot);
  
  Future<void> analyzeProject() async {
    print('🔍 WagerLoop Enhanced Code Analysis');
    print('=' * 50);
    
    final libDir = Directory(path.join(_projectRoot, 'lib'));
    if (!await libDir.exists()) {
      print('❌ lib directory not found');
      return;
    }
    
    final analysisResults = <String, Map<String, dynamic>>{};
    
    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final relativePath = path.relative(entity.path, from: _projectRoot);
        final analysis = await _analyzeFile(entity.path);
        analysisResults[relativePath] = analysis;
      }
    }
    
    await _generateReport(analysisResults);
  }
  
  Future<Map<String, dynamic>> _analyzeFile(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final lines = content.split('\n');
    
    return {
      'lineCount': lines.length,
      'complexity': _calculateComplexity(content),
      'issues': await _findIssues(content, filePath),
      'suggestions': await _generateSuggestions(content, filePath),
      'extractableWidgets': _findExtractableWidgets(content),
      'themeIssues': _findThemeIssues(content),
      'stateManagementIssues': _findStateManagementIssues(content),
    };
  }
  
  int _calculateComplexity(String content) {
    int complexity = 0;
    
    // Count nested structures
    final nestedPatterns = [
      RegExp(r'if\s*\('),
      RegExp(r'for\s*\('),
      RegExp(r'while\s*\('),
      RegExp(r'switch\s*\('),
      RegExp(r'setState\s*\('),
      RegExp(r'Future\s*\<'),
      RegExp(r'Stream\s*\<'),
    ];
    
    for (final pattern in nestedPatterns) {
      complexity += pattern.allMatches(content).length;
    }
    
    return complexity;
  }
  
  Future<List<String>> _findIssues(String content, String filePath) async {
    final issues = <String>[];
    final fileName = path.basename(filePath);
    
    // Check file size
    final lineCount = content.split('\n').length;
    if (lineCount > 500) {
      issues.add('File too large ($lineCount lines) - consider breaking into smaller components');
    }
    
    // Check for hardcoded colors
    final hardcodedColorPatterns = [
      RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)'),
      RegExp(r'Colors\.\w+(?!\s*\(context\))'),
    ];
    
    for (final pattern in hardcodedColorPatterns) {
      if (pattern.hasMatch(content)) {
        issues.add('Hardcoded colors found - use Theme.of(context) instead');
        break;
      }
    }
    
    // Check for missing const constructors
    final constPattern = RegExp(r'(\w+)\(\{[^}]*Key\?\s+key[^}]*\}\)\s*:\s*super\(key:\s*key\);');
    final matches = constPattern.allMatches(content);
    int missingConst = 0;
    
    for (final match in matches) {
      if (!match.group(0)!.contains('const ')) {
        missingConst++;
      }
    }
    
    if (missingConst > 0) {
      issues.add('$missingConst constructors missing const keyword');
    }
    
    // Check naming conventions
    if (fileName.endsWith('_page.dart')) {
      final classPattern = RegExp(r'class\s+(\w+)\s+extends\s+StatefulWidget');
      final match = classPattern.firstMatch(content);
      if (match != null) {
        final className = match.group(1)!;
        if (!className.endsWith('Page')) {
          issues.add('Page class should end with "Page": $className');
        }
      }
    }
    
    // Check for long build methods
    final buildMethodPattern = RegExp(
      r'Widget\s+build\(BuildContext\s+context\)\s*\{',
      multiLine: true
    );
    
    final buildMatches = buildMethodPattern.allMatches(content);
    for (final match in buildMatches) {
      final methodContent = _extractMethodContent(content, match.start);
      if (methodContent.split('\n').length > 50) {
        issues.add('Build method too long - consider extracting into _build*() methods');
      }
    }
    
    return issues;
  }
  
  Future<List<String>> _generateSuggestions(String content, String filePath) async {
    final suggestions = <String>[];
    final fileName = path.basename(filePath);
    
    // Suggest widget extraction for large files
    if (content.split('\n').length > 300) {
      suggestions.add('Extract large widgets into separate components in lib/widgets/');
    }
    
    // Suggest consistent spacing
    if (content.contains('Card(') && content.contains('Container(')) {
      suggestions.add('Ensure consistent spacing in card layouts (EdgeInsets.all(16))');
    }
    
    // Suggest state management improvements
    final setStateCount = RegExp(r'setState\s*\(').allMatches(content).length;
    if (setStateCount > 5) {
      suggestions.add('Consider extracting state management logic into separate methods');
    }
    
    // Suggest async/await improvements
    if (content.contains('async') && content.contains('await')) {
      if (!content.contains('try') || !content.contains('catch')) {
        suggestions.add('Add proper error handling to async methods');
      }
    }
    
    // Suggest consistent button styling
    if (content.contains('ElevatedButton') || content.contains('TextButton')) {
      suggestions.add('Ensure consistent button styles across betting and social features');
    }
    
    return suggestions;
  }
  
  List<String> _findExtractableWidgets(String content) {
    final extractableWidgets = <String>[];
    
    // Look for complex widget trees
    final complexWidgets = [
      RegExp(r'Card\s*\([^)]*child:\s*Column\s*\('),
      RegExp(r'Container\s*\([^)]*child:\s*Column\s*\('),
      RegExp(r'Padding\s*\([^)]*child:\s*Column\s*\('),
      RegExp(r'Column\s*\([^)]*children:\s*\[[\s\S]*?\]'),
    ];
    
    for (int i = 0; i < complexWidgets.length; i++) {
      final matches = complexWidgets[i].allMatches(content);
      if (matches.length > 3) {
        extractableWidgets.add('Complex widget pattern ${i + 1} found ${matches.length} times');
      }
    }
    
    // Look for betting-specific patterns
    if (content.contains('betting') || content.contains('pick') || content.contains('odds')) {
      extractableWidgets.add('Betting-related widgets should be extracted to separate components');
    }
    
    // Look for social feed patterns
    if (content.contains('post') || content.contains('comment') || content.contains('like')) {
      extractableWidgets.add('Social feed widgets should be extracted to separate components');
    }
    
    return extractableWidgets;
  }
  
  List<String> _findThemeIssues(String content) {
    final themeIssues = <String>[];
    
    // Check for hardcoded colors
    final hardcodedColors = [
      'Color(0xFF4CAF50)',
      'Color(0xFF616161)',
      'Colors.green',
      'Colors.grey[800]',
      'Colors.white',
      'Colors.black87',
    ];
    
    for (final color in hardcodedColors) {
      if (content.contains(color) && !content.contains('Theme.of(context)')) {
        themeIssues.add('Replace $color with theme reference');
      }
    }
    
    // Check for inconsistent button styles
    if (content.contains('ElevatedButton') && !content.contains('ElevatedButton.styleFrom')) {
      themeIssues.add('Use consistent button styling from theme');
    }
    
    return themeIssues;
  }
  
  List<String> _findStateManagementIssues(String content) {
    final stateIssues = <String>[];
    
    // Check for inconsistent setState patterns
    final setStatePatterns = [
      RegExp(r'setState\s*\(\s*\(\s*\)\s*\{'),
      RegExp(r'setState\s*\(\s*\(\s*\)\s*=>'),
    ];
    
    int totalSetState = 0;
    for (final pattern in setStatePatterns) {
      totalSetState += pattern.allMatches(content).length;
    }
    
    if (totalSetState > 5) {
      stateIssues.add('Too many setState calls ($totalSetState) - consider state management refactoring');
    }
    
    // Check for missing error handling
    if (content.contains('Supabase') && content.contains('await')) {
      if (!content.contains('try') || !content.contains('catch')) {
        stateIssues.add('Supabase calls should have proper error handling');
      }
    }
    
    return stateIssues;
  }
  
  String _extractMethodContent(String content, int start) {
    int braceCount = 0;
    int current = start;
    
    while (current < content.length) {
      if (content[current] == '{') braceCount++;
      if (content[current] == '}') braceCount--;
      if (braceCount == 0 && content[current] == '}') break;
      current++;
    }
    
    return content.substring(start, current + 1);
  }
  
  Future<void> _generateReport(Map<String, Map<String, dynamic>> analysisResults) async {
    print('\n📊 Analysis Report');
    print('=' * 50);
    
    // Sort files by complexity
    final sortedFiles = analysisResults.entries.toList()
      ..sort((a, b) => b.value['complexity'].compareTo(a.value['complexity']));
    
    print('\n🔥 Most Complex Files:');
    for (int i = 0; i < (sortedFiles.length > 5 ? 5 : sortedFiles.length); i++) {
      final entry = sortedFiles[i];
      final fileName = entry.key;
      final analysis = entry.value;
      
      print('  ${i + 1}. $fileName');
      print('     Lines: ${analysis['lineCount']}, Complexity: ${analysis['complexity']}');
      
      if (analysis['issues'].isNotEmpty) {
        print('     Issues:');
        for (final issue in analysis['issues']) {
          print('       - $issue');
        }
      }
      
      if (analysis['suggestions'].isNotEmpty) {
        print('     Suggestions:');
        for (final suggestion in analysis['suggestions']) {
          print('       > $suggestion');
        }
      }
      print('');
    }
    
    // Generate summary statistics
    final totalFiles = analysisResults.length;
    final totalLines = analysisResults.values.fold(0, (sum, analysis) => sum + analysis['lineCount'] as int);
    final totalComplexity = analysisResults.values.fold(0, (sum, analysis) => sum + analysis['complexity'] as int);
    final totalIssues = analysisResults.values.fold(0, (sum, analysis) => sum + (analysis['issues'] as List).length);
    
    print('\n📈 Summary Statistics:');
    print('  Total files analyzed: $totalFiles');
    print('  Total lines of code: $totalLines');
    print('  Average complexity: ${(totalComplexity / totalFiles).toStringAsFixed(2)}');
    print('  Total issues found: $totalIssues');
    
    // Generate specific recommendations
    print('\n🎯 WagerLoop-Specific Recommendations:');
    print('  1. Extract large betting widgets from social_feed_page.dart');
    print('  2. Create consistent card layouts for betting cards and post cards');
    print('  3. Implement theme-based color system throughout the app');
    print('  4. Add proper error handling for all Supabase calls');
    print('  5. Follow naming conventions: *Page for screens, *Widget for components');
    
    // Save report to file
    final reportFile = File(path.join(_projectRoot, 'wagerloop_analysis_report.md'));
    await _saveMarkdownReport(reportFile, analysisResults);
    
    print('\n💾 Full report saved to: wagerloop_analysis_report.md');
  }
  
  Future<void> _saveMarkdownReport(File reportFile, Map<String, Map<String, dynamic>> analysisResults) async {
    final buffer = StringBuffer();
    
    buffer.writeln('# WagerLoop Code Analysis Report');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    
    // Sort files by complexity
    final sortedFiles = analysisResults.entries.toList()
      ..sort((a, b) => b.value['complexity'].compareTo(a.value['complexity']));
    
    buffer.writeln('## File Analysis');
    buffer.writeln('');
    
    for (final entry in sortedFiles) {
      final fileName = entry.key;
      final analysis = entry.value;
      
      buffer.writeln('### $fileName');
      buffer.writeln('- **Lines:** ${analysis['lineCount']}');
      buffer.writeln('- **Complexity:** ${analysis['complexity']}');
      buffer.writeln('');
      
      if (analysis['issues'].isNotEmpty) {
        buffer.writeln('#### Issues');
        for (final issue in analysis['issues']) {
          buffer.writeln('- $issue');
        }
        buffer.writeln('');
      }
      
      if (analysis['suggestions'].isNotEmpty) {
        buffer.writeln('#### Suggestions');
        for (final suggestion in analysis['suggestions']) {
          buffer.writeln('- $suggestion');
        }
        buffer.writeln('');
      }
      
      if (analysis['extractableWidgets'].isNotEmpty) {
        buffer.writeln('#### Extractable Widgets');
        for (final widget in analysis['extractableWidgets']) {
          buffer.writeln('- $widget');
        }
        buffer.writeln('');
      }
    }
    
    buffer.writeln('## Summary');
    final totalFiles = analysisResults.length;
    final totalLines = analysisResults.values.fold(0, (sum, analysis) => sum + analysis['lineCount'] as int);
    final totalComplexity = analysisResults.values.fold(0, (sum, analysis) => sum + analysis['complexity'] as int);
    final totalIssues = analysisResults.values.fold(0, (sum, analysis) => sum + (analysis['issues'] as List).length);
    
    buffer.writeln('- **Total files:** $totalFiles');
    buffer.writeln('- **Total lines:** $totalLines');
    buffer.writeln('- **Average complexity:** ${(totalComplexity / totalFiles).toStringAsFixed(2)}');
    buffer.writeln('- **Total issues:** $totalIssues');
    
    await reportFile.writeAsString(buffer.toString());
  }
}

Future<void> main(List<String> args) async {
  final projectRoot = args.isNotEmpty ? args[0] : Directory.current.path;
  
  final analyzer = WagerLoopEnhancedAnalysis(projectRoot);
  await analyzer.analyzeProject();
}