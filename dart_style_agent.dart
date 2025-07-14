#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:path/path.dart' as path;

class WagerLoopStyleAgent {
  static const String _configFile = 'wagerloop_style_config.json';
  static const int _lineLengthLimit = 80;
  static const int _maxWidgetSize = 300; // lines
  static const int _maxPageSize = 500; // lines
  
  final FileSystemWatcher _watcher;
  final String _projectRoot;
  late Map<String, dynamic> _config;
  
  WagerLoopStyleAgent(this._projectRoot) : _watcher = FileSystemWatcher();
  
  Future<void> init() async {
    await _loadConfig();
    await _setupWatcher();
    print('🎯 WagerLoop Dart Style Agent initialized');
    print('📁 Watching: $_projectRoot/lib');
    print('📏 Line limit: $_lineLengthLimit characters');
    print('🔧 Auto-fixes enabled for safe changes');
  }
  
  Future<void> _loadConfig() async {
    final configFile = File(path.join(_projectRoot, _configFile));
    if (await configFile.exists()) {
      final content = await configFile.readAsString();
      _config = jsonDecode(content);
    } else {
      _config = _defaultConfig();
      await _saveConfig();
    }
  }
  
  Future<void> _saveConfig() async {
    final configFile = File(path.join(_projectRoot, _configFile));
    await configFile.writeAsString(jsonEncode(_config));
  }
  
  Map<String, dynamic> _defaultConfig() {
    return {
      'lastRun': DateTime.now().toIso8601String(),
      'autoFix': {
        'dartFormat': true,
        'removeUnusedImports': true,
        'addConstConstructors': true,
        'fixHardcodedColors': true,
      },
      'suggest': {
        'extractWidgets': true,
        'consistentNaming': true,
        'themeUsage': true,
        'stateManagement': true,
      },
      'wagerLoopPatterns': {
        'pageNamingSuffix': 'Page',
        'widgetNamingSuffix': 'Widget',
        'buildMethodPrefix': '_build',
        'primaryColor': 'Colors.green',
        'backgroundColor': 'Colors.grey[800]',
      }
    };
  }
  
  Future<void> _setupWatcher() async {
    final libDir = Directory(path.join(_projectRoot, 'lib'));
    if (!await libDir.exists()) {
      throw Exception('lib directory not found in $_projectRoot');
    }
    
    libDir.watch(recursive: true).listen((event) {
      if (event.type == FileSystemEvent.modify && 
          event.path.endsWith('.dart')) {
        _handleFileChange(event.path);
      }
    });
  }
  
  Future<void> _handleFileChange(String filePath) async {
    if (!await File(filePath).exists()) return;
    
    print('\n📝 File changed: ${path.basename(filePath)}');
    
    // Apply safe auto-fixes
    await _applyAutoFixes(filePath);
    
    // Analyze and suggest improvements
    await _analyzeAndSuggest(filePath);
    
    print('✅ Style check complete\n');
  }
  
  Future<void> _applyAutoFixes(String filePath) async {
    if (_config['autoFix']['dartFormat']) {
      await _runDartFormat(filePath);
    }
    
    if (_config['autoFix']['removeUnusedImports']) {
      await _removeUnusedImports(filePath);
    }
    
    if (_config['autoFix']['addConstConstructors']) {
      await _addConstConstructors(filePath);
    }
    
    if (_config['autoFix']['fixHardcodedColors']) {
      await _fixHardcodedColors(filePath);
    }
  }
  
  Future<void> _runDartFormat(String filePath) async {
    try {
      final result = await Process.run(
        'dart',
        ['format', '--line-length=$_lineLengthLimit', filePath],
        workingDirectory: _projectRoot,
      );
      
      if (result.exitCode == 0) {
        print('  ✓ Applied dart format');
      } else {
        print('  ⚠️  Dart format warning: ${result.stderr}');
      }
    } catch (e) {
      print('  ❌ Dart format error: $e');
    }
  }
  
  Future<void> _removeUnusedImports(String filePath) async {
    try {
      final result = await Process.run(
        'dart',
        ['fix', '--apply', filePath],
        workingDirectory: _projectRoot,
      );
      
      if (result.exitCode == 0) {
        print('  ✓ Removed unused imports');
      }
    } catch (e) {
      print('  ⚠️  Could not remove unused imports: $e');
    }
  }
  
  Future<void> _addConstConstructors(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    
    // Simple regex to find widget constructors that could be const
    final constructorPattern = RegExp(
      r'(\w+)\(\{[^}]*Key\?\s+key[^}]*\}\)\s*:\s*super\(key:\s*key\);',
      multiLine: true
    );
    
    String newContent = content.replaceAllMapped(constructorPattern, (match) {
      final constructor = match.group(0)!;
      if (!constructor.contains('const ')) {
        return 'const $constructor';
      }
      return constructor;
    });
    
    if (newContent != content) {
      await file.writeAsString(newContent);
      print('  ✓ Added const constructors');
    }
  }
  
