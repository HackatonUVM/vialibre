import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../media/image_sanitizer.dart';
import '../network/bff_client.dart';
import 'offline_db.dart';

/// Sincroniza borradores locales en cuanto vuelve la conectividad usando `idempotency_key`.
class SyncManager {
  SyncManager(this._db, this._bff);

  final OfflineDb _db;
  final BffClient _bff;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _isSyncing = false;

  void startListening(void Function(int remaining) onCountChanged) {
    _sub?.cancel();
    _sub = Connectivity().onConnectivityChanged.listen((results) async {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (hasNetwork) {
        await syncPending();
        final remaining = (await _db.getPending()).length;
        onCountChanged(remaining);
      }
    });
  }

  Future<int> pendingCount() async => (await _db.getPending()).length;

  Future<void> enqueue(OfflineReportItem item) => _db.enqueue(item);

  Future<int> syncPending() async {
    if (_isSyncing) return await pendingCount();
    _isSyncing = true;
    var synced = 0;

    try {
      final pending = await _db.getPending();
      for (final item in pending) {
        try {
          final body = item.payloadJson != null
              ? (jsonDecode(item.payloadJson!) as Map<String, dynamic>)
              : <String, dynamic>{
                  'idempotencyKey': item.idempotencyKey,
                  'lat': item.lat,
                  'lng': item.lng,
                  'accuracyMeters': item.accuracyMeters,
                  'inputMode': item.inputMode,
                  'textNote': item.textNote,
                };

          if (item.localPhotoPath != null) {
            final photo = File(item.localPhotoPath!);
            if (await photo.exists()) {
              final clean = await ImageSanitizer.sanitizeForUpload(photo);
              body['imageBase64'] = clean.base64Data;
            }
          }

          await _bff.postJson('/api/barriers/report', body);
          await _db.remove(item.idempotencyKey);
          synced++;
        } catch (_) {
          // Conserva el borrador en SQLite para el siguiente intento.
        }
      }
      return synced;
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}

final offlineDbProvider = Provider<OfflineDb>((ref) => OfflineDb());

final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(
    ref.read(offlineDbProvider),
    ref.read(bffClientProvider),
  );
  ref.onDispose(manager.dispose);
  return manager;
});

final pendingOfflineCountProvider = StateProvider<int>((ref) => 0);
