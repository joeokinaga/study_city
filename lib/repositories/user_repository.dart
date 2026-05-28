import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';
import '../services/firestore_service.dart';

class UserRepository {
  final FirestoreService _firestore;
  static const _collection = 'users';

  UserRepository(this._firestore);

  Future<void> createUser(User user) async {
    await _firestore.setDocument(_collection, user.uid, user.toJson());
  }

  Future<User?> getUser(String uid) async {
    final data = await _firestore.getDocument(_collection, uid);
    if (data == null) return null;
    return User.fromJson({'uid': uid, ...data});
  }

  Future<void> updateUser(User user) async {
    await _firestore.updateDocument(_collection, user.uid, user.toJson());
  }

  Future<void> updateWeeklyGoal(String uid, int minutes) async {
    await _firestore.updateDocument(_collection, uid, {
      'weeklyGoalMinutes': minutes,
    });
  }

  Future<void> addExpAndCoins(String uid, int exp, int coins) async {
    await _firestore.updateDocument(_collection, uid, {
      'exp': FieldValue.increment(exp),
      'coins': FieldValue.increment(coins),
    });
  }

  Stream<User?> streamUser(String uid) {
    return _firestore
        .streamCollection(_collection, where: [
          ['uid', '==', uid],
        ])
        .map((docs) => docs.isEmpty ? null : User.fromJson(docs.first));
  }
}
