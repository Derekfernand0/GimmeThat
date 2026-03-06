// lib/features/auth/presentation/auth_gate.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';
import '../../tasks/presentation/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder está "escuchando" constantemente los cambios en Firebase
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mientras espera la respuesta de internet, mostramos un cargador
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si Firebase dice que SÍ hay datos de usuario, lo dejamos pasar al Home
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Si NO hay usuario, le mostramos la pantalla de Login
        return const LoginScreen();
      },
    );
  }
}
