import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/building.dart';
import '../models/building_catalog.dart';
import '../viewmodels/city_view_model.dart';
import '../viewmodels/user_view_model.dart';

/// Bottom sheet that displays purchasable buildings and stocked buildings.
///
/// Opens when the user taps an empty tile on the isometric grid.
/// If the user has stocked (un-placed) buildings, a "Your Stock" section
/// appears above the shop grid so they can place them for free.
class BuildingShopSheet extends ConsumerWidget {
  final List<BuildingDefinition> catalog;
  final String userId;
  final int gridRow;
  final int gridCol;

  /// Buildings the user owns but are not currently placed on the grid.
  final List<Building> stockedBuildings;

  const BuildingShopSheet({
    super.key,
    required this.catalog,
    required this.userId,
    required this.gridRow,
    required this.gridCol,
    this.stockedBuildings = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userVM = ref.watch(userViewModelProvider);
    final userCoins = userVM.currentUser?.coins ?? 0;
    final cityVM = ref.watch(cityViewModelProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
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
                    stockedBuildings.isNotEmpty
                        ? 'Place or Buy'
                        : 'Building Shop',
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

            // Scrollable content: stock section + shop grid.
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  // ─── Stock section ──────────────────────────────────
                  if (stockedBuildings.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2,
                              size: 18, color: Colors.orange[700]),
                          const SizedBox(width: 6),
                          Text(
                            'Your Stock (${stockedBuildings.length})',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Horizontal scroll of stocked buildings.
                    SizedBox(
                      height: 130,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: stockedBuildings.length,
                        itemBuilder: (context, index) {
                          final building = stockedBuildings[index];
                          final def = BuildingCatalog.getByType(building.type);
                          final canFit = def != null &&
                              cityVM.canPlaceBuilding(
                                  def, gridRow, gridCol);

                          return _StockItem(
                            building: building,
                            canFit: canFit,
                            onTap: canFit
                                ? () => _confirmPlaceStock(
                                    context, ref, building)
                                : null,
                          );
                        },
                      ),
                    ),

                    const Divider(height: 1),
                  ],

                  // ─── Shop section header ────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Buy New',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── Shop grid (non-scrollable inside ListView) ────
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: catalog.length,
                    itemBuilder: (context, index) {
                      final definition = catalog[index];
                      final canAfford =
                          userCoins >= definition.purchasePrice;
                      final canFit = cityVM.canPlaceBuilding(
                          definition, gridRow, gridCol);

                      return _BuildingShopItem(
                        definition: definition,
                        canAfford: canAfford,
                        canFit: canFit,
                        onTap: canAfford && canFit
                            ? () =>
                                _confirmPurchase(context, ref, definition)
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Place from stock ─────────────────────────────────────────────

  Future<void> _confirmPlaceStock(
    BuildContext context,
    WidgetRef ref,
    Building building,
  ) async {
    final def = BuildingCatalog.getByType(building.type);
    final sizeLabel = def != null && def.totalTiles > 1 ? def.sizeLabel : null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Place ${building.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                building.imagePath,
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
            Text(building.description),
            const SizedBox(height: 8),
            Text(
              'Level ${building.level}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (sizeLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                'Size: $sizeLabel tiles',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Free — already owned',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
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
            child: const Text('Place'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final success =
        await ref.read(cityViewModelProvider).placeStockedBuilding(
              building,
              gridRow,
              gridCol,
            );

    if (!context.mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${building.name} has been placed!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough space')),
      );
    }
  }

  // ─── Purchase from shop ───────────────────────────────────────────

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
            if (definition.totalTiles > 1) ...[
              const SizedBox(height: 4),
              Text(
                'Size: ${definition.sizeLabel} tiles',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
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
        const SnackBar(content: Text('Not enough space or coins')),
      );
    }
  }
}

// ─── Stock item card (horizontal list) ────────────────────────────────

class _StockItem extends StatelessWidget {
  final Building building;
  final bool canFit;
  final VoidCallback? onTap;

  const _StockItem({
    required this.building,
    required this.canFit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final def = BuildingCatalog.getByType(building.type);
    final sizeLabel = def != null && def.totalTiles > 1 ? def.sizeLabel : null;

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        elevation: canFit ? 2 : 0,
        color: canFit ? null : theme.colorScheme.surfaceContainerHighest,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: canFit ? 1.0 : 0.5,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Building thumbnail.
                  Expanded(
                    child: Image.asset(
                      building.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.home,
                        size: 32,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Name.
                  Text(
                    building.name,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Level + size badges.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Lv.${building.level}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      if (sizeLabel != null) ...[
                        const SizedBox(width: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: canFit
                                ? theme.colorScheme.primaryContainer
                                : Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            sizeLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: canFit
                                  ? theme.colorScheme.onPrimaryContainer
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),

                  // FREE label.
                  Text(
                    'FREE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shop item card (grid) ────────────────────────────────────────────

class _BuildingShopItem extends StatelessWidget {
  final BuildingDefinition definition;
  final bool canAfford;
  final bool canFit;
  final VoidCallback? onTap;

  const _BuildingShopItem({
    required this.definition,
    required this.canAfford,
    required this.canFit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = canAfford && canFit;

    return Card(
      elevation: enabled ? 2 : 0,
      color: enabled ? null : theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
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

                // Tile size badge (only for multi-tile buildings).
                if (definition.totalTiles > 1)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: canFit
                          ? theme.colorScheme.primaryContainer
                          : Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      definition.sizeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: canFit
                            ? theme.colorScheme.onPrimaryContainer
                            : Colors.red,
                      ),
                    ),
                  ),

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
