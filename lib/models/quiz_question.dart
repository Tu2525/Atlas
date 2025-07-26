class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String? correctAnswer;
  final String? explanation;
  final int points;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    this.correctAnswer,
    this.explanation,
    this.points = 1,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
      explanation: json['explanation'],
      points: json['points'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'points': points,
    };
  }
}

class QuizResult {
  final String track;
  final int score;
  final int totalQuestions;
  final List<Map<String, dynamic>> recommendations;
  final List<Map<String, dynamic>> resources;

  QuizResult({
    required this.track,
    required this.score,
    required this.totalQuestions,
    required this.recommendations,
    required this.resources,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      track: json['track'],
      score: json['score'],
      totalQuestions: json['totalQuestions'],
      recommendations: List<Map<String, dynamic>>.from(
        json['recommendations'] ?? [],
      ),
      resources: List<Map<String, dynamic>>.from(json['resources'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'track': track,
      'score': score,
      'totalQuestions': totalQuestions,
      'recommendations': recommendations,
      'resources': resources,
    };
  }

  double get percentage => (score / totalQuestions) * 100;
}
