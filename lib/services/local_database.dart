import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'cumbigestor_offline.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla para usuarios
    await db.execute('''
      CREATE TABLE usuarios(
        id TEXT PRIMARY KEY,
        nombres TEXT NOT NULL,
        apellidos TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        telefono TEXT,
        cedula TEXT,
        estado TEXT DEFAULT 'activo',
        rol TEXT DEFAULT 'usuario',
        fecha_registro TEXT,
        updated_at INTEGER,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    // Tabla para solicitudes
    await db.execute('''
      CREATE TABLE solicitudes(
        id TEXT PRIMARY KEY,
        usuario_id TEXT NOT NULL,
        motivo TEXT NOT NULL,
        descripcion TEXT,
        estado TEXT DEFAULT 'pendiente',
        fecha_creacion TEXT NOT NULL,
        fecha_actualizacion TEXT,
        comentario_admin TEXT,
        updated_at INTEGER,
        sync_status TEXT DEFAULT 'pending',
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
      )
    ''');

    // Tabla para documentos
    await db.execute('''
      CREATE TABLE documentos(
        id TEXT PRIMARY KEY,
        solicitud_id TEXT NOT NULL,
        nombre TEXT NOT NULL,
        tipo TEXT NOT NULL,
        url TEXT,
        local_path TEXT,
        tamano INTEGER,
        fecha_subida TEXT,
        updated_at INTEGER,
        sync_status TEXT DEFAULT 'pending',
        FOREIGN KEY (solicitud_id) REFERENCES solicitudes (id)
      )
    ''');

    // Tabla para cola de sincronización
    await db.execute('''
      CREATE TABLE sync_queue(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT,
        created_at INTEGER NOT NULL,
        attempts INTEGER DEFAULT 0,
        last_attempt INTEGER
      )
    ''');

    // Índices para mejorar rendimiento
    await db.execute('CREATE INDEX idx_solicitudes_usuario ON solicitudes(usuario_id)');
    await db.execute('CREATE INDEX idx_documentos_solicitud ON documentos(solicitud_id)');
    await db.execute('CREATE INDEX idx_sync_queue_table ON sync_queue(table_name)');
    await db.execute('CREATE INDEX idx_sync_status ON solicitudes(sync_status)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Implementar migraciones futuras aquí
    if (oldVersion < 2) {
      // Ejemplo de migración
      // await db.execute('ALTER TABLE usuarios ADD COLUMN nueva_columna TEXT');
    }
  }

  // Métodos para usuarios
  Future<int> insertUsuario(Map<String, dynamic> usuario) async {
    final db = await database;
    usuario['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    usuario['sync_status'] = 'pending';
    return await db.insert('usuarios', usuario);
  }

  Future<List<Map<String, dynamic>>> getUsuarios() async {
    final db = await database;
    return await db.query('usuarios');
  }

  Future<Map<String, dynamic>?> getUsuario(String id) async {
    final db = await database;
    final result = await db.query(
      'usuarios', 
      where: 'id = ?', 
      whereArgs: [id],
      limit: 1
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateUsuario(String id, Map<String, dynamic> usuario) async {
    final db = await database;
    usuario['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    usuario['sync_status'] = 'pending';
    return await db.update(
      'usuarios',
      usuario,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Métodos para solicitudes
  Future<int> insertSolicitud(Map<String, dynamic> solicitud) async {
    final db = await database;
    solicitud['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    solicitud['sync_status'] = 'pending';
    return await db.insert('solicitudes', solicitud);
  }

  Future<List<Map<String, dynamic>>> getSolicitudes({String? usuarioId}) async {
    final db = await database;
    if (usuarioId != null) {
      return await db.query(
        'solicitudes',
        where: 'usuario_id = ?',
        whereArgs: [usuarioId],
        orderBy: 'fecha_creacion DESC',
      );
    }
    return await db.query('solicitudes', orderBy: 'fecha_creacion DESC');
  }

  Future<Map<String, dynamic>?> getSolicitud(String id) async {
    final db = await database;
    final result = await db.query(
      'solicitudes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateSolicitud(String id, Map<String, dynamic> solicitud) async {
    final db = await database;
    solicitud['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    solicitud['sync_status'] = 'pending';
    return await db.update(
      'solicitudes',
      solicitud,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Métodos para documentos
  Future<int> insertDocumento(Map<String, dynamic> documento) async {
    final db = await database;
    documento['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    documento['sync_status'] = 'pending';
    return await db.insert('documentos', documento);
  }

  Future<List<Map<String, dynamic>>> getDocumentos({String? solicitudId}) async {
    final db = await database;
    if (solicitudId != null) {
      return await db.query(
        'documentos',
        where: 'solicitud_id = ?',
        whereArgs: [solicitudId],
      );
    }
    return await db.query('documentos');
  }

  Future<int> updateDocumento(String id, Map<String, dynamic> documento) async {
    final db = await database;
    documento['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    documento['sync_status'] = 'pending';
    return await db.update(
      'documentos',
      documento,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Métodos para cola de sincronización
  Future<int> addToSyncQueue({
    required String tableName,
    required String recordId,
    required String operation,
    Map<String, dynamic>? data,
  }) async {
    final db = await database;
    return await db.insert('sync_queue', {
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'data': data != null ? data.toString() : null,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'attempts': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      orderBy: 'created_at ASC',
      limit: 50, // Procesar en lotes
    );
  }

  Future<int> removeSyncItem(int id) async {
    final db = await database;
    return await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> incrementSyncAttempts(int id) async {
    final db = await database;
    return await db.update(
      'sync_queue',
      {
        'attempts': db.rawQuery('SELECT attempts + 1 FROM sync_queue WHERE id = ?', [id]),
        'last_attempt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Métodos para obtener registros que necesitan sincronización
  Future<List<Map<String, dynamic>>> getPendingSync(String tableName) async {
    final db = await database;
    return await db.query(
      tableName,
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );
  }

  Future<int> markAsSynced(String tableName, String id) async {
    final db = await database;
    return await db.update(
      tableName,
      {'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Limpiar base de datos
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('sync_queue');
    await db.delete('documentos');
    await db.delete('solicitudes');
    await db.delete('usuarios');
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
