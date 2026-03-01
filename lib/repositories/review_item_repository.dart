import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/review_item.dart';
import '../services/firestore_service.dart';

class ReviewItemRepository {
  final FirestoreService _firestore;
  static const _collection = 'review_items';

  ReviewItemRepository(this._firestore);

  Future<void> saveReviewItem(ReviewItem item) async {
    await _firestore.setDocument(_collection, item.id, item.toJson());
  }

  Future<void> updateReviewItem(ReviewItem item) async {
    await _firestore.updateDocument(_collection, item.id, item.toJson());
  }

  Future<void> deleteReviewItem(String userId, String itemId) async {
    await _firestore.deleteDocument(_collection, itemId);
  }

  Future<List<ReviewItem>> getTodayReviewItems(String userId) async {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final docs = await _firestore.queryCollection(
      _collection,
      where: [
        ['userId', '==', userId],
        ['nextReviewDate', '<=', Timestamp.fromDate(endOfToday)],
      ],
      orderBy: 'nextReviewDate',
    );
    return docs.map((d) => ReviewItem.fromJson(d)).toList();
  }

  Stream<List<ReviewItem>> streamReviewItems(String userId) {
    return _firestore
        .streamCollection(
          _collection,
          where: [
            ['userId', '==', userId],
          ],
          orderBy: 'nextReviewDate',
        )
        .map((docs) => docs.map((d) => ReviewItem.fromJson(d)).toList());
  }
}
