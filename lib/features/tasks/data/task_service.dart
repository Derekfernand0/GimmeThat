// lib/features/tasks/data/task_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Crear una nueva tarea
  Future<void> createTask(TaskModel task) async {
    final docRef = await _firestore.collection('tasks').add(task.toMap());

    // --- NUEVO: Notificación de Tarea Nueva ---
    try {
      // Buscamos el nombre del grupo y del creador
      final groupDoc = await _firestore
          .collection('groups')
          .doc(task.groupId)
          .get();
      final userDoc = await _firestore
          .collection('users')
          .doc(task.createdBy)
          .get();

      final groupName = groupDoc.data()?['name'] ?? 'un grupo';
      final username = userDoc.data()?['username'] ?? 'Alguien';
      final members = List<String>.from(groupDoc.data()?['members'] ?? []);

      // Le avisamos a todos los miembros (menos al que la creó)
      for (var memberId in members) {
        if (memberId != task.createdBy) {
          await _firestore
              .collection('users')
              .doc(memberId)
              .collection('notifications')
              .add({
                'type': 'newTask',
                'title': 'Nueva tarea en $groupName 📝',
                'message': '$username creó la tarea: "${task.title}"',
                'taskId': docRef.id,
                'groupId': task.groupId,
                'taskTitle': task.title,
                'groupName': groupName,
                'createdAt': FieldValue.serverTimestamp(),
                'isRead': false,
              });
        }
      }
    } catch (e) {
      print("Error enviando notificaciones de nueva tarea: $e");
    }
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

  // 3. Marcar tarea como completada INDIVIDUALMENTE
  Future<void> toggleTaskCompletion(
    String taskId,
    String userId,
    bool isCompleted,
  ) async {
    if (isCompleted) {
      await _firestore.collection('tasks').doc(taskId).update({
        'completedBy': FieldValue.arrayUnion([userId]),
      });

      // --- NUEVO: Notificación de Tarea Completada ---
      try {
        final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
        final groupId = taskDoc.data()?['groupId'];
        final taskTitle = taskDoc.data()?['title'] ?? 'Tarea';

        final groupDoc = await _firestore
            .collection('groups')
            .doc(groupId)
            .get();
        final groupName = groupDoc.data()?['name'] ?? 'un grupo';
        final members = List<String>.from(groupDoc.data()?['members'] ?? []);

        final userDoc = await _firestore.collection('users').doc(userId).get();
        final username = userDoc.data()?['username'] ?? 'Alguien';

        // Avisamos a todos menos al que la completó
        for (var memberId in members) {
          if (memberId != userId) {
            await _firestore
                .collection('users')
                .doc(memberId)
                .collection('notifications')
                .add({
                  'type': 'taskCompleted',
                  'title': '¡Avance en $groupName! 🌟',
                  'message': '$username acaba de terminar: "$taskTitle"',
                  'taskId': taskId,
                  'groupId': groupId,
                  'taskTitle': taskTitle,
                  'groupName': groupName,
                  'createdAt': FieldValue.serverTimestamp(),
                  'isRead': false,
                });
          }
        }
      } catch (e) {
        print("Error enviando notificaciones de tarea completada: $e");
      }
    } else {
      await _firestore.collection('tasks').doc(taskId).update({
        'completedBy': FieldValue.arrayRemove([userId]),
      });
    }
  }

  // 4. Actualizar cualquier dato de la tarea
  Future<void> updateTaskFields(
    String taskId,
    Map<String, dynamic> fieldsToUpdate,
  ) async {
    await _firestore.collection('tasks').doc(taskId).update(fieldsToUpdate);
  }

  // 5. Borrar una tarea y sus comentarios
  Future<void> deleteTask(String taskId) async {
    final comments = await _firestore
        .collection('tasks')
        .doc(taskId)
        .collection('comments')
        .get();

    final batch = _firestore.batch();

    for (final comment in comments.docs) {
      batch.delete(comment.reference);
    }

    batch.delete(_firestore.collection('tasks').doc(taskId));
    await batch.commit();
  }

  // 6. Enviar comentario, detectar menciones y avisar al grupo 🦋
  Future<void> addComment(
    String taskId,
    String userId,
    String text,
    List<String> mentionedUsernames,
  ) async {
    // 1. Obtenemos quién está escribiendo
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final username = userDoc.data()?['username'] ?? 'Usuario';

    // 2. Obtenemos los detalles de la Tarea (para el título y el groupId)
    final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
    final groupId = taskDoc.data()?['groupId'];
    final taskTitle = taskDoc.data()?['title'] ?? 'Tarea';

    // 3. Obtenemos los detalles del Grupo (para el nombre y la lista de integrantes)
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    final groupName = groupDoc.data()?['name'] ?? 'Grupo';
    final groupMembers = List<String>.from(groupDoc.data()?['members'] ?? []);

    // 4. Guardamos el comentario
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

    // 5. Convertimos los @nombres en IDs reales
    List<String> mentionedUserIds = [];
    for (String mentionedName in mentionedUsernames) {
      final userQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: mentionedName)
          .get();

      if (userQuery.docs.isNotEmpty) {
        mentionedUserIds.add(userQuery.docs.first.id);
      }
    }

    // 6. ¡A REPARTIR NOTIFICACIONES A TODO EL GRUPO! 📨
    for (String memberId in groupMembers) {
      // No te mandes notificación a ti mismo por tu propio comentario
      if (memberId == userId) continue;

      bool isMentioned = mentionedUserIds.contains(memberId);

      // Decidimos qué tipo de notificación es
      String type = isMentioned ? 'mention' : 'newComment';
      String title = isMentioned
          ? 'Te mencionaron en $groupName 💬'
          : 'Nuevo comentario en $groupName 🦋';
      String message = isMentioned
          ? '$username te mencionó en: "$taskTitle"'
          : '$username comentó en: "$taskTitle"';

      // La guardamos en el buzón del usuario
      await _firestore
          .collection('users')
          .doc(memberId)
          .collection('notifications')
          .add({
            'type': type,
            'title': title,
            'message': message,
            'taskId': taskId,
            'groupId': groupId,
            'taskTitle': taskTitle,
            'groupName': groupName, // ¡Súper importante para los Deep Links!
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
    }
  }

  // 7. Escuchar los comentarios en tiempo real
  Stream<QuerySnapshot> getTaskComments(String taskId) {
    return _firestore
        .collection('tasks')
        .doc(taskId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
