import 'dart:math';

import 'package:flutter/material.dart';

import '../helpers/isometric_math.dart';

/// A single decoration sprite to render.
class _DecoItem {
  final String asset;
  final double width;
  final double height;
  final double x;
  final double y;

  const _DecoItem({
    required this.asset,
    required this.width,
    required this.height,
    required this.x,
    required this.y,
  });
}

/// Densely fills the non-buildable area of the canvas with nature assets
/// (trees, bushes, rocks, flowers, logs) so the city feels embedded in a
/// forest clearing.  Items are placed on a jittered grid and filtered so
/// they never overlap the buildable tile area.
class NatureDecorationLayer extends StatelessWidget {
  const NatureDecorationLayer({super.key});

  // ── Asset pools ──────────────────────────────────────────────────────

  static const _trees = [
    ('assets/images/nature/pine_tree.png', 65.0, 120.0),
    ('assets/images/nature/tree.png', 90.0, 90.0),
    ('assets/images/nature/pine_tree_grass.png', 65.0, 120.0),
  ];

  static const _medium = [
    ('assets/images/nature/bush.png', 38.0, 30.0),
    ('assets/images/nature/shrub.png', 34.0, 24.0),
    ('assets/images/nature/rock1.png', 36.0, 32.0),
    ('assets/images/nature/rock2.png', 40.0, 30.0),
    ('assets/images/nature/log.png', 42.0, 30.0),
  ];

  static const _small = [
    ('assets/images/nature/flower1.png', 22.0, 20.0),
    ('assets/images/nature/flower2.png', 18.0, 18.0),
    ('assets/images/nature/flower3.png', 22.0, 20.0),
    ('assets/images/nature/shrub.png', 24.0, 16.0),
  ];

  // ── Helpers ──────────────────────────────────────────────────────────

  /// Returns true if (px, py) falls inside the buildable grid diamond
  /// (with a small margin so items don't clip into tiles).
  static bool _isInsideGrid(double px, double py) {
    final top = gridToScreen(0, 0);
    final right = gridToScreen(0, gridCols - 1);
    final bottom = gridToScreen(gridRows - 1, gridCols - 1);
    final left = gridToScreen(gridRows - 1, 0);

    // Expand the exclusion zone slightly so nothing overlaps the edge.
    const m = 30.0;
    final topPt = Offset(top.dx, top.dy - m);
    final rightPt =
        Offset(right.dx + tileWidth / 2 + m, right.dy + tileHeight / 2);
    final bottomPt =
        Offset(bottom.dx, bottom.dy + tileHeight + m);
    final leftPt =
        Offset(left.dx - tileWidth / 2 - m, left.dy + tileHeight / 2);

    // Point-in-diamond test using cross products.
    bool crossSign(Offset a, Offset b, Offset p) {
      return (b.dx - a.dx) * (p.dy - a.dy) -
              (b.dy - a.dy) * (p.dx - a.dx) >=
          0;
    }

    final p = Offset(px, py);
    final s1 = crossSign(topPt, rightPt, p);
    final s2 = crossSign(rightPt, bottomPt, p);
    final s3 = crossSign(bottomPt, leftPt, p);
    final s4 = crossSign(leftPt, topPt, p);
    return s1 == s2 && s2 == s3 && s3 == s4;
  }

  // ── Generate layout ──────────────────────────────────────────────────

  List<_DecoItem> _generate() {
    final rng = Random(77); // seeded for stable layout
    final items = <_DecoItem>[];

    final cw = canvasWidth;
    final ch = canvasHeight;

    // Step size for the placement grid.  Smaller = denser.
    const step = 38.0;

    for (double gy = 20; gy < ch - 10; gy += step) {
      for (double gx = 20; gx < cw - 10; gx += step) {
        // Jitter the position so it looks natural, not gridlike.
        final px = gx + rng.nextDouble() * step * 0.7 - step * 0.35;
        final py = gy + rng.nextDouble() * step * 0.7 - step * 0.35;

        // Skip if this point is inside the buildable grid area.
        if (_isInsideGrid(px, py)) continue;

        // Randomly choose what to place.
        final roll = rng.nextDouble();
        final scale = 0.7 + rng.nextDouble() * 0.5;

        if (roll < 0.25) {
          // Tree (25%)
          final t = _trees[rng.nextInt(_trees.length)];
          items.add(_DecoItem(
            asset: t.$1,
            width: t.$2 * scale,
            height: t.$3 * scale,
            x: px,
            y: py,
          ));
        } else if (roll < 0.55) {
          // Medium item (30%)
          final m = _medium[rng.nextInt(_medium.length)];
          items.add(_DecoItem(
            asset: m.$1,
            width: m.$2 * scale,
            height: m.$3 * scale,
            x: px,
            y: py,
          ));
        } else if (roll < 0.80) {
          // Small item (25%)
          final s = _small[rng.nextInt(_small.length)];
          items.add(_DecoItem(
            asset: s.$1,
            width: s.$2 * scale,
            height: s.$3 * scale,
            x: px,
            y: py,
          ));
        }
        // else (20%): empty gap for variety
      }
    }

    // Sort by Y for correct depth ordering.
    items.sort((a, b) => a.y.compareTo(b.y));
    return items;
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final decorations = _generate();

    return Stack(
      children: decorations.map((d) {
        return Positioned(
          left: d.x - d.width / 2,
          top: d.y - d.height,
          child: Image.asset(
            d.asset,
            width: d.width,
            height: d.height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none, // crisp pixel art
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        );
      }).toList(),
    );
  }
}
