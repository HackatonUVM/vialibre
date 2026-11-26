import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/vialibre_theme.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/tactile_press.dart';
import '../../gemini_assistant/presentation/assess_space_sheet.dart';
import '../../gemini_assistant/presentation/copilot_sheet.dart';
import '../../map_routes/domain/transit_route_model.dart';
import '../../map_routes/presentation/widgets/first_timer_guide_sheet.dart';
import '../../profile/data/profile_prefs_repo.dart';

/// Intención enviada desde Explorar hacia el Mapa para ejecutar búsqueda o filtro inmediato.
class ExploreMapIntent {
  const ExploreMapIntent({
    this.destinationQuery,
    this.categoryKey,
    this.placesQuery,
    this.onlyWheelchair = false,
  });

  final String? destinationQuery;
  final String? categoryKey;
  final String? placesQuery;
  final bool onlyWheelchair;
}

final pendingMapIntentProvider = StateProvider<ExploreMapIntent?>((ref) => null);

/// Pantalla de inicio cálida e intuitiva adaptable a Modo Claro y Modo Oscuro.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _launchMapSearch([String? overrideQuery]) {
    final query = (overrideQuery ?? _searchCtrl.text).trim();
    if (query.isEmpty) {
      context.go('/map');
      return;
    }
    ref.read(pendingMapIntentProvider.notifier).state = ExploreMapIntent(
      destinationQuery: query,
    );
    context.go('/map');
  }

  void _launchCategoryOnMap({
    required String categoryKey,
    required String placesQuery,
    bool onlyWheelchair = false,
  }) {
    ref.read(pendingMapIntentProvider.notifier).state = ExploreMapIntent(
      categoryKey: categoryKey,
      placesQuery: placesQuery,
      onlyWheelchair: onlyWheelchair,
    );
    context.go('/map');
  }

  void _openFirstTimerStarterGuide() {
    const sampleRoute = TransitRouteOption(
      id: 'starter-guide',
      mode: 'TRANSIT',
      summaryLabel: 'Guía rápida · Metro, Metrobús, Camión y Combi',
      durationSeconds: 1200,
      distanceMeters: 2800,
      steps: [],
      barriersOnRoute: [],
      firstTimerGuide: FirstTimerGuide(
        checklistBeforeBoarding: [
          'Lleva tu Tarjeta de Movilidad Integrada (o monedas exactas si subes a camión/combi).',
          'Revisa el letrero frontal con el nombre de la terminal final antes de abordar.',
          'Si usas silla de ruedas o carriola, busca el vagón o puerta señalizada con elevador/rampa.',
        ],
        stepByStep: [
          FirstTimerGuideStep(
            stepNumber: 1,
            title: 'Identifica la entrada accesible y dirección',
            plainInstruction:
                'En Metro o Metrobús, revisa qué lado va hacia tu destino final antes de cruzar torniquetes. En camión o combi, espera en la esquina señalada y levanta la mano cuando veas la ruta.',
            accessibilityTip:
                'En estaciones con desnivel pide al personal de taquilla abrir la puerta amplia o activar el elevador.',
          ),
          FirstTimerGuideStep(
            stepNumber: 2,
            title: 'Paga o valida tu entrada con calma',
            plainInstruction:
                'Acerca tu tarjeta al lector verde del torniquete o validador del autobús hasta escuchar el sonido de confirmación.',
            accessibilityTip:
                'Si viajas con baja visión, el sonido agudo y la luz verde confirman el paso libre.',
          ),
          FirstTimerGuideStep(
            stepNumber: 3,
            title: 'Ubica los asientos reservados y pide bajada',
            plainInstruction:
                'Siéntate cerca de la puerta en los lugares reservados o espacio para silla. Dos cuadras antes de tu destino presiona el timbre o di con voz clara: "Bajan en la siguiente, por favor".',
            accessibilityTip:
                'En Metrobús las puertas abren al nivel de la banqueta, evitando escalones al bajar.',
          ),
        ],
        spokenSummaryText:
            'Antes de subir, confirma la dirección final, valida tu tarjeta al entrar y solicita tu parada con anticipación.',
      ),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FirstTimerGuideSheet(route: sampleRoute),
    );
  }

  void _openCopilot() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CopilotSheet(
        onOpenFirstTimerGuide: _openFirstTimerStarterGuide,
      ),
    );
  }

  void _openSpaceEvaluator() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AssessSpaceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    final prefs = ref.watch(profileControllerProvider).valueOrNull;
    final activeProfile = prefs?.profile ?? AccessibilityProfile.wheelchair;

    final shortcuts = <_ShortcutTileData>[
      _ShortcutTileData(
        label: 'Metro',
        icon: Icons.subway_rounded,
        onTap: () => _launchCategoryOnMap(
          categoryKey: 'metro',
          placesQuery: 'estación metro accesible',
        ),
      ),
      _ShortcutTileData(
        label: 'Metrobús',
        icon: Icons.directions_bus_filled_rounded,
        onTap: () => _launchCategoryOnMap(
          categoryKey: 'metrobus',
          placesQuery: 'estación metrobús',
        ),
      ),
      _ShortcutTileData(
        label: 'Bus / Combi',
        icon: Icons.directions_bus_outlined,
        onTap: () => _launchCategoryOnMap(
          categoryKey: 'camion',
          placesQuery: 'parada camión combi transporte',
        ),
      ),
      _ShortcutTileData(
        label: 'Evaluar foto',
        icon: Icons.center_focus_strong_rounded,
        onTap: _openSpaceEvaluator,
      ),
      _ShortcutTileData(
        label: 'Rampas',
        icon: Icons.accessible_forward_rounded,
        onTap: () => _launchCategoryOnMap(
          categoryKey: 'rampas',
          placesQuery: 'entrada accesible rampa clínica',
          onlyWheelchair: true,
        ),
      ),
      _ShortcutTileData(
        label: 'Primera vez',
        icon: Icons.explore_rounded,
        onTap: _openFirstTimerStarterGuide,
      ),
      _ShortcutTileData(
        label: 'Reportar',
        icon: Icons.add_alert_rounded,
        onTap: () => context.go('/report'),
      ),
      _ShortcutTileData(
        label: 'Avisos hoy',
        icon: Icons.campaign_rounded,
        onTap: () => context.go('/briefs'),
      ),
    ];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          const ScreenHeader(
            eyebrow: 'VíaLibre · Movilidad inclusiva',
            title: '¿A dónde vamos hoy?',
            showLogo: true,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              button: true,
              label: 'Perfil activo ${activeProfile.label}. Toca para cambiar.',
              child: TactilePress(
                borderRadius: 24,
                onTap: () => context.push('/profile'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: p.sand,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: p.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: p.ink,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Perfil: ${activeProfile.label}',
                        style: TextStyle(
                          color: p.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: p.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: 'Busca estación, clínica o destino...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: (_) => _launchMapSearch(),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Buscar ruta accesible en el mapa',
                  child: TactilePress(
                    borderRadius: 24,
                    onTap: _launchMapSearch,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: p.ctaBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: p.ctaFg,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            decoration: BoxDecoration(
              color: p.lavender,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ShortcutRow(items: shortcuts.sublist(0, 4)),
                const SizedBox(height: 16),
                _ShortcutRow(items: shortcuts.sublist(4, 8)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TactilePress(
            borderRadius: 22,
            onTap: _openCopilot,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.ctaBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: p.coral,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pregúntale a VíaLibre · Gemini',
                          style: TextStyle(
                            color: p.ctaFg,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Habla o escribe para pedir rutas, consejos o ayuda al instante.',
                          style: TextStyle(
                            color: p.ctaFg.withValues(alpha: 0.78),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: p.ctaFg.withValues(alpha: 0.78),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lugares accesibles cerca',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () => _launchCategoryOnMap(
                  categoryKey: 'rampas',
                  placesQuery: 'entrada accesible rampa clínica',
                  onlyWheelchair: true,
                ),
                child: Text(
                  'Ver mapa',
                  style: TextStyle(
                    color: p.coral,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 176,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _HighlightCard(
                  badge: 'Cero escalones',
                  badgeBg: p.mintSoft,
                  badgeFg: p.mintInk,
                  title: 'Clínica Familiar / Centro de Salud',
                  subtitle: 'Rampa continua y acceso directo en banqueta.',
                  icon: Icons.local_hospital_rounded,
                  onTap: () => _launchMapSearch('Clínica cercana accesible'),
                ),
                const SizedBox(width: 12),
                _HighlightCard(
                  badge: 'Elevador activo',
                  badgeBg: p.lavender,
                  badgeFg: p.lavenderInk,
                  title: 'Estación Metro / Metrobús cercana',
                  subtitle: 'Guía paso a paso para abordar sin dudas.',
                  icon: Icons.subway_rounded,
                  onTap: () => _launchMapSearch('Estación de Metro accesible'),
                ),
                const SizedBox(width: 12),
                _HighlightCard(
                  badge: 'Aviso claro hoy',
                  badgeBg: p.amberSoft,
                  badgeFg: p.amberInk,
                  title: 'Desvíos y obras en tu zona',
                  subtitle: 'Explicados en 3 pasos y listos para escuchar.',
                  icon: Icons.campaign_rounded,
                  onTap: () => context.go('/briefs'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TactilePress(
            borderRadius: 22,
            onTap: _openFirstTimerStarterGuide,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: p.sand,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: p.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: p.coralSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.record_voice_over_rounded,
                      color: p.coral,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Primera vez en Metro o camión?',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Abre la guía paso a paso en lenguaje simple antes de viajar.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: p.ink,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutTileData {
  const _ShortcutTileData({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.items});

  final List<_ShortcutTileData> items;

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Semantics(
                button: true,
                label: item.label,
                child: TactilePress(
                  borderRadius: 16,
                  onTap: item.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: p.card,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            color: p.lavenderInk,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: p.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.badge,
    required this.badgeBg,
    required this.badgeFg,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String badge;
  final Color badgeBg;
  final Color badgeFg;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    return SizedBox(
      width: 245,
      child: TactilePress(
        borderRadius: 22,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: p.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: badgeFg,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, color: p.ink, size: 22),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
