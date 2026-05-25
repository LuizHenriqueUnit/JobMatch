import 'dart:async';

import '../../features/auth/domain/app_user.dart';
import '../../core/constants/job_status.dart';
import '../../features/jobs/domain/job_application.dart';
import '../../features/notifications/domain/app_notification.dart';
import '../../features/profile/domain/profile.dart';

class InMemoryStore {
  static const _demoEmail = 'demo@jobmatch.app';

  final Map<String, _Account> _accountsByEmail = <String, _Account>{};
  final Map<String, _Account> _accountsById = <String, _Account>{};

  final List<JobApplication> _jobs = <JobApplication>[];
  final List<AppNotification> _notifications = <AppNotification>[];

  final StreamController<AppUser?> _authEvents = StreamController<AppUser?>.broadcast();
  final StreamController<void> _jobEvents = StreamController<void>.broadcast();
  final StreamController<void> _notificationEvents = StreamController<void>.broadcast();
  final StreamController<void> _profileEvents = StreamController<void>.broadcast();

  int _nextUserId = 1;
  int _nextJobId = 1;
  int _nextNotificationId = 1;

  AppUser? _currentUser;

  InMemoryStore() {
    final demoUser = _createAccount(
      name: 'Demo User',
      email: _demoEmail,
      password: '123456',
    );
    _seedDemoData(demoUser.user.id);
  }

  AppUser? get currentUser => _currentUser;

  void dispose() {
    _authEvents.close();
    _jobEvents.close();
    _notificationEvents.close();
    _profileEvents.close();
  }

  Stream<AppUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _authEvents.stream;
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (_accountsByEmail.containsKey(normalizedEmail)) {
      throw const AppAuthException('Este e-mail ja esta cadastrado.');
    }

