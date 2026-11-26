import 'package:flutter/material.dart';

import '../../../../app/theme/vialibre_theme.dart';
import '../../../../core/widgets/audio_player_bar.dart';
import '../../domain/transit_route_model.dart';

/// Guía visual tipo Timeline ("Paso 01 / Paso 02") para abordar Metro, Metrobús,
/// camión o combi por primera vez en lenguaje claro.
class FirstTimerGuideSheet extends StatelessWidget {
  const FirstTimerGuideSheet({
    required this.route,
    super.key,
  });

  final TransitRouteOption route;

  String _buildSpokenFallback(FirstTimerGuide? guide) {
    if (guide == null) {
      return route.steps.map((s) => s.instruction).join('. ');
    }
    final buffer = StringBuffer(guide.spokenSummaryText);
    for (final step in guide.stepByStep) {
      buffer.write(' Paso ${step.stepNumber}: ${step.title}. ${step.plainInstruction}.');
    }
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    final guide = route.firstTimerGuide;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return SafeArea(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: p.coralSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Modo Primera Vez',
                      style: TextStyle(
                        color: p.coral,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      route.summaryLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Guía paso a paso en lenguaje claro para viajar con seguridad.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              AudioPlayerBar(
                title: 'Escuchar guía paso a paso',
                base64Wav: route.audioBase64,
                fallbackText: _buildSpokenFallback(guide),
              ),
              if (guide != null && guide.checklistBeforeBoarding.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.sand,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: p.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Antes de subir',
                        style: TextStyle(
                          color: p.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final item in guide.checklistBeforeBoarding)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: p.mintInk,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Itinerario paso a paso',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (guide != null && guide.stepByStep.isNotEmpty)
                for (var i = 0; i < guide.stepByStep.length; i++)
                  _TimelineStepCard(
                    step: guide.stepByStep[i],
                    isLast: i == guide.stepByStep.length - 1,
                  )
              else
                for (var i = 0; i < route.steps.length; i++)
                  _RawTransitStepCard(index: i + 1, step: route.steps[i]),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineStepCard extends StatelessWidget {
  const _TimelineStepCard({
    required this.step,
    required this.isLast,
  });

  final FirstTimerGuideStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    final stepTag = 'Paso ${step.stepNumber.toString().padLeft(2, '0')}';

    return Semantics(
      container: true,
      label:
          '$stepTag: ${step.title}. ${step.plainInstruction}. Consejo: ${step.accessibilityTip}',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(top: 18),
                    decoration: BoxDecoration(
                      color: p.coral,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: p.coralSoft,
                        width: 3,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: p.border,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: p.lavender,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          stepTag,
                          style: TextStyle(
                            color: p.lavenderInk,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        step.plainInstruction,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (step.accessibilityTip.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: p.mintSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.accessible_forward_rounded,
                                size: 18,
                                color: p.mintInk,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  step.accessibilityTip,
                                  style: TextStyle(
                                    color: p.mintInk,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RawTransitStepCard extends StatelessWidget {
  const _RawTransitStepCard({required this.index, required this.step});

  final int index;
  final TransitStep step;

  @override
  Widget build(BuildContext context) {
    final badge = step.lineName ?? step.vehicleType ?? step.stepMode;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paso $index · $badge',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              step.instruction,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (step.departureStop != null || step.arrivalStop != null) ...[
              const SizedBox(height: 6),
              Text(
                'Sube en: ${step.departureStop ?? "Parada inicial"} → Baja en: ${step.arrivalStop ?? "Destino"}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
