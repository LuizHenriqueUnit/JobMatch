import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/data/auth_repository.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(inMemoryStoreProvider)),
);

final profileStreamProvider = StreamProvider.autoDispose<Profile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream<Profile?>.value(null);
  return ref.watch(profileRepositoryProvider).watchProfile(user.id);
});
