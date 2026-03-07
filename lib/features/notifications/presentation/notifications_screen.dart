// lib/features/notifications/presentation/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7), // Nuestro crema pastel
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
        // Escuchamos la colección secreta de notificaciones de ESTE usuario
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('notifications')
            .orderBy('createdAt', descending: true) // Las más nuevas arriba
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
                      : const Color(
                          0xFFFFF59D,
                        ).withOpacity(0.3), // Amarillo suave si no la has leído
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
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF8BBD0),
                      child: Icon(
                        Icons.alternate_email,
                        color: Color(0xFF5D4037),
                      ), // Icono de arroba @
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
                      _markAsRead(doc.id, currentUserId);
                      // TODO: Más adelante podemos hacer que al tocarla te lleve directo a la tarea
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
