import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cumbigestor/screens/departments_screens/AdminSolicitudDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_drawer.dart';
import '../utils/utils.dart';

const Map<String, String> adminDepartmentMapping = {
  'A3zwu7ksPzZQ0BLoYHSO46jUFy03': 'educacion',
  'QCYtuiLFcnTAYLSPtUAolgVCQBg2': 'deporte',
  'uid_admin_cultura': 'cultura',
};

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getSolicitudesCollection(String department) {
    switch (department.toLowerCase()) {
      case 'educacion':
        return "solicitudes_educacion";
      case 'deporte':
        return "solicitudes_deporte";
      case 'cultura':
        return "solicitudes_cultura";
      default:
        return "solicitudes";
    }
  }

  IconData _getStatusIcon(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Icons.hourglass_empty;
      case 'En proceso':
        return Icons.sync;
      case 'Aprobado':
        return Icons.check_circle;
      case 'Rechazado':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Colors.orange;
      case 'En proceso':
        return Colors.blue;
      case 'Aprobado':
        return Colors.green;
      case 'Rechazado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<Color> _getStatusGradient(String estado) {
    switch (estado) {
      case 'Pendiente':
        return [Colors.orange, Colors.orangeAccent];
      case 'En proceso':
        return [Colors.blue, Colors.lightBlue];
      case 'Aprobado':
        return [Colors.green, Colors.lightGreen];
      case 'Rechazado':
        return [Colors.red, Colors.redAccent];
      default:
        return [Colors.grey, Colors.grey[400]!];
    }
  }

  IconData _getDepartmentIcon(String department) {
    switch (department.toLowerCase()) {
      case 'educacion':
        return Icons.school_rounded;
      case 'deporte':
        return Icons.sports_soccer_rounded;
      case 'cultura':
        return Icons.palette_rounded;
      default:
        return Icons.business;
    }
  }

  Widget _buildSolicitudesList(String solicitudesCollection, String estadoFiltrado) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(solicitudesCollection)
          .where('estado', isEqualTo: estadoFiltrado)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final solicitudes = snapshot.data!.docs;
        if (solicitudes.isEmpty) {
          return const Center(child: Text('No hay solicitudes en este estado'));
        }
        return ListView.builder(
          itemCount: solicitudes.length,
          itemBuilder: (context, index) {
            final data = solicitudes[index].data() as Map<String, dynamic>;
            final proceso = data["proceso"] ?? "Sin proceso";
            final estado = data["estado"] ?? "Sin estado";
            final fechaTimestamp = data["fecha"];
            final fecha = fechaTimestamp != null
                ? (fechaTimestamp as Timestamp).toDate().toLocal().toString()
                : "Sin fecha";

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
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getStatusGradient(estado),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(estado),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                title: Text(
                  proceso,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(estado).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(estado).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        estado == "Aprobado" ? "Completado" : estado,
                        style: TextStyle(
                          color: _getStatusColor(estado),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            fecha.split(' ')[0], // Solo mostrar la fecha
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    estadoWidget,
                  ],
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminSolicitudDetailScreen(
                        solicitudId: solicitudes[index].id,
                        collectionName: solicitudesCollection,
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final uid = authProvider.user?.uid ?? '';
    final department = adminDepartmentMapping[uid];

    if (department == null) {
      return const Scaffold(
        body: Center(child: Text('No se encontró el departamento para este administrador')),
      );
    }

    String solicitudesCollection = _getSolicitudesCollection(department);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(text: 'Pendientes', icon: Icon(Icons.hourglass_empty, size: 20)),
            Tab(text: 'En Proceso', icon: Icon(Icons.sync, size: 20)),
            Tab(text: 'Rechazadas', icon: Icon(Icons.cancel, size: 20)),
            Tab(text: 'Completadas', icon: Icon(Icons.check_circle, size: 20)),
          ],
        ),
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          // Header con información del departamento
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  _getDepartmentIcon(department),
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  'Departamento de ${department.capitalize()}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Gestiona las solicitudes de tu departamento',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSolicitudesList(solicitudesCollection, "Pendiente"),
                _buildSolicitudesList(solicitudesCollection, "En proceso"),
                _buildSolicitudesList(solicitudesCollection, "Rechazado"),
                _buildSolicitudesList(solicitudesCollection, "Aprobado"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}