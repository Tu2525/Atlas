import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/quiz_question.dart';
import '../config/api_config.dart';
import 'dart:async'; // Add this at the top

class ChatService {
  // Track conversation history for analysis
  final List<String> _conversationHistory = [];
  String? _currentTrack;
  List<Map<String, dynamic>> _currentQuiz = [];

  // Send message to Atlas and get response
  Future<ChatMessage> sendMessage(
    String message,
    List<ChatMessage> conversationHistory,
  ) async {
    try {
      // Add message to conversation history
      _conversationHistory.add(message);

      // If we have enough conversation history, analyze for track
      if (_conversationHistory.length >= 3 && _currentTrack == null) {
        await _analyzeProfile();
      }

      // Get Atlas response from backend
      return await _getAtlasResponse(message, conversationHistory);
    } on TimeoutException {
      print('Request to /chat timed out');
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content:
            "Sorry, my backend is taking too long to respond. Please try again later.",
        type: MessageType.atlas,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Error getting Atlas response: $e');
      // Return error message instead of fallback
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content:
            "Sorry, I'm having trouble connecting to my backend. Please check your connection and try again.",
        type: MessageType.atlas,
        timestamp: DateTime.now(),
      );
    }
  }

  // Get Atlas response from backend
  Future<ChatMessage> _getAtlasResponse(
    String message,
    List<ChatMessage> conversationHistory,
  ) async {
    try {
      // Convert conversation history to format expected by backend
      List<Map<String, String>> history = [];

      // Build conversation history properly - user and atlas messages alternate
      for (int i = 0; i < conversationHistory.length - 1; i++) {
        ChatMessage current = conversationHistory[i];
        ChatMessage next = conversationHistory[i + 1];

        // If current is user and next is atlas, add the exchange
        if (current.type == MessageType.user &&
            next.type == MessageType.atlas) {
          history.add({'user': current.content, 'atlas': next.content});
        }
      }

      final url = ApiConfig.getUrl(ApiConfig.chatEndpoint);
      print('🌐 Trying to connect to: $url');
      print(
        '📤 Sending data: ${jsonEncode({'message': message, 'conversation_history': history})}',
      );

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'conversation_history': history,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📥 Backend response: ${jsonEncode(data)}');

        // Check if this is a track recommendation
        if (data['track_recommendation'] != null) {
          _currentTrack = data['track_recommendation'];
          print('✅ Track recommended by backend: $_currentTrack');
        } else {
          print('❌ No track recommendation in response');
        }

        return ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content:
              data['response'] ??
              'I understand. Tell me more about your interests.',
          type: MessageType.atlas,
          timestamp: DateTime.now(),
        );
      } else {
        throw Exception('Failed to get response from backend');
      }
    } on TimeoutException {
      print('Request to /chat timed out');
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content:
            "Sorry, my backend is taking too long to respond. Please try again later.",
        type: MessageType.atlas,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Error calling chat endpoint: $e');
      // Return error message instead of fallback
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content:
            "Sorry, I'm having trouble connecting to my backend. Please check your connection and try again.",
        type: MessageType.atlas,
        timestamp: DateTime.now(),
      );
    }
  }

  // Analyze user profile to determine track
  Future<void> _analyzeProfile() async {
    try {
      // Combine conversation history into a paragraph
      String paragraph = _conversationHistory.join(' ');

      final response = await http.post(
        Uri.parse(ApiConfig.getUrl(ApiConfig.analyzeEndpoint)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'paragraph': paragraph}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentTrack = data['track'];
        _currentQuiz = List<Map<String, dynamic>>.from(data['quiz']);
        print('Track determined: $_currentTrack');
      }
    } catch (e) {
      print('Error analyzing profile: $e');
      // Fallback track prediction
      _currentTrack = _predictTrackFromConversation();
    }
  }

  // Analyze a specific track and fetch quiz questions from backend
  Future<void> analyzeTrackAndFetchQuiz(String track) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.getUrl(ApiConfig.analyzeEndpoint)),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'paragraph': track}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentTrack = data['track'];
        _currentQuiz = List<Map<String, dynamic>>.from(data['quiz']);
        print('📝 Quiz fetched for track: $_currentTrack');
      } else {
        print('❌ Failed to fetch quiz for track: $track');
        _currentQuiz = [];
      }
    } on TimeoutException {
      print('Request to /analyze timed out');
      _currentQuiz = [];
    } catch (e) {
      print('Error fetching quiz for track: $e');
      _currentQuiz = [];
    }
  }

  // Get quiz questions for the determined track
  Future<List<QuizQuestion>> getQuizQuestions(String track) async {
    try {
      // If we already have quiz from analyze endpoint, use it
      if (_currentQuiz.isNotEmpty && _currentTrack == track) {
        return _currentQuiz
            .map(
              (q) => QuizQuestion(
                id: q['question'] ?? '',
                question: q['question'] ?? '',
                options: List<String>.from(q['options'] ?? []),
                correctAnswer: q['correct'] ?? '',
                points: 1,
              ),
            )
            .toList();
      }

      // Otherwise, get quiz from analyze endpoint
      if (_currentTrack == null) {
        await _analyzeProfile();
      }

      if (_currentQuiz.isNotEmpty) {
        return _currentQuiz
            .map(
              (q) => QuizQuestion(
                id: q['question'] ?? '',
                question: q['question'] ?? '',
                options: List<String>.from(q['options'] ?? []),
                correctAnswer: q['correct'] ?? '',
                points: 1,
              ),
            )
            .toList();
      }
    } catch (e) {
      print('Error getting quiz questions: $e');
    }

    // Return empty list if backend fails
    return [];
  }

  // Submit quiz answers and get results
  Future<Map<String, dynamic>> submitQuizAnswers(
    String track,
    Map<String, String> answers,
  ) async {
    try {
      // Convert answers to list format expected by backend
      List<String> answerList = [];
      for (int i = 0; i < _currentQuiz.length; i++) {
        String questionId = _currentQuiz[i]['question'] ?? '';
        // Extract just the letter (e.g., "B" from "B) ...")
        String fullAnswer = answers[questionId] ?? '';
        String letter =
            fullAnswer.isNotEmpty ? fullAnswer[0].toUpperCase() : '';
        answerList.add(letter);
      }

      // Clean quiz for backend: only question, options, correct
      List<Map<String, dynamic>> quizForBackend =
          _currentQuiz
              .map(
                (q) => {
                  'question': q['question'],
                  'options': q['options'],
                  'correct': q['correct'],
                },
              )
              .toList();

      final payload = {'answers': answerList, 'quiz': quizForBackend};
      print(
        '📤 Sending to /evaluate: ' +
            jsonEncode(payload) +
            ' with track: ' +
            track,
      );

      final response = await http
          .post(
            Uri.parse(
              '${ApiConfig.getUrl(ApiConfig.evaluateEndpoint)}?track=$track',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final level = data['level'] ?? 'beginner';

        // Convert dynamic list to List<Map<String, dynamic>> and tag resources
        final rawRecommendations = data['recommendations'] ?? [];
        final recommendationsList = List<Map<String, dynamic>>.from(
          rawRecommendations,
        );

        final taggedRecommendations = _tagResources(
          recommendationsList,
          level,
          true,
        );
        final taggedResources = _tagResources(
          recommendationsList,
          level,
          false,
        );

        return {
          'track': track,
          'score': _calculateScore(answers),
          'totalQuestions': _currentQuiz.length,
          'recommendations': taggedRecommendations,
          'evaluation': data['evaluation'] ?? '',
          'level': level,
          'resources': taggedResources,
        };
      } else {
        throw Exception('Failed to submit quiz');
      }
    } on TimeoutException {
      print('Request to /evaluate timed out');
      return {
        'track': track,
        'score': 0,
        'totalQuestions': 0,
        'recommendations': [],
        'evaluation':
            'Sorry, my backend is taking too long to respond. Please try again later.',
        'level': 'beginner',
        'resources': [],
      };
    } catch (e) {
      print('Error submitting quiz: $e');
      // Fallback results
      return _getFallbackQuizResults(track, answers);
    }
  }

  // Calculate score from answers
  int _calculateScore(Map<String, String> answers) {
    int correct = 0;
    for (int i = 0; i < _currentQuiz.length; i++) {
      String questionId = _currentQuiz[i]['question'] ?? '';
      String userAnswer = answers[questionId] ?? '';
      String correctAnswer = _currentQuiz[i]['correct'] ?? '';

      // Extract letter from user answer (e.g., "A" from "A) Some text")
      String userLetter =
          userAnswer.isNotEmpty ? userAnswer[0].toUpperCase() : '';
      if (userLetter == correctAnswer.toUpperCase()) {
        correct++;
      }
    }
    return correct;
  }

  // Get learning resources for a track
  Future<List<Map<String, dynamic>>> getLearningResources(String track) async {
    try {
      // The backend doesn't have a separate resources endpoint,
      // but we can use the recommendations from the evaluate endpoint
      // For now, return fallback resources
      return _getFallbackResources(track);
    } catch (e) {
      print('Error getting resources: $e');
      return _getFallbackResources(track);
    }
  }

  // Simple track prediction based on keywords (fallback)
  String _predictTrackFromConversation() {
    final conversation = _conversationHistory.join(' ').toLowerCase();

    if (conversation.contains('machine learning') ||
        conversation.contains('ai') ||
        conversation.contains('data') ||
        conversation.contains('python') ||
        conversation.contains('neural') ||
        conversation.contains('model')) {
      return 'machine learning';
    } else if (conversation.contains('web') ||
        conversation.contains('frontend') ||
        conversation.contains('html') ||
        conversation.contains('css') ||
        conversation.contains('javascript') ||
        conversation.contains('react')) {
      return 'web development';
    } else if (conversation.contains('embedded') ||
        conversation.contains('microcontroller') ||
        conversation.contains('hardware') ||
        conversation.contains('iot') ||
        conversation.contains('arduino') ||
        conversation.contains('raspberry')) {
      return 'embedded systems';
    } else {
      return 'web development'; // default
    }
  }

  // Reset conversation state
  void resetConversation() {
    _conversationHistory.clear();
    _currentTrack = null;
    _currentQuiz.clear();
  }

  // Get current track (for external access)
  String? getCurrentTrack() {
    return _currentTrack;
  }

  // Removed all hardcoded fallback responses - only use backend

  // Removed fallback quiz questions - only use backend

  Map<String, dynamic> _getFallbackQuizResults(
    String track,
    Map<String, String> answers,
  ) {
    return {
      'track': track,
      'score': answers.length,
      'totalQuestions': answers.length,
      'recommendations': [
        'Start with the basics of $track',
        'Practice with small projects',
        'Join online communities',
      ],
      'level': 'beginner',
      'evaluation':
          'Based on your answers, you appear to be at a beginner level. Focus on fundamentals!',
      'resources': {
        'courses': [
          {
            'title': 'Introduction to $track',
            'url': 'https://example.com/course',
            'type': 'course',
            'difficulty': 'beginner',
          },
        ],
        'articles': [
          {
            'title': 'Getting Started with $track',
            'url': 'https://example.com/article',
            'type': 'article',
            'difficulty': 'beginner',
          },
        ],
      },
    };
  }

  List<Map<String, dynamic>> _getFallbackResources(String track) {
    return [
      {
        'title': 'Complete $track Course',
        'description': 'A comprehensive course covering all aspects of $track',
        'url': 'https://example.com/course',
        'type': 'course',
        'difficulty': 'beginner',
        'rating': 4.5,
        'duration': 120,
        'isFree': false,
      },
      {
        'title': '$track Documentation',
        'description': 'Official documentation and guides',
        'url': 'https://example.com/docs',
        'type': 'documentation',
        'difficulty': 'beginner',
        'rating': 4.8,
        'duration': 0,
        'isFree': true,
      },
    ];
  }

  // Helper to tag resources with additional metadata
  List<Map<String, dynamic>> _tagResources(
    List<Map<String, dynamic>> resources,
    String level,
    bool isRecommendation,
  ) {
    return resources.map((resource) {
      final newResource = Map<String, dynamic>.from(resource);

      // Add level and recommendation flag
      newResource['level'] = level;
      newResource['isRecommendation'] = isRecommendation;

      // Determine if resource is free based on URL
      final url = resource['url']?.toString().toLowerCase() ?? '';
      newResource['isFree'] =
          url.contains('free') ||
          url.contains('coursera.org') ||
          url.contains('edx.org') ||
          url.contains('freecodecamp.org') ||
          url.contains('github.com');

      // Determine resource type based on URL
      if (url.contains('coursera.org') ||
          url.contains('udemy.com') ||
          url.contains('udacity.com')) {
        newResource['type'] = 'course';
      } else if (url.contains('github.com') ||
          url.contains('docs.') ||
          url.contains('documentation')) {
        newResource['type'] = 'documentation';
      } else if (url.contains('youtube.com') || url.contains('video')) {
        newResource['type'] = 'video';
      } else if (url.contains('medium.com') ||
          url.contains('blog') ||
          url.contains('article')) {
        newResource['type'] = 'article';
      } else {
        newResource['type'] = 'resource';
      }

      // Set difficulty based on level
      newResource['difficulty'] = level.toLowerCase();

      // Add description if not present
      if (newResource['description'] == null) {
        final title = resource['title']?.toString() ?? '';
        if (title.isNotEmpty) {
          newResource['description'] =
              'Learn $title for ${level.toLowerCase()} level';
        }
      }

      return newResource;
    }).toList();
  }
}
