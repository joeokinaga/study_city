import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dev_config.dart';
import 'firebase_options.dart';
import 'models/user.dart' as app;
import 'repositories/user_repository.dart';
import 'router.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDevMode) {
    await _devAutoLogin();
  }

  runApp(const ProviderScope(child: StudyCityApp()));
}

/// Auto-login with anonymous auth and ensure the test user has lots of coins.
///
/// Only called when [kDevMode] is `true`.
Future<void> _devAutoLogin() async {
  try {
    var fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) {
      final credential = await FirebaseAuth.instance.signInAnonymously();
      fbUser = credential.user;
    }
    if (fbUser == null) return;

    final firestore = FirestoreService();
    final userRepo = UserRepository(firestore);
    final existing = await userRepo.getUser(fbUser.uid);

    if (existing == null) {
      // Create a new dev user with lots of coins.
      await userRepo.createUser(app.User(
        uid: fbUser.uid,
        name: 'Dev Tester',
        email: 'dev@test.com',
        coins: kDevCoins,
        createdAt: DateTime.now(),
      ));
    } else if (existing.coins < kDevCoins) {
      // Top up coins to the dev amount.
      await userRepo.addExpAndCoins(
        fbUser.uid,
        0,
        kDevCoins - existing.coins,
      );
    }
  } catch (e) {
    debugPrint('Dev auto-login failed: $e');
  }
}

class StudyCityApp extends StatelessWidget {
  const StudyCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Study City',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
