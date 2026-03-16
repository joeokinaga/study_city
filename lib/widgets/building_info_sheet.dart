import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/building.dart';
import '../models/building_catalog.dart';
import '../services/building_service.dart';
import '../viewmodels/city_view_model.dart';
import '../viewmodels/user_view_model.dart';

/// Bottom sheet that shows information about an existing building.
///
/// Displays the building image, name, level, description, upgrade button,
/// and action buttons for moving / removing the building.
class BuildingInfoSheet extends ConsumerWidget {
  final Building building;
  final String userId;

  /// Called when the user taps "Move" — the parent should enter move mode.
  final VoidCallback? onMove;

  /// Called when the user confirms "Remove to Stock".
  final VoidCallback? onRemove;

  const BuildingInfoSheet({
    super.key,
    required this.building,
    required this.userId,
    this.onMove,
    this.onRemove,
  });

  static const int _maxLevel = BuildingService.maxLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userVM = ref.watch(userViewModelProvider);
    final userCoins = userVM.currentUser?.coins ?? 0;
    final isMax = building.level >= _maxLevel;
    final canAfford = !isMax && userCoins >= building.coinsToNextLevel;
    final theme = Theme.of(context);
    final scale = CityViewModel.levelScale(building.level);

    // Get tile dimensions from catalog.
    final def = BuildingCatalog.getByType(building.type);
    final sizeLabel = def != null && def.totalTiles > 1 ? def.sizeLabel : null;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Handle bar.
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Building image.
          Container(
            constraints: BoxConstraints(maxHeight: 140 * scale),
            decoration: isMax
                ? BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ],
                  )
                : null,
            child: Image.asset(
              building.imagePath,
              height: 120 * scale,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.home,
                size: 80,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name.
          Text(
            building.name,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),

          // Tile size label (for multi-tile buildings).
          if (sizeLabel != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$sizeLabel tiles',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Level stars.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_maxLevel, (i) {
              return Icon(
                i < building.level ? Icons.star : Icons.star_border,
                size: 24,
                color:
                    i < building.level ? Colors.amber[700] : Colors.grey[400],
              );
            }),
          ),
          const SizedBox(height: 4),

          Text(
            isMax ? 'MAX LEVEL' : 'Level ${building.level}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isMax ? Colors.amber[700] : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          // Description.
          if (building.description.isNotEmpty)
            Text(
              building.description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 20),

          // Upgrade button.
          if (isMax)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Fully upgraded!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed:
                    canAfford ? () => _confirmUpgrade(context, ref) : null,
                icon: const Icon(Icons.arrow_upward),
                label: Text(
                  canAfford
                      ? 'Upgrade to Lv.${building.level + 1}  (${building.coinsToNextLevel} coins)'
                      : 'Not enough coins (${building.coinsToNextLevel} required)',
                ),
              ),
            ),
          const SizedBox(height: 12),

          // ─── Move / Remove action buttons ───────────────────────────
          Row(
            children: [
              // Move button.
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onMove,
                  icon: const Icon(Icons.open_with, size: 18),
                  label: const Text('Move'),
                ),
              ),
              const SizedBox(width: 12),
              // Remove to stock button.
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmRemove(context),
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange[800],
                    side: BorderSide(color: Colors.orange.shade300),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        ),
      ),
    );
  }

  Future<void> _confirmUpgrade(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Upgrade'),
        content: Text(
          'Upgrade ${building.name} from Lv.${building.level} to '
          'Lv.${building.level + 1}?\n\n'
          'Cost: ${building.coinsToNextLevel} coins',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final success = await ref.read(cityViewModelProvider).upgradeBuilding(
          userId,
          building,
        );

    if (!context.mounted) return;

    if (success) {
      ref.read(userViewModelProvider).loadUser(userId);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${building.name} upgraded to Lv.${building.level + 1}!'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins')),
      );
    }
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Building?'),
        content: Text(
          'Remove ${building.name} from the grid?\n\n'
          'It will be stored in your stock and can be placed again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange[700],
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    onRemove?.call();
  }
}
