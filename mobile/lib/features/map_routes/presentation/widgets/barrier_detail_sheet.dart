import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/vialibre_theme.dart';
import '../../../../core/widgets/accessible_button.dart';
import '../../data/barriers_realtime_repo.dart';
import '../../domain/barrier_model.dart';

/// Hoja inferior con detalles del obstáculo (`GET /api/barriers/:id`) y voto ciudadano resuelto.
class BarrierDetailSheet extends ConsumerStatefulWidget {
  const BarrierDetailSheet({
    required this.barrier,
    required this.onResolved,
    super.key,
  });

  final BarrierPin barrier;
  final VoidCallback onResolved;

  @override
  ConsumerState<BarrierDetailSheet> createState() => _BarrierDetailSheetState();
}

class _BarrierDetailSheetState extends ConsumerState<BarrierDetailSheet> {
  BarrierPin? _enriched;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await ref
          .read(barriersRealtimeRepoProvider)
          .fetchDetail(widget.barrier.id);
      if (mounted) {
        setState(() => _enriched = detail);
      }
    } catch (_) {
      // Mantiene datos base si aún no hay conexión o el servidor no responde.
    }
  }

  Future<void> _voteResolved() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref
          .read(barriersRealtimeRepoProvider)
          .voteResolved(barrierId: widget.barrier.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onResolved();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    final barrier = _enriched ?? widget.barrier;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: p.alertRedSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Severidad ${barrier.severity}/5 · ${barrier.categoryLabel}',
                    style: TextStyle(
                      color: p.alertRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${barrier.confirmationsCount} conf.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              barrier.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (barrier.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText(
                barrier.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            if (barrier.photoSignedUrl != null &&
                barrier.photoSignedUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  barrier.photoSignedUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ],
            if (barrier.distanceMeters != null) ...[
              const SizedBox(height: 8),
              Text(
                'Distancia aprox.: ${barrier.distanceMeters!.round()} m',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: p.alertRed),
              ),
            ],
            const SizedBox(height: 20),
            AccessibleButton(
              label: 'Ya está libre / Reparado',
              icon: Icons.check_circle_outline_rounded,
              backgroundColor: const Color(0xFF166534),
              foregroundColor: Colors.white,
              isLoading: _submitting,
              semanticHint:
                  'Reportar que este obstáculo urbano ya fue liberado',
              onPressed: _voteResolved,
            ),
          ],
        ),
      ),
    );
  }
}
