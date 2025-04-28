import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cumbigestor/screens/departments_screens/AdminSolicitudDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_drawer.dart';
import '../utils/utils.dart'; // Importar las funciones auxiliares

const Map<String, String> adminDepartmentMapping = {
  'A3zwu7ksPzZQ0BLoYHSO46jUFy03': 'educacion',
  '1XqbIxjcLThw8L8nAlEeFQtV2pP2': 'deporte',
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

            // Calcular días hábiles restantes solo si el estado es "Pendiente" o "En proceso"
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
              // Para "Aprobado" o "Rechazado"
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
                    Text("Fecha: $fecha"),
                    estadoWidget,
                  ],
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
      appBar: AppBar(
        title: const Text('Administrador'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pendiente'),
            Tab(text: 'En proceso'),
            Tab(text: 'Rechazado'),
            Tab(text: 'Completado'),
          ],
        ),
      ),
      drawer: const CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Bienvenido, Se encuentra\n En el Departamento: ${department.capitalize()}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
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