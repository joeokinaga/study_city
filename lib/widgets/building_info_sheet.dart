import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/building.dart';
import '../services/building_service.dart';
import '../viewmodels/city_view_model.dart';
import '../viewmodels/user_view_model.dart';

/// Bottom sheet that shows information about an existing building.
///
/// Displays the building image, name, level, description, and upgrade button.
class BuildingInfoSheet extends ConsumerWidget {
  final Building building;
  final String userId;

  const BuildingInfoSheet({
    super.key,
    required this.building,
    required this.userId,
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

    return Padding(
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
              width: 96 * scale,
              height: 96 * scale,
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
          const SizedBox(height: 8),

          // Level stars.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_maxLevel, (i) {
              return Icon(
                i < building.level ? Icons.star : Icons.star_border,
                size: 24,
                color: i < building.level ? Colors.amber[700] : Colors.grey[400],
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
          const SizedBox(height: 8),
        ],
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
}
