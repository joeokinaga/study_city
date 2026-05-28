import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../viewmodels/city_view_model.dart';
import '../viewmodels/review_view_model.dart';
import '../viewmodels/user_view_model.dart';
import '../widgets/isometric_city_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _authService = AuthService();
  final _notificationService = NotificationService();

  String get _uid => fb.FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_uid.isNotEmpty) {
        ref.read(userViewModelProvider).loadUser(_uid);
        await ref.read(reviewViewModelProvider).loadTodayItems(_uid);
        // Show a browser notification if there are reviews due today.
        final count = ref.read(reviewViewModelProvider).todayItems.length;
        _notificationService.showReviewReminder(count);
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
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background color behind the isometric grid.
          Container(color: const Color(0xFF4A8C30)),

          // Isometric city view — Positioned.fill gives tight constraints so
          // the widget's LayoutBuilder always reports the true viewport size.
          const Positioned.fill(child: IsometricCityWidget()),

          // User info card (top-left overlay).
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: _buildUserOverlay(userVM, theme),
          ),

          // Logout button (top-right).
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: Material(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                tooltip: 'Sign out',
                onPressed: _signOut,
              ),
            ),
          ),

          // Review badge (top-right, below logout).
          if (reviewVM.todayItems.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              right: 12,
              child: _buildReviewBadge(reviewVM.todayItems.length, theme),
            ),

          // Stock badge (top-right, below review badge).
          if (ref.watch(cityViewModelProvider).stockedBuildings.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top +
                  (reviewVM.todayItems.isNotEmpty ? 96 : 56),
              right: 12,
              child: _buildStockBadge(
                ref.watch(cityViewModelProvider).stockedBuildings.length,
                theme,
              ),
            ),

          // Start study FAB (bottom-center).
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.extended(
                heroTag: 'study_fab',
                onPressed: () => context.go('/timer'),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Studying'),
              ),
            ),
          ),

          // Hint text for empty city.
          if (userVM.currentUser != null &&
              !userVM.isLoading &&
              ref.watch(cityViewModelProvider).buildings.isEmpty)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              left: 40,
              right: 40,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tap an empty tile to build!\nStudy to earn coins and grow your city.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
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
              context.go('/progress');
            case 4:
              context.go('/stats');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.timer), label: 'Study'),
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Review'),
          NavigationDestination(icon: Icon(Icons.trending_up), label: 'Progress'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
      ),
    );
  }

  Widget _buildUserOverlay(UserViewModel userVM, ThemeData theme) {
    final user = userVM.currentUser;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              user?.name.isNotEmpty == true
                  ? user!.name.substring(0, 1)
                  : '?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user?.name ?? 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.star, size: 13, color: Colors.amber[400]),
                  const SizedBox(width: 3),
                  Text(
                    '${user?.exp ?? 0}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.monetization_on,
                      size: 13, color: Colors.amber[400]),
                  const SizedBox(width: 3),
                  Text(
                    '${user?.coins ?? 0}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockBadge(int count, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade800,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            '$count in stock',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewBadge(int count, ThemeData theme) {
    return Material(
      color: Colors.orange.shade700,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go('/review'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_active,
                  color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                '$count reviews',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
