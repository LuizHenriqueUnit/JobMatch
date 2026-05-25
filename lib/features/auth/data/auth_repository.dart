import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/in_memory_store.dart';
import '../domain/app_user.dart';

final inMemoryStoreProvider = Provider<InMemoryStore>((ref) {
  final store = InMemoryStore();
  ref.onDispose(store.dispose);
  return store;
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(inMemoryStoreProvider)),
);

final authUserProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

final currentUserProvider = Provider<AppUser?>((ref) {
  final streamedUser = ref.watch(authUserProvider).valueOrNull;
  return streamedUser ?? ref.watch(authRepositoryProvider).currentUser;
});

class AuthRepository {
  AuthRepository(this._store);

  final InMemoryStore _store;

  AppUser? get currentUser => _store.currentUser;

  Stream<AppUser?> authStateChanges() {
    return _store.authStateChanges();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _store.signIn(email: email, password: password);
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _store.signUp(name: name, email: email, password: password);
  }

  Future<void> signOut() async {
    await _store.signOut();
  }
}
