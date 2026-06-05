import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/features/auth/data/auth_repository.dart';
import 'package:welinked/features/auth/domain/app_user.dart';

/// Provider for watching the current user's state in Firestore.
final currentUserStreamProvider = StreamProvider<AppUser?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.watchCurrentUser();
});

/// State notifier provider or future providers to authenticate the user.
class AuthLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool val) {
    state = val;
  }
}

final authLoadingProvider = NotifierProvider<AuthLoadingNotifier, bool>(
  AuthLoadingNotifier.new,
);

/// State notifier to manage user login and registration states.
class AuthController {
  final AuthRepository _repository;
  final Ref _ref;

  AuthController(this._repository, this._ref);

  Future<void> login(String email, String password, {required Function(String error) onError}) async {
    _ref.read(authLoadingProvider.notifier).set(true);
    try {
      await _repository.signIn(email: email, password: password);
    } catch (e) {
      onError(e.toString());
    } finally {
      _ref.read(authLoadingProvider.notifier).set(false);
    }
  }

  Future<void> register(String name, String email, String password, {required Function(String error) onError}) async {
    _ref.read(authLoadingProvider.notifier).set(true);
    try {
      await _repository.signUp(name: name, email: email, password: password);
    } catch (e) {
      onError(e.toString());
    } finally {
      _ref.read(authLoadingProvider.notifier).set(false);
    }
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.read(authRepositoryProvider), ref);
});
