import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/review_screen.dart';
import 'screens/building_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/subject_management_screen.dart';

/// Listenable that notifies GoRouter when Firebase auth state changes.
class AuthStateNotifier extends ChangeNotifier {
  late final StreamSubscription<User?> _subscription;

  AuthStateNotifier() {
    _subscription =
        FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final _authNotifier = AuthStateNotifier();

final router = GoRouter(
  initialLocation: '/home',
  refreshListenable: _authNotifier,
  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final isLoginRoute = state.matchedLocation == '/login';

    if (!loggedIn && !isLoginRoute) return '/login';
    if (loggedIn && isLoginRoute) return '/home';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/timer',
      builder: (context, state) => const TimerScreen(),
    ),
    GoRoute(
      path: '/review',
      builder: (context, state) => const ReviewScreen(),
    ),
    GoRoute(
      path: '/buildings',
      builder: (context, state) => const BuildingScreen(),
    ),
    GoRoute(
      path: '/stats',
      builder: (context, state) => const StatsScreen(),
    ),
    GoRoute(
      path: '/subjects',
      builder: (context, state) => const SubjectManagementScreen(),
    ),
  ],
);
