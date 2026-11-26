import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/env.dart';
import '../../../core/network/bff_client.dart';

enum AccessibilityProfile {
  wheelchair(
    keyName: 'wheelchair',
    label: 'Silla de ruedas / Carriola',
    subtitle: 'Rutas sin escalones ni pendientes fuertes.',
  ),
  lowVision(
    keyName: 'low_vision',
    label: 'Baja visión',
    subtitle: 'Guía por voz y alto contraste.',
  ),
  plainLanguage(
    keyName: 'plain_language',
    label: 'Lectura clara',
    subtitle: 'Instrucciones simples paso a paso.',
  );

  const AccessibilityProfile({
    required this.keyName,
    required this.label,
    required this.subtitle,
  });

  final String keyName;
  final String label;
  final String subtitle;

  static AccessibilityProfile fromKey(String? key) {
    return AccessibilityProfile.values.firstWhere(
      (e) => e.keyName == key,
      orElse: () => AccessibilityProfile.wheelchair,
    );
  }
}

class ProfilePrefs {
  const ProfilePrefs({
    required this.profile,
    required this.highContrast,
    required this.firstTimerMode,
    this.themeMode = ThemeMode.system,
    this.avoidSlopes = true,
    this.maxSlopePercent = 8.0,
    this.ttsSpeed = 1.0,
    this.largeText = false,
  });

  final AccessibilityProfile profile;
  final bool highContrast;
  final bool firstTimerMode;
  final ThemeMode themeMode;
  final bool avoidSlopes;
  final double maxSlopePercent;
  final double ttsSpeed;
  final bool largeText;

  ProfilePrefs copyWith({
    AccessibilityProfile? profile,
    bool? highContrast,
    bool? firstTimerMode,
    ThemeMode? themeMode,
    bool? avoidSlopes,
    double? maxSlopePercent,
    double? ttsSpeed,
    bool? largeText,
  }) {
    return ProfilePrefs(
      profile: profile ?? this.profile,
      highContrast: highContrast ?? this.highContrast,
      firstTimerMode: firstTimerMode ?? this.firstTimerMode,
      themeMode: themeMode ?? this.themeMode,
      avoidSlopes: avoidSlopes ?? this.avoidSlopes,
      maxSlopePercent: maxSlopePercent ?? this.maxSlopePercent,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      largeText: largeText ?? this.largeText,
    );
  }

  Map<String, dynamic> toBackendJson() => {
        'accessibilityProfile': profile.keyName,
        'avoidSlopes': avoidSlopes,
        'maxSlopePercent': maxSlopePercent,
        'ttsSpeed': ttsSpeed,
        'largeText': largeText,
      };

  ProfilePrefs mergeFromBackendJson(Map<String, dynamic> json) {
    final remoteLargeText = json['largeText'] as bool?;
    return copyWith(
      profile: AccessibilityProfile.fromKey(
        json['accessibilityProfile'] as String? ?? profile.keyName,
      ),
      avoidSlopes: (json['avoidSlopes'] as bool?) ?? avoidSlopes,
      maxSlopePercent:
          (json['maxSlopePercent'] as num?)?.toDouble() ?? maxSlopePercent,
      ttsSpeed: (json['ttsSpeed'] as num?)?.toDouble() ?? ttsSpeed,
      largeText: remoteLargeText ?? largeText,
    );
  }
}

class ProfilePrefsRepo {
  ProfilePrefsRepo(this._bff);

  final BffClient _bff;

  static const _kProfileKey = 'vialibre_profile';
  static const _kHighContrastKey = 'vialibre_high_contrast';
  static const _kFirstTimerKey = 'vialibre_first_timer_mode';
  static const _kAvoidSlopesKey = 'vialibre_avoid_slopes';
  static const _kMaxSlopeKey = 'vialibre_max_slope';
  static const _kTtsSpeedKey = 'vialibre_tts_speed';
  static const _kLargeTextKey = 'vialibre_large_text';
  static const _kThemeModeKey = 'vialibre_theme_mode';

