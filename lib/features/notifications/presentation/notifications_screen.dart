// lib/features/notifications/presentation/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ¡Importamos los modelos y pantallas necesarias para viajar a la tarea!
import '../../tasks/domain/task_model.dart';
import '../../groups/domain/group_model.dart';
import '../../tasks/presentation/task_details_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // Función para marcar una notificación como leída
  void _markAsRead(String docId, String userId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }

  // Función para borrar la notificación
  void _deleteNotification(String docId, String userId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(docId)
        .delete();
  }

  // --- NUEVA FUNCIÓN MÁGICA: Navegar a la Tarea (Deep Linking) 🚀 ---
  Future<void> _navigateToTask(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final taskId = data['taskId'];
    final groupId = data['groupId'];

    if (taskId == null || groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta alerta es muy antigua y no tiene enlace. 😔'),
        ),
      );
      return;
    }

    try {
      // 1. Buscamos el documento del Grupo
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .get();
      if (!groupDoc.exists) throw Exception("El grupo ya no existe.");
      final group = GroupModel.fromMap(groupDoc.data()!, groupDoc.id);

      // 2. Buscamos el documento de la Tarea
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .get();
      if (!taskDoc.exists) throw Exception("Esta tarea ya fue eliminada.");
      final task = TaskModel.fromMap(taskDoc.data()!, taskDoc.id);

      // 3. Viajamos a la pantalla de detalles
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailsScreen(task: task, group: group),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al abrir la tarea: ${e.toString().split(": ").last}',
            ),
          ),
        );
      }
    }
  }

  // Función para elegir el ícono dependiendo del tipo de notificación
  IconData _getIconForType(String? type) {
    switch (type) {
      case 'mention':
        return Icons.alternate_email;
      case 'newComment':
        return Icons.chat_bubble_outline;
      case 'newTask':
        return Icons.assignment_add;
      case 'taskCompleted':
        return Icons.task_alt;
      case 'newMember':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      appBar: AppBar(
        title: const Text(
          'Tus Alertas 🔔',
          style: TextStyle(
            color: Color(0xFF5D4037),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5D4037)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.brown),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_paused,
                    size: 80,
                    color: Color(0xFFF8BBD0),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No tienes notificaciones nuevas 🌸',
                    style: TextStyle(fontSize: 18, color: Color(0xFF5D4037)),
                  ),
                  Text(
                    'Aquí aparecerán tus menciones',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['isRead'] ?? false;
              final type = data['type'] as String?;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.redAccent,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  _deleteNotification(doc.id, currentUserId);
                },
                child: Card(
                  elevation: 0,
                  color: isRead
                      ? Colors.white
                      : const Color(0xFFFFF59D).withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: isRead
                          ? Colors.grey.shade200
                          : const Color(0xFFFFF59D),
                      width: 2,
                    ),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFF8BBD0),
                      // Usamos el icono que toque según el tipo de alerta
                      child: Icon(
                        _getIconForType(type),
                        color: const Color(0xFF5D4037),
                      ),
                    ),
                    title: Text(
                      data['title'] ?? '',
                      style: TextStyle(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        color: const Color(0xFF5D4037),
                      ),
                    ),
                    subtitle: Text(
                      data['message'] ?? '',
                      style: const TextStyle(color: Color(0xFF5D4037)),
                    ),
                    onTap: () {
                      // 1. Marcamos como leída para que se quite el fondo amarillo
                      _markAsRead(doc.id, currentUserId);
                      // 2. ¡VIAJAMOS A LA TAREA! 🚀
                      _navigateToTask(context, data);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
