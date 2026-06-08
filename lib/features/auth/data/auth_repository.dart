import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../shared/providers/firebase_providers.dart';
import '../domain/app_auth_exception.dart';
import '../domain/app_user.dart';

const _institutionalDomain = '@souunit.com.br';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  ),
);

final authUserProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

final currentUserProvider = Provider<AppUser?>((ref) {
  final streamedUser = ref.watch(authUserProvider).valueOrNull;
  return streamedUser ?? ref.watch(authRepositoryProvider).currentUser;
});

class AuthRepository {
  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  GoogleSignIn? _googleSignIn;

  AppUser? get currentUser {
    final user = _mapUser(_auth.currentUser);
    if (user == null) return null;
    return _isInstitutionalEmail(user.email) ? user : null;
  }

  Stream<AppUser?> authStateChanges() async* {
    await for (final user in _auth.authStateChanges()) {
      if (user == null) {
        yield null;
        continue;
      }

      final email = user.email?.trim().toLowerCase() ?? '';
      if (!_isInstitutionalEmail(email)) {
        try {
          await _auth.signOut();
        } catch (_) {
          // Ignore sign-out issues on stream sync.
        }
        yield null;
        continue;
      }

      final mapped = _mapUser(user);
      // Nao bloqueia o fluxo de autenticacao por escrita no Firestore.
      unawaited(_safeSyncProfile(user));
      yield mapped;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.trim().isEmpty) {
      throw const AppAuthException('Informe e-mail e senha.');
    }
    if (!_isInstitutionalEmail(normalizedEmail)) {
      throw const AppAuthException(
        'Apenas contas @souunit.com.br podem acessar o aplicativo.',
      );
    }

    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password.trim(),
      );
      final user = result.user;
      if (user == null) {
        throw const AppAuthException('Nao foi possivel autenticar sua conta.');
      }
      await _ensureDomainOrLogout(user);
      await _syncProfile(user);
    } on FirebaseAuthException catch (error) {
      throw AppAuthException(_mapFirebaseAuthError(error));
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final user = await _signInWithGoogleInternal();
      if (user == null) {
        throw const AppAuthException('Falha ao autenticar com Google.');
      }
      await _ensureDomainOrLogout(user);
      await _syncProfile(user);
    } on AppAuthException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AppAuthException(_mapFirebaseAuthError(error));
    } catch (_) {
      throw const AppAuthException('Falha ao autenticar com Google.');
    }
  }

  Future<User?> _signInWithGoogleInternal() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.setCustomParameters({'prompt': 'select_account'});
      final result = await _auth.signInWithPopup(provider);
      return result.user;
    }

    final googleUser = await (_googleSignIn ??= GoogleSignIn()).signIn();
    if (googleUser == null) {
      throw const AppAuthException('Login Google cancelado.');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!_isInstitutionalEmail(normalizedEmail)) {
      throw const AppAuthException(
        'Cadastro permitido apenas para e-mails @souunit.com.br.',
      );
    }
    if (name.trim().isEmpty) {
      throw const AppAuthException('Informe seu nome.');
    }
    if (password.trim().length < 6) {
      throw const AppAuthException('A senha deve ter no minimo 6 caracteres.');
    }

    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password.trim(),
      );
      final user = result.user;
      if (user == null) {
        throw const AppAuthException('Nao foi possivel criar sua conta.');
      }
      await user.updateDisplayName(name.trim());
      await user.reload();
      final refreshed = _auth.currentUser ?? user;
      await _ensureDomainOrLogout(refreshed);
      await _syncProfile(refreshed);
    } on FirebaseAuthException catch (error) {
      throw AppAuthException(_mapFirebaseAuthError(error));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb && _googleSignIn != null) {
      try {
        await _googleSignIn!.signOut();
      } catch (_) {
        // Ignore local Google session cleanup failures.
      }
    }
  }

  bool _isInstitutionalEmail(String email) {
    return email.endsWith(_institutionalDomain);
  }

  Future<void> _ensureDomainOrLogout(User user) async {
    final email = user.email?.trim().toLowerCase() ?? '';
    if (_isInstitutionalEmail(email)) return;
    await signOut();
    throw const AppAuthException(
      'Acesso negado. Utilize uma conta @souunit.com.br.',
    );
  }

  Future<void> _syncProfile(User user) async {
    final email = user.email?.trim().toLowerCase() ?? '';
    if (email.isEmpty) return;
    final displayName = (user.displayName ?? '').trim();
    final profileName =
        displayName.isNotEmpty ? displayName : email.split('@').first;

    await _firestore.collection('profiles').doc(user.uid).set({
      'id': user.uid,
      'name': profileName,
      'email': email,
      'usuario_logado': email,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _safeSyncProfile(User user) async {
    try {
      await _syncProfile(user);
    } catch (_) {
      // Nao interrompe auth stream quando perfil nao puder ser sincronizado.
    }
  }

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    final email = user.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) return null;
    final name = (user.displayName ?? '').trim();
    return AppUser(
      id: user.uid,
      name: name.isNotEmpty ? name : email.split('@').first,
      email: email,
    );
  }

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'E-mail invalido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha invalidos.';
      case 'email-already-in-use':
        return 'Este e-mail ja esta em uso.';
      case 'weak-password':
        return 'A senha informada e muito fraca.';
      case 'network-request-failed':
        return 'Falha de rede. Verifique sua conexao.';
      case 'popup-blocked':
        return 'Pop-up bloqueado pelo navegador. Permita pop-ups para o site.';
      case 'popup-closed-by-user':
        return 'Janela de login Google foi fechada antes de concluir.';
      case 'unauthorized-domain':
        return 'Dominio nao autorizado no Firebase Auth. Adicione localhost em Authorized domains.';
      case 'operation-not-allowed':
        return 'Login com Google nao esta habilitado no Firebase Authentication.';
      default:
        return error.message ?? 'Nao foi possivel concluir a autenticacao.';
    }
  }
}
