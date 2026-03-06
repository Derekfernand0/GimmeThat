// lib/features/tasks/presentation/home_screen.dart

import 'package:flutter/material.dart';
import '../../auth/data/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Tareas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Botón para cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.brown),
            onPressed: () async {
              await authService.signOut();
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Usaremos un icono temporal fácil de cambiar por tu imagen después
            const Icon(
              Icons.check_circle_outline,
              size: 100,
              color: Color(0xFFC8E6C9),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aún no hay tareas',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Aquí aparecerán tus pendientes 🦋',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      // Botón flotante para crear tareas en el futuro
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Abrir formulario de nueva tarea
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
