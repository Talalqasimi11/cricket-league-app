class Feedback {
  final int id;
  final String userId;
  final String? userName;
  final String subject;
  final String message;
  final String rating;
  final String status; // open, in_progress, resolved, closed
  final String? category; // bug, feature, general
  final DateTime createdAt;
  final DateTime updatedAt;

  Feedback({
    required this.id,
    required this.userId,
    this.userName,
    required this.subject,
    required this.message,
    required this.rating,
    required this.status,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'] as int? ?? 0,
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name'] as String?,
      subject: json['subject'] as String? ?? '',
      message: json['message'] as String? ?? '',
      rating: json['rating'] as String? ?? '5',
      status: json['status'] as String? ?? 'open',
      category: json['category'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'subject': subject,
      'message': message,
      'rating': rating,
      'status': status,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
