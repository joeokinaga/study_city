import '../models/building.dart';
import '../models/building_catalog.dart';

class BuildingService {
  /// Maximum building level.
  static const int maxLevel = 5;

  /// Check if the user has enough coins to upgrade this building.
  bool canUpgrade(Building building, int userCoins) {
    if (building.level >= maxLevel) return false;
    return userCoins >= building.coinsToNextLevel;
  }

  /// Upgrade a building: level + 1, next cost = newLevel * 100 + 200.
  Building upgrade(Building building) {
    final newLevel = building.level + 1;
    return building.copyWith(
      level: newLevel,
      coinsToNextLevel: newLevel * 100 + 200,
    );
  }

  /// Check if the user has enough coins to purchase a building.
  bool canPurchase(BuildingDefinition definition, int userCoins) {
    return userCoins >= definition.purchasePrice;
  }

  /// Create a new [Building] instance from a catalog definition.
  Building createFromDefinition(
    BuildingDefinition definition,
    String userId,
    int gridRow,
    int gridCol,
    String buildingId,
  ) {
    return Building(
      id: buildingId,
      userId: userId,
      name: definition.name,
      type: definition.type,
      level: 1,
      coinsToNextLevel: 2 * 100 + 200, // cost to reach level 2 = 400
      description: definition.description,
      gridRow: gridRow,
      gridCol: gridCol,
    );
  }
}
