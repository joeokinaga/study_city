import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart' as app;
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService;
  final UserRepository _userRepository;

  bool isLoading = false;

  LoginViewModel(this._authService, this._userRepository);

  Future<void> signIn(String email, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      await _authService.signInWithEmail(email, password);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      final credential = await _authService.signUpWithEmail(email, password, name);
      final uid = credential.user!.uid;
      await _userRepository.createUser(app.User(
        uid: uid,
        name: name,
        email: email,
        coins: 200,
        createdAt: DateTime.now(),
      ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }
}

final loginViewModelProvider = ChangeNotifierProvider<LoginViewModel>((ref) {
  final firestore = FirestoreService();
  return LoginViewModel(
    AuthService(),
    UserRepository(firestore),
  );
});
