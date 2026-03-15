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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Tus Alertas 🔔',
          style: TextStyle(
            color: theme.appBarTheme.titleTextStyle?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryColor),
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
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_paused,
                    size: 80,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No tienes notificaciones nuevas 🌸',
                    style: TextStyle(fontSize: 18, color: theme.primaryColor),
                  ),
                  Text(
                    'Aquí aparecerán tus menciones',
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
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
                  color: colorScheme.errorContainer,
                  child: Icon(
                    Icons.delete,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                onDismissed: (direction) {
                  _deleteNotification(doc.id, currentUserId);
                },
                child: Card(
                  elevation: 0,
                  color: isRead
                      ? theme.cardColor
                      : colorScheme.secondaryContainer.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: isRead
                          ? theme.dividerColor
                          : colorScheme.secondary,
                      width: 2,
                    ),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.secondaryContainer,
                      // Usamos el icono que toque según el tipo de alerta
                      child: Icon(
                        _getIconForType(type),
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    title: Text(
                      data['title'] ?? '',
                      style: TextStyle(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    subtitle: Text(
                      data['message'] ?? '',
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    ),
                    onTap: () {
                      // 1. Marcamos como leída para que se quite el fondo amarillo
                      _markAsRead(doc.id, currentUserId);
                      // 2. ¡VIAJAMOS A LA TAREA! 🚀
                      if (data['taskId'] != null) {
                        _navigateToTask(context, data);
                      }
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
