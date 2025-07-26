class TechnicalTrack {
  final String id;
  final String name;
  final String description;
  final String icon;
  final List<String> skills;
  final List<String> keywords;
  final int difficulty;

  TechnicalTrack({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.skills,
    required this.keywords,
    required this.difficulty,
  });

  factory TechnicalTrack.fromJson(Map<String, dynamic> json) {
    return TechnicalTrack(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      skills: List<String>.from(json['skills']),
      keywords: List<String>.from(json['keywords']),
      difficulty: json['difficulty'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'skills': skills,
      'keywords': keywords,
      'difficulty': difficulty,
    };
  }
}

class LearningResource {
  final String id;
  final String title;
  final String description;
  final String url;
  final String type; // video, article, course, book, etc.
  final String difficulty; // beginner, intermediate, advanced
  final double rating;
  final int duration; // in minutes
  final bool isFree;

  LearningResource({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.type,
    required this.difficulty,
    required this.rating,
    required this.duration,
    required this.isFree,
  });

  factory LearningResource.fromJson(Map<String, dynamic> json) {
    return LearningResource(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      url: json['url'],
      type: json['type'],
      difficulty: json['difficulty'],
      rating: json['rating'].toDouble(),
      duration: json['duration'],
      isFree: json['isFree'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'type': type,
      'difficulty': difficulty,
      'rating': rating,
      'duration': duration,
      'isFree': isFree,
    };
  }
}
