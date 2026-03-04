import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// A single building type definition from the catalog.
class BuildingDefinition {
  final String type;
  final String name;
  final int purchasePrice;
  final String description;

  /// Number of grid rows this building occupies.
  final int tileRows;

  /// Number of grid columns this building occupies.
  final int tileCols;

  /// Image height-to-width ratio for correct aspect-ratio rendering.
  final double heightRatio;

  const BuildingDefinition({
    required this.type,
    required this.name,
    required this.purchasePrice,
    required this.description,
    this.tileRows = 1,
    this.tileCols = 1,
    this.heightRatio = 1.0,
  });

  /// Path to the building's image asset.
  String get imagePath => 'assets/buildings/$type.png';

  /// The footprint scale factor relative to a 1×1 building.
  double get footprintFactor => (tileRows + tileCols) / 2.0;

  /// Total tiles occupied by this building.
  int get totalTiles => tileRows * tileCols;

  /// Human-readable tile size label (e.g. "1×1", "2×2").
  String get sizeLabel => '$tileRows×$tileCols';

  factory BuildingDefinition.fromJson(Map<String, dynamic> json) {
    return BuildingDefinition(
      type: json['type'] as String,
      name: json['name'] as String,
      purchasePrice: json['price'] as int,
      description: json['description'] as String,
      tileRows: json['tileRows'] as int? ?? 1,
      tileCols: json['tileCols'] as int? ?? 1,
      heightRatio: (json['heightRatio'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Static catalog of all available building types.
///
/// Loads building definitions from a JSON asset file, allowing future
/// editor UI to modify the catalog without code changes.
class BuildingCatalog {
  static List<BuildingDefinition>? _cache;

  /// Load all building definitions from the JSON asset.
  static Future<List<BuildingDefinition>> loadAll() async {
    if (_cache != null) return _cache!;
    final jsonString =
        await rootBundle.loadString('assets/data/building_catalog.json');
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    _cache = jsonList
        .map((e) => BuildingDefinition.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  /// Get a building definition by its type identifier.
  static BuildingDefinition? getByType(String type) {
    if (_cache == null) return null;
    return _cache!.where((d) => d.type == type).firstOrNull;
  }

  /// Get the image path for a building type (fallback for legacy data).
  static String imagePathForType(String type) {
    return 'assets/buildings/$type.png';
  }
}
