// educacion_process_screen.dart
import 'package:flutter/material.dart';
import 'solicitud_detail_screen.dart';

class EducacionProcessScreen extends StatelessWidget {
  const EducacionProcessScreen({Key? key}) : super(key: key);

  final List<String> procesos = const [
    "Actas de Pago del Transporte Escolar",
    "Subsidios para Educación Superior",
    "Solicitudes Educativas"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Procesos de Educación")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: procesos.map((proceso) {
            return GestureDetector(
              onTap: () {
                // Navegar a la pantalla de detalle de la solicitud sin crear el documento
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SolicitudDetailScreen(proceso: proceso),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      proceso,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
