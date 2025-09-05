import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'solicitud_detail_view_screen.dart';
import '../services/offline_manager.dart';
import '../widgets/connection_indicator.dart';

class MisSolicitudesOfflineScreen extends StatefulWidget {
  const MisSolicitudesOfflineScreen({super.key});

  @override
  _MisSolicitudesOfflineScreenState createState() => _MisSolicitudesOfflineScreenState();
}

// Funciones utilitarias locales
String _capitalizeFirst(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

String _formatearFecha(dynamic fecha) {
  if (fecha == null) return 'Sin fecha';
  
  DateTime? fechaDateTime;
  
  if (fecha is String) {
    fechaDateTime = DateTime.tryParse(fecha);
  } else if (fecha is Timestamp) {
    fechaDateTime = fecha.toDate();
  } else if (fecha is DateTime) {
    fechaDateTime = fecha;
  }
  
  if (fechaDateTime == null) return 'Fecha inválida';
  
  return '${fechaDateTime.day.toString().padLeft(2, '0')}/${fechaDateTime.month.toString().padLeft(2, '0')}/${fechaDateTime.year}';
}

class _MisSolicitudesOfflineScreenState extends State<MisSolicitudesOfflineScreen> {
  List<Map<String, dynamic>> _solicitudes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSolicitudes();
  }

  Future<void> _loadSolicitudes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _error = "No hay usuario autenticado";
          _isLoading = false;
        });
        return;
      }

      final offlineManager = Provider.of<OfflineManager>(context, listen: false);
      
      if (offlineManager.isOnline) {
        // Online: usar Firebase directamente (se sincronizará automáticamente)
        await _loadFromFirebase(uid);
      } else {
        // Offline: usar datos locales
        await _loadFromLocal(uid);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFromFirebase(String uid) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('solicitudes')
          .where('usuario_id', isEqualTo: uid)
          .orderBy('fecha_creacion', descending: true)
          .get();

      final solicitudes = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _solicitudes = solicitudes;
        _isLoading = false;
      });
    } catch (e) {
      // Si falla Firebase, intentar cargar datos locales
      await _loadFromLocal(uid);
    }
  }

  Future<void> _loadFromLocal(String uid) async {
    try {
      final offlineManager = Provider.of<OfflineManager>(context, listen: false);
      final solicitudes = await offlineManager.getSolicitudesLocales(usuarioId: uid);

      setState(() {
        _solicitudes = solicitudes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    final offlineManager = Provider.of<OfflineManager>(context, listen: false);
    if (offlineManager.isOnline) {
      await offlineManager.performSync();
    }
    await _loadSolicitudes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Indicador de conexión
          const ConnectionIndicator(showWhenOnline: true),
          
          // AppBar integrada
          AppBar(
            title: const Text("Mis Solicitudes"),
            actions: [
              Consumer<OfflineManager>(
                builder: (context, offlineManager, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ConnectionStatusIcon(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _refresh,
                        tooltip: 'Actualizar',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          
          // Contenido principal
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: _buildCreateSolicitudFAB(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Error al cargar solicitudes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSolicitudes,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_solicitudes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No tienes solicitudes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primera solicitud tocando el botón +',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        itemCount: _solicitudes.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final solicitud = _solicitudes[index];
          return _buildSolicitudCard(solicitud);
        },
      ),
    );
  }

  Widget _buildSolicitudCard(Map<String, dynamic> solicitud) {
    final estado = solicitud['estado'] ?? 'pendiente';
    final isOffline = solicitud['id'].toString().startsWith('offline_');
    
    Color estadoColor;
    IconData estadoIcon;
    
    switch (estado.toLowerCase()) {
      case 'aprobada':
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle;
        break;
      case 'rechazada':
        estadoColor = Colors.red;
        estadoIcon = Icons.cancel;
        break;
      default:
        estadoColor = Colors.orange;
        estadoIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToDetail(solicitud),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      solicitud['motivo'] ?? 'Sin motivo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (isOffline)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off, size: 12, color: Colors.blue.shade800),
                          const SizedBox(width: 4),
                          Text(
                            'Sin sincronizar',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (solicitud['descripcion'] != null)
                Text(
                  solicitud['descripcion'],
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(estadoIcon, color: estadoColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _capitalizeFirst(estado),
                    style: TextStyle(
                      color: estadoColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatearFecha(solicitud['fecha_creacion']),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateSolicitudFAB() {
    return Consumer<OfflineManager>(
      builder: (context, offlineManager, child) {
        return FloatingActionButton.extended(
          onPressed: () => _showCreateSolicitudDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Nueva Solicitud'),
          tooltip: offlineManager.isOffline 
              ? 'Crear solicitud (se enviará cuando haya conexión)'
              : 'Crear solicitud',
        );
      },
    );
  }

  void _navigateToDetail(Map<String, dynamic> solicitud) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SolicitudDetailViewScreen(
          solicitudId: solicitud['id'],
        ),
      ),
    );
  }

  void _showCreateSolicitudDialog() {
    final motivoController = TextEditingController();
    final descripcionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nueva Solicitud'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer<OfflineManager>(
                  builder: (context, offlineManager, child) {
                    if (offlineManager.isOffline) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cloud_off, color: Colors.orange.shade800, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Sin conexión. La solicitud se enviará cuando se restablezca la conexión.',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                TextField(
                  controller: motivoController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => _createSolicitud(
                motivoController.text,
                descripcionController.text,
              ),
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createSolicitud(String motivo, String descripcion) async {
    if (motivo.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El motivo es obligatorio')),
      );
      return;
    }

    Navigator.pop(context); // Cerrar diálogo

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Usuario no autenticado');

      final offlineManager = Provider.of<OfflineManager>(context, listen: false);
      
      await offlineManager.createSolicitudOffline(
        usuarioId: uid,
        motivo: motivo.trim(),
        descripcion: descripcion.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            offlineManager.isOnline 
                ? 'Solicitud creada exitosamente'
                : 'Solicitud guardada. Se enviará cuando haya conexión.',
          ),
          backgroundColor: offlineManager.isOnline ? Colors.green : Colors.orange,
        ),
      );

      // Recargar lista
      await _loadSolicitudes();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear solicitud: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
