import 'package:flutter/material.dart';

import '../../../../app/theme/vialibre_theme.dart';
import '../../../../core/widgets/accessible_button.dart';
import '../../domain/transit_route_model.dart';

/// Hoja de resultados multimodales (Metro, Metrobús, Camión, Combi, Caminata).
class TransitRoutesSheet extends StatefulWidget {
  const TransitRoutesSheet({
    required this.destinationName,
    required this.routes,
    required this.selectedRouteId,
    required this.onSelectRoute,
    required this.onOpenFirstTimerGuide,
    super.key,
  });

  final String destinationName;
  final List<TransitRouteOption> routes;
  final String? selectedRouteId;
  final ValueChanged<TransitRouteOption> onSelectRoute;
  final ValueChanged<TransitRouteOption> onOpenFirstTimerGuide;

  @override
  State<TransitRoutesSheet> createState() => _TransitRoutesSheetState();
}

class _TransitRoutesSheetState extends State<TransitRoutesSheet> {
  String _modeFilter = 'ALL';

  List<TransitRouteOption> get _filteredRoutes {
    if (_modeFilter == 'ALL') return widget.routes;
    if (_modeFilter == 'WALK') {
      return widget.routes.where((r) => r.mode == 'WALK').toList();
    }
    return widget.routes.where((r) {
      if (r.mode != 'TRANSIT') return false;
      if (_modeFilter == 'TRANSIT') return true;
      return r.steps
          .any((s) => (s.vehicleType ?? '').toUpperCase() == _modeFilter);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    final visible = _filteredRoutes;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: p.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Opciones hacia ${widget.destinationName}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildChip('ALL', 'Todas'),
                          const SizedBox(width: 8),
                          _buildChip('TRANSIT', 'Transporte público'),
                          const SizedBox(width: 8),
                          _buildChip('SUBWAY', 'Metro'),
                          const SizedBox(width: 8),
                          _buildChip('BUS', 'Camión / Metrobús'),
                          const SizedBox(width: 8),
                          _buildChip('WALK', 'A pie'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No hay rutas registradas para este filtro de transporte. Prueba con "Todas".',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final route = visible[index];
                          final isSelected = route.id == widget.selectedRouteId;
                          return _RouteOptionCard(
                            route: route,
                            isSelected: isSelected,
                            onSelect: () => widget.onSelectRoute(route),
                            onOpenGuide: () =>
                                widget.onOpenFirstTimerGuide(route),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(String key, String label) {
    final p = ViaLibreTheme.paletteOf(context);
    final selected = _modeFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: p.ctaBg,
      labelStyle: TextStyle(
        color: selected ? p.ctaFg : p.ink,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) => setState(() => _modeFilter = key),
    );
  }
}

class _RouteOptionCard extends StatelessWidget {
  const _RouteOptionCard({
    required this.route,
    required this.isSelected,
    required this.onSelect,
    required this.onOpenGuide,
  });

  final TransitRouteOption route;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onOpenGuide;

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    final hasBarriers = route.barriersOnRoute.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? p.coral : p.border,
          width: isSelected ? 2.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  route.mode == 'TRANSIT'
                      ? Icons.directions_transit_rounded
                      : Icons.directions_walk_rounded,
                  color: p.ink,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    route.summaryLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: p.sand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${route.durationMinutes} min',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: p.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (route.recommendationReason != null &&
                route.recommendationReason!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.lavender,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: p.lavenderInk,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        route.recommendationReason!,
                        style: TextStyle(
                          color: p.lavenderInk,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _InfoBadge(
                  text: '${route.distanceMeters} m',
                  background: p.canvas,
                  foreground: p.ink,
                ),
                if (route.maxSlopePercent != null)
                  _InfoBadge(
                    text:
                        'Pendiente máx ${route.maxSlopePercent!.toStringAsFixed(1)}%',
                    background: p.canvas,
                    foreground: p.ink,
                  ),
                _InfoBadge(
                  text: hasBarriers
                      ? '${route.barriersOnRoute.length} obstáculo(s) cerca'
                      : 'Sin obstáculos reportados',
                  background: hasBarriers ? p.alertRedSoft : p.mintSoft,
                  foreground: hasBarriers ? p.alertRed : p.mintInk,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSelect,
                    child: Text(isSelected ? 'Ruta en mapa' : 'Ver en mapa'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AccessibleButton(
                    label: 'Guía paso a paso',
                    icon: Icons.record_voice_over_rounded,
                    onPressed: onOpenGuide,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
