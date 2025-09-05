import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_database.dart';
import 'connectivity_service.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final LocalDatabase _localDb = LocalDatabase();
  final ConnectivityService _connectivity = ConnectivityService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Timer? _syncTimer;
  bool _isSyncing = false;
  bool _autoSyncEnabled = true;

  // Callbacks para notificar el progreso de sincronización
  Function(int pending, int synced)? onSyncProgress;
  Function(String message)? onSyncError;
  Function()? onSyncComplete;

  void startAutoSync() {
    _autoSyncEnabled = true;
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_connectivity.isConnected && !_isSyncing) {
        syncAll();
      }
    });
  }

  void stopAutoSync() {
    _autoSyncEnabled = false;
    _syncTimer?.cancel();
  }

  Future<void> syncAll() async {
    if (_isSyncing || !_connectivity.isConnected) return;

    _isSyncing = true;
    
    try {
      print('🔄 Iniciando sincronización...');
      
      // 1. Sincronizar datos hacia Firebase
      await _syncToFirebase();
      
      // 2. Sincronizar datos desde Firebase
      await _syncFromFirebase();
      
      print('✅ Sincronización completada');
      onSyncComplete?.call();
    } catch (e) {
      print('❌ Error en sincronización: $e');
      onSyncError?.call(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncToFirebase() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Sincronizar solicitudes pendientes
    await _syncSolicitudes();
    
    // Sincronizar documentos pendientes
    await _syncDocumentos();
  }

  Future<void> _syncSolicitudes() async {
    try {
      final pendingSolicitudes = await _localDb.getPendingSync('solicitudes');
      int synced = 0;

      for (var solicitud in pendingSolicitudes) {
        try {
          final solicitudData = Map<String, dynamic>.from(solicitud);
          solicitudData.remove('sync_status');
          solicitudData.remove('updated_at');

          // Si es una solicitud nueva (creada offline)
          if (solicitudData['id'].toString().startsWith('offline_')) {
            // Crear nueva solicitud en Firebase
            final docRef = await _firestore
                .collection('solicitudes')
                .add(solicitudData);
            
            // Actualizar ID local con el ID de Firebase
            final oldId = solicitudData['id'];
            solicitudData['id'] = docRef.id;
            
            await _localDb.updateSolicitud(oldId, solicitudData);
            await _localDb.markAsSynced('solicitudes', docRef.id);
          } else {
            // Actualizar solicitud existente
            await _firestore
                .collection('solicitudes')
                .doc(solicitudData['id'])
                .set(solicitudData, SetOptions(merge: true));
            
            await _localDb.markAsSynced('solicitudes', solicitudData['id']);
          }
          
          synced++;
          onSyncProgress?.call(pendingSolicitudes.length - synced, synced);
        } catch (e) {
          print('Error sincronizando solicitud ${solicitud['id']}: $e');
        }
      }

      print('✅ Solicitudes sincronizadas: $synced/${pendingSolicitudes.length}');
    } catch (e) {
      print('Error sincronizando solicitudes: $e');
      throw e;
    }
  }

  Future<void> _syncDocumentos() async {
    try {
      final pendingDocumentos = await _localDb.getPendingSync('documentos');
      int synced = 0;

      for (var documento in pendingDocumentos) {
        try {
          final docData = Map<String, dynamic>.from(documento);
          docData.remove('sync_status');
          docData.remove('updated_at');

          // Si es un documento nuevo (creado offline)
          if (docData['id'].toString().startsWith('offline_')) {
            // Crear nuevo documento en Firebase
            final docRef = await _firestore
                .collection('documentos')
                .add(docData);
            
            // Actualizar ID local con el ID de Firebase
            final oldId = docData['id'];
            docData['id'] = docRef.id;
            
            await _localDb.updateDocumento(oldId, docData);
            await _localDb.markAsSynced('documentos', docRef.id);
          } else {
            // Actualizar documento existente
            await _firestore
                .collection('documentos')
                .doc(docData['id'])
                .set(docData, SetOptions(merge: true));
            
            await _localDb.markAsSynced('documentos', docData['id']);
          }
          
          synced++;
          onSyncProgress?.call(pendingDocumentos.length - synced, synced);
        } catch (e) {
          print('Error sincronizando documento ${documento['id']}: $e');
        }
      }

      print('✅ Documentos sincronizados: $synced/${pendingDocumentos.length}');
    } catch (e) {
      print('Error sincronizando documentos: $e');
      throw e;
    }
  }

  Future<void> _syncFromFirebase() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Obtener última fecha de sincronización
      final lastSync = await _getLastSyncDate();
      
      // Sincronizar solicitudes del usuario desde Firebase
      await _syncSolicitudesFromFirebase(currentUser.uid, lastSync);
      
      // Guardar nueva fecha de sincronización
      await _saveLastSyncDate();
      
    } catch (e) {
      print('Error sincronizando desde Firebase: $e');
      throw e;
    }
  }

  Future<void> _syncSolicitudesFromFirebase(String userId, DateTime? lastSync) async {
    try {
      Query query = _firestore
          .collection('solicitudes')
          .where('usuario_id', isEqualTo: userId);

      if (lastSync != null) {
        query = query.where('fecha_actualizacion', isGreaterThan: Timestamp.fromDate(lastSync));
      }

      final snapshot = await query.get();
      int updated = 0;

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          data['sync_status'] = 'synced';

          // Verificar si existe localmente
          final existingLocal = await _localDb.getSolicitud(doc.id);
          
          if (existingLocal != null) {
            // Actualizar registro existente
            await _localDb.updateSolicitud(doc.id, data);
          } else {
            // Insertar nuevo registro
            await _localDb.insertSolicitud(data);
          }

          // Sincronizar documentos de esta solicitud
          await _syncDocumentosFromFirebase(doc.id);
          
          updated++;
        } catch (e) {
          print('Error procesando solicitud ${doc.id}: $e');
        }
      }

      print('✅ Solicitudes actualizadas desde Firebase: $updated');
    } catch (e) {
      print('Error sincronizando solicitudes desde Firebase: $e');
      throw e;
    }
  }

  Future<void> _syncDocumentosFromFirebase(String solicitudId) async {
    try {
      final snapshot = await _firestore
          .collection('documentos')
          .where('solicitud_id', isEqualTo: solicitudId)
          .get();

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          data['sync_status'] = 'synced';

          // Verificar si existe localmente
          final existingDocs = await _localDb.getDocumentos(solicitudId: solicitudId);
          final existing = existingDocs.firstWhere(
            (d) => d['id'] == doc.id,
            orElse: () => <String, dynamic>{},
          );

          if (existing.isNotEmpty) {
            // Actualizar registro existente
            await _localDb.updateDocumento(doc.id, data);
          } else {
            // Insertar nuevo registro
            await _localDb.insertDocumento(data);
          }
        } catch (e) {
          print('Error procesando documento ${doc.id}: $e');
        }
      }
    } catch (e) {
      print('Error sincronizando documentos desde Firebase: $e');
    }
  }

  Future<DateTime?> _getLastSyncDate() async {
    try {
      // Usar SharedPreferences para guardar fecha de última sincronización
      // Por ahora retornamos null para sincronizar todo
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveLastSyncDate() async {
    try {
      // Guardar fecha actual como última sincronización
      // Implementar con SharedPreferences si es necesario
    } catch (e) {
      print('Error guardando fecha de sincronización: $e');
    }
  }

  // Métodos para manejar operaciones offline
  Future<String> createSolicitudOffline({
    required String usuarioId,
    required String motivo,
    required String descripcion,
  }) async {
    final offlineId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    
    final solicitudData = {
      'id': offlineId,
      'usuario_id': usuarioId,
      'motivo': motivo,
      'descripcion': descripcion,
      'estado': 'pendiente',
      'fecha_creacion': DateTime.now().toIso8601String(),
      'fecha_actualizacion': DateTime.now().toIso8601String(),
    };

    await _localDb.insertSolicitud(solicitudData);
    
    // Intentar sincronizar inmediatamente si hay conexión
    if (_connectivity.isConnected) {
      Timer(const Duration(seconds: 2), () => syncAll());
    }

    return offlineId;
  }

  Future<String> addDocumentoOffline({
    required String solicitudId,
    required String nombre,
    required String tipo,
    String? localPath,
  }) async {
    final offlineId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    
    final documentoData = {
      'id': offlineId,
      'solicitud_id': solicitudId,
      'nombre': nombre,
      'tipo': tipo,
      'local_path': localPath,
      'fecha_subida': DateTime.now().toIso8601String(),
    };

    await _localDb.insertDocumento(documentoData);
    
    // Intentar sincronizar inmediatamente si hay conexión
    if (_connectivity.isConnected) {
      Timer(const Duration(seconds: 2), () => syncAll());
    }

    return offlineId;
  }

  // Estado de sincronización
  bool get isSyncing => _isSyncing;
  bool get autoSyncEnabled => _autoSyncEnabled;

  Future<Map<String, int>> getSyncStatus() async {
    final pendingSolicitudes = await _localDb.getPendingSync('solicitudes');
    final pendingDocumentos = await _localDb.getPendingSync('documentos');
    
    return {
      'pending_solicitudes': pendingSolicitudes.length,
      'pending_documentos': pendingDocumentos.length,
      'total_pending': pendingSolicitudes.length + pendingDocumentos.length,
    };
  }

  void dispose() {
    stopAutoSync();
    _syncTimer?.cancel();
  }
}
