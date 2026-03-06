// lib/features/tasks/presentation/group_tasks_screen.dart

import 'package:flutter/material.dart';
import '../../groups/domain/group_model.dart';
import 'create_task_screen.dart';

class GroupTasksScreen extends StatelessWidget {
  final GroupModel group; // Recibimos el grupo entero al entrar a esta pantalla

  const GroupTasksScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          group.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFF5D4037),
        ), // Color de la flecha de regreso
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 80,
              color: Color(0xFFFFF59D),
            ), // Estrella pastel
            const SizedBox(height: 20),
            Text(
              'Bienvenido a ${group.name} 🌸',
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF5D4037),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Aún no hay tareas aquí',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateTaskScreen(groupId: group.id),
            ),
          );
        },
        backgroundColor: const Color(0xFFC8E6C9), // Verde suave
        icon: const Icon(Icons.add, color: Color(0xFF5D4037)),
        label: const Text(
          'Nueva Tarea',
          style: TextStyle(
            color: Color(0xFF5D4037),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
