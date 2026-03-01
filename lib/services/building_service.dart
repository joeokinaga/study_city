import '../models/building.dart';

class BuildingService {
  bool canUpgrade(Building building, int userCoins) {
    return userCoins >= building.coinsToNextLevel;
  }

  /// Upgrade a building: level + 1, next cost = newLevel * 100 + 200
  Building upgrade(Building building) {
    final newLevel = building.level + 1;
    return building.copyWith(
      level: newLevel,
      coinsToNextLevel: newLevel * 100 + 200,
    );
  }
}
