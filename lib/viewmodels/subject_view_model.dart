import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subject.dart';
import '../repositories/subject_repository.dart';
import '../services/firestore_service.dart';

class SubjectViewModel extends ChangeNotifier {
  final SubjectRepository _subjectRepository;

  List<Subject> subjects = [];
  bool isLoading = false;

  SubjectViewModel(this._subjectRepository);

  Stream<List<Subject>> streamSubjects(String userId) {
    return _subjectRepository.streamSubjects(userId);
  }

  Future<void> createSubject(
    String userId,
    String name,
    String icon,
    String color,
  ) async {
    final now = DateTime.now();
    final subject = Subject(
      id: '${userId}_${now.millisecondsSinceEpoch}',
      userId: userId,
      name: name,
      icon: icon,
      color: color,
      createdAt: now,
    );
    await _subjectRepository.createSubject(subject);
    notifyListeners();
  }

  Future<void> updateSubject(Subject subject) async {
    await _subjectRepository.updateSubject(subject);
    notifyListeners();
  }

  Future<void> deleteSubject(String userId, String subjectId) async {
    await _subjectRepository.deleteSubject(userId, subjectId);
    notifyListeners();
  }
}

final subjectViewModelProvider =
    ChangeNotifierProvider<SubjectViewModel>((ref) {
  final firestore = FirestoreService();
  return SubjectViewModel(SubjectRepository(firestore));
});
