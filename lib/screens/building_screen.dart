import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/building.dart';
import '../viewmodels/building_view_model.dart';
import '../viewmodels/user_view_model.dart';

class BuildingScreen extends ConsumerStatefulWidget {
  const BuildingScreen({super.key});

  @override
  ConsumerState<BuildingScreen> createState() => _BuildingScreenState();
}

class _BuildingScreenState extends ConsumerState<BuildingScreen> {
  static const _maxLevel = 5;

  String get _uid => fb.FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userViewModelProvider).loadUser(_uid);
    });
  }

  Widget _buildStars(int level) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_maxLevel, (i) {
        return Icon(
          i < level ? Icons.star : Icons.star_border,
          size: 18,
          color: i < level ? Colors.amber[700] : Colors.grey[400],
        );
      }),
    );
  }

  Future<void> _confirmUpgrade(Building building) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Upgrade'),
        content: Text(
          'Upgrade ${building.name} from Lv.${building.level} to Lv.${building.level + 1}?\n'
          '\nThis will cost ${building.coinsToNextLevel} coins.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(buildingViewModelProvider)
        .upgradeBuilding(_uid, building);

    if (!mounted) return;

    if (success) {
      // Reload user coins
      ref.read(userViewModelProvider).loadUser(_uid);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${building.name} leveled up!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userVM = ref.watch(userViewModelProvider);
    final buildingVM = ref.watch(buildingViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('City Builder'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  Icon(Icons.monetization_on,
                      size: 20, color: Colors.amber[700]),
                  const SizedBox(width: 4),
                  Text(
                    '${userVM.currentUser?.coins ?? 0}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Building>>(
        stream: buildingVM.streamBuildings(_uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final buildings = snapshot.data ?? [];
          if (buildings.isEmpty) {
            return const Center(child: Text('No buildings yet'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: buildings.length,
            itemBuilder: (context, index) {
              return _buildBuildingCard(
                buildings[index],
                userVM.currentUser?.coins ?? 0,
                theme,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBuildingCard(
    Building building,
    int userCoins,
    ThemeData theme,
  ) {
    final isMax = building.level >= _maxLevel;
    final canAfford = userCoins >= building.coinsToNextLevel;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Building image + MAX badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  building.imagePath,
                  width: 64,
                  height: 64,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.home,
                    size: 48,
                    color: theme.colorScheme.outline,
                  ),
                ),
                if (isMax)
                  Positioned(
                    top: -8,
                    right: -16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'MAX',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Name
            Text(
              building.name,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Stars
            _buildStars(building.level),
            const SizedBox(height: 4),
            Text(
              'Lv.${building.level}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.primary),
            ),

            const Spacer(),

            // Upgrade button
            if (isMax)
              Text(
                'Max Level',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: canAfford
                      ? () => _confirmUpgrade(building)
                      : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  child: canAfford
                      ? Text(
                          'Lv.${building.level + 1}\n${building.coinsToNextLevel} coins',
                          textAlign: TextAlign.center,
                        )
                      : const Text('Not enough coins'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
