import '../models/building.dart';
import '../services/firestore_service.dart';

class BuildingRepository {
  final FirestoreService _firestore;
  static const _collection = 'buildings';

  BuildingRepository(this._firestore);

  /// Create a new building document in Firestore.
  Future<void> createBuilding(Building building) async {
    await _firestore.setDocument(_collection, building.id, building.toJson());
  }

  /// Update an existing building's level and upgrade cost.
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

  /// Update a building's grid position.
  Future<void> updateBuildingPosition(
    String buildingId,
    int row,
    int col,
  ) async {
    await _firestore.updateDocument(_collection, buildingId, {
      'gridRow': row,
      'gridCol': col,
    });
  }

  /// Delete a building document from Firestore.
  Future<void> deleteBuilding(String buildingId) async {
    await _firestore.deleteDocument(_collection, buildingId);
  }

  /// Stream all buildings for a given user.
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

  /// Initialize default buildings for a new user.
  ///
  /// Deprecated: New users start with an empty city and buy buildings
  /// from the shop instead.
  @Deprecated('Use the shop system to purchase buildings instead')
  Future<void> initializeBuildings(String userId) async {
    // Kept for backward compatibility only.
  }
}
