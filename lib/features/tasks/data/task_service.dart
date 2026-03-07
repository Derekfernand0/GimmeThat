// lib/features/tasks/data/task_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Crear una nueva tarea
  Future<void> createTask(TaskModel task) async {
    await _firestore.collection('tasks').add(task.toMap());
  }

  // 2. Escuchar todas las tareas de UN grupo
  Stream<List<TaskModel>> getTasksForGroup(String groupId) {
    return _firestore
        .collection('tasks')
        .where('groupId', isEqualTo: groupId)
        .orderBy('deadline')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // 3. ¡CORREGIDO! Marcar tarea como completada INDIVIDUALMENTE
  Future<void> toggleTaskCompletion(
    String taskId,
    String userId,
    bool isCompleted,
  ) async {
    if (isCompleted) {
      // arrayUnion mete tu ID a la lista (y Firebase se asegura de no repetirlo)
      await _firestore.collection('tasks').doc(taskId).update({
        'completedBy': FieldValue.arrayUnion([userId]),
      });
    } else {
      // arrayRemove saca tu ID de la lista
      await _firestore.collection('tasks').doc(taskId).update({
        'completedBy': FieldValue.arrayRemove([userId]),
      });
    }
  }

  // 4. Actualizar cualquier dato de la tarea (como los checklists)
  Future<void> updateTaskFields(
    String taskId,
    Map<String, dynamic> fieldsToUpdate,
  ) async {
    await _firestore.collection('tasks').doc(taskId).update(fieldsToUpdate);
  }

  // 5. NUEVO: Enviar un comentario Y detectar menciones
  Future<void> addComment(
    String taskId,
    String userId,
    String text,
    List<String> mentionedUsernames,
  ) async {
    // Primero, buscamos tu nombre de usuario
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final username = userDoc.data()?['username'] ?? 'Usuario';

    // Guardamos el comentario normalmente
    await _firestore
        .collection('tasks')
        .doc(taskId)
        .collection('comments')
        .add({
          'userId': userId,
          'username': username,
          'text': text,
          'createdAt': FieldValue.serverTimestamp(),
        });

    // ¡LA MAGIA DE LAS MENCIONES! 🦋
    // Por cada usuario que mencionaste, le dejamos una notificación en su perfil
    for (String mentionedName in mentionedUsernames) {
      // Buscamos cuál es el ID real de este usuario usando su nombre
      final userQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: mentionedName)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final targetUserId = userQuery.docs.first.id;

        // Verificamos que no te estés mencionando a ti mismo
        if (targetUserId != userId) {
          await _firestore
              .collection('users')
              .doc(targetUserId)
              .collection('notifications')
              .add({
                'type': 'mention',
                'title': '¡Alguien te mencionó!',
                'message': '$username te ha mencionado en un comentario.',
                'taskId': taskId,
                'createdAt': FieldValue.serverTimestamp(),
                'isRead': false, // Para saber si ya la vio o no
              });
          print(
            '✅ Notificación guardada en la base de datos para $mentionedName',
          );
        }
      }
    }
  }

  // 6. NUEVO: Escuchar los comentarios en tiempo real
  Stream<QuerySnapshot> getTaskComments(String taskId) {
    return _firestore
        .collection('tasks')
        .doc(taskId)
        .collection('comments')
        .orderBy('createdAt', descending: true) // Los más nuevos arriba
        .snapshots();
  }
}
