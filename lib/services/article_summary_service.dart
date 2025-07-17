import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html;

class ArticleSummaryService {
  static ArticleSummaryService? _instance;
  GenerativeModel? _model;
  
  ArticleSummaryService._();
  
  static ArticleSummaryService get instance {
    _instance ??= ArticleSummaryService._();
    return _instance!;
  }
  
  bool get isInitialized => _model != null;
  
  void initialize() {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'YOUR_GEMINI_API_KEY_HERE';
      
      if (apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        throw Exception('Gemini API key not configured. Please set GEMINI_API_KEY in your .env file.');
      }
      
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(_getSystemPrompt()),
      );
    } catch (e) {
      print('Error initializing ArticleSummaryService: $e');
      rethrow;
    }
  }
  
  String _getSystemPrompt() {
    return '''
You are an expert sports journalism assistant specializing in creating comprehensive, insightful article summaries for WagerLoop, a premium sports betting community app.

Your role is to:
1. Analyze sports articles and create detailed, engaging summaries
2. Extract key information, insights, and implications
3. Highlight betting-relevant details and market impacts
4. Maintain a professional yet accessible tone
5. Focus on actionable insights for sports bettors

Guidelines:
- Create summaries that are 2-3 paragraphs long
- Include key facts, quotes, and statistics
- Explain the broader context and implications
- Highlight any betting or fantasy sports relevance
- Use clear, engaging language suitable for sports fans
- Maintain accuracy and avoid speculation beyond what's stated in the article

Format your response as a clean, well-structured summary without markdown formatting.
''';
  }
  
  Future<String> summarizeArticle(String articleUrl, String fallbackTitle, String fallbackDescription) async {
    if (!isInitialized) {
      throw Exception('ArticleSummaryService not initialized');
    }
    
    try {
      // First, try to fetch and parse the full article
      String articleContent = await _fetchArticleContent(articleUrl);
      
      if (articleContent.isEmpty) {
        // Fallback to using the RSS description if we can't get full content
        articleContent = '$fallbackTitle\n\n$fallbackDescription';
      }
      
      // Generate AI summary
      final prompt = '''
Please provide an in-depth summary of this sports article:

Title: $fallbackTitle

Content:
$articleContent

Create a comprehensive summary that captures the key points, context, and implications for sports fans and bettors.
''';
      
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? _generateFallbackSummary(fallbackTitle, fallbackDescription);
      
    } catch (e) {
      print('Error generating article summary: $e');
      // Return a fallback summary if AI fails
      return _generateFallbackSummary(fallbackTitle, fallbackDescription);
    }
  }
  
  Future<String> _fetchArticleContent(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
          'Accept-Encoding': 'gzip, deflate',
          'Connection': 'keep-alive',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return _extractArticleText(response.body);
      } else {
        print('Failed to fetch article: HTTP ${response.statusCode}');
        return '';
      }
    } catch (e) {
      print('Error fetching article content: $e');
      return '';
    }
  }
  
  String _extractArticleText(String htmlContent) {
    try {
      final document = html_parser.parse(htmlContent);
      
      // Try multiple selectors to find article content
      List<String> contentSelectors = [
        'article',
        '.article-content',
        '.content',
        '.post-content',
        '.entry-content',
        '.article-body',
        '.story-body',
        '.article-text',
        '[data-module="ArticleBody"]',
        '.ArticleBody',
        'main',
        '.main-content'
      ];
      
      String extractedText = '';
      
      for (String selector in contentSelectors) {
        final elements = document.querySelectorAll(selector);
        if (elements.isNotEmpty) {
          extractedText = elements.first.text;
          if (extractedText.length > 200) {
            break; // Found substantial content
          }
        }
      }
      
      // If no content found with selectors, try to extract from paragraphs
      if (extractedText.length < 200) {
        final paragraphs = document.querySelectorAll('p');
        final textParts = <String>[];
        
        for (html.Element p in paragraphs) {
          final text = p.text.trim();
          if (text.length > 50) { // Only include substantial paragraphs
            textParts.add(text);
          }
        }
        
        extractedText = textParts.join('\n\n');
      }
      
      // Clean up the text
      extractedText = extractedText
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'\n\s*\n'), '\n\n')
          .trim();
      
      // Limit content length to avoid token limits
      if (extractedText.length > 8000) {
        extractedText = extractedText.substring(0, 8000) + '...';
      }
      
      return extractedText;
    } catch (e) {
      print('Error extracting article text: $e');
      return '';
    }
  }
  
  String _generateFallbackSummary(String title, String description) {
    return '''
This article covers: $title

$description

For the complete story with additional details, quotes, and analysis, please read the full article using the button below. Our AI-powered summaries are temporarily unavailable, but we're working to restore this feature.
''';
  }
} 