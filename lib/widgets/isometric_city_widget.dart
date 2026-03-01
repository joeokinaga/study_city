import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/isometric_math.dart';
import '../models/building.dart';
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

  void _onTapUp(TapUpDetails details) {
    final localPosition = details.localPosition;
    final (row, col) = screenToGrid(localPosition);

    if (!isValidTile(row, col)) {
      ref.read(cityViewModelProvider).clearSelection();
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
      case TileAction.none:
        break;
    }
  }

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
      ),
    ).then((_) {
      ref.read(cityViewModelProvider).clearSelection();
    });
  }

  void _showBuildingInfo(Building building) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BuildingInfoSheet(
        building: building,
        userId: _uid,
      ),
    ).then((_) {
      ref.read(cityViewModelProvider).clearSelection();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cityVM = ref.watch(cityViewModelProvider);

    if (cityVM.isLoading && cityVM.buildings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Collect occupied tile positions for the painter.
    final occupiedTiles = <(int, int)>{};
    for (final b in cityVM.buildings) {
      if (b.isPlaced) {
        occupiedTiles.add((b.gridRow!, b.gridCol!));
      }
    }

    // Sort buildings by depth (row + col) for correct Z-ordering.
    final sortedBuildings = cityVM.buildings
        .where((b) => b.isPlaced)
        .toList()
      ..sort((a, b) => (a.gridRow! + a.gridCol!)
          .compareTo(b.gridRow! + b.gridCol!));

    return InteractiveViewer(
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
              ...sortedBuildings.map((building) => _buildBuildingSprite(building)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuildingSprite(Building building) {
    final pos = gridToScreen(building.gridRow!, building.gridCol!);
    final scale = CityViewModel.levelScale(building.level);
    final isMaxLevel = building.level >= 5;

    // Building image size (base 64x64, matching tile width).
    const baseSize = 64.0;
    final scaledSize = baseSize * scale;

    // Position the building image so it sits centered on the tile.
    // The gridToScreen returns the top-center of the diamond.
    final left = pos.dx - scaledSize / 2;
    final top = pos.dy - scaledSize + tileHeight; // sit on the tile surface

    return Positioned(
      left: left,
      top: top,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Building image with optional golden glow for max level.
          Container(
            width: scaledSize,
            height: scaledSize,
            decoration: isMaxLevel
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
              width: scaledSize,
              height: scaledSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: scaledSize,
                height: scaledSize,
                color: Colors.grey.withValues(alpha: 0.5),
                child: const Icon(Icons.home, color: Colors.white),
              ),
            ),
          ),

          // Level badge below the building.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isMaxLevel
                  ? Colors.amber
                  : Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isMaxLevel ? 'MAX' : 'Lv.${building.level}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
