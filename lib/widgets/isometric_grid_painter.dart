import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../helpers/isometric_math.dart';

/// CustomPainter that draws the grass island surface with earth cliff
/// edges and the isometric tile grid.  Background is a flat dark-green
/// so nature-asset images (trees, rocks, etc.) fill the rest visually.
class IsometricGridPainter extends CustomPainter {
  final Set<(int, int)> occupiedTiles;
  final (int, int)? selectedTile;

  IsometricGridPainter({
    this.occupiedTiles = const {},
    this.selectedTile,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Flat natural background (dark forest green).
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF3B7A20),
    );

    _drawIsland(canvas);
    _drawGrid(canvas);
  }

  // ─── Grass island with earth cliff ───────────────────────────────────

  void _drawIsland(Canvas canvas) {
    final top = gridToScreen(0, 0);
    final right = gridToScreen(0, gridCols - 1);
    final bottom = gridToScreen(gridRows - 1, gridCols - 1);
    final left = gridToScreen(gridRows - 1, 0);

    const expand = 48.0;
    const cliffH = 36.0;

    final topPt = Offset(top.dx, top.dy - expand * 0.5);
    final rightPt =
        Offset(right.dx + tileWidth / 2 + expand, right.dy + tileHeight / 2);
    final bottomPt =
        Offset(bottom.dx, bottom.dy + tileHeight + expand * 0.5);
    final leftPt =
        Offset(left.dx - tileWidth / 2 - expand, left.dy + tileHeight / 2);

    // Right cliff face.
    final cliffRight = Path()
      ..moveTo(rightPt.dx, rightPt.dy)
      ..lineTo(bottomPt.dx, bottomPt.dy)
      ..lineTo(bottomPt.dx, bottomPt.dy + cliffH)
      ..lineTo(rightPt.dx, rightPt.dy + cliffH)
      ..close();
    canvas.drawPath(
      cliffRight,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(rightPt.dx, rightPt.dy),
          Offset(rightPt.dx, rightPt.dy + cliffH),
          [const Color(0xFF8B6B3D), const Color(0xFF5C4420)],
        ),
    );

    // Left cliff face.
    final cliffLeft = Path()
      ..moveTo(leftPt.dx, leftPt.dy)
      ..lineTo(bottomPt.dx, bottomPt.dy)
      ..lineTo(bottomPt.dx, bottomPt.dy + cliffH)
      ..lineTo(leftPt.dx, leftPt.dy + cliffH)
      ..close();
    canvas.drawPath(
      cliffLeft,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(leftPt.dx, leftPt.dy),
          Offset(leftPt.dx, leftPt.dy + cliffH),
          [const Color(0xFF7A5C30), const Color(0xFF4A3518)],
        ),
    );

    // Top grass surface.
    final islandPath = Path()
      ..moveTo(topPt.dx, topPt.dy)
      ..lineTo(rightPt.dx, rightPt.dy)
      ..lineTo(bottomPt.dx, bottomPt.dy)
      ..lineTo(leftPt.dx, leftPt.dy)
      ..close();

    canvas.drawPath(
      islandPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(topPt.dx, topPt.dy),
          Offset(bottomPt.dx, bottomPt.dy),
          [
            const Color(0xFF78C840),
            const Color(0xFF5AAE2E),
            const Color(0xFF4A9A24),
          ],
          [0.0, 0.5, 1.0],
        ),
    );

    // Edge outline.
    canvas.drawPath(
      islandPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF3D7A1C)
        ..strokeWidth = 1.2,
    );
  }

  // ─── Grid tiles ──────────────────────────────────────────────────────

  void _drawGrid(Canvas canvas) {
    final grassPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF7EC850);

    final occupiedPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF6AB340);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF5A9E38).withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

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

        canvas.drawPath(path, isOccupied ? occupiedPaint : grassPaint);
        canvas.drawPath(path, borderPaint);

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
