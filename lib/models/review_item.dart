import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewItem {
  final String id;
  final String userId;
  final String title;
  final String subjectId;
  final DateTime nextReviewDate;
  final int interval; // days
  final double easeFactor;
  final int difficulty; // 0-5
  final int repetitions;
  final DateTime createdAt;

  const ReviewItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.subjectId,
    required this.nextReviewDate,
    this.interval = 1,
    this.easeFactor = 2.5,
    this.difficulty = 0,
    this.repetitions = 0,
    required this.createdAt,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      subjectId: json['subjectId'] as String,
      nextReviewDate: (json['nextReviewDate'] as Timestamp).toDate(),
      interval: json['interval'] as int? ?? 1,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      difficulty: json['difficulty'] as int? ?? 0,
      repetitions: json['repetitions'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'subjectId': subjectId,
      'nextReviewDate': Timestamp.fromDate(nextReviewDate),
      'interval': interval,
      'easeFactor': easeFactor,
      'difficulty': difficulty,
      'repetitions': repetitions,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ReviewItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? subjectId,
    DateTime? nextReviewDate,
    int? interval,
    double? easeFactor,
    int? difficulty,
    int? repetitions,
    DateTime? createdAt,
  }) {
    return ReviewItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      subjectId: subjectId ?? this.subjectId,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      interval: interval ?? this.interval,
      easeFactor: easeFactor ?? this.easeFactor,
      difficulty: difficulty ?? this.difficulty,
      repetitions: repetitions ?? this.repetitions,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
