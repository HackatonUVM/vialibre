import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vialibre/app/theme/vialibre_theme.dart';
import 'package:vialibre/core/auth/auth_service.dart';
import 'package:vialibre/core/widgets/accessible_button.dart';
import 'package:vialibre/core/widgets/screen_header.dart';
import 'package:vialibre/core/widgets/tactile_press.dart';
import '../data/profile_prefs_repo.dart';

/// Pantalla de perfil accesible + selector de Modo Claro/Oscuro + cuenta opcional.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isCreateMode = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    if (email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ingresa un correo válido y contraseña de al menos 6 caracteres.',
          ),
        ),
      );
      return;
    }

    final notifier = ref.read(authStateProvider.notifier);
    if (_isCreateMode) {
      await notifier.upgradeAnonymousAccount(email, password);
    } else {
      await notifier.signInWithEmail(email, password);
    }

    if (!mounted) return;
    final auth = ref.read(authStateProvider);
    if (auth.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo completar: ${auth.error}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta vinculada correctamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    final profileAsync = ref.watch(profileControllerProvider);
    final authAsync = ref.watch(authStateProvider);

    final prefs = profileAsync.valueOrNull ??
        const ProfilePrefs(
          profile: AccessibilityProfile.wheelchair,
          highContrast: false,
          firstTimerMode: true,
        );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const ScreenHeader(
              eyebrow: 'Preferencias y accesibilidad',
              title: 'Elige tu perfil',
              subtitle:
                  'Adaptamos tus rutas, alertas y guías de transporte sin pedir registro obligatorio.',
              showBack: true,
            ),
            const SizedBox(height: 18),
            // Tarjeta de Apariencia (Claro / Oscuro / Sistema) con logo vivo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            p.isDark
                                ? 'assets/branding/logo_dark.png'
                                : 'assets/branding/logo_light.png',
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Apariencia',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'Elige modo claro u oscuro según tu comodidad visual.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_rounded, size: 18),
                          label: Text('Auto'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_rounded, size: 18),
                          label: Text('Claro'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_rounded, size: 18),
                          label: Text('Oscuro'),
                        ),
                      ],
                      selected: {prefs.themeMode},
                      onSelectionChanged: (modes) {
                        ref
                            .read(profileControllerProvider.notifier)
                            .setThemeMode(modes.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...AccessibilityProfile.values.map((item) {
              final selected = prefs.profile == item;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Semantics(
                  selected: selected,
                  button: true,
                  label: '${item.label}. ${item.subtitle}',
                  child: TactilePress(
                    borderRadius: 20,
                    onTap: () => ref
                        .read(profileControllerProvider.notifier)
                        .setProfile(item),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      constraints: const BoxConstraints(minHeight: 74),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selected ? p.ctaBg : p.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? p.ctaBg : p.border,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: selected ? p.coral : p.lavender,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _iconForProfile(item),
                              color: selected ? Colors.white : p.lavenderInk,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: selected ? p.ctaFg : p.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.subtitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selected
                                        ? p.ctaFg.withValues(alpha: 0.78)
                                        : p.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: p.coral,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    activeColor: p.coral,
                    title: const Text(
                      'Modo Primera Vez en transporte',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Explica paso a paso cómo usar Metro, Metrobús, camión o combi.',
                    ),
                    value: prefs.firstTimerMode,
                    onChanged: (v) => ref
                        .read(profileControllerProvider.notifier)
                        .toggleFirstTimerMode(v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    activeColor: p.coral,
                    title: const Text(
                      'Evitar pendientes fuertes (> 8%)',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    value: prefs.avoidSlopes,
                    onChanged: (v) => ref
                        .read(profileControllerProvider.notifier)
                        .toggleAvoidSlopes(v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    activeColor: p.coral,
                    title: const Text(
                      'Alto contraste reforzado',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    value: prefs.highContrast,
                    onChanged: (v) => ref
                        .read(profileControllerProvider.notifier)
                        .toggleHighContrast(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AccessibleButton(
              label: 'Buscar ruta accesible',
              icon: Icons.directions_rounded,
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/map');
                }
              },
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: authAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Estado de sesión: $err'),
                  data: (auth) {
                    if (auth.isSignedInWithAccount) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Cuenta conectada: ${auth.email ?? auth.userId}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tus reportes e historial están respaldados en tu cuenta.',
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => ref
                                .read(authStateProvider.notifier)
                                .signOutToGuest(),
                            child: const Text('Volver a modo invitado'),
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Cuenta opcional (no obligatoria)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ya estás usando VíaLibre libremente como invitado. Si deseas respaldar tus reportes entre dispositivos, inicia sesión o vincula un correo.',
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          style: const TextStyle(fontSize: 16),
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passCtrl,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(fontSize: 16),
                          decoration: const InputDecoration(
                            labelText: 'Contraseña (mín. 6 caracteres)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Vincular mi sesión'),
                              selected: _isCreateMode,
                              labelStyle: TextStyle(
                                color: _isCreateMode ? p.ctaFg : p.ink,
                              ),
                              onSelected: (_) =>
                                  setState(() => _isCreateMode = true),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Ya tengo cuenta'),
                              selected: !_isCreateMode,
                              labelStyle: TextStyle(
                                color: !_isCreateMode ? p.ctaFg : p.ink,
                              ),
                              onSelected: (_) =>
                                  setState(() => _isCreateMode = false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        AccessibleButton(
                          label: _isCreateMode
                              ? 'Guardar historial con correo'
                              : 'Iniciar sesión',
                          icon: Icons.person_rounded,
                          onPressed: _submitAuth,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForProfile(AccessibilityProfile profile) {
    switch (profile) {
      case AccessibilityProfile.wheelchair:
        return Icons.accessible_rounded;
      case AccessibilityProfile.lowVision:
        return Icons.visibility_rounded;
      case AccessibilityProfile.plainLanguage:
        return Icons.menu_book_rounded;
    }
  }
}