  static ThemeMode _parseThemeMode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<ProfilePrefs> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return ProfilePrefs(
      profile: AccessibilityProfile.fromKey(prefs.getString(_kProfileKey)),
      highContrast: prefs.getBool(_kHighContrastKey) ?? false,
      firstTimerMode: prefs.getBool(_kFirstTimerKey) ?? true,
      themeMode: _parseThemeMode(prefs.getString(_kThemeModeKey)),
      avoidSlopes: prefs.getBool(_kAvoidSlopesKey) ?? true,
      maxSlopePercent: prefs.getDouble(_kMaxSlopeKey) ?? 8.0,
      ttsSpeed: prefs.getDouble(_kTtsSpeedKey) ?? 1.0,
      largeText: prefs.getBool(_kLargeTextKey) ?? false,
    );
  }

  Future<void> saveLocal(ProfilePrefs value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileKey, value.profile.keyName);
    await prefs.setBool(_kHighContrastKey, value.highContrast);
    await prefs.setBool(_kFirstTimerKey, value.firstTimerMode);
    await prefs.setString(_kThemeModeKey, value.themeMode.name);
    await prefs.setBool(_kAvoidSlopesKey, value.avoidSlopes);
    await prefs.setDouble(_kMaxSlopeKey, value.maxSlopePercent);
    await prefs.setDouble(_kTtsSpeedKey, value.ttsSpeed);
    await prefs.setBool(_kLargeTextKey, value.largeText);
  }

  Future<ProfilePrefs?> fetchRemote(ProfilePrefs local) async {
    if (!Env.isSupabaseConfigured) return null;
    try {
      final json = await _bff.getJson('/api/profile/me');
      final raw = json['profile'];
      if (raw is Map<String, dynamic>) {
        final merged = local.mergeFromBackendJson(raw);
        await saveLocal(merged);
        return merged;
      }
    } catch (_) {
      // Mantiene preferencias locales si no hay red o el usuario está offline.
    }
    return null;
  }

  Future<void> syncRemote(ProfilePrefs value) async {
    if (!Env.isSupabaseConfigured) return;
    try {
      await _bff.putJson('/api/profile/me', value.toBackendJson());
    } catch (_) {
      // Silencioso en modo offline; SharedPreferences conserva la configuración.
    }
  }

  Future<void> deleteRemote() async {
    if (!Env.isSupabaseConfigured) return;
    await _bff.deleteJson('/api/profile/me');
  }
}

final profilePrefsRepoProvider = Provider<ProfilePrefsRepo>(
  (ref) => ProfilePrefsRepo(ref.read(bffClientProvider)),
);

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfilePrefs>(
  ProfileController.new,
);

class ProfileController extends AsyncNotifier<ProfilePrefs> {
  @override
  Future<ProfilePrefs> build() async {
    final repo = ref.read(profilePrefsRepoProvider);
    final local = await repo.loadLocal();
    // Sincronización en segundo plano sin bloquear el arranque instantáneo.
    Future.microtask(() async {
      final remote = await repo.fetchRemote(local);
      if (remote != null) {
        state = AsyncData(remote);
      }
    });
    return local;
  }

  Future<void> _update(ProfilePrefs next) async {
    state = AsyncData(next);
    final repo = ref.read(profilePrefsRepoProvider);
    await repo.saveLocal(next);
    await repo.syncRemote(next);
  }

  Future<void> setProfile(AccessibilityProfile profile) async {
    final current = state.valueOrNull ??
        const ProfilePrefs(
          profile: AccessibilityProfile.wheelchair,
          highContrast: false,
          firstTimerMode: true,
        );
    final next = current.copyWith(
      profile: profile,
      highContrast: profile == AccessibilityProfile.lowVision
          ? true
          : current.highContrast,
      largeText: profile == AccessibilityProfile.lowVision
          ? true
          : current.largeText,
    );
    await _update(next);
  }

  Future<void> toggleHighContrast(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _update(current.copyWith(highContrast: enabled));
  }

  Future<void> toggleFirstTimerMode(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _update(current.copyWith(firstTimerMode: enabled));
  }

  Future<void> toggleAvoidSlopes(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _update(current.copyWith(avoidSlopes: enabled));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final current = state.valueOrNull ??
        const ProfilePrefs(
          profile: AccessibilityProfile.wheelchair,
          highContrast: false,
          firstTimerMode: true,
        );
    final next = current.copyWith(themeMode: mode);
    state = AsyncData(next);
    await ref.read(profilePrefsRepoProvider).saveLocal(next);
  }
}
