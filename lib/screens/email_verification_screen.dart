import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as my;

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isSending = false;

  Future<void> _checkVerification() async {
    final authProvider = Provider.of<my.AuthProvider>(context, listen: false);
    await authProvider.user?.reload();
    if (authProvider.user!.emailVerified) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<my.AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifica tu Email'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.signOut(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email, size: 100, color: Colors.blue),
            const SizedBox(height: 30),
            const Text('Revisa tu correo electrónico para verificar tu cuenta'),
            const SizedBox(height: 20),
            Text(
              authProvider.user?.email ?? 'correo@ejemplo.com',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isSending ? null : () async {
                setState(() => _isSending = true);
                try {
                  await authProvider.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nuevo enlace enviado'))
                  );
                } finally {
                  setState(() => _isSending = false);
                }
              },
              child: const Text('Reenviar enlace'),
            ),
            TextButton(
              onPressed: _checkVerification,
              child: const Text('Ya verifiqué mi email'),
            ),
          ],
        ),
      ),
    );
  }
}
