import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/building.dart';
import '../services/auth_service.dart';
import '../viewmodels/building_view_model.dart';
import '../viewmodels/review_view_model.dart';
import '../viewmodels/user_view_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _authService = AuthService();

  String get _uid => fb.FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_uid.isNotEmpty) {
        ref.read(userViewModelProvider).loadUser(_uid);
        ref.read(reviewViewModelProvider).loadTodayItems(_uid);
      }
    });
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final userVM = ref.watch(userViewModelProvider);
    final reviewVM = ref.watch(reviewViewModelProvider);
    final buildingVM = ref.watch(buildingViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Study City',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'サインアウト',
            onPressed: _signOut,
          ),
        ],
      ),
      body: userVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(userViewModelProvider).loadUser(_uid);
                await ref.read(reviewViewModelProvider).loadTodayItems(_uid);
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // User info card
                  _buildUserCard(userVM, theme),
                  const SizedBox(height: 20),

                  // Review banner
                  if (reviewVM.todayItems.isNotEmpty)
                    _buildReviewBanner(reviewVM.todayItems.length, theme),
                  if (reviewVM.todayItems.isNotEmpty) const SizedBox(height: 20),

                  // Buildings section
                  Text(
                    'あなたの街',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildBuildingList(buildingVM),
                  const SizedBox(height: 24),

                  // Start study button
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: () => context.go('/timer'),
                      icon: const Icon(Icons.play_arrow, size: 28),
                      label: const Text(
                        '学習を始める',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              break; // already on home
            case 1:
              context.go('/timer');
            case 2:
              context.go('/review');
            case 3:
              context.go('/buildings');
            case 4:
              context.go('/stats');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'ホーム'),
          NavigationDestination(icon: Icon(Icons.timer), label: '学習'),
          NavigationDestination(icon: Icon(Icons.checklist), label: '復習'),
          NavigationDestination(icon: Icon(Icons.location_city), label: '街'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: '統計'),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserViewModel userVM, ThemeData theme) {
    final user = userVM.currentUser;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                user?.name.isNotEmpty == true
                    ? user!.name.substring(0, 1)
                    : '?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'ユーザー',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text('${user?.exp ?? 0} EXP'),
                      const SizedBox(width: 16),
                      Icon(Icons.monetization_on,
                          size: 16, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text('${user?.coins ?? 0} Coins'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewBanner(int count, ThemeData theme) {
    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: InkWell(
        onTap: () => context.go('/review'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.notifications_active,
                  color: theme.colorScheme.onTertiaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '今日の復習: $count件',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: theme.colorScheme.onTertiaryContainer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuildingList(BuildingViewModel buildingVM) {
    if (_uid.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 140,
      child: StreamBuilder<List<Building>>(
        stream: buildingVM.streamBuildings(_uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final buildings = snapshot.data ?? [];
          if (buildings.isEmpty) {
            return const Center(child: Text('建物がありません'));
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: buildings.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final b = buildings[index];
              return _buildBuildingCard(b);
            },
          );
        },
      ),
    );
  }

  Widget _buildBuildingCard(Building building) {
    final emoji = _buildingEmoji(building.type);
    final theme = Theme.of(context);
    return SizedBox(
      width: 120,
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(
                building.name,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Lv.${building.level}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildingEmoji(String type) {
    switch (type) {
      case 'library':
        return '📚';
      case 'cafeteria':
        return '🍽';
      case 'gym':
        return '🏋';
      case 'art_room':
        return '🎨';
      case 'science_lab':
        return '🔬';
      default:
        return '🏠';
    }
  }
}