  Future<void> _fixHardcodedColors(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    
    final colorReplacements = {
      'Color(0xFF4CAF50)': 'Theme.of(context).primaryColor',
      'Color(0xFF616161)': 'Theme.of(context).scaffoldBackgroundColor',
      'Colors.green': 'Theme.of(context).primaryColor',
      'Colors.grey[800]': 'Theme.of(context).scaffoldBackgroundColor',
    };
    
    String newContent = content;
    bool hasChanges = false;
    
    for (final entry in colorReplacements.entries) {
      if (newContent.contains(entry.key)) {
        newContent = newContent.replaceAll(entry.key, entry.value);
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      await file.writeAsString(newContent);
      print('  ✓ Fixed hardcoded colors');
    }
  }
  
  Future<void> _analyzeAndSuggest(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final lines = content.split('\n');
    
    // Check file size and suggest extraction
    if (lines.length > _maxPageSize) {
      print('  > Consider extracting large widgets into separate components (${lines.length} lines)');
    }
    
    // Check for build methods that could be extracted
    await _checkForExtractableBuildMethods(content, path.basename(filePath));
    
    // Check naming consistency
    await _checkNamingConsistency(content, path.basename(filePath));
    
    // Check theme usage
    await _checkThemeUsage(content);
    
    // Check state management patterns
    await _checkStateManagement(content);
  }
  
  Future<void> _checkForExtractableBuildMethods(String content, String fileName) async {
    // Look for large build methods
    final buildMethodPattern = RegExp(
      r'Widget\s+build\(BuildContext\s+context\)\s*\{',
      multiLine: true
    );
    
    final matches = buildMethodPattern.allMatches(content);
    for (final match in matches) {
      final methodStart = match.start;
      final methodContent = _extractMethodContent(content, methodStart);
      
      if (methodContent.split('\n').length > 50) {
        print('  > Consider extracting build method sections into _build*() methods');
      }
    }
    
    // Look for complex widget trees
    final complexWidgetPattern = RegExp(
      r'(Card|Container|Column|Row|Stack)\s*\([^)]*\)\s*\{',
      multiLine: true
    );
    
    final complexMatches = complexWidgetPattern.allMatches(content);
    if (complexMatches.length > 10) {
      print('  > Consider extracting complex widget trees into separate components');
    }
  }
  
  Future<void> _checkNamingConsistency(String content, String fileName) async {
    final patterns = _config['wagerLoopPatterns'];
    
    // Check page naming
    if (content.contains('class') && content.contains('StatefulWidget')) {
      if (fileName.endsWith('_page.dart')) {
        final classPattern = RegExp(r'class\s+(\w+)\s+extends\s+StatefulWidget');
        final match = classPattern.firstMatch(content);
        if (match != null) {
          final className = match.group(1)!;
          if (!className.endsWith(patterns['pageNamingSuffix'])) {
            print('  > Consider renaming $className to ${className}Page for consistency');
          }
        }
      }
    }
    
    // Check widget naming
    if (content.contains('class') && content.contains('StatelessWidget')) {
      if (!fileName.endsWith('_page.dart')) {
        final classPattern = RegExp(r'class\s+(\w+)\s+extends\s+StatelessWidget');
        final match = classPattern.firstMatch(content);
        if (match != null) {
          final className = match.group(1)!;
          if (!className.endsWith(patterns['widgetNamingSuffix']) && 
              !className.endsWith(patterns['pageNamingSuffix'])) {
            print('  > Consider renaming $className to ${className}Widget for consistency');
          }
        }
      }
    }
  }
  
  Future<void> _checkThemeUsage(String content) async {
    final hardcodedColors = [
      'Color(0xFF',
      'Colors.green',
      'Colors.grey[800]',
      'Colors.white',
      'Colors.black'
    ];
    
    for (final color in hardcodedColors) {
      if (content.contains(color) && !content.contains('Theme.of(context)')) {
        print('  > Consider using Theme.of(context) instead of hardcoded colors');
        break;
      }
    }
  }
  
  Future<void> _checkStateManagement(String content) async {
    // Check for consistent setState patterns
    final setStatePattern = RegExp(r'setState\s*\(\s*\(\s*\)\s*\{');
    final setStateCalls = setStatePattern.allMatches(content);
    
    if (setStateCalls.length > 5) {
      print('  > Consider extracting state management logic into separate methods');
    }
    
    // Check for async/await patterns
    if (content.contains('async') && content.contains('await')) {
      if (!content.contains('try') || !content.contains('catch')) {
        print('  > Consider adding proper error handling to async methods');
      }
    }
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
  
  Future<void> analyzeExistingFiles() async {
    print('\n🔍 Analyzing existing files...');
    
    final libDir = Directory(path.join(_projectRoot, 'lib'));
    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        await _analyzeAndSuggest(entity.path);
      }
    }
  }
  
  void startWatching() {
    print('\n👀 Watching for file changes... (Press Ctrl+C to stop)');
    
    // Keep the process running
    Timer.periodic(const Duration(seconds: 30), (timer) {
      print('🔄 Style agent running... (${DateTime.now().toIso8601String()})');
    });
  }
}

Future<void> main(List<String> args) async {
  final projectRoot = args.isNotEmpty ? args[0] : Directory.current.path;
  
  print('🚀 WagerLoop Dart Style Agent');
  print('📁 Project: $projectRoot');
  
  final agent = WagerLoopStyleAgent(projectRoot);
  await agent.init();
  
  // Analyze existing files once
  await agent.analyzeExistingFiles();
  
  // Start watching for changes
  agent.startWatching();
  
  // Keep the process running
  await Future.delayed(const Duration(days: 365));
}