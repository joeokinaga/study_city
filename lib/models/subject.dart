import 'package:cloud_firestore/cloud_firestore.dart';

class Subject {
  final String id;
  final String userId;
  final String name;
  final String icon;
  final String color;
  final int totalStudyTime; // seconds
  final DateTime createdAt;

  const Subject({
    required this.id,
    required this.userId,
    required this.name,
    this.icon = '📚',
    this.color = '#2196F3',
    this.totalStudyTime = 0,
    required this.createdAt,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '📚',
      color: json['color'] as String? ?? '#2196F3',
      totalStudyTime: json['totalStudyTime'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'totalStudyTime': totalStudyTime,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Subject copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    String? color,
    int? totalStudyTime,
    DateTime? createdAt,
  }) {
    return Subject(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      totalStudyTime: totalStudyTime ?? this.totalStudyTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
