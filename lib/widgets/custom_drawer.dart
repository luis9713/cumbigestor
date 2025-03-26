import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await Provider.of<AuthProvider>(context, listen: false).signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.displayName ?? 'Usuario'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundImage: user?.photoURL != null 
                  ? NetworkImage(user!.photoURL!) 
                  : null,
              child: user?.photoURL == null 
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () => _confirmSignOut(context),
          )
        ],
      ),
    );
  }
}
