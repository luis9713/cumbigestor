import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _internetChecker = InternetConnectionChecker.createInstance();
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<InternetConnectionStatus>? _internetSubscription;
  
  bool _isConnected = false;
  bool _hasInternet = false;
  List<ConnectivityResult> _connectionTypes = [ConnectivityResult.none];

  bool get isConnected => _isConnected && _hasInternet;
  bool get hasWifi => _connectionTypes.contains(ConnectivityResult.wifi) && _hasInternet;
  bool get hasMobile => _connectionTypes.contains(ConnectivityResult.mobile) && _hasInternet;
  List<ConnectivityResult> get connectionTypes => _connectionTypes;

  Future<void> initialize() async {
    // Verificar estado inicial
    await _updateConnectionStatus();
    
    // Escuchar cambios de conectividad
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        _connectionTypes = results;
        _isConnected = !results.every((result) => result == ConnectivityResult.none);
        await _checkInternetConnection();
        notifyListeners();
      },
    );

    // Escuchar cambios de conexión a internet real
    _internetSubscription = _internetChecker.onStatusChange.listen(
      (InternetConnectionStatus status) {
        _hasInternet = status == InternetConnectionStatus.connected;
        notifyListeners();
      },
    );
  }

  Future<void> _updateConnectionStatus() async {
    try {
      _connectionTypes = await _connectivity.checkConnectivity();
      _isConnected = !_connectionTypes.every((result) => result == ConnectivityResult.none);
      await _checkInternetConnection();
    } catch (e) {
      print('Error checking connectivity: $e');
      _isConnected = false;
      _hasInternet = false;
    }
  }

  Future<void> _checkInternetConnection() async {
    if (_isConnected) {
      try {
        _hasInternet = await _internetChecker.hasConnection;
      } catch (e) {
        print('Error checking internet connection: $e');
        _hasInternet = false;
      }
    } else {
      _hasInternet = false;
    }
  }

  Future<bool> checkConnection() async {
    await _updateConnectionStatus();
    return isConnected;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
    super.dispose();
  }
}
