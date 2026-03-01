import 'package:intl/intl.dart';

import '../models/daily_stats.dart';
import '../models/study_session.dart';
import '../models/time_period.dart';
import '../services/firestore_service.dart';

class StudySessionRepository {
  final FirestoreService _firestore;
  static const _collection = 'study_sessions';

  StudySessionRepository(this._firestore);

  Future<void> saveSession(StudySession session) async {
    await _firestore.setDocument(_collection, session.id, session.toJson());
  }

  Future<List<StudySession>> getSessionsByDateRange(
    String userId,
    DateTime from,
    DateTime to,
  ) async {
    final fromDate = DateFormat('yyyy-MM-dd').format(from);
    final toDate = DateFormat('yyyy-MM-dd').format(to);
    final docs = await _firestore.queryCollection(
      _collection,
      where: [
        ['userId', '==', userId],
        ['date', '>=', fromDate],
        ['date', '<=', toDate],
      ],
      orderBy: 'date',
      descending: true,
    );
    return docs.map((d) => StudySession.fromJson(d)).toList();
  }

  Stream<List<StudySession>> streamRecentSessions(
    String userId, {
    int limit = 30,
  }) {
    return _firestore
        .streamCollection(
          _collection,
          where: [
            ['userId', '==', userId],
          ],
          orderBy: 'startTime',
          descending: true,
        )
        .map((docs) => docs
            .take(limit)
            .map((d) => StudySession.fromJson(d))
            .toList());
  }

  Future<List<DailyStats>> getDailyStats(
    String userId,
    TimePeriod period,
  ) async {
    final now = DateTime.now();
    final from = period == TimePeriod.allTime
        ? DateTime(2000)
        : now.subtract(Duration(days: period.days));
    final sessions = await getSessionsByDateRange(userId, from, now);

    final Map<String, DailyStats> statsMap = {};
    for (final session in sessions) {
      final existing = statsMap[session.date];
      statsMap[session.date] = DailyStats(
        date: session.date,
        totalDuration: (existing?.totalDuration ?? 0) + session.duration,
        sessionCount: (existing?.sessionCount ?? 0) + 1,
        reviewCount: existing?.reviewCount ?? 0,
      );
    }

    final result = statsMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return result;
  }
}
