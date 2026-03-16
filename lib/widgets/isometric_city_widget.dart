import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/isometric_math.dart';
import '../models/building.dart';
import '../models/building_catalog.dart';
import '../viewmodels/city_view_model.dart';
import 'building_info_sheet.dart';
import 'building_shop_sheet.dart';
import 'isometric_grid_painter.dart';

/// Main isometric city widget.
///
/// Uses [InteractiveViewer] for pan/zoom over a [Stack] composed of:
/// - [CustomPaint] for the ground grid
/// - [Positioned] [Image.asset] for each building
///
/// Tap detection converts screen coordinates to grid positions and opens
/// the shop (empty tile) or building info (occupied tile).
///
/// When in **move mode**, a banner appears at the top and the next tap
/// relocates the building being moved.
class IsometricCityWidget extends ConsumerStatefulWidget {
  const IsometricCityWidget({super.key});

  @override
  ConsumerState<IsometricCityWidget> createState() =>
      _IsometricCityWidgetState();
}

class _IsometricCityWidgetState extends ConsumerState<IsometricCityWidget> {
  String get _uid => fb.FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_uid.isNotEmpty) {
        ref.read(cityViewModelProvider).init(_uid);
      }
    });
  }

  // ─── Tap handling ───────────────────────────────────────────────────

  void _onTapUp(TapUpDetails details) {
    final localPosition = details.localPosition;
    final (row, col) = screenToGrid(localPosition);

    if (!isValidTile(row, col)) {
      final cityVM = ref.read(cityViewModelProvider);
      if (cityVM.isMoving) {
        // Tap outside grid while moving → cancel.
        cityVM.cancelMove();
        _showSnack('Move cancelled');
      } else {
        cityVM.clearSelection();
      }
      return;
    }

    final action = ref.read(cityViewModelProvider).selectTile(row, col);

    switch (action) {
      case TileAction.showShop:
        _showShop(row, col);
      case TileAction.showInfo:
        final building = ref.read(cityViewModelProvider).selectedBuilding;
        if (building != null) {
          _showBuildingInfo(building);
        }
      case TileAction.completeMove:
        _handleCompleteMove(row, col);
      case TileAction.none:
        break;
    }
  }

  // ─── Complete move ──────────────────────────────────────────────────

  Future<void> _handleCompleteMove(int row, int col) async {
    final cityVM = ref.read(cityViewModelProvider);
    final building = cityVM.movingBuilding;
    if (building == null) return;

    final success = await cityVM.completeMove(row, col);

    if (!mounted) return;

    if (success) {
      _showSnack('${building.name} moved!');
    } else {
      _showSnack('Cannot place here — not enough space');
    }
  }

  // ─── Show shop ──────────────────────────────────────────────────────

  void _showShop(int row, int col) {
    final cityVM = ref.read(cityViewModelProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BuildingShopSheet(
        catalog: cityVM.catalog,
        userId: _uid,
        gridRow: row,
        gridCol: col,
        stockedBuildings: cityVM.stockedBuildings,
      ),
    ).then((_) {
      ref.read(cityViewModelProvider).clearSelection();
    });
  }

  // ─── Show building info ─────────────────────────────────────────────

  void _showBuildingInfo(Building building) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BuildingInfoSheet(
        building: building,
        userId: _uid,
        onMove: () {
          // Close the sheet first, then enter move mode.
          Navigator.of(context).pop();
          ref.read(cityViewModelProvider).startMove(building);
          _showSnack('Tap a tile to move ${building.name}');
        },
        onRemove: () {
          // Close the sheet, unplace the building.
          Navigator.of(context).pop();
          ref.read(cityViewModelProvider).unplaceBuilding(building);
          _showSnack('${building.name} moved to stock');
        },
      ),
    ).then((_) {
      ref.read(cityViewModelProvider).clearSelection();
    });
  }

  // ─── Snackbar helper ────────────────────────────────────────────────

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cityVM = ref.watch(cityViewModelProvider);

    if (cityVM.isLoading && cityVM.buildings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Collect occupied tile positions for the painter (includes multi-tile).
    final occupiedTiles = <(int, int)>{};
    for (final b in cityVM.buildings) {
      if (b.isPlaced) {
        final def = BuildingCatalog.getByType(b.type);
        final tR = def?.tileRows ?? 1;
        final tC = def?.tileCols ?? 1;
        for (int r = b.gridRow!; r < b.gridRow! + tR; r++) {
          for (int c = b.gridCol!; c < b.gridCol! + tC; c++) {
            occupiedTiles.add((r, c));
          }
        }
      }
    }

    // Sort buildings by depth for correct Z-ordering.
    // Multi-tile buildings use the bottom-right corner for depth.
    final sortedBuildings = cityVM.buildings
        .where((b) => b.isPlaced)
        .toList()
      ..sort((a, b) {
        final defA = BuildingCatalog.getByType(a.type);
        final defB = BuildingCatalog.getByType(b.type);
        final depthA =
            a.gridRow! + a.gridCol! + (defA?.tileRows ?? 1) + (defA?.tileCols ?? 1);
        final depthB =
            b.gridRow! + b.gridCol! + (defB?.tileRows ?? 1) + (defB?.tileCols ?? 1);
        return depthA.compareTo(depthB);
      });

    return Stack(
      children: [
        // ─── Main isometric view (pannable / zoomable) ──────────────
        InteractiveViewer(
          constrained: false,
          boundaryMargin: const EdgeInsets.all(100),
          minScale: 0.5,
          maxScale: 2.5,
          child: GestureDetector(
            onTapUp: _onTapUp,
            child: SizedBox(
              width: canvasWidth,
              height: canvasHeight,
              child: Stack(
                children: [
                  // Ground grid layer.
                  CustomPaint(
                    size: Size(canvasWidth, canvasHeight),
                    painter: IsometricGridPainter(
                      occupiedTiles: occupiedTiles,
                      selectedTile: cityVM.selectedTile,
                    ),
                  ),

                  // Building sprites layer.
                  ...sortedBuildings
                      .map((building) => _buildBuildingSprite(building, cityVM)),
                ],
              ),
            ),
          ),
        ),

        // ─── Move mode banner (overlays the city) ───────────────────
        if (cityVM.isMoving) _buildMoveBanner(cityVM),
      ],
    );
  }

  // ─── Building sprite ────────────────────────────────────────────────

  Widget _buildBuildingSprite(Building building, CityViewModel cityVM) {
    final pos = gridToScreen(building.gridRow!, building.gridCol!);
    final scale = CityViewModel.levelScale(building.level);
    final isMaxLevel = building.level >= 5;

    // Get tile dimensions from catalog.
    final def = BuildingCatalog.getByType(building.type);
    final tR = def?.tileRows ?? 1;
    final tC = def?.tileCols ?? 1;

    // Sprite width proportional to footprint, height from aspect ratio.
    final footprintFactor = (tR + tC) / 2.0;
    const baseSize = 64.0;
    final scaledWidth = baseSize * footprintFactor * scale;
    final heightRatio = def?.heightRatio ?? 1.0;
    final scaledHeight = scaledWidth * heightRatio;

    // Diamond center X offset for asymmetric footprints.
    final centerOffsetX = (tC - tR) * tileWidth / 4;

    // Diamond bottom Y of the multi-tile footprint.
    final diamondBottomY = pos.dy + (tC + tR) * tileHeight / 2;

    // Position so the sprite bottom aligns with the diamond bottom.
    final left = pos.dx + centerOffsetX - scaledWidth / 2;
    final top = diamondBottomY - scaledHeight;

    // Dim the building being moved to indicate it's "picked up".
    final isBeingMoved =
        cityVM.isMoving && cityVM.movingBuilding?.id == building.id;

    return Positioned(
      left: left,
      top: top,
      child: Opacity(
        opacity: isBeingMoved ? 0.4 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Building image with optional golden glow for max level.
            Container(
              width: scaledWidth,
              height: scaledHeight,
              decoration: isMaxLevel && !isBeingMoved
                  ? BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    )
                  : null,
              child: Image.asset(
                building.imagePath,
                width: scaledWidth,
                height: scaledHeight,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: scaledWidth,
                  height: scaledHeight,
                  color: Colors.grey.withValues(alpha: 0.5),
                  child: const Icon(Icons.home, color: Colors.white),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  // ─── Move mode banner ───────────────────────────────────────────────

  Widget _buildMoveBanner(CityViewModel cityVM) {
    return Positioned(
      bottom: 80,
      left: 24,
      right: 24,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        color: Colors.blue.shade700,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.open_with, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tap a tile to move ${cityVM.movingBuilding?.name ?? "building"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  cityVM.cancelMove();
                  _showSnack('Move cancelled');
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
