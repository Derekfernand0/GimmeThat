// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'features/auth/presentation/auth_gate.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/notification_service.dart';
import 'core/theme/theme_notifier.dart';
import 'features/splash/presentation/splash_screen_svg.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 1. Registramos la función que escucha cuando la app está cerrada
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 2. Inicializamos el servicio de notificaciones para pedir permiso
  final notificationService = NotificationService();
  await notificationService.initNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos los cambios del tema en tiempo real
    return ValueListenableBuilder<ThemeData>(
      valueListenable: ThemeNotifier(),
      builder: (context, currentTheme, child) {
        return MaterialApp(
          title: 'GimmeThat',
          debugShowCheckedModeBanner: false,
          theme: currentTheme, // ¡El tema ahora es dinámico!
          home: const SplashScreenSvg(),
        );
      },
    );
  }
}
