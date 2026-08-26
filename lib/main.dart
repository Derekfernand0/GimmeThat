// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'core/utils/notification_service.dart';
import 'core/theme/theme_notifier.dart';
import 'features/splash/presentation/splash_screen_svg.dart';

// --- NUEVO: MANEJADOR DE SEGUNDO PLANO ---
// Es vital que esté AFUERA de cualquier clase y tenga esta etiqueta
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Mensaje recibido en segundo plano: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ThemeNotifier().loadTheme();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 1. Registramos el manejador correctamente
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 2. Inicializamos el servicio local
  final notificationService = NotificationService();
  await notificationService.initNotifications();

  // --- NUEVO: REFRESCAR EL TOKEN AUTOMÁTICAMENTE ---
  // Si el usuario reinstala la app, atrapamos el nuevo token y lo guardamos
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fcmToken': newToken},
      );
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeData>(
      valueListenable: ThemeNotifier(),
      builder: (context, currentTheme, child) {
        return MaterialApp(
          title: 'GimmeThat',
          debugShowCheckedModeBanner: false,
          theme: currentTheme,
          home: const SplashScreenSvg(),
        );
      },
    );
  }
}
