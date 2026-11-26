import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class OfflineReportItem {
  const OfflineReportItem({
    required this.idempotencyKey,
    required this.lat,
    required this.lng,
    required this.inputMode,
    required this.createdAtIso,
    this.accuracyMeters,
    this.localPhotoPath,
    this.textNote,
    this.payloadJson,
  });

  final String idempotencyKey;
  final double lat;
  final double lng;
  final String inputMode;
  final String createdAtIso;
  final double? accuracyMeters;
  final String? localPhotoPath;
  final String? textNote;
  final String? payloadJson;

  Map<String, Object?> toMap() => {
        'idempotency_key': idempotencyKey,
        'lat': lat,
        'lng': lng,
        'accuracy_meters': accuracyMeters,
        'input_mode': inputMode,
        'local_photo_path': localPhotoPath,
        'text_note': textNote,
        'payload_json': payloadJson,
        'created_at': createdAtIso,
      };

  factory OfflineReportItem.fromMap(Map<String, Object?> map) {
    return OfflineReportItem(
      idempotencyKey: map['idempotency_key']! as String,
      lat: (map['lat']! as num).toDouble(),
      lng: (map['lng']! as num).toDouble(),
      accuracyMeters: (map['accuracy_meters'] as num?)?.toDouble(),
      inputMode: map['input_mode']! as String,
      localPhotoPath: map['local_photo_path'] as String?,
      textNote: map['text_note'] as String?,
      payloadJson: map['payload_json'] as String?,
      createdAtIso: map['created_at']! as String,
    );
  }
}

/// Base SQLite local para guardar borradores de reportes cuando no hay señal.
class OfflineDb {
  Database? _db;

  Future<Database> _database() async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'vialibre_offline.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          create table offline_reports (
            idempotency_key text primary key,
            lat real not null,
            lng real not null,
            accuracy_meters real,
            input_mode text not null,
            local_photo_path text,
            text_note text,
            payload_json text,
            created_at text not null
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> enqueue(OfflineReportItem item) async {
    final db = await _database();
    await db.insert(
      'offline_reports',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<OfflineReportItem>> getPending() async {
    final db = await _database();
    final rows = await db.query('offline_reports', orderBy: 'created_at ASC');
    return rows.map(OfflineReportItem.fromMap).toList();
  }

  Future<void> remove(String idempotencyKey) async {
    final db = await _database();
    await db.delete(
      'offline_reports',
      where: 'idempotency_key = ?',
      whereArgs: [idempotencyKey],
    );
  }
}
