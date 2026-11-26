import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/explore/presentation/explore_screen.dart';
import '../features/map_routes/presentation/map_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/public_briefs/presentation/briefs_screen.dart';
import '../features/report_barrier/presentation/report_screen.dart';
import 'theme/vialibre_theme.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/explore',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _ViaLibreShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/report',
                builder: (context, state) => const ReportScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/briefs',
                builder: (context, state) => const BriefsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});

class _ViaLibreShell extends StatelessWidget {
  const _ViaLibreShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = <_NavPillItem>[
    _NavPillItem(
      label: 'Explorar',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavPillItem(
      label: 'Mapa',
      icon: Icons.map_outlined,
      activeIcon: Icons.map_rounded,
    ),
    _NavPillItem(
      label: 'Reportar',
      icon: Icons.add_alert_outlined,
      activeIcon: Icons.add_alert_rounded,
    ),
    _NavPillItem(
      label: 'Avisos',
      icon: Icons.campaign_outlined,
      activeIcon: Icons.campaign_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: p.border),
            boxShadow: [
              BoxShadow(
                color: p.isDark
                    ? const Color(0x55000000)
                    : const Color(0x14000000),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = navigationShell.currentIndex == index;

              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: item.label,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        navigationShell.goBranch(
                          index,
                          initialLocation: index == navigationShell.currentIndex,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOut,
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? p.coral : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              selected ? item.activeIcon : item.icon,
                              size: 20,
                              color: selected ? Colors.white : p.muted,
                            ),
                            if (selected) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavPillItem {
  const _NavPillItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}
