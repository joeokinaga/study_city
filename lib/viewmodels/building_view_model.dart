import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/building.dart';
import '../repositories/building_repository.dart';
import '../repositories/user_repository.dart';
import '../services/building_service.dart';
import '../services/firestore_service.dart';

class BuildingViewModel extends ChangeNotifier {
  final BuildingService _buildingService;
  final BuildingRepository _buildingRepository;
  final UserRepository _userRepository;

  List<Building> buildings = [];
  bool isLoading = false;

  BuildingViewModel(
    this._buildingService,
    this._buildingRepository,
    this._userRepository,
  );

  Stream<List<Building>> streamBuildings(String userId) {
    return _buildingRepository.streamBuildings(userId);
  }

  Future<bool> upgradeBuilding(String userId, Building building) async {
    final user = await _userRepository.getUser(userId);
    if (user == null) return false;

    if (!_buildingService.canUpgrade(building, user.coins)) {
      return false;
    }

    final upgraded = _buildingService.upgrade(building);
    await _buildingRepository.upgradeBuilding(
      userId,
      building.id,
      upgraded.level,
      upgraded.coinsToNextLevel,
    );

    // Deduct coins
    await _userRepository.addExpAndCoins(
      userId,
      0,
      -building.coinsToNextLevel,
    );

    notifyListeners();
    return true;
  }
}

final buildingViewModelProvider =
    ChangeNotifierProvider<BuildingViewModel>((ref) {
  final firestore = FirestoreService();
  return BuildingViewModel(
    BuildingService(),
    BuildingRepository(firestore),
    UserRepository(firestore),
  );
});
