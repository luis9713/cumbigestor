import 'dart:async';
import 'package:flutter/foundation.dart';
import 'connectivity_service.dart';
import 'sync_manager.dart';
import 'local_database.dart';

enum OfflineStatus {
  online,
  offline,
  syncing,
  syncError,
}

class OfflineManager extends ChangeNotifier {
  static final OfflineManager _instance = OfflineManager._internal();
  factory OfflineManager() => _instance;
  OfflineManager._internal();

  final ConnectivityService _connectivity = ConnectivityService();
  final SyncManager _syncManager = SyncManager();
  final LocalDatabase _localDb = LocalDatabase();

  OfflineStatus _status = OfflineStatus.offline;
  String? _lastError;
  int _pendingOperations = 0;
  bool _initialized = false;

  // Getters
  OfflineStatus get status => _status;
  bool get isOnline => _status == OfflineStatus.online;
  bool get isOffline => _status == OfflineStatus.offline;
  bool get isSyncing => _status == OfflineStatus.syncing;
  String? get lastError => _lastError;
  int get pendingOperations => _pendingOperations;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Inicializar servicios
      await _connectivity.initialize();
      await _localDb.database; // Inicializar base de datos

      // Configurar listeners
      _connectivity.addListener(_onConnectivityChanged);
      _setupSyncCallbacks();

      // Verificar estado inicial
      await _updateStatus();

      // Iniciar auto-sync si hay conexión
      if (_connectivity.isConnected) {
        _syncManager.startAutoSync();
        await _performInitialSync();
      }

