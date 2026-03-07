// lib/core/utils/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Inicializar las notificaciones y guardar el Token
  Future<void> initNotifications() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permiso de notificaciones concedido');

      String? token = await _fcm.getToken();

      // ¡LA MAGIA NUEVA! 🦋 Guardamos el token en la base de datos
      if (token != null) {
        _saveTokenToDatabase(token);
      }

      // Si el token llega a cambiar en el futuro (pasa a veces), lo actualizamos
      _fcm.onTokenRefresh.listen((newToken) {
        _saveTokenToDatabase(newToken);
      });

      // Escuchar mensajes con la app ABIERTA
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // Aquí es donde más adelante haremos que salga una alerta dentro de la app
        print('💌 Mensaje recibido en la app: ${message.notification?.title}');
      });
    }
  }

  // Función interna para guardar el token en el perfil del usuario actual
  Future<void> _saveTokenToDatabase(String token) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({'fcmToken': token})
          .catchError((e) {
            print("Error guardando el token: $e");
          });
      print('🌸 Token guardado exitosamente en el perfil del usuario');
    }
  }
}

// Escuchar mensajes con la app CERRADA
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('💤 Mensaje recibido en segundo plano: ${message.notification?.title}');
}
