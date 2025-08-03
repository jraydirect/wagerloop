# TheOddsAPI Widget Setup Guide

## 🚀 Quick Setup

### 1. Get Your Widget API Key
1. Sign up for a free account at [TheOddsAPI](https://the-odds-api.com/)
2. Go to the **Accounts** page
3. Create a **Widget Subscription**
4. Copy your Widget API Key (starts with `wk_`)

### 2. Configure Environment Variable
Add this line to your `.env` file:
```
ODDS_API_WIDGET_KEY=wk_c58c553b857f62e6608a4413267e1376
```

### 3. Platform Support
- ✅ **iOS**: Full WebView + JavaScript + OCR pick detection
- ✅ **Android**: Full WebView + JavaScript + OCR pick detection  
- ✅ **Web**: Full WebView + OCR pick detection (JavaScript not supported)
- ✅ **Desktop**: Full WebView + JavaScript + OCR pick detection

### 4. OCR Technology
- **🔍 Universal Solution**: Works on ALL platforms including web
- **📸 Screenshot Analysis**: Captures widget content and reads text via ML
- **🎯 Smart Extraction**: Detects odds, teams, and market types automatically
- **⚡ Real-time Processing**: Fast OCR processing with visual feedback

## 📱 How It Works

### In-App Experience (All Platforms)
- **Live odds widget embedded directly** in the Create Pick page
- **Full-width display** for optimal viewing
- **Real-time updates** from TheOddsAPI
- **Multiple sportsbooks** and sports to choose from
- **Interactive betting markets** (Moneyline, Spreads, Over/Under)

### Smart Navigation
- **Widget content stays in-app** for odds viewing
- **Sportsbook links open externally** when users want to place actual bets
- **Seamless experience** across mobile, web, and desktop

### Web Platform Notes
- **Limitation**: WebView on web doesn't support JavaScript injection
- **Solution**: Use the **"Demo" button** to add sample picks to test functionality
- **Full Experience**: For complete pick detection, use mobile app or desktop
- **Demo Picks**: Includes realistic examples (Moneyline, Spread, Over/Under)

## ⚙️ Features

### Available Sports
- NFL (American Football)
- NBA (Basketball)
- MLB (Baseball)
- NHL (Hockey)
- NCAAF (College Football)
- NCAAB (College Basketball)

### Supported Sportsbooks
- DraftKings
- FanDuel
- BetMGM
- Caesars
- Bovada
- BetRivers

### Betting Markets
- **Moneyline**: Who wins the game
- **Spread**: Point spread betting
- **Totals**: Over/Under betting

## 💰 Cost & Usage

### Widget Subscription
- **Free tier**: Limited requests per month
- **Paid tiers**: Higher request limits
- **Cost**: Only charged when widget loads (page visits)

### Affiliate Links (Optional)
- Set up affiliate links in your TheOddsAPI dashboard
- Earn commission when users click through to sportsbooks
- Configure per sportsbook in your account settings

## 🔧 Troubleshooting

### WebView Issues
The app now includes enhanced error handling for WebView compatibility:

1. **NavigationDelegate errors**: App automatically switches to simplified WebView mode
2. **Platform-specific issues**: Falls back to basic WebView without advanced features
3. **Complete WebView failure**: Shows fallback interface with external browser option

**Common Error Messages:**
- `"WebView not fully supported on this device"` → Retry button uses simplified mode
- `"NavigationDelegate not supported"` → Automatic fallback, widget still works
- `"Platform issue detected"` → App tries alternative initialization method

### API Key Issues
```
Error: "Odds API key not configured"
```
- Verify `.env` file has correct key
- Restart app after adding key
- Check key starts with `wk_`

### No Odds Displayed
```
Error: "Access key out of usage quota"
```
- Check your TheOddsAPI dashboard usage
- Upgrade subscription if needed
- Widget loads count against quota

## 📞 Support

### TheOddsAPI Support
- [Documentation](https://the-odds-api.com/docs)
- [Widget Builder](https://the-odds-api.com/widget-builder)
- Support email: support@the-odds-api.com

### Common Issues
1. **Widget not loading**: Check API key and internet connection
2. **Slow loading**: Normal for first load, subsequent loads are faster
3. **Empty widget**: No games scheduled for selected sport/day

## 🎯 Next Steps

1. **Add your API key** to `.env` file
2. **Test on mobile device** for full experience
3. **Configure affiliate links** (optional)
4. **Monitor usage** in TheOddsAPI dashboard

The widget provides professional-grade odds display that enhances your app's betting pick functionality!