      _initialized = true;
      print('✅ OfflineManager inicializado');
    } catch (e) {
      print('❌ Error inicializando OfflineManager: $e');
      _status = OfflineStatus.syncError;
      _lastError = e.toString();
      notifyListeners();
    }
  }

  void _setupSyncCallbacks() {
    _syncManager.onSyncProgress = (pending, synced) {
      _pendingOperations = pending;
      notifyListeners();
    };

    _syncManager.onSyncError = (error) {
      _status = OfflineStatus.syncError;
      _lastError = error;
      notifyListeners();
    };

    _syncManager.onSyncComplete = () {
      _updatePendingOperations();
      if (_connectivity.isConnected) {
        _status = OfflineStatus.online;
      } else {
        _status = OfflineStatus.offline;
      }
      _lastError = null;
      
      // Mostrar notificación de sincronización exitosa
      _showSyncCompletedNotification();
      
      notifyListeners();
    };
  }

  void _showSyncCompletedNotification() {
    // Este método será llamado desde los widgets que escuchan al OfflineManager
    // usando Consumer para mostrar un SnackBar cuando la sincronización se complete
    _syncCompletedCallback?.call();
  }

  // Callback para notificar sincronización completada
  VoidCallback? _syncCompletedCallback;
  VoidCallback? _reconnectedCallback;
  
  void setSyncCompletedCallback(VoidCallback callback) {
    _syncCompletedCallback = callback;
  }

  void removeSyncCompletedCallback() {
    _syncCompletedCallback = null;
  }

  void setReconnectedCallback(VoidCallback callback) {
    _reconnectedCallback = callback;
  }

  void removeReconnectedCallback() {
    _reconnectedCallback = null;
  }

  void _onConnectivityChanged() async {
    final wasOffline = _status == OfflineStatus.offline;
    
    await _updateStatus();
    
    if (_connectivity.isConnected && _status != OfflineStatus.syncing) {
      // Reconectado - iniciar sincronización
      _syncManager.startAutoSync();
      
      // Si venía de offline, mostrar mensaje de reconexión
      if (wasOffline) {
        _reconnectedCallback?.call();
      }
      
      await performSync();
    } else if (!_connectivity.isConnected) {
      // Desconectado - detener auto-sync
      _syncManager.stopAutoSync();
      _status = OfflineStatus.offline;
      notifyListeners();
    }
  }

  Future<void> _updateStatus() async {
    if (_syncManager.isSyncing) {
      _status = OfflineStatus.syncing;
    } else if (_connectivity.isConnected) {
      _status = OfflineStatus.online;
    } else {
      _status = OfflineStatus.offline;
    }
    
    await _updatePendingOperations();
    notifyListeners();
  }

  Future<void> _updatePendingOperations() async {
    try {
      final syncStatus = await _syncManager.getSyncStatus();
      _pendingOperations = syncStatus['total_pending'] ?? 0;
    } catch (e) {
      print('Error actualizando operaciones pendientes: $e');
    }
  }

  Future<void> _performInitialSync() async {
    if (!_connectivity.isConnected) return;
    
    try {
      _status = OfflineStatus.syncing;
      notifyListeners();
      
      await _syncManager.syncAll();
    } catch (e) {
      print('Error en sincronización inicial: $e');
    }
  }

  // Métodos públicos para operaciones offline
  Future<void> performSync() async {
    if (!_connectivity.isConnected) {
      _lastError = 'No hay conexión a internet';
      return;
    }

    if (_syncManager.isSyncing) return;

    try {
      _status = OfflineStatus.syncing;
      _lastError = null;
      notifyListeners();
      
      await _syncManager.syncAll();
    } catch (e) {
      _status = OfflineStatus.syncError;
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<String> createSolicitudOffline({
    required String usuarioId,
    required String motivo,
    required String descripcion,
  }) async {
    final solicitudId = await _syncManager.createSolicitudOffline(
      usuarioId: usuarioId,
      motivo: motivo,
      descripcion: descripcion,
    );
    
    await _updatePendingOperations();
    notifyListeners();
    
    return solicitudId;
  }

  Future<String> addDocumentoOffline({
    required String solicitudId,
    required String nombre,
    required String tipo,
    String? localPath,
  }) async {
    final documentoId = await _syncManager.addDocumentoOffline(
      solicitudId: solicitudId,
      nombre: nombre,
      tipo: tipo,
      localPath: localPath,
    );
    
    await _updatePendingOperations();
    notifyListeners();
    
    return documentoId;
  }

  // Métodos para acceder a datos locales
  Future<List<Map<String, dynamic>>> getSolicitudesLocales({String? usuarioId}) async {
    return await _localDb.getSolicitudes(usuarioId: usuarioId);
  }

  Future<Map<String, dynamic>?> getSolicitudLocal(String id) async {
    return await _localDb.getSolicitud(id);
  }

  Future<List<Map<String, dynamic>>> getDocumentosLocales({String? solicitudId}) async {
    return await _localDb.getDocumentos(solicitudId: solicitudId);
  }

  // Método para forzar reconexión
  Future<void> forceSync() async {
    await _connectivity.checkConnection();
    if (_connectivity.isConnected) {
      await performSync();
    }
  }

  // Limpiar datos offline (usar con cuidado)
  Future<void> clearOfflineData() async {
    await _localDb.clearDatabase();
    await _updatePendingOperations();
    notifyListeners();
  }

  // Información de estado para UI
  String getStatusMessage() {
    switch (_status) {
      case OfflineStatus.online:
        return _pendingOperations > 0 
            ? 'En línea - $_pendingOperations operaciones pendientes'
            : 'En línea - Todo sincronizado';
      case OfflineStatus.offline:
        return _pendingOperations > 0
            ? 'Sin conexión - $_pendingOperations operaciones pendientes'
            : 'Sin conexión';
      case OfflineStatus.syncing:
        return 'Sincronizando...';
      case OfflineStatus.syncError:
        return 'Error de sincronización: $_lastError';
    }
  }

  // Método para verificar si una operación necesita conexión
  bool requiresConnection(String operation) {
    // Lista de operaciones que requieren conexión obligatoriamente
    const onlineOnlyOperations = [
      'upload_file',
      'download_file',
      'send_notification',
      'real_time_updates',
    ];
    
    return onlineOnlyOperations.contains(operation);
  }

  @override
  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
    _syncManager.dispose();
    super.dispose();
  }
}
