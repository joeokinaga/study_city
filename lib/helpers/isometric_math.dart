import 'dart:ui';

/// Constants for the isometric grid.
const double tileWidth = 64.0;
const double tileHeight = 32.0;
const int gridRows = 8;
const int gridCols = 8;

/// Extra vertical space above the grid origin so buildings don't clip.
/// Tall buildings (e.g. Office Tower, heightRatio 2.0) need extra headroom.
const double gridOffsetY = 200.0;

/// Horizontal center offset for the grid canvas.
double get gridOffsetX => (gridRows + gridCols) * tileWidth / 4;

/// Total canvas size needed to contain the full isometric grid + buildings.
double get canvasWidth => (gridRows + gridCols) * tileWidth / 2 + tileWidth;
double get canvasHeight =>
    (gridRows + gridCols) * tileHeight / 2 + gridOffsetY + 80;

/// Convert grid coordinates (row, col) to screen pixel position.
///
/// The returned [Offset] represents the top-center of the diamond tile,
/// suitable for positioning buildings or drawing tile paths.
Offset gridToScreen(int row, int col) {
  final x = (col - row) * (tileWidth / 2) + gridOffsetX;
  final y = (col + row) * (tileHeight / 2) + gridOffsetY;
  return Offset(x, y);
}

/// Convert a screen tap position back to grid coordinates.
///
/// Returns a record `(row, col)`. The caller should validate the result
/// with [isValidTile] since the tap may land outside the grid.
(int row, int col) screenToGrid(Offset screenPoint) {
  final dx = screenPoint.dx - gridOffsetX;
  final dy = screenPoint.dy - gridOffsetY;

  final col = (dx / (tileWidth / 2) + dy / (tileHeight / 2)) / 2;
  final row = (dy / (tileHeight / 2) - dx / (tileWidth / 2)) / 2;
  return (row.floor(), col.floor());
}

/// Whether the given grid coordinates are within the valid range.
bool isValidTile(int row, int col) {
  return row >= 0 && row < gridRows && col >= 0 && col < gridCols;
}

/// Build a diamond [Path] for the tile at (row, col).
///
/// The diamond has four points: top, right, bottom, left.
Path getTilePath(int row, int col) {
  final center = gridToScreen(row, col);
  final path = Path()
    ..moveTo(center.dx, center.dy) // top
    ..lineTo(center.dx + tileWidth / 2, center.dy + tileHeight / 2) // right
    ..lineTo(center.dx, center.dy + tileHeight) // bottom
    ..lineTo(center.dx - tileWidth / 2, center.dy + tileHeight / 2) // left
    ..close();
  return path;
}

// ─── Multi-tile helpers ────────────────────────────────────────────────

/// Screen-space center X of a multi-tile diamond footprint anchored at
/// (row, col) with size (tileRows, tileCols).
double multiTileCenterX(int row, int col, int tileRows, int tileCols) {
  final anchor = gridToScreen(row, col);
  return anchor.dx + (tileCols - tileRows) * tileWidth / 4;
}

/// Screen-space Y of the bottom vertex of a multi-tile diamond footprint.
double multiTileBottomY(int row, int col, int tileRows, int tileCols) {
  final anchor = gridToScreen(row, col);
  return anchor.dy + (tileCols + tileRows) * tileHeight / 2;
}

/// Whether **all** tiles required by a multi-tile building starting at
/// (row, col) with size (tileRows, tileCols) are within the grid bounds.
bool canFitMultiTile(int row, int col, int tileRows, int tileCols) {
  for (int r = row; r < row + tileRows; r++) {
    for (int c = col; c < col + tileCols; c++) {
      if (!isValidTile(r, c)) return false;
    }
  }
  return true;
}
