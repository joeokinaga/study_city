import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> setDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    await _db.collection(collection).doc(id).set(data);
  }

  Future<void> updateDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    await _db.collection(collection).doc(id).update(data);
  }

  Future<void> deleteDocument(String collection, String id) async {
    await _db.collection(collection).doc(id).delete();
  }

  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String id,
  ) async {
    final doc = await _db.collection(collection).doc(id).get();
    return doc.data();
  }

  Stream<List<Map<String, dynamic>>> streamCollection(
    String collection, {
    List<List<dynamic>>? where,
    String? orderBy,
    bool descending = false,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(collection);
    query = _applyFilters(query, where: where, orderBy: orderBy, descending: descending);
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
    );
  }

  Future<List<Map<String, dynamic>>> queryCollection(
    String collection, {
    List<List<dynamic>>? where,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _db.collection(collection);
    query = _applyFilters(query, where: where, orderBy: orderBy, descending: descending);
    if (limit != null) query = query.limit(limit);
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Query<Map<String, dynamic>> _applyFilters(
    Query<Map<String, dynamic>> query, {
    List<List<dynamic>>? where,
    String? orderBy,
    bool descending = false,
  }) {
    if (where != null) {
      for (final condition in where) {
        final field = condition[0] as String;
        final operator = condition[1] as String;
        final value = condition[2];
        switch (operator) {
          case '==':
            query = query.where(field, isEqualTo: value);
          case '<':
            query = query.where(field, isLessThan: value);
          case '<=':
            query = query.where(field, isLessThanOrEqualTo: value);
          case '>':
            query = query.where(field, isGreaterThan: value);
          case '>=':
            query = query.where(field, isGreaterThanOrEqualTo: value);
          case 'array-contains':
            query = query.where(field, arrayContains: value);
        }
      }
    }
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    return query;
  }
}
