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

  // 5. NUEVO: Enviar un comentario
  Future<void> addComment(String taskId, String userId, String text) async {
    // Primero, buscamos tu nombre de usuario en la base de datos
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final username = userDoc.data()?['username'] ?? 'Usuario';

    // Guardamos el comentario dentro de una "sub-carpeta" en esta tarea específica
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
