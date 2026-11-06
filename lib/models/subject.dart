import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Subject {
  static const List<String> iconOptions = [
    '📚', '📐', '🔬', '🎨', '🎵', '🌍',
    '💻', '📝', '🧪', '⚡', '🧮', '📖',
  ];

  static const List<String> colorOptions = [
    '#2196F3',
    '#4CAF50',
    '#FF9800',
    '#9C27B0',
    '#F44336',
    '#009688',
  ];

  static Color parseColor(String hex) {
    final code = hex.replaceFirst('#', '');
    return Color(int.parse('FF$code', radix: 16));
  }

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subject && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

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
