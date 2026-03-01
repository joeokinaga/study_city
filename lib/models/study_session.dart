import 'package:cloud_firestore/cloud_firestore.dart';

class StudySession {
  final String id;
  final String userId;
  final String subjectId;
  final String subjectName;
  final DateTime startTime;
  final DateTime endTime;
  final int duration; // seconds
  final String date; // yyyy-MM-dd

  const StudySession({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.subjectName,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.date,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      startTime: (json['startTime'] as Timestamp).toDate(),
      endTime: (json['endTime'] as Timestamp).toDate(),
      duration: json['duration'] as int,
      date: json['date'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'duration': duration,
      'date': date,
    };
  }
}