    _createAccount(
      name: name.trim(),
      email: normalizedEmail,
      password: password.trim(),
    );
    _profileEvents.add(null);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();
    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      final demo = _accountsByEmail[_demoEmail];
      if (demo != null) {
        _currentUser = demo.user;
        _authEvents.add(_currentUser);
        return;
      }
    }

    final account = _accountsByEmail[normalizedEmail];
    if (account == null || account.password != normalizedPassword) {
      throw const AppAuthException('E-mail ou senha invalidos.');
    }

    _currentUser = account.user;
    _authEvents.add(_currentUser);
  }

  Future<void> signOut() async {
    _currentUser = null;
    _authEvents.add(null);
  }

  Stream<List<JobApplication>> watchJobs(String userId) async* {
    yield _jobsForUser(userId);
    yield* _jobEvents.stream.map((_) => _jobsForUser(userId));
  }

  Future<JobApplication?> getJobById({
    required String id,
    required String userId,
  }) async {
    for (final job in _jobs) {
      if (job.id == id && job.userId == userId) {
        return job;
      }
    }
    return null;
  }

  Future<void> createJob({
    required String userId,
    required String roleName,
    required String companyName,
    required String platform,
    required String statusLabel,
    String notes = '',
  }) async {
    final job = JobApplication(
      id: 'job_${_nextJobId++}',
      userId: userId,
      roleName: roleName.trim(),
      companyName: companyName.trim(),
      platform: platform.trim(),
      status: JobStatus.fromLabel(statusLabel),
      notes: notes.trim(),
      createdAt: DateTime.now(),
    );
    _jobs.add(job);
    _jobEvents.add(null);
    _createNotification(
      userId: userId,
      message: 'Nova candidatura criada: ${job.roleName} em ${job.companyName}',
    );
  }

  Future<void> updateJobStatus({
    required String id,
    required String userId,
    required String statusLabel,
    required String roleName,
    required String companyName,
  }) async {
    final index = _jobs.indexWhere((job) => job.id == id && job.userId == userId);
    if (index < 0) return;

    _jobs[index] = _jobs[index].copyWith(status: JobStatus.fromLabel(statusLabel));
    _jobEvents.add(null);
    _createNotification(
      userId: userId,
      message: 'Status atualizado para "$statusLabel": ${roleName.trim()} em ${companyName.trim()}',
    );
  }

  Future<void> updateJob({
    required String id,
    required String roleName,
    required String companyName,
    required String platform,
    required String notes,
    required String statusLabel,
  }) async {
    final index = _jobs.indexWhere((job) => job.id == id);
    if (index < 0) return;

    _jobs[index] = _jobs[index].copyWith(
      roleName: roleName.trim(),
      companyName: companyName.trim(),
      platform: platform.trim(),
      notes: notes.trim(),
      status: JobStatus.fromLabel(statusLabel),
    );
    _jobEvents.add(null);
  }

  Future<void> deleteJob({
    required String id,
    required String userId,
    required String roleName,
    required String companyName,
  }) async {
    _jobs.removeWhere((job) => job.id == id && job.userId == userId);
    _jobEvents.add(null);
    _createNotification(
      userId: userId,
      message: 'Candidatura removida: ${roleName.trim()} em ${companyName.trim()}',
    );
  }

  Stream<List<AppNotification>> watchNotifications(String userId) async* {
    yield _notificationsForUser(userId);
    yield* _notificationEvents.stream.map((_) => _notificationsForUser(userId));
  }

  Future<void> markNotificationAsRead(String id) async {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index < 0) return;

    final current = _notifications[index];
    _notifications[index] = current.copyWith(isRead: true);
    _notificationEvents.add(null);
  }

  Stream<Profile?> watchProfile(String userId) async* {
    yield _profileForUser(userId);
    yield* _profileEvents.stream.map((_) => _profileForUser(userId));
  }

  _Account _createAccount({
    required String name,
    required String email,
    required String password,
  }) {
    final account = _Account(
      user: AppUser(
        id: 'user_${_nextUserId++}',
        name: name,
        email: email,
      ),
      password: password,
    );
    _accountsByEmail[email] = account;
    _accountsById[account.user.id] = account;
    return account;
  }

  List<JobApplication> _jobsForUser(String userId) {
    final jobs = _jobs.where((job) => job.userId == userId).toList(growable: false);
    jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return jobs;
  }

  List<AppNotification> _notificationsForUser(String userId) {
    final notifications = _notifications
        .where((item) => item.userId == userId)
        .toList(growable: false);
    notifications.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;
      if (aDate != null && bDate != null) {
        return bDate.compareTo(aDate);
      }
      return b.id.compareTo(a.id);
    });
    return notifications;
  }

  Profile? _profileForUser(String userId) {
    final account = _accountsById[userId];
    if (account == null) return null;
    return Profile(id: account.user.id, name: account.user.name, email: account.user.email);
  }

  void _createNotification({
    required String userId,
    required String message,
  }) {
    _notifications.add(
      AppNotification(
        id: 'notification_${_nextNotificationId++}',
        userId: userId,
        message: message,
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
    _notificationEvents.add(null);
  }

  void _seedDemoData(String userId) {
    _jobs.addAll(<JobApplication>[
      JobApplication(
        id: 'job_${_nextJobId++}',
        userId: userId,
        roleName: 'Flutter Developer',
        companyName: 'Tech Nova',
        platform: 'LinkedIn',
        status: JobStatus.inscrito,
        notes: 'Aplicacao enviada ontem.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      JobApplication(
        id: 'job_${_nextJobId++}',
        userId: userId,
        roleName: 'Mobile Engineer',
        companyName: 'Blue Ocean',
        platform: 'Gupy',
        status: JobStatus.entrevista,
        notes: 'Entrevista tecnica marcada.',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ]);
    _createNotification(
      userId: userId,
      message: 'Bem-vindo ao modo demonstracao do JobMatch.',
    );
  }
}

class _Account {
  const _Account({
    required this.user,
    required this.password,
  });

  final AppUser user;
  final String password;
}

class AppAuthException implements Exception {
  const AppAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
