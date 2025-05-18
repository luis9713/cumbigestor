import 'dart:io';
import 'package:cumbigestor/screens/mis_solicitudes_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'theme.dart';

// Manejador de notificaciones en background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Notificación en background recibida: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configurar manejador de notificaciones en background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
    Permission.storage,
    Permission.photos,
    Permission.videos,
    Permission.audio,
  ].request();

  bool allGranted = statuses.values.every((status) => status.isGranted);
  if (!allGranted) {
    bool isPermanentlyDenied = statuses.values.any((status) => status.isPermanentlyDenied);
    if (isPermanentlyDenied) {
      print("Permisos denegados permanentemente. Dirige al usuario a los ajustes de la app.");
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _initializeFCM();
  }

  Future<void> _initializeFCM() async {
    // Solicitar permisos de notificaciones
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('Permiso de notificaciones: ${settings.authorizationStatus}');

    // Obtener el token FCM y guardarlo en Firestore
    String? fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'fcmToken': fcmToken}, SetOptions(merge: true));
      }
    }

    // Manejar notificaciones en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Notificación en foreground: ${message.notification?.title}');
    });

    // Manejar notificaciones cuando la app se abre desde una notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notificación clickeada: ${message.data}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión Documental - Cumbitara',
      theme: cumbitaraTheme(),
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

    final uid = authProvider.user!.uid;
    if (adminUIDs.contains(uid)) {
      return const AdminHomeScreen();
    } else {
      return const UserHomeScreen();
    }
  }
}