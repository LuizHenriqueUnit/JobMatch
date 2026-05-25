import '../../../shared/data/in_memory_store.dart';
import '../domain/profile.dart';

class ProfileRepository {
  ProfileRepository(this._store);

  final InMemoryStore _store;

  Stream<Profile?> watchProfile(String userId) {
    return _store.watchProfile(userId);
  }
}
