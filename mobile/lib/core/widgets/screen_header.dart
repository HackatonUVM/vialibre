import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/vialibre_theme.dart';
import '../../features/profile/data/profile_prefs_repo.dart';
import 'tactile_press.dart';

/// Cabecera editorial adaptable a Modo Claro / Oscuro con el emblema VíaLibre
/// y acceso circular superior derecho a Perfil y accesibilidad.
class ScreenHeader extends ConsumerWidget {
  const ScreenHeader({
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.showLogo = false,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final bool showBack;
  final bool showLogo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ViaLibreTheme.paletteOf(context);
    final prefs = ref.watch(profileControllerProvider).valueOrNull;
    final profileLabel = prefs?.profile.label ?? 'Silla de ruedas';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (showBack) ...[
              Semantics(
                button: true,
                label: 'Regresar',
                child: TactilePress(
                  borderRadius: 24,
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/explore');
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: p.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.border),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: p.ink,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ] else if (showLogo) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  p.isDark
                      ? 'assets/branding/logo_dark.png'
                      : 'assets/branding/logo_light.png',
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            if (!showBack) ...[
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label:
                    'Perfil activo: $profileLabel. Toca para cambiar perfil, tema claro u oscuro, o cuenta.',
                child: TactilePress(
                  borderRadius: 24,
                  onTap: () => context.push('/profile'),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: p.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.border),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: p.ink,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}
