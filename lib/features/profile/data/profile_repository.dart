import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/profile.dart';

class ProfileRepository {
  ProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<Profile?> watchProfile(String userId) {
    return _firestore
        .collection('profiles')
        .doc(userId)
        .snapshots(includeMetadataChanges: true)
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return Profile.fromMap({
        ...data,
        'id': doc.id,
      });
    }).timeout(
      const Duration(seconds: 20),
      onTimeout: (sink) => sink.addError(
        TimeoutException('Tempo limite ao carregar perfil.'),
      ),
    );
  }
}
