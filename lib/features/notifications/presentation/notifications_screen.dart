// lib/features/notifications/presentation/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../tasks/domain/task_model.dart';
import '../../groups/domain/group_model.dart';
import '../../tasks/presentation/task_details_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // Función para marcar UNA notificación como leída
  void _markAsRead(String docId, String userId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }

  // Función para borrar UNA notificación
  void _deleteNotification(String docId, String userId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(docId)
        .delete();
  }

  // --- NUEVO: Marcar TODAS como leídas de un golpe (Batch) ---
  Future<void> _markAllAsRead(String userId, BuildContext context) async {
    final batch = FirebaseFirestore.instance.batch();
    final unreadDocs = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    if (unreadDocs.docs.isEmpty) return;

    for (var doc in unreadDocs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todas las alertas marcadas como leídas ✅'),
        ),
      );
    }
  }

  // --- NUEVO: Borrar TODAS las notificaciones (Batch) ---
  Future<void> _deleteAllNotifications(
    String userId,
    BuildContext context,
  ) async {
    final theme = Theme.of(context);

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '¿Limpiar buzón? 🧹',
          style: TextStyle(color: theme.primaryColor),
        ),
        content: const Text(
          'Se eliminarán todas tus notificaciones. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Borrar Todo',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final batch = FirebaseFirestore.instance.batch();
      final allDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      for (var doc in allDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    }
  }

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
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .get();
      if (!groupDoc.exists) throw Exception("El grupo ya no existe.");
      final group = GroupModel.fromMap(groupDoc.data()!, groupDoc.id);

      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .get();
      if (!taskDoc.exists) throw Exception("Esta tarea ya fue eliminada.");
      final task = TaskModel.fromMap(taskDoc.data()!, taskDoc.id);

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
        // --- NUEVO: BOTONES SUPERIORES ---
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            tooltip: 'Borrar todas',
            onPressed: () => _deleteAllNotifications(currentUserId, context),
          ),
          IconButton(
            icon: Icon(Icons.done_all, color: theme.primaryColor),
            tooltip: 'Marcar todas como leídas',
            onPressed: () => _markAllAsRead(currentUserId, context),
          ),
        ],
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
                    'Aquí aparecerán tus alertas',
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
                onDismissed: (direction) =>
                    _deleteNotification(doc.id, currentUserId),
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
                      _markAsRead(doc.id, currentUserId);
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
