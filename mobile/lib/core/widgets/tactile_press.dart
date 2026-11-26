import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Contenedor interactivo con respuesta táctil inmediata (escala 0.97 en 100 ms)
/// y retroalimentación háptica ligera, respetando `disableAnimations`.
class TactilePress extends StatefulWidget {
  const TactilePress({
    required this.child,
    required this.onTap,
    this.borderRadius = 20,
    this.enableHaptics = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool enableHaptics;

  @override
  State<TactilePress> createState() => _TactilePressState();
}

class _TactilePressState extends State<TactilePress> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final radius = BorderRadius.circular(widget.borderRadius);

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: (!reducedMotion && _pressed) ? 0.97 : 1.0,
        duration: reducedMotion
            ? Duration.zero
            : const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onTap == null
                ? null
                : () {
                    if (widget.enableHaptics) {
                      HapticFeedback.selectionClick();
                    }
                    widget.onTap!();
                  },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
