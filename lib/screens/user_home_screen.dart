// screens/user_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_drawer.dart';
import 'document_upload_screen.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final uid = authProvider.user?.uid ?? 'No UID';

    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      drawer: const CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Bienvenido, Usuario\nUID: $uid', textAlign: TextAlign.center,),
            const SizedBox(height: 20),
            // Tarjetas para cada departamento
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildCategoryCard(context, 'Educación'),
                  _buildCategoryCard(context, 'Deporte'),
                  _buildCategoryCard(context, 'Cultura'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String category) {
    return GestureDetector(
      onTap: () {
        // Navega a la pantalla de subida, pasando la categoría
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentUploadScreen(category: category.toLowerCase()),
          ),
        );
      },
      child: Card(
        elevation: 4,
        child: Center(
          child: Text(
            category,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
