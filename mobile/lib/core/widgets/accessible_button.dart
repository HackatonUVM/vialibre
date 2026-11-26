import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/vialibre_theme.dart';
import 'tactile_press.dart';

/// Botón principal tipo pill accesible (>= 48x54 dp) adaptable a Claro / Oscuro.
class AccessibleButton extends StatelessWidget {
  const AccessibleButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.semanticHint,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? semanticHint;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    final bg = backgroundColor ?? p.ctaBg;
    final fg = foregroundColor ?? p.ctaFg;
    final active = onPressed != null && !isLoading;

    return Semantics(
      button: true,
      enabled: active,
      label: label,
      hint: semanticHint,
      child: TactilePress(
        borderRadius: 28,
        onTap: active
            ? () {
                HapticFeedback.lightImpact();
                onPressed!();
              }
            : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: active ? 1.0 : 0.55,
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 54),
            padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: fg,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: bg == p.ctaBg
                        ? p.coral
                        : Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: fg,
                          ),
                        )
                      : Icon(
                          icon ?? Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
