import 'dart:io';
import 'package:cumbigestor/screens/mis_solicitudes_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'providers/auth_provider.dart';
import 'screens/admin_home_screen.dart';
import 'screens/user_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/email_verification_screen.dart';
import 'firebase_options.dart';
import 'constants.dart';
import 'theme.dart'; // Importamos el tema personalizado

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Solicitar permisos al iniciar la app (solo en Android)
  if (Platform.isAndroid) {
    await _requestPermissionsOnStart();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _requestPermissionsOnStart() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.storage, // Para Android 12 y anteriores
    Permission.photos,  // Para Android 13+ (permisos granulares)
    Permission.videos,
    Permission.audio,
  ].request();

  bool allGranted = statuses.values.every((status) => status.isGranted);
  if (!allGranted) {
    bool isPermanentlyDenied = statuses.values.any((status) => status.isPermanentlyDenied);
    if (isPermanentlyDenied) {
      // No podemos mostrar un diálogo aquí porque el contexto de la app aún no está disponible.
      // El usuario tendrá que ir a ajustes manualmente si los permisos están denegados permanentemente.
      print("Permisos denegados permanentemente. Dirige al usuario a los ajustes de la app.");
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión Documental - Cumbitara',
      theme: cumbitaraTheme(), // Aplicamos el tema personalizado
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/email-verification': (context) => const EmailVerificationScreen(),
        '/admin-home': (context) => const AdminHomeScreen(),
        '/user-home': (context) => const UserHomeScreen(),
        '/mis-solicitudes': (context) => const MisSolicitudesScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authProvider.user == null) return const LoginScreen();
    if (!authProvider.user!.emailVerified) return const EmailVerificationScreen();

    // Verificar el UID del usuario autenticado contra la lista de administradores definida en constants.dart
    final uid = authProvider.user!.uid;
    if (adminUIDs.contains(uid)) {
      return const AdminHomeScreen();
    } else {
      return const UserHomeScreen();
    }
  }
}