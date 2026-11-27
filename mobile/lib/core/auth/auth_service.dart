import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Estado de sesión: acceso libre inmediato (anónimo) con opción de cuenta registrada.
class AuthStateSummary {
  const AuthStateSummary({
    required this.isReady,
    required this.isAnonymous,
    this.userId,
    this.email,
    this.errorMessage,
  });

  final bool isReady;
  final bool isAnonymous;
  final String? userId;
  final String? email;
  final String? errorMessage;

  bool get isSignedInWithAccount => userId != null && !isAnonymous;
}

class AuthService {
  SupabaseClient? get _client {
    try {
      return Env.isInitialized ? Supabase.instance.client : null;
    } catch (_) {
      return null;
    }
  }

  /// Garantiza sesión anónima transparente; refresca si expiró y captura
  /// `anonymous_provider_disabled` (422) sin bloquear el arranque de la app.
  Future<AuthStateSummary> ensureSession() async {
    final client = _client;
    if (client == null) {
      return const AuthStateSummary(
        isReady: true,
        isAnonymous: true,
        errorMessage: 'Modo local sin SUPABASE_ANON_KEY configurado.',
      );
    }

    try {
      var session = client.auth.currentSession;
      if (session != null && session.isExpired && session.refreshToken != null) {
        final refreshed = await client.auth.refreshSession();
        session = refreshed.session;
      }

      if (session == null) {
        final response = await client.auth.signInAnonymously();
        session = response.session;
      }

      final user = session?.user ?? client.auth.currentUser;
      return AuthStateSummary(
        isReady: true,
        isAnonymous: user?.isAnonymous ?? true,
        userId: user?.id,
        email: user?.email,
      );
    } on AuthException catch (e) {
      final isDisabled = e.message.contains('anonymous_provider_disabled') ||
          e.statusCode == '422';
      return AuthStateSummary(
        isReady: true,
        isAnonymous: true,
        errorMessage: isDisabled
            ? 'Activa "Allow anonymous sign-ins" en Supabase Auth -> Providers.'
            : 'Sesión anónima pendiente: ${e.message}',
      );
    } catch (e) {
      return AuthStateSummary(
        isReady: true,
        isAnonymous: true,
        errorMessage: 'Sesión anónima diferida: $e',
      );
    }
  }

  String? get currentAccessToken => _client?.auth.currentSession?.accessToken;
  String? get currentUserId => _client?.auth.currentUser?.id;

  Future<AuthStateSummary> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase no configurado.');
    }
    final res = await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = res.user;
    return AuthStateSummary(
      isReady: true,
      isAnonymous: user?.isAnonymous ?? false,
      userId: user?.id,
      email: user?.email,
    );
  }

  Future<AuthStateSummary> upgradeAnonymousAccount({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase no configurado.');
    }
    final current = client.auth.currentUser;
    if (current != null && current.isAnonymous) {
      final res = await client.auth.updateUser(
        UserAttributes(email: email.trim(), password: password),
      );
      final user = res.user;
      return AuthStateSummary(
        isReady: true,
        isAnonymous: user?.isAnonymous ?? false,
        userId: user?.id,
        email: user?.email,
      );
    }

    final res = await client.auth.signUp(
      email: email.trim(),
      password: password,
    );
    final user = res.user;
    return AuthStateSummary(
      isReady: true,
      isAnonymous: user?.isAnonymous ?? false,
      userId: user?.id,
      email: user?.email,
    );
  }

  Future<void> signInOrLinkWithGoogle() async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase no configurado.');
    }
    final current = client.auth.currentUser;
    if (current != null && current.isAnonymous) {
      await client.auth.linkIdentity(OAuthProvider.google);
    } else {
      await client.auth.signInWithOAuth(OAuthProvider.google);
    }
  }

  Future<AuthStateSummary> signOutToGuest() async {
    final client = _client;
    if (client == null) {
      return const AuthStateSummary(isReady: true, isAnonymous: true);
    }
    await client.auth.signOut();
    return ensureSession();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider =
    AsyncNotifierProvider<AuthStateNotifier, AuthStateSummary>(
  AuthStateNotifier.new,
);

class AuthStateNotifier extends AsyncNotifier<AuthStateSummary> {
  @override
  Future<AuthStateSummary> build() {
    return ref.read(authServiceProvider).ensureSession();
  }

  Future<void> refreshSession() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(authServiceProvider).ensureSession());
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authServiceProvider)
          .signInWithEmail(email: email, password: password),
    );
  }

  Future<void> upgradeAnonymousAccount(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authServiceProvider)
          .upgradeAnonymousAccount(email: email, password: password),
    );
  }

  Future<void> signOutToGuest() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(authServiceProvider).signOutToGuest());
  }
}
