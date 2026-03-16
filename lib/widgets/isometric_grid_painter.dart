import 'package:flutter/material.dart';

import '../helpers/isometric_math.dart';

/// CustomPainter that draws an 8×8 isometric diamond grid.
///
/// Tiles are colored to represent grass land. Occupied tiles get a slightly
/// different shade, and the selected tile gets a highlight border.
class IsometricGridPainter extends CustomPainter {
  /// Set of grid positions that have buildings placed on them.
  final Set<(int, int)> occupiedTiles;

  /// Currently selected / highlighted tile, if any.
  final (int, int)? selectedTile;

  IsometricGridPainter({
    this.occupiedTiles = const {},
    this.selectedTile,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final grassPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF7EC850); // bright grass green

    final occupiedPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF6AB340); // slightly darker for occupied

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF5A9E38)
      ..strokeWidth = 0.8;

    final selectedBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 2.5;

    final selectedFillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.25);

    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        final path = getTilePath(row, col);
        final isOccupied = occupiedTiles.contains((row, col));
        final isSelected = selectedTile == (row, col);

        // Fill tile.
        canvas.drawPath(path, isOccupied ? occupiedPaint : grassPaint);

        // Border.
        canvas.drawPath(path, borderPaint);

        // Selection highlight.
        if (isSelected) {
          canvas.drawPath(path, selectedFillPaint);
          canvas.drawPath(path, selectedBorderPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant IsometricGridPainter oldDelegate) {
    return occupiedTiles != oldDelegate.occupiedTiles ||
        selectedTile != oldDelegate.selectedTile;
  }
}
