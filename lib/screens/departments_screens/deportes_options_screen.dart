import 'package:flutter/material.dart';
import 'formulario_deportes_screen.dart';
import 'document_upload_deportes_screen.dart';

class DeportesOptionsScreen extends StatelessWidget {
  const DeportesOptionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Opciones - Deportes"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            // Card para "Generar Solicitud"
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FormularioDeportesScreen(),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                child: const Center(
                  child: Text(
                    "Generar Solicitud",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            // Card para "Realizar Solicitud"
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DocumentUploadDeportesScreen(),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                child: const Center(
                  child: Text(
                    "Realizar Solicitud",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
