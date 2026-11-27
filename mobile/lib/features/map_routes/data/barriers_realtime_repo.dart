import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/env.dart';
import '../../../core/network/bff_client.dart';
import '../domain/barrier_model.dart';

/// Repositorio en tiempo real de barreras urbanas (`GET /api/barriers/*` + Supabase Realtime).
class BarriersRealtimeRepo {
  BarriersRealtimeRepo(this._bff);

  final BffClient _bff;
  RealtimeChannel? _channel;

  SupabaseClient? get _client {
    try {
      return Env.isInitialized ? Supabase.instance.client : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<BarrierPin>> fetchNearby({
    required double lat,
    required double lng,
    double radiusMeters = 500,
  }) async {
    try {
      final json = await _bff.getJson(
        '/api/barriers/nearby?lat=$lat&lng=$lng&radius=${radiusMeters.round()}&format=json',
        requireAuth: false,
      );
      final raw = (json['barriers'] as List?) ?? const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(BarrierPin.fromRpcJson)
          .toList();
    } catch (_) {
      final client = _client;
      if (client == null) return const [];
      final res = await client.rpc(
        'find_nearby_barriers',
        params: {
          'p_lat': lat,
          'p_lng': lng,
          'p_radius_meters': radiusMeters,
        },
      );
      if (res is! List) return const [];
      return res
          .whereType<Map<String, dynamic>>()
          .map(BarrierPin.fromRpcJson)
          .toList();
    }
  }

  Future<BarrierPin> fetchDetail(int barrierId) async {
    final json = await _bff.getJson('/api/barriers/$barrierId');
    final raw = json['barrier'];
    if (raw is Map<String, dynamic>) {
      return BarrierPin.fromRpcJson(raw);
    }
    return BarrierPin.fromRpcJson(json);
  }

  Future<List<BarrierPin>> fetchMine() async {
    final json = await _bff.getJson('/api/barriers/mine');
    final raw = (json['barriers'] as List?) ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(BarrierPin.fromRpcJson)
        .toList();
  }

  /// Escucha INSERT/UPDATE en `public.barriers` para actualizar el mapa al instante.
  void subscribeToLiveUpdates(void Function() onDatabaseChanged) {
    final client = _client;
    if (client == null) return;

    _channel?.unsubscribe();
    _channel = client
        .channel('public:barriers')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'barriers',
          callback: (_) => onDatabaseChanged(),
        )
        .subscribe();
  }

  Future<void> voteResolved({
    required int barrierId,
    String? note,
    String? photoPath,
  }) async {
    await _bff.postJson('/api/barriers/resolve', {
      'barrierId': barrierId,
      'idempotencyKey': const Uuid().v4(),
      'note': note ?? 'Confirmado despejado desde la app',
      if (photoPath != null) 'photoPath': photoPath,
    });
  }

  void dispose() {
    _channel?.unsubscribe();
  }
}

final barriersRealtimeRepoProvider = Provider<BarriersRealtimeRepo>((ref) {
  final repo = BarriersRealtimeRepo(ref.read(bffClientProvider));
  ref.onDispose(repo.dispose);
  return repo;
});
