import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WagerGPTService {
  static WagerGPTService? _instance;
  GenerativeModel? _model;
  ChatSession? _chat;
  
  WagerGPTService._();
  
  static WagerGPTService get instance {
    _instance ??= WagerGPTService._();
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
      
      _chat = _model!.startChat();
    } catch (e) {
      print('Error initializing WagerGPT: $e');
      rethrow;
    }
  }
  
  Future<String> sendMessage(String message) async {
    if (!isInitialized) {
      throw Exception('WagerGPT service not initialized');
    }
    
    try {
      final response = await _chat!.sendMessage(Content.text(message));
      return response.text ?? 'Sorry, I couldn\'t generate a response.';
    } catch (e) {
      throw Exception('Failed to get response from WagerGPT: $e');
    }
  }
  
  void resetChat() {
    if (isInitialized) {
      _chat = _model!.startChat();
    }
  }
  
  void clearChatHistory() {
    resetChat();
  }
  
  String _getSystemPrompt() {
    return '''
You are WagerGPT, an AI assistant specialized in sports betting insights and analysis. 
You provide data-driven betting advice, game analysis, and statistical insights.

Key characteristics:
- Expert in sports analytics and betting strategies
- Provide odds analysis and value bet identification
- Explain complex betting concepts in simple terms
- Always remind users to bet responsibly
- Focus on data-driven insights rather than gambling promotion
- Help with bankroll management and betting psychology
- Analyze team performance, player stats, and game trends
- Support all major sports: NFL, NBA, MLB, NHL, Soccer, etc.

Response guidelines:
- Keep responses informative but concise (under 500 words typically)
- Use emojis sparingly but effectively for readability
- Include specific actionable advice when possible
- Always include a responsible gambling reminder when appropriate
- Structure longer responses with clear sections using bullet points or headers
- Acknowledge uncertainty when data is limited
- Suggest where users can find additional information

Responsible gambling principles:
- Never guarantee wins or "sure bets"
- Emphasize bankroll management (1-3% per bet maximum)
- Remind users that all betting involves risk
- Encourage setting limits and sticking to them
- Promote betting for entertainment, not as income
- Provide resources for problem gambling help when appropriate

If asked about specific games, provide analysis based on:
- Team/player statistics and trends
- Historical matchup data
- Injury reports and lineup changes
- Weather and venue factors
- Public betting sentiment vs sharp money
- Line movement analysis

Always conclude betting advice with: "Remember to bet responsibly and within your means!"
''';
  }
}
