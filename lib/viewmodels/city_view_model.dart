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
  ///
  /// For multi-tile buildings every occupied tile maps to the same [Building].
  final Map<(int, int), Building> gridMap = {};

  /// Currently selected tile for UI highlighting.
  (int, int)? selectedTile;

  /// Whether the catalog has been loaded.
  bool catalogLoaded = false;

  /// Available building definitions from the catalog.
  List<BuildingDefinition> catalog = [];

  /// Loading state.
  bool isLoading = false;

  // ─── Move mode ──────────────────────────────────────────────────────

  /// The building currently being moved, or `null` when not in move mode.
  Building? movingBuilding;

  /// Whether the view-model is in *move-mode* (the user is picking a
  /// destination tile for [movingBuilding]).
  bool get isMoving => movingBuilding != null;

  // ─── Stock (inventory) ──────────────────────────────────────────────

  /// Buildings that the user owns but are **not** placed on the grid.
  List<Building> get stockedBuildings =>
      buildings.where((b) => !b.isPlaced).toList();

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
  ///
  /// Multi-tile buildings occupy every tile in their footprint.
  void _rebuildGridMap() {
    gridMap.clear();
    for (final b in buildings) {
      if (b.isPlaced) {
        final def = BuildingCatalog.getByType(b.type);
        final tR = def?.tileRows ?? 1;
        final tC = def?.tileCols ?? 1;
        for (int r = b.gridRow!; r < b.gridRow! + tR; r++) {
          for (int c = b.gridCol!; c < b.gridCol! + tC; c++) {
            gridMap[(r, c)] = b;
          }
        }
      }
    }
  }

  // ─── Tile selection ─────────────────────────────────────────────────

  /// Select a tile on the grid. Returns the action the UI should take.
  ///
  /// When in move mode the method returns [TileAction.completeMove] if the
  /// tapped tile is a valid destination for the building being moved.
  TileAction selectTile(int row, int col) {
    if (!isValidTile(row, col)) return TileAction.none;

    // ── Move mode: try to complete the move. ──
    if (isMoving) {
      selectedTile = (row, col);
      notifyListeners();
      return TileAction.completeMove;
    }

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

  /// Check whether a building definition can fit at (row, col).
  ///
  /// [exclude] is an optional building whose current tiles should be treated
  /// as free (used when moving a building to a new position).
  bool canPlaceBuilding(
    BuildingDefinition definition,
    int row,
    int col, {
    Building? exclude,
  }) {
    for (int r = row; r < row + definition.tileRows; r++) {
      for (int c = col; c < col + definition.tileCols; c++) {
        if (!isValidTile(r, c)) return false;
        final occupant = gridMap[(r, c)];
        if (occupant != null && occupant.id != exclude?.id) return false;
      }
    }
    return true;
  }

  // ─── Move mode ──────────────────────────────────────────────────────

  /// Enter move mode for the given [building].
  void startMove(Building building) {
    movingBuilding = building;
    selectedTile = null;
    notifyListeners();
  }

  /// Cancel move mode without changing anything.
  void cancelMove() {
    movingBuilding = null;
    selectedTile = null;
    notifyListeners();
  }

  /// Complete a move: place [movingBuilding] at (row, col).
  ///
  /// Returns `true` on success, `false` if the destination is invalid.
  Future<bool> completeMove(int row, int col) async {
    final building = movingBuilding;
    if (building == null) return false;

    final def = BuildingCatalog.getByType(building.type);
    if (def == null) return false;

    // Validate: all tiles free (excluding the building's own current tiles).
    if (!canPlaceBuilding(def, row, col, exclude: building)) return false;

    // Update position in Firestore.
    await _buildingRepository.updateBuildingPosition(building.id, row, col);

    movingBuilding = null;
    selectedTile = null;
    notifyListeners();
    return true;
  }

  // ─── Stock / inventory ──────────────────────────────────────────────

  /// Remove a building from the grid and put it into stock.
  Future<void> unplaceBuilding(Building building) async {
    await _buildingRepository.unplaceBuilding(building.id);
  }

  /// Place a stocked (un-placed) building onto the grid at (row, col).
  ///
  /// Returns `true` on success.
  Future<bool> placeStockedBuilding(Building building, int row, int col) async {
    final def = BuildingCatalog.getByType(building.type);
    if (def == null) return false;

    if (!canPlaceBuilding(def, row, col)) return false;

    await _buildingRepository.updateBuildingPosition(building.id, row, col);
    return true;
  }

  // ─── Purchase ───────────────────────────────────────────────────────

  /// Purchase a building from the catalog and place it on the selected tile.
  Future<bool> purchaseBuilding(
    String userId,
    BuildingDefinition definition,
    int row,
    int col,
  ) async {
    // Verify all tiles are valid and empty.
    if (!canPlaceBuilding(definition, row, col)) return false;

    // Check user has enough coins.
    final user = await _userRepository.getUser(userId);
    if (user == null) return false;
    if (!_buildingService.canPurchase(definition, user.coins)) return false;

    // Create the building.
    final now = DateTime.now();
    final buildingId =
        '${userId}_${definition.type}_${now.millisecondsSinceEpoch}';
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

  // ─── Upgrade ────────────────────────────────────────────────────────

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
  ///
  /// Buildings fill their tiles tightly even at level 1.
  static double levelScale(int level) {
    switch (level) {
      case 1:
        return 0.90;
      case 2:
        return 0.95;
      case 3:
        return 1.00;
      case 4:
        return 1.05;
      case 5:
        return 1.10;
      default:
        return 0.90;
    }
  }

  @override
  void dispose() {
    _buildingsSub?.cancel();
    super.dispose();
  }
}

/// Actions the UI should take after selecting a tile.
enum TileAction { none, showShop, showInfo, completeMove }

final cityViewModelProvider = ChangeNotifierProvider<CityViewModel>((ref) {
  final firestore = FirestoreService();
  return CityViewModel(
    BuildingRepository(firestore),
    BuildingService(),
    UserRepository(firestore),
  );
});
