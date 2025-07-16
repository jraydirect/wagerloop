# WagerGPT Implementation Guide

## Overview
WagerGPT is an AI-powered betting insights assistant integrated into the WagerLoop app using Google's Gemini API. It provides intelligent sports betting analysis, strategies, and recommendations through a conversational interface.

## Features
- 🎯 Game analysis & predictions
- 📊 Statistical insights
- 💰 Value bet identification
- 📈 Betting strategies
- 🧮 Bankroll management
- 🎲 Responsible gambling guidance

## Setup Instructions

### 1. Install Dependencies
The following dependency has been added to `pubspec.yaml`:
```yaml
dependencies:
  google_generative_ai: ^0.4.3
```

Run `flutter pub get` to install the new dependency.

### 2. Configure Gemini API Key

#### Get your Gemini API Key:
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated API key

#### Add the API key to your environment:
1. Open `assets/.env` file
2. Replace `YOUR_GEMINI_API_KEY_HERE` with your actual API key:
```
GEMINI_API_KEY=your_actual_api_key_here
```

### 3. File Structure
```
lib/
├── pages/
│   ├── discover_page.dart        # Updated to navigate to WagerGPT
│   └── wager_gpt_page.dart       # New WagerGPT interface
├── main.dart                     # Updated to load assets/.env
└── ...

assets/
└── .env                          # Updated with GEMINI_API_KEY
```

## Implementation Details

### WagerGPT Page Features
- **Modern Chat Interface**: Sleek dark theme with gradient backgrounds
- **Typing Indicators**: Animated typing indicators while AI responds
- **Message Bubbles**: User and AI messages with distinct styling
- **Avatar System**: User and AI avatars for easy identification
- **Error Handling**: Graceful error handling for API failures
- **Smooth Animations**: Fade-in and slide-up animations for messages

### AI System Prompt
The AI is configured with a specialized system prompt for sports betting insights:
- Expert in sports analytics and betting strategies
- Provides data-driven advice
- Explains complex betting concepts simply
- Always includes responsible gambling reminders
- Focuses on education rather than gambling promotion

### Navigation Integration
- WagerGPT is accessible from the Discover page under "Features"
- Tapping the WagerGPT card navigates to the full chat interface
- Back navigation returns to the Discover page

## Usage Examples

### User Queries WagerGPT Can Handle:
1. **Game Analysis**: "Analyze the Lakers vs Warriors game tonight"
2. **Betting Strategy**: "What's a good bankroll management strategy?"
3. **Odds Analysis**: "How do I identify value bets?"
4. **Statistical Insights**: "What stats should I look at for NBA betting?"
5. **Team Performance**: "How has the Chiefs defense performed this season?"

### Sample Conversations:
```
User: "What should I look for when betting on NFL games?"

WagerGPT: "When betting on NFL games, focus on these key factors:

🏈 **Team Analysis**
- Injury reports (especially key players)
- Recent form and momentum
- Head-to-head history

📊 **Statistical Insights**
- Offensive/defensive rankings
- Turnover differential
- Red zone efficiency
- Home/away performance

🌦️ **External Factors**
- Weather conditions
- Travel schedules
- Divisional rivalries

💰 **Betting Strategy**
- Compare odds across sportsbooks
- Look for value, not just winners
- Manage your bankroll (never bet more than 1-3% per game)

Remember: Bet responsibly and never chase losses!"
```

## Error Handling
- **API Key Issues**: Clear error messages guide users to check their API key
- **Network Errors**: Graceful handling of connection issues
- **Rate Limiting**: Appropriate handling of API rate limits
- **Malformed Responses**: Fallback messages for unexpected responses

## Responsible Gambling
WagerGPT is designed with responsible gambling principles:
- Always includes disclaimers about responsible betting
- Focuses on education and strategy rather than encouraging gambling
- Promotes bankroll management and risk awareness
- Provides resources for problem gambling help when appropriate

## Customization Options

### Modifying the AI Personality:
Edit the system instruction in `wager_gpt_page.dart`:
```dart
systemInstruction: Content.system('''
Your custom AI personality and instructions here...
'''),
```

### Styling Changes:
- Message bubble colors: Look for gradient definitions in `_buildMessage()`
- Animation timings: Modify duration values in `_setupAnimations()`
- UI colors: Update the color scheme throughout the build methods

### Adding New Features:
- **Quick Suggestions**: Add predefined question buttons
- **Image Analysis**: Integrate with Google Vision API for bet slip analysis
- **Voice Input**: Add speech-to-text capabilities
- **Conversation History**: Implement local storage for chat history

## Performance Considerations
- Messages are rendered efficiently with ListView.builder
- Animations are optimized with proper disposal
- API calls are throttled to prevent abuse
- Memory usage is managed through proper widget lifecycle

## Security Notes
- API keys are stored in environment variables
- No sensitive user data is sent to the AI
- All communications are encrypted in transit
- Consider implementing user authentication for enhanced security

## Troubleshooting

### Common Issues:
1. **"API key not found"**: Check that GEMINI_API_KEY is set in assets/.env
2. **"No response from AI"**: Verify API key is valid and has quota remaining
3. **App crashes**: Ensure flutter pub get was run after adding dependencies
4. **Styling issues**: Check for any missing imports or widget tree problems

### Debug Mode:
Enable debug logging by modifying the GenerativeModel initialization:
```dart
_model = GenerativeModel(
  model: 'gemini-1.5-flash',
  apiKey: apiKey,
  // Add debug logging here if needed
);
```

## Future Enhancements
- Integration with live sports data APIs
- Real-time odds comparison
- Personalized betting recommendations
- Machine learning for user preference tracking
- Multi-language support
- Voice interactions

## Support
For issues with WagerGPT implementation:
1. Check the troubleshooting section above
2. Verify all dependencies are properly installed
3. Ensure API key is correctly configured
4. Review console logs for specific error messages

Remember to always promote responsible gambling and comply with local regulations regarding sports betting applications.
