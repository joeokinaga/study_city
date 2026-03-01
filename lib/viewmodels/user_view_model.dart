import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../services/firestore_service.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository _userRepository;

  User? currentUser;
  bool isLoading = false;

  UserViewModel(this._userRepository);

  Future<void> loadUser(String uid) async {
    isLoading = true;
    notifyListeners();
    currentUser = await _userRepository.getUser(uid);
    isLoading = false;
    notifyListeners();
  }

  Stream<User?> streamUser(String uid) {
    return _userRepository.streamUser(uid);
  }
}

final userViewModelProvider = ChangeNotifierProvider<UserViewModel>((ref) {
  final firestore = FirestoreService();
  return UserViewModel(UserRepository(firestore));
});
