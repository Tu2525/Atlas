# Atlas - AI Learning Assistant

Atlas is a Flutter-based chatbot application that helps users discover their ideal technical learning path through intelligent conversation and personalized quizzes.

## Features

### 🤖 Intelligent Chat Interface
- **Atlas Greeting**: Starts with "Hey! I'm Atlas, your AI learning assistant"
- **Natural Conversation**: Chat with Atlas about your interests and experience
- **Smart Responses**: Atlas responds contextually to your messages
- **Beautiful UI**: Modern, dark theme with smooth animations

### 🎯 Technical Track Prediction
- **Conversation Analysis**: Atlas analyzes your conversation to predict your interests
- **Keyword Detection**: Identifies technical keywords to suggest relevant tracks
- **Track Categories**: 
  - Web Development
  - Mobile Development
  - Data Science
  - Backend Development
  - Software Development

### 📝 Interactive Quiz System
- **Personalized Questions**: Quiz questions tailored to your predicted track
- **Multiple Choice**: Easy-to-answer format within the chat
- **Progress Tracking**: Shows current question and total progress
- **Score Calculation**: Evaluates your responses and provides feedback

### 📚 Learning Resources
- **Personalized Recommendations**: Based on your quiz results
- **Resource Categories**: Courses, articles, documentation, and more
- **Difficulty Levels**: Beginner, intermediate, and advanced resources
- **Free/Paid Indicators**: Clear labeling of resource costs
- **Direct Links**: One-click access to learning materials

## App Flow

1. **Welcome**: Atlas greets you and asks about your interests
2. **Conversation**: Chat naturally about your tech experience and goals
3. **Prediction**: After a few messages, Atlas predicts your ideal track
4. **Quiz**: Answer personalized questions about your preferences
5. **Results**: Get your score and personalized recommendations
6. **Resources**: Access curated learning materials for your track

## Technical Architecture

### Models
- `ChatMessage`: Represents individual chat messages
- `QuizQuestion`: Quiz question structure with options
- `QuizResult`: Quiz results with score and recommendations
- `TechnicalTrack`: Learning track information
- `LearningResource`: Resource details and metadata

### Services
- `ChatService`: Handles API communication with backend
- Fallback responses for demo/testing purposes

### State Management
- `ChatProvider`: Manages chat state, quiz flow, and results
- Uses Provider pattern for reactive UI updates

### Screens
- `ChatScreen`: Main chat interface with quiz integration
- `ResourcesScreen`: Learning resources display

### Widgets
- `ChatMessageWidget`: Individual message display
- `ChatInputWidget`: Message input with send functionality

## Setup Instructions

### Prerequisites
- Flutter SDK (3.7.2 or higher)
- Dart SDK
- Android Studio / VS Code

### Installation

1. **Clone the repository**
   ```bash
   git clone <https://github.com/Tu2525/Atlas>
   cd atlas
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure backend URL**
   - Open `lib/config/api_config.dart`
   - Replace `YOUR_NGROK_URL` with your actual ngrok URL
   - See `BACKEND_SETUP.md` for detailed instructions

4. **Run the app**
   ```bash
   flutter run
   ```

## Backend Integration

The app is designed to work with your FastAPI backend running on Google Colab with ngrok. See `BACKEND_SETUP.md` for detailed setup instructions.

### Quick Setup

1. **Update the ngrok URL** in `lib/config/api_config.dart`:
   ```dart
   static const String baseUrl = 'https://your-ngrok-url.ngrok.io';
   ```

2. **Restart the app** to connect to your backend

### API Endpoints Used

1. **POST /analyze** - Analyzes user profile and returns track + quiz
2. **POST /evaluate** - Evaluates quiz answers and returns results
3. **GET /** - Root endpoint for testing connection

### API Response Format

```json
{
  "response": "Atlas's response message",
  "track": "predicted_track",
  "score": 8,
  "totalQuestions": 10,
  "recommendations": ["Start with basics", "Practice projects"],
  "resources": {
    "courses": [...],
    "articles": [...]
  }
}
```

## Customization

### Themes
- Modify colors in `lib/main.dart`
- Update UI components in individual widgets

### Quiz Questions
- Add questions in `ChatService._getFallbackQuizQuestions()`
- Customize track prediction logic in `ChatProvider._predictTrackFromConversation()`

### Resources
- Update resource lists in `ResourcesScreen._getGeneralResources()`
- Modify resource categories and types

## Dependencies

- `flutter`: Core Flutter framework
- `provider`: State management
- `http`: API communication
- `flutter_animate`: Smooth animations
- `url_launcher`: External link handling
- `shared_preferences`: Local data storage
- `lottie`: Animation support

## Demo Mode

The app includes fallback responses and demo data for testing without a backend:

- Automatic responses based on conversation keywords
- Sample quiz questions for each track
- Mock learning resources and recommendations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For questions or issues, please open an issue on the repository or contact the development team.

---

**Atlas** - Your AI Learning Assistant 🤖✨
