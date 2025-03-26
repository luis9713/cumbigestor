import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart' as my;
import '../utils/validators.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<my.AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.lock_reset, size: 100, color: Colors.blue),
              const SizedBox(height: 30),
              TextFormField(
                controller: _emailController,
                validator: Validators.email,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: authProvider.isLoading ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await authProvider.resetPassword(_emailController.text.trim());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Correo de recuperación enviado'))
                      );
                      Navigator.pop(context);
                    } on FirebaseAuthException catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message ?? 'Error al enviar correo'))
                      );
                    }
                  }
                },
                child: authProvider.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Enviar enlace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
