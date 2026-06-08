import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

bool _firestoreSettingsInitialized = false;

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  final firestore = FirebaseFirestore.instance;
  if (kIsWeb && !_firestoreSettingsInitialized) {
    try {
      firestore.settings = const Settings(
        persistenceEnabled: true,
        webExperimentalForceLongPolling: true,
      );
    } catch (_) {
      // Ignore reconfiguration errors if Firestore was already started.
    }
    _firestoreSettingsInitialized = true;
  }
  return firestore;
});
