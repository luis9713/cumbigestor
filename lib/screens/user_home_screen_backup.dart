import 'package:cumbigestor/screens/departments/educacion/educacion_process_screen.dart';
import 'package:cumbigestor/screens/departments/deportes/deportes_options_screen.dart';
import 'package:cumbigestor/screens/departments/cultura/cultura_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as my;
import '../widgets/custom_drawer.dart';
import '../services/offline_manager.dart';
import '../widgets/connection_indicator.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<my.AuthProvider>(context);
    final user = authProvider.user?.displayName ?? 'Usuario';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('CumbiGestor'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
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
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          // Indicador de conexión principal
          const ConnectionIndicator(),
          
          // Contenido principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Saludo de bienvenida con diseño moderno
                  Container(
                    width: double.infinity,
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
                          Icons.waving_hand,
                          size: 40,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '¡Hola, $user!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bienvenido a CumbiGestor',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Departamentos',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildDepartmentCard(
                        context: context,
                        title: 'Educación',
                        icon: Icons.school_rounded,
                        gradient: [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EducacionProcessScreen()),
                        ),
                      ),
                      _buildDepartmentCard(
                        context: context,
                        title: 'Deportes',
                        icon: Icons.sports_soccer_rounded,
                        gradient: [const Color(0xFF2E7D32), const Color(0xFF4CAF50)],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DeportesOptionsScreen()),
                        ),
                      ),
                      _buildDepartmentCard(
                        context: context,
                        title: 'Cultura',
                        icon: Icons.palette_rounded,
                        gradient: [const Color(0xFF66BB6A), const Color(0xFF81C784)],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CulturaScreen()),
                        ),
                      ),
                      _buildDepartmentCard(
                        context: context,
                        title: 'Próximamente',
                        icon: Icons.construction_rounded,
                        gradient: [Colors.grey, Colors.grey.shade400],
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
