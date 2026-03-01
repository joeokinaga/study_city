import '../models/building.dart';
import '../services/firestore_service.dart';

class BuildingRepository {
  final FirestoreService _firestore;
  static const _collection = 'buildings';

  static const _initialBuildings = [
    {'name': '図書館', 'type': 'library', 'description': '学習効率がアップする静かな空間'},
    {'name': '食堂', 'type': 'cafeteria', 'description': '仲間と交流できる憩いの場'},
    {'name': '体育館', 'type': 'gym', 'description': '集中力を高める運動施設'},
    {'name': '美術室', 'type': 'art_room', 'description': '創造力を刺激するアトリエ'},
    {'name': '理科室', 'type': 'science_lab', 'description': '実験と発見の場'},
  ];

  BuildingRepository(this._firestore);

  Future<void> initializeBuildings(String userId) async {
    for (var i = 0; i < _initialBuildings.length; i++) {
      final def = _initialBuildings[i];
      final id = '${userId}_${def['type']}';
      final building = Building(
        id: id,
        userId: userId,
        name: def['name']!,
        type: def['type']!,
        level: 1,
        coinsToNextLevel: 100,
        description: def['description']!,
      );
      await _firestore.setDocument(_collection, id, building.toJson());
    }
  }

  Future<void> upgradeBuilding(
    String userId,
    String buildingId,
    int newLevel,
    int newCoinsRequired,
  ) async {
    await _firestore.updateDocument(_collection, buildingId, {
      'level': newLevel,
      'coinsToNextLevel': newCoinsRequired,
    });
  }

  Stream<List<Building>> streamBuildings(String userId) {
    return _firestore
        .streamCollection(
          _collection,
          where: [
            ['userId', '==', userId],
          ],
        )
        .map((docs) => docs.map((d) => Building.fromJson(d)).toList());
  }
}
