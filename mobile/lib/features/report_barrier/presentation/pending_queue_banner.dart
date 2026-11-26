import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/vialibre_theme.dart';
import '../../../../core/offline/sync_manager.dart';

/// Banner informativo cuando existen reportes guardados en SQLite pendientes de sincronizar.
class PendingQueueBanner extends ConsumerStatefulWidget {
  const PendingQueueBanner({super.key});

  @override
  ConsumerState<PendingQueueBanner> createState() => _PendingQueueBannerState();
}

class _PendingQueueBannerState extends ConsumerState<PendingQueueBanner> {
  bool _syncing = false;

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    try {
      await ref.read(syncManagerProvider).syncPending();
      final remaining = await ref.read(syncManagerProvider).pendingCount();
      ref.read(pendingOfflineCountProvider.notifier).state = remaining;
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    final pendingCount = ref.watch(pendingOfflineCountProvider);
    if (pendingCount <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.amberSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: p.amberInk,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$pendingCount reporte(s) pendientes por enviar cuando haya conexión.',
              style: TextStyle(
                color: p.amberInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: _syncing ? null : _syncNow,
            child: _syncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Reintentar',
                    style: TextStyle(
                      color: p.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
