import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/offline_manager.dart';
import '../widgets/connection_indicator.dart';

class QuickCreateSolicitudScreen extends StatefulWidget {
  const QuickCreateSolicitudScreen({super.key});

  @override
  _QuickCreateSolicitudScreenState createState() => _QuickCreateSolicitudScreenState();
}

class _QuickCreateSolicitudScreenState extends State<QuickCreateSolicitudScreen> {
  final _motivoController = TextEditingController();
  final _descripcionController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _motivoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _createSolicitud() async {
    if (_motivoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El motivo es obligatorio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Usuario no autenticado');

      final offlineManager = Provider.of<OfflineManager>(context, listen: false);
      
      await offlineManager.createSolicitudOffline(
        usuarioId: uid,
        motivo: _motivoController.text.trim(),
        descripcion: _descripcionController.text.trim(),
      );

      // Limpiar campos
      _motivoController.clear();
      _descripcionController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            offlineManager.isOnline 
                ? '✅ Solicitud creada y enviada'
                : '📱 Solicitud guardada offline (se enviará cuando haya conexión)',
          ),
          backgroundColor: offlineManager.isOnline ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Solicitud Rápida'),
        actions: [
          Consumer<OfflineManager>(
            builder: (context, offlineManager, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ConnectionStatusIcon(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicador de conexión
          const ConnectionIndicator(showWhenOnline: true),
          
          // Información de estado
          Consumer<OfflineManager>(
            builder: (context, offlineManager, child) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: offlineManager.isOnline 
                      ? Colors.green.shade50 
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: offlineManager.isOnline 
                        ? Colors.green.shade300 
                        : Colors.orange.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      offlineManager.isOnline ? Icons.cloud_done : Icons.cloud_off,
                      color: offlineManager.isOnline 
                          ? Colors.green.shade700 
                          : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offlineManager.isOnline ? 'Modo Online' : 'Modo Offline',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: offlineManager.isOnline 
                                  ? Colors.green.shade700 
                                  : Colors.orange.shade700,
                            ),
                          ),
                          Text(
                            offlineManager.isOnline 
                                ? 'Las solicitudes se enviarán inmediatamente'
                                : 'Las solicitudes se guardarán y se enviarán cuando haya conexión',
                            style: TextStyle(
                              fontSize: 12,
                              color: offlineManager.isOnline 
                                  ? Colors.green.shade600 
                                  : Colors.orange.shade600,
                            ),
                          ),
                          if (offlineManager.pendingOperations > 0)
                            Text(
                              'Operaciones pendientes: ${offlineManager.pendingOperations}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: offlineManager.isOnline 
                                    ? Colors.green.shade600 
                                    : Colors.orange.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Formulario
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crear Nueva Solicitud',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _motivoController,
                    decoration: const InputDecoration(
                      labelText: 'Motivo de la solicitud *',
                      border: OutlineInputBorder(),
                      hintText: 'Ej: Solicitud de certificado de estudios',
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      border: OutlineInputBorder(),
                      hintText: 'Detalles adicionales sobre la solicitud...',
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  
                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isCreating ? null : () {
                            _motivoController.clear();
                            _descripcionController.clear();
                          },
                          child: const Text('Limpiar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isCreating ? null : _createSolicitud,
                          child: _isCreating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Crear Solicitud'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botones de acceso rápido
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Acceso Rápido',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.pushNamed(
                                    context, 
                                    '/mis-solicitudes-offline'
                                  ),
                                  icon: const Icon(Icons.list_alt),
                                  label: const Text('Ver Solicitudes'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Consumer<OfflineManager>(
                                builder: (context, offlineManager, child) {
                                  return Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: offlineManager.isSyncing 
                                          ? null 
                                          : () => offlineManager.forceSync(),
                                      icon: offlineManager.isSyncing 
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Icon(Icons.sync),
                                      label: Text(
                                        offlineManager.isSyncing 
                                            ? 'Sincronizando...' 
                                            : 'Sincronizar'
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Información
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Esta pantalla te permite probar la funcionalidad offline. Puedes crear solicitudes sin conexión a internet.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
