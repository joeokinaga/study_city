import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/subject.dart';
import '../services/firestore_service.dart';

class SubjectRepository {
  final FirestoreService _firestore;
  static const _collection = 'subjects';

  SubjectRepository(this._firestore);

  Future<void> createSubject(Subject subject) async {
    await _firestore.setDocument(_collection, subject.id, subject.toJson());
  }

  Future<void> updateSubject(Subject subject) async {
    await _firestore.updateDocument(_collection, subject.id, subject.toJson());
  }

  Future<void> deleteSubject(String userId, String subjectId) async {
    await _firestore.deleteDocument(_collection, subjectId);
  }

  Stream<List<Subject>> streamSubjects(String userId) {
    return _firestore
        .streamCollection(
          _collection,
          where: [
            ['userId', '==', userId],
          ],
          orderBy: 'createdAt',
        )
        .map((docs) => docs.map((d) => Subject.fromJson(d)).toList());
  }

  Future<void> addStudyTime(
    String userId,
    String subjectId,
    int seconds,
  ) async {
    await _firestore.updateDocument(_collection, subjectId, {
      'totalStudyTime': FieldValue.increment(seconds),
    });
  }
}
