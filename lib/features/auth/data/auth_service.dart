// lib/features/auth/data/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Estas son nuestras "llaves" para usar Firebase Auth y la base de datos Firestore
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Saber si hay un usuario conectado actualmente (escucha cambios en tiempo real)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 2. Iniciar sesión con Correo y Contraseña
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print("Error al iniciar sesión: $e");
      return null;
    }
  }

  // 3. Registrarse con Correo, Contraseña y Nombre de usuario
  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      // a) Crea la cuenta secreta en Firebase Authentication
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      // b) Si se creó con éxito, guardamos su "Perfil" público en nuestra base de datos
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'username': username,
          'photoUrl': '', // Vacío por ahora
          'createdAt':
              FieldValue.serverTimestamp(), // Fecha actual del servidor
        });
      }
      return user;
    } catch (e) {
      print("Error al registrar: $e");
      return null;
    }
  }

  // 4. Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
