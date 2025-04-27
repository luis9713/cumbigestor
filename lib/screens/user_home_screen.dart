import 'package:cumbigestor/screens/departments_screens/educacion_process_screen.dart';
import 'package:cumbigestor/screens/departments_screens/deportes_options_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as my;
import '../widgets/custom_drawer.dart';


class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<my.AuthProvider>(context);
    final user = authProvider.user?.displayName ?? 'No User';

    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      drawer: const CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Bienvenido, Usuario:\n $user',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Navegar a la pantalla de procesos para Educación
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EducacionProcessScreen()),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      child: const Center(
                        child: Text(
                          'Educación',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DeportesOptionsScreen()),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      child: const Center(
                        child: Text(
                          'Deporte',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Implementa la navegación para Cultura
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Funcionalidad de Cultura en desarrollo")),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      child: const Center(
                        child: Text(
                          'Cultura',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
