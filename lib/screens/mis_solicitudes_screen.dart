import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'solicitud_detail_view_screen.dart';
import '../utils/utils.dart';
import '../services/offline_manager.dart';
import '../widgets/connection_indicator.dart';

class MisSolicitudesScreen extends StatelessWidget {
  const MisSolicitudesScreen({super.key});

  String _getCollection(String type) {
    switch (type) {
      case "Educación":
        return "solicitudes_educacion";
      case "Deporte":
        return "solicitudes_deporte";
      case "Cultura":
        return "solicitudes_cultura";
      default:
        return "solicitudes_educacion";
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("No hay usuario autenticado")),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Mis Solicitudes"),
          actions: [
            Consumer<OfflineManager>(
              builder: (context, offlineManager, child) {
                return IconButton(
                  icon: Icon(
                    offlineManager.isOnline ? Icons.cloud_done : Icons.cloud_off,
                    color: offlineManager.isOnline ? Colors.green : Colors.orange,
                  ),
                  onPressed: () => _showConnectionStatus(context, offlineManager),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Educación"),
              Tab(text: "Deporte"),
              Tab(text: "Cultura"),
            ],
          ),
        ),
        body: Column(
          children: [
            // Indicador de conexión solo cuando hay problemas
            Consumer<OfflineManager>(
              builder: (context, offlineManager, child) {
                if (offlineManager.isOnline && offlineManager.pendingOperations == 0) {
                  return const SizedBox.shrink();
                }
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: offlineManager.isOnline ? Colors.blue.shade100 : Colors.orange.shade100,
                  child: Row(
                    children: [
                      Icon(
                        offlineManager.isOnline ? Icons.sync : Icons.cloud_off,
                        color: offlineManager.isOnline ? Colors.blue : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          offlineManager.isOnline 
                              ? '${offlineManager.pendingOperations} solicitudes pendientes de sincronizar'
                              : 'Sin conexión. Las solicitudes se guardarán localmente.',
                          style: TextStyle(
                            color: offlineManager.isOnline ? Colors.blue.shade800 : Colors.orange.shade800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (offlineManager.pendingOperations > 0)
                        TextButton(
                          onPressed: () => offlineManager.forceSync(),
                          child: Text(
                            'Sincronizar',
                            style: TextStyle(
                              color: offlineManager.isOnline ? Colors.blue.shade800 : Colors.orange.shade800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            
            // Contenido de tabs
            Expanded(
              child: TabBarView(
                children: [
                  _buildSolicitudesTabWithOffline(context, "Educación", uid),
                  _buildSolicitudesTabWithOffline(context, "Deporte", uid),
                  _buildSolicitudesTabWithOffline(context, "Cultura", uid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectionStatus(BuildContext context, OfflineManager offlineManager) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Estado de Conexión'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    offlineManager.isOnline ? Icons.cloud_done : Icons.cloud_off,
                    color: offlineManager.isOnline ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(offlineManager.isOnline ? 'En línea' : 'Sin conexión'),
                ],
              ),
              const SizedBox(height: 8),
              if (offlineManager.pendingOperations > 0) ...[
                Text('Operaciones pendientes: ${offlineManager.pendingOperations}'),
                const SizedBox(height: 8),
                Text(
                  'Las solicitudes offline se sincronizarán automáticamente cuando haya conexión.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ] else if (offlineManager.isOnline) ...[
                const Text('Todas las solicitudes están sincronizadas.'),
              ] else ...[
                const Text('Sin conexión a internet. Las solicitudes se guardarán localmente.'),
              ],
            ],
          ),
          actions: [
            if (offlineManager.pendingOperations > 0 && offlineManager.isOnline)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  offlineManager.forceSync();
                },
                child: const Text('Sincronizar Ahora'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSolicitudesTabWithOffline(BuildContext context, String type, String uid) {
    return Consumer<OfflineManager>(
      builder: (context, offlineManager, child) {
        if (offlineManager.isOnline) {
          // Modo online: usar Firebase + mostrar pendientes offline
          return _buildOnlineSolicitudesTab(context, type, uid, offlineManager);
        } else {
          // Modo offline: mostrar solo datos locales
          return _buildOfflineSolicitudesTab(context, type, uid, offlineManager);
        }
      },
    );
  }

  Widget _buildOnlineSolicitudesTab(BuildContext context, String type, String uid, OfflineManager offlineManager) {
    final collection = _getCollection(type);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where("uid", isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final firebaseDocs = snapshot.data!.docs;
        
        // Combinar con solicitudes offline pendientes
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: offlineManager.getSolicitudesLocales(usuarioId: uid),
          builder: (context, offlineSnapshot) {
            if (!offlineSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final offlineSolicitudes = offlineSnapshot.data!
                .where((s) => s['sync_status'] == 'pending')
                .toList();

            final allSolicitudes = <Map<String, dynamic>>[];
            
            // Agregar solicitudes de Firebase
            for (var doc in firebaseDocs) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              data['isOffline'] = false;
              allSolicitudes.add(data);
            }
            
            // Agregar solicitudes offline pendientes
            for (var solicitud in offlineSolicitudes) {
              solicitud['isOffline'] = true;
              allSolicitudes.add(solicitud);
            }

            if (allSolicitudes.isEmpty) {
              return Center(child: Text("No tienes solicitudes registradas en $type."));
            }

            // Ordenar por fecha
            allSolicitudes.sort((a, b) {
              final aFecha = _getDateFromSolicitud(a);
              final bFecha = _getDateFromSolicitud(b);
              return bFecha.compareTo(aFecha);
            });

            return ListView.builder(
              itemCount: allSolicitudes.length,
              itemBuilder: (context, index) {
                final solicitud = allSolicitudes[index];
                return _buildSolicitudCard(context, solicitud, type);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOfflineSolicitudesTab(BuildContext context, String type, String uid, OfflineManager offlineManager) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: offlineManager.getSolicitudesLocales(usuarioId: uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final solicitudes = snapshot.data ?? [];
        
        if (solicitudes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text("No tienes solicitudes registradas en $type."),
                const SizedBox(height: 8),
                const Text(
                  "Sin conexión a internet. Solo se muestran solicitudes guardadas localmente.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Ordenar por fecha
        final sortedSolicitudes = List<Map<String, dynamic>>.from(solicitudes);
        sortedSolicitudes.sort((a, b) {
          final aFecha = _getDateFromSolicitud(a);
          final bFecha = _getDateFromSolicitud(b);
          return bFecha.compareTo(aFecha);
        });

        return ListView.builder(
          itemCount: sortedSolicitudes.length,
          itemBuilder: (context, index) {
            final solicitud = sortedSolicitudes[index];
            solicitud['isOffline'] = true;
            return _buildSolicitudCard(context, solicitud, type);
          },
        );
      },
    );
  }

  DateTime _getDateFromSolicitud(Map<String, dynamic> solicitud) {
    final fecha = solicitud['fecha'] ?? solicitud['fecha_creacion'];
    if (fecha == null) return DateTime.now();
    
    if (fecha is Timestamp) {
      return fecha.toDate();
    } else if (fecha is String) {
      return DateTime.tryParse(fecha) ?? DateTime.now();
    }
    
    return DateTime.now();
  }

  Widget _buildSolicitudCard(BuildContext context, Map<String, dynamic> solicitud, String type) {
    final proceso = solicitud["proceso"] ?? solicitud["motivo"] ?? "Sin proceso";
    final estado = solicitud["estado"] ?? "pendiente";
    final isOffline = solicitud['isOffline'] == true;
    final fecha = _getDateFromSolicitud(solicitud);
    
    final fechaFormateada = "${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getEstadoColor(estado),
          child: Icon(
            _getEstadoIcon(estado),
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(proceso)),
            if (isOffline) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 10, color: Colors.orange.shade700),
                    const SizedBox(width: 2),
                    Text(
                      'OFFLINE',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Estado: ${estado.toUpperCase()}"),
            Text("Fecha: $fechaFormateada"),
            if (isOffline) ...[
              const SizedBox(height: 4),
              Text(
                "⏳ Pendiente de sincronización",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SolicitudDetailViewScreen(
                solicitudId: solicitud['id'] ?? 'offline-${DateTime.now().millisecondsSinceEpoch}',
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'aprobada':
      case 'aprobado':
        return Colors.green;
      case 'rechazada':
      case 'rechazado':
        return Colors.red;
      case 'en proceso':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'aprobada':
      case 'aprobado':
        return Icons.check;
      case 'rechazada':
      case 'rechazado':
        return Icons.close;
      case 'en proceso':
        return Icons.hourglass_empty;
      default:
        return Icons.schedule;
    }
  }

  Widget _buildSolicitudesTab(BuildContext context, String type, String uid) {
    final collection = _getCollection(type);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where("uid", isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Text("No tienes solicitudes registradas en $type."));
        }

        final sortedDocs = List.from(docs);
        sortedDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          final aTimestamp = aData["fecha"] as Timestamp?;
          final bTimestamp = bData["fecha"] as Timestamp?;

          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;

          return bTimestamp.compareTo(aTimestamp);
        });

        return ListView.builder(
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final doc = sortedDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final proceso = data["proceso"] ?? "Sin proceso";
            final estado = data["estado"] ?? "Sin estado";
            final fechaTimestamp = data["fecha"];

            String fechaFormateada = "Sin fecha";
            if (fechaTimestamp != null) {
              final fecha = (fechaTimestamp as Timestamp).toDate();
              fechaFormateada =
                  "${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}";
            }

            Widget estadoWidget;
            if (estado == "Pendiente" || estado == "En proceso") {
              int diasRestantes = 0;
              if (fechaTimestamp != null) {
                DateTime fechaCreacion = (fechaTimestamp as Timestamp).toDate();
                diasRestantes = calcularDiasHabilesRestantes(fechaCreacion, 15);
              }
              estadoWidget = Text(
                "Días hábiles restantes: $diasRestantes",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: diasRestantes <= 3 ? Colors.red : Colors.black,
                    ),
              );
            } else {
              estadoWidget = Text(
                estado == "Aprobado" ? "Completado" : "Rechazado",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: estado == "Aprobado" ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
              );
            }

            return Card(
              child: ListTile(
                title: Text(proceso),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Estado: $estado"),
                    Text("Fecha: $fechaFormateada"),
                    estadoWidget,
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SolicitudDetailViewScreen(
                        solicitudId: doc.id,
                        collectionName: collection,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}