import 'package:flutter/material.dart';

import '../../../../app/theme/vialibre_theme.dart';
import '../data/report_repo.dart';

/// Dibuja recuadros de detección devueltos por Gemini (`box_2d` en escala 0..1000)
/// sobre la fotografía capturada.
class BoundingBoxOverlay extends StatelessWidget {
  const BoundingBoxOverlay({
    required this.boxes,
    super.key,
  });

  final List<BoundingBoxItem> boxes;

  @override
  Widget build(BuildContext context) {
    if (boxes.isEmpty) return const SizedBox.shrink();
    final p = ViaLibreTheme.paletteOf(context);
    return IgnorePointer(
      child: CustomPaint(
        painter: _BoxPainter(boxes, p),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BoxPainter extends CustomPainter {
  _BoxPainter(this.boxes, this.palette);

  final List<BoundingBoxItem> boxes;
  final ViaLibrePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = palette.coral
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final fillPaint = Paint()
      ..color = palette.coral.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    for (final box in boxes) {
      if (box.box2d.length != 4) continue;
      final ymin = (box.box2d[0] / 1000.0) * size.height;
      final xmin = (box.box2d[1] / 1000.0) * size.width;
      final ymax = (box.box2d[2] / 1000.0) * size.height;
      final xmax = (box.box2d[3] / 1000.0) * size.width;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTRB(xmin, ymin, xmax, ymax),
        const Radius.circular(8),
      );
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, strokePaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: ' ${box.label} ',
          style: TextStyle(
            backgroundColor: palette.ctaBg,
            color: palette.ctaFg,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);

      final labelY = (ymin - 22).clamp(4.0, size.height - 22);
      final labelX = xmin.clamp(4.0, size.width - textPainter.width - 4);
      textPainter.paint(canvas, Offset(labelX, labelY));
    }
  }

  @override
  bool shouldRepaint(covariant _BoxPainter oldDelegate) =>
      oldDelegate.boxes != boxes || oldDelegate.palette != palette;
}
