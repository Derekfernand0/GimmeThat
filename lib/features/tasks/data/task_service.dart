// lib/features/tasks/data/task_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Crear una nueva tarea en la base de datos
  Future<void> createTask(TaskModel task) async {
    await _firestore.collection('tasks').add(task.toMap());
  }

  // 2. Escuchar todas las tareas de UN grupo específico en tiempo real
  Stream<List<TaskModel>> getTasksForGroup(String groupId) {
    return _firestore
        .collection('tasks')
        .where('groupId', isEqualTo: groupId)
        // Las ordenamos para que las más urgentes (fecha límite más cercana) salgan primero
        .orderBy('deadline')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // 3. Marcar una tarea como completada (o desmarcarla)
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'isCompleted': isCompleted,
    });
  }
}
