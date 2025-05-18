import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'solicitud_detail_view_screen.dart';
import '../utils/utils.dart';

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
          bottom: const TabBar(
            tabs: [
              Tab(text: "Educación"),
              Tab(text: "Deporte"),
              Tab(text: "Cultura"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSolicitudesTab(context, "Educación", uid),
            _buildSolicitudesTab(context, "Deporte", uid),
            _buildSolicitudesTab(context, "Cultura", uid),
          ],
        ),
      ),
    );
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