import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart' as my;
import '../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
 
class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleAuthError(FirebaseAuthException e) {
    String message = 'Error de autenticación';
    switch (e.code) {
      case 'user-not-found': message = 'Usuario no registrado'; break;
      case 'wrong-password': message = 'Contraseña incorrecta'; break;
      case 'email-not-verified': message = 'Verifica tu email primero'; break;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<my.AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(Icons.lock_person, size: 100, color: Colors.blue),
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
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  validator: Validators.password,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        await authProvider.signInWithEmailAndPassword(
                          _emailController.text.trim(),
                          _passwordController.text,
                        );
                        Navigator.pushReplacementNamed(context, '/home');
                      } on FirebaseAuthException catch (e) {
                        _handleAuthError(e);
                      }
                    }
                  },
                  child: authProvider.isLoading 
                      ? const CircularProgressIndicator()
                      : const Text('Ingresar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/reset-password'),
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
                const Divider(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Continuar con Google'),
                  onPressed: () async {
                    try {
                      await authProvider.signInWithGoogle();
                    } on FirebaseAuthException catch (e) {
                      _handleAuthError(e);
                    }
                  },
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text('Crear nueva cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
