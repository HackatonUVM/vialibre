import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_service.dart';
import '../core/offline/sync_manager.dart';
import '../features/profile/data/profile_prefs_repo.dart';
import 'router.dart';
import 'theme/vialibre_theme.dart';

/// Widget raíz de VíaLibre: inicia sesión anónima transparente,
/// aplica Modo Claro / Oscuro configurable y gestiona la cola offline SQLite.
class ViaLibreApp extends ConsumerStatefulWidget {
  const ViaLibreApp({super.key});

  @override
  ConsumerState<ViaLibreApp> createState() => _ViaLibreAppState();
}

class _ViaLibreAppState extends ConsumerState<ViaLibreApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await ref.read(authStateProvider.future);
      } catch (_) {}
      try {
        final sync = ref.read(syncManagerProvider);
        final initialCount = await sync.pendingCount();
        if (mounted) {
          ref.read(pendingOfflineCountProvider.notifier).state = initialCount;
        }
        sync.startListening((remaining) {
          if (mounted) {
            ref.read(pendingOfflineCountProvider.notifier).state = remaining;
          }
        });
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final prefs = ref.watch(profileControllerProvider).valueOrNull;
    final highContrast = prefs?.highContrast ?? false;
    final themeMode = prefs?.themeMode ?? ThemeMode.system;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);

    final effectiveBrightness = themeMode == ThemeMode.system
        ? platformBrightness
        : (themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light);

    ThemeData applyMotion(ThemeData base) {
      if (!disableAnimations) return base;
      return base.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _NoTransitionsBuilder(),
          },
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ViaLibreTheme.overlayStyleFor(effectiveBrightness),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          final focus = FocusManager.instance.primaryFocus;
          if (focus != null && !focus.hasPrimaryFocus) {
            focus.unfocus();
          }
        },
        child: MaterialApp.router(
          title: 'VíaLibre',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: applyMotion(
            ViaLibreTheme.buildLightTheme(highContrast: highContrast),
          ),
          darkTheme: applyMotion(
            ViaLibreTheme.buildDarkTheme(highContrast: highContrast),
          ),
          routerConfig: router,
          builder: (context, child) {
            final textScaler = (prefs?.largeText ?? false)
                ? const TextScaler.linear(1.22)
                : MediaQuery.of(context).textScaler;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: child!,
            );
          },
        ),
      ),
    );
  }
}

class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
