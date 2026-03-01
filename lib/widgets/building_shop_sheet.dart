import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/building_catalog.dart';
import '../viewmodels/city_view_model.dart';
import '../viewmodels/user_view_model.dart';

/// Bottom sheet that displays purchasable buildings in a grid.
///
/// Opens when the user taps an empty tile on the isometric grid.
/// Buildings the user cannot afford are grayed out.
class BuildingShopSheet extends ConsumerWidget {
  final List<BuildingDefinition> catalog;
  final String userId;
  final int gridRow;
  final int gridCol;

  const BuildingShopSheet({
    super.key,
    required this.catalog,
    required this.userId,
    required this.gridRow,
    required this.gridCol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userVM = ref.watch(userViewModelProvider);
    final userCoins = userVM.currentUser?.coins ?? 0;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar.
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header.
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.storefront, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Building Shop',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Icon(Icons.monetization_on,
                      size: 20, color: Colors.amber[700]),
                  const SizedBox(width: 4),
                  Text(
                    '$userCoins',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Building grid.
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: catalog.length,
                itemBuilder: (context, index) {
                  final definition = catalog[index];
                  final canAfford = userCoins >= definition.purchasePrice;

                  return _BuildingShopItem(
                    definition: definition,
                    canAfford: canAfford,
                    onTap: canAfford
                        ? () => _confirmPurchase(context, ref, definition)
                        : null,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmPurchase(
    BuildContext context,
    WidgetRef ref,
    BuildingDefinition definition,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Purchase ${definition.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                definition.imagePath,
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.home,
                  size: 64,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(definition.description),
            const SizedBox(height: 8),
            Text(
              'Cost: ${definition.purchasePrice} coins',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Purchase'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final success = await ref.read(cityViewModelProvider).purchaseBuilding(
          userId,
          definition,
          gridRow,
          gridCol,
        );

    if (!context.mounted) return;

    if (success) {
      // Reload user coins.
      ref.read(userViewModelProvider).loadUser(userId);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${definition.name} has been built!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins')),
      );
    }
  }
}

class _BuildingShopItem extends StatelessWidget {
  final BuildingDefinition definition;
  final bool canAfford;
  final VoidCallback? onTap;

  const _BuildingShopItem({
    required this.definition,
    required this.canAfford,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: canAfford ? 2 : 0,
      color: canAfford ? null : theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: canAfford ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Building thumbnail.
                Expanded(
                  child: Image.asset(
                    definition.imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.home,
                      size: 40,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Name.
                Text(
                  definition.name,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),

                // Price.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monetization_on,
                        size: 14, color: Colors.amber[700]),
                    const SizedBox(width: 2),
                    Text(
                      '${definition.purchasePrice}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: canAfford
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
