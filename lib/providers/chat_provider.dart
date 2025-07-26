import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/quiz_question.dart';
import '../services/chat_service.dart';

enum ChatState { initial, chatting, quiz, results }

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatMessage> _messages = [];
  ChatState _state = ChatState.initial;
  String? _predictedTrack;
  List<QuizQuestion> _quizQuestions = [];
  int _currentQuestionIndex = 0;
  final Map<String, String> _quizAnswers = {};
  QuizResult? _quizResult;
  bool _isLoading = false;
  String? _pendingQuizTrack; // <-- Add this flag

  // Getters
  List<ChatMessage> get messages => _messages;
  ChatState get state => _state;
  String? get predictedTrack => _predictedTrack;
  List<QuizQuestion> get quizQuestions => _quizQuestions;
  int get currentQuestionIndex => _currentQuestionIndex;
  QuizResult? get quizResult => _quizResult;
  bool get isLoading => _isLoading;
  bool get isQuizComplete => _currentQuestionIndex >= _quizQuestions.length;

  // Initialize the chat with Atlas's greeting
  void initializeChat() {
    _messages = [
      ChatMessage(
        id: '1',
        content:
            "Hey! I'm Atlas, your AI learning assistant. I'm here to help you discover the perfect technical track and guide you through your learning journey. What brings you here today?",
        type: MessageType.atlas,
        timestamp: DateTime.now(),
      ),
    ];
    _state = ChatState.chatting;
    notifyListeners();
  }

  // Send a message and get Atlas's response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.user,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    notifyListeners();

    // If a track was recommended and quiz is pending, start the quiz now
    if (_pendingQuizTrack != null && _state == ChatState.chatting) {
      final trackToStart = _pendingQuizTrack!;
      print(
        '🚀 Starting quiz with backend track (after user confirmation): $trackToStart',
      );
      _pendingQuizTrack = null;
      await _startQuizWithBackendTrack(trackToStart);
      return; // Exit early, don't process further
    }

    // Show typing indicator
    _isLoading = true;
    notifyListeners();

    try {
      // Get Atlas's response
      final atlasResponse = await _chatService.sendMessage(content, _messages);
      _messages.add(atlasResponse);

      // Check if backend recommended a track and set pending quiz
      final currentTrack = _chatService.getCurrentTrack();
      print('🔍 Checking for track recommendation: $currentTrack');
      if (currentTrack != null &&
          _state == ChatState.chatting &&
          _pendingQuizTrack == null) {
        print(
          '🕒 Track recommended, waiting for user confirmation to start quiz: $currentTrack',
        );
        _pendingQuizTrack = currentTrack;
        // Do NOT start quiz yet; wait for next user message
      }
      // Fallback: Check if we should start the quiz (after a few messages)
      else if (_messages.length >= 6 &&
          _state == ChatState.chatting &&
          _pendingQuizTrack == null) {
        await _predictTrackAndStartQuiz();
      }
    } catch (e) {
      print('Error in sendMessage: $e');
      // Add error message
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content:
              "Sorry, I'm having trouble connecting right now. Let's continue our conversation!",
          type: MessageType.atlas,
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Start quiz with backend-recommended track
  Future<void> _startQuizWithBackendTrack(String track) async {
    print('📝 Starting quiz generation for track: $track');
    _isLoading = true;
    _state = ChatState.quiz; // Set state immediately to prevent loops
    notifyListeners();

    try {
      _predictedTrack = track;
      print('📝 Fetching quiz from backend...');
      await _chatService.analyzeTrackAndFetchQuiz(_predictedTrack!);
      _quizQuestions = await _chatService.getQuizQuestions(_predictedTrack!);
      print('📝 Quiz questions fetched: ${_quizQuestions.length}');

      _currentQuestionIndex = 0;
      _quizAnswers.clear();

      // Add first quiz question
      if (_quizQuestions.isNotEmpty) {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: _quizQuestions[0].question,
            type: MessageType.atlas,
            timestamp: DateTime.now(),
          ),
        );
        print('📝 First quiz question added');
      } else {
        print('❌ No quiz questions available');
        // Revert to chatting state if no quiz questions
        _state = ChatState.chatting;
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content:
                "Sorry, I couldn't generate a quiz right now. Let's continue our conversation!",
            type: MessageType.atlas,
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      print('Error generating quiz: $e');
      // Revert to chatting state on error
      _state = ChatState.chatting;
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content:
              "Sorry, I couldn't generate a quiz right now. Please try again later.",
          type: MessageType.atlas,
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Predict track and start quiz
  Future<void> _predictTrackAndStartQuiz() async {
    // Simple track prediction based on conversation keywords
    _predictedTrack = _predictTrackFromConversation();

    // Add prediction message
    _messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content:
            "Based on our conversation, I think you might be interested in $_predictedTrack! Let me give you a quick quiz to better understand your preferences and provide personalized recommendations.",
        type: MessageType.atlas,
        timestamp: DateTime.now(),
      ),
    );

    // Get quiz questions
    _quizQuestions = await _chatService.getQuizQuestions(_predictedTrack!);
    _currentQuestionIndex = 0;
    _quizAnswers.clear();
    _state = ChatState.quiz;

    // Add first quiz question
    if (_quizQuestions.isNotEmpty) {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: _quizQuestions[0].question,
          type: MessageType.atlas,
          timestamp: DateTime.now(),
        ),
      );
    }

    notifyListeners();
  }

  // Simple track prediction based on keywords
  String _predictTrackFromConversation() {
    final conversation = _messages
        .map((m) => m.content.toLowerCase())
        .join(' ');

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

  // Submit quiz answer
  Future<void> submitQuizAnswer(String answer) async {
    if (_currentQuestionIndex >= _quizQuestions.length) return;

    final currentQuestion = _quizQuestions[_currentQuestionIndex];
    _quizAnswers[currentQuestion.id] = answer;

    // Add user's answer to chat
    _messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: answer,
        type: MessageType.user,
        timestamp: DateTime.now(),
      ),
    );

    _currentQuestionIndex++;

    if (_currentQuestionIndex < _quizQuestions.length) {
      // Add next question
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: _quizQuestions[_currentQuestionIndex].question,
          type: MessageType.atlas,
          timestamp: DateTime.now(),
        ),
      );
    } else {
      // Quiz complete, get results
      await _completeQuiz();
    }

    notifyListeners();
  }

  // Complete quiz and get results
  Future<void> _completeQuiz() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await _chatService.submitQuizAnswers(
        _predictedTrack!,
        _quizAnswers,
      );

      _quizResult = QuizResult(
        track: results['track'],
        score: results['score'],
        totalQuestions: results['totalQuestions'],
        recommendations: List<Map<String, dynamic>>.from(
          results['recommendations'] ?? [],
        ),
        resources: List<Map<String, dynamic>>.from(results['resources'] ?? []),
      );

      // Add completion message
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content:
              "Great! I've analyzed your responses. You scored ${_quizResult!.score}/${_quizResult!.totalQuestions} (${_quizResult!.percentage.toStringAsFixed(1)}%). Let me show you your personalized learning path!",
          type: MessageType.atlas,
          timestamp: DateTime.now(),
        ),
      );

      _state = ChatState.results;
    } catch (e) {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content:
              "Sorry, I couldn't process your quiz results. Let me show you some general resources for $_predictedTrack.",
          type: MessageType.atlas,
          timestamp: DateTime.now(),
        ),
      );
      _state = ChatState.results;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset chat
  void resetChat() {
    _messages.clear();
    _state = ChatState.initial;
    _predictedTrack = null;
    _quizQuestions.clear();
    _currentQuestionIndex = 0;
    _quizAnswers.clear();
    _quizResult = null;
    _isLoading = false;
    _pendingQuizTrack = null; // Reset the pending quiz flag
    _chatService.resetConversation();
    notifyListeners();

    // Reinitialize the chat after reset
    initializeChat();
  }

  // Get current quiz question
  QuizQuestion? get currentQuizQuestion {
    if (_currentQuestionIndex < _quizQuestions.length) {
      return _quizQuestions[_currentQuestionIndex];
    }
    return null;
  }
}
