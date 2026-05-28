import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String name;
  final String email;
  final int exp;
  final int coins;
  final int weeklyGoalMinutes;
  final DateTime createdAt;

  const User({
    required this.uid,
    required this.name,
    required this.email,
    this.exp = 0,
    this.coins = 0,
    this.weeklyGoalMinutes = 600,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      exp: json['exp'] as int? ?? 0,
      coins: json['coins'] as int? ?? 0,
      weeklyGoalMinutes: json['weeklyGoalMinutes'] as int? ?? 600,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'exp': exp,
      'coins': coins,
      'weeklyGoalMinutes': weeklyGoalMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  User copyWith({
    String? uid,
    String? name,
    String? email,
    int? exp,
    int? coins,
    int? weeklyGoalMinutes,
    DateTime? createdAt,
  }) {
    return User(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      exp: exp ?? this.exp,
      coins: coins ?? this.coins,
      weeklyGoalMinutes: weeklyGoalMinutes ?? this.weeklyGoalMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
