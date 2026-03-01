import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/isometric_math.dart';
import '../models/building.dart';
import '../models/building_catalog.dart';
import '../repositories/building_repository.dart';
import '../repositories/user_repository.dart';
import '../services/building_service.dart';
import '../services/firestore_service.dart';

class CityViewModel extends ChangeNotifier {
  final BuildingRepository _buildingRepository;
  final BuildingService _buildingService;
  final UserRepository _userRepository;

  StreamSubscription<List<Building>>? _buildingsSub;

  /// All buildings owned by the current user.
  List<Building> buildings = [];

  /// Fast lookup: grid position → Building.
  final Map<(int, int), Building> gridMap = {};

  /// Currently selected tile for UI highlighting.
  (int, int)? selectedTile;

  /// Whether the catalog has been loaded.
  bool catalogLoaded = false;

  /// Available building definitions from the catalog.
  List<BuildingDefinition> catalog = [];

  /// Loading state.
  bool isLoading = false;

  CityViewModel(
    this._buildingRepository,
    this._buildingService,
    this._userRepository,
  );

  /// Initialize by loading the catalog and subscribing to the user's buildings.
  Future<void> init(String userId) async {
    isLoading = true;
    notifyListeners();

    // Load building catalog from JSON asset.
    if (!catalogLoaded) {
      catalog = await BuildingCatalog.loadAll();
      catalogLoaded = true;
    }

    // Subscribe to the user's building stream.
    await _buildingsSub?.cancel();
    _buildingsSub = _buildingRepository.streamBuildings(userId).listen(
      (list) {
        buildings = list;
        _rebuildGridMap();
        isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming buildings: $error');
        isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Rebuild the gridMap from the current buildings list.
  void _rebuildGridMap() {
    gridMap.clear();
    for (final b in buildings) {
      if (b.isPlaced) {
        gridMap[(b.gridRow!, b.gridCol!)] = b;
      }
    }
  }

  /// Select a tile on the grid. Returns the action the UI should take.
  TileAction selectTile(int row, int col) {
    if (!isValidTile(row, col)) return TileAction.none;

    selectedTile = (row, col);
    notifyListeners();

    final existing = gridMap[(row, col)];
    if (existing != null) {
      return TileAction.showInfo;
    } else {
      return TileAction.showShop;
    }
  }

  /// Clear the current tile selection.
  void clearSelection() {
    selectedTile = null;
    notifyListeners();
  }

  /// Get the building at the selected tile (if any).
  Building? get selectedBuilding {
    if (selectedTile == null) return null;
    return gridMap[selectedTile!];
  }

  /// Check if a tile is occupied.
  bool isTileOccupied(int row, int col) {
    return gridMap.containsKey((row, col));
  }

  /// Purchase a building from the catalog and place it on the selected tile.
  Future<bool> purchaseBuilding(
    String userId,
    BuildingDefinition definition,
    int row,
    int col,
  ) async {
    // Verify tile is valid and empty.
    if (!isValidTile(row, col) || isTileOccupied(row, col)) return false;

    // Check user has enough coins.
    final user = await _userRepository.getUser(userId);
    if (user == null) return false;
    if (!_buildingService.canPurchase(definition, user.coins)) return false;

    // Create the building.
    final now = DateTime.now();
    final buildingId = '${userId}_${definition.type}_${now.millisecondsSinceEpoch}';
    final building = _buildingService.createFromDefinition(
      definition,
      userId,
      row,
      col,
      buildingId,
    );

    // Save to Firestore.
    await _buildingRepository.createBuilding(building);

    // Deduct coins.
    await _userRepository.addExpAndCoins(userId, 0, -definition.purchasePrice);

    return true;
  }

  /// Upgrade an existing building.
  Future<bool> upgradeBuilding(String userId, Building building) async {
    final user = await _userRepository.getUser(userId);
    if (user == null) return false;
    if (!_buildingService.canUpgrade(building, user.coins)) return false;

    final upgraded = _buildingService.upgrade(building);
    await _buildingRepository.upgradeBuilding(
      userId,
      building.id,
      upgraded.level,
      upgraded.coinsToNextLevel,
    );

    // Deduct coins.
    await _userRepository.addExpAndCoins(
      userId,
      0,
      -building.coinsToNextLevel,
    );

    return true;
  }

  /// Get the scale factor for a building based on its level.
  static double levelScale(int level) {
    switch (level) {
      case 1:
        return 0.7;
      case 2:
        return 0.8;
      case 3:
        return 0.9;
      case 4:
        return 1.0;
      case 5:
        return 1.1;
      default:
        return 0.7;
    }
  }

  @override
  void dispose() {
    _buildingsSub?.cancel();
    super.dispose();
  }
}

/// Actions the UI should take after selecting a tile.
enum TileAction { none, showShop, showInfo }

final cityViewModelProvider = ChangeNotifierProvider<CityViewModel>((ref) {
  final firestore = FirestoreService();
  return CityViewModel(
    BuildingRepository(firestore),
    BuildingService(),
    UserRepository(firestore),
  );
});
