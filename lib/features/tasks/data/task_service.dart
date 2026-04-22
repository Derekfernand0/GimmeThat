// lib/features/tasks/data/task_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Crear una nueva tarea o anuncio
  Future<void> createTask(TaskModel task) async {
    final docRef = await _firestore.collection('tasks').add(task.toMap());

    // Solo mandamos notificación Push si es Tarea o Anuncio
    try {
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

      for (var memberId in members) {
        if (memberId != task.createdBy) {
          // Diferenciamos si es anuncio o tarea para la alerta
          final isAnuncio = task.type == 'announcement';

          await _firestore
              .collection('users')
              .doc(memberId)
              .collection('notifications')
              .add({
                'type': isAnuncio ? 'newAnnouncement' : 'newTask',
                'title': isAnuncio
                    ? '📢 Anuncio en $groupName'
                    : '📝 Nueva tarea en $groupName',
                'message': '$username publicó: "${task.title}"',
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
      print("Error enviando notificaciones: $e");
    }
  }

  // 2. Escuchar todas las tareas de UN grupo
  Stream<List<TaskModel>> getTasksForGroup(String groupId) {
    return _firestore
        .collection('tasks')
        .where('groupId', isEqualTo: groupId)
        // Ya no ordenamos directo en Firebase por deadline, porque los anuncios pueden no tener fecha.
        // Lo ordenaremos en el lado de la pantalla (Dart) para más poder.
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // 3. Marcar tarea como completada
  Future<void> toggleTaskCompletion(
    String taskId,
    String userId,
    bool isCompleted,
  ) async {
    if (isCompleted) {
      await _firestore.collection('tasks').doc(taskId).update({
        'completedBy': FieldValue.arrayUnion([userId]),
      });

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

  // 5. Borrar una tarea
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

  // 6. Enviar comentario
  Future<void> addComment(
    String taskId,
    String userId,
    String text,
    List<String> mentionedUsernames,
  ) async {
    // ... [Mantenemos el mismo código tuyo exacto de los comentarios aquí] ...
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final username = userDoc.data()?['username'] ?? 'Usuario';
    final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
    final groupId = taskDoc.data()?['groupId'];
    final taskTitle = taskDoc.data()?['title'] ?? 'Tarea';
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    final groupName = groupDoc.data()?['name'] ?? 'Grupo';
    final groupMembers = List<String>.from(groupDoc.data()?['members'] ?? []);

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

    for (String memberId in groupMembers) {
      if (memberId == userId) continue;
      bool isMentioned = mentionedUserIds.contains(memberId);
      await _firestore
          .collection('users')
          .doc(memberId)
          .collection('notifications')
          .add({
            'type': isMentioned ? 'mention' : 'newComment',
            'title': isMentioned
                ? 'Te mencionaron en $groupName 💬'
                : 'Nuevo comentario en $groupName 🦋',
            'message': isMentioned
                ? '$username te mencionó en: "$taskTitle"'
                : '$username comentó en: "$taskTitle"',
            'taskId': taskId,
            'groupId': groupId,
            'taskTitle': taskTitle,
            'groupName': groupName,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
    }
  }

  Stream<QuerySnapshot> getTaskComments(String taskId) {
    return _firestore
        .collection('tasks')
        .doc(taskId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ========================================================
  // --- NUEVAS FUNCIONES: FIJAR Y DESFIJAR TAREAS/ANUNCIOS ---
  // ========================================================

  Future<void> pinItem(
    String taskId,
    String userId,
    DateTime? expirationDate,
  ) async {
    // Si expirationDate es nulo, significa 'Indefinido'. Si no, guardamos la fecha en la que caduca el pin.
    await _firestore.collection('tasks').doc(taskId).update({
      'pinnedBy.$userId': expirationDate != null
          ? Timestamp.fromDate(expirationDate)
          : 'indefinite',
    });
  }

  Future<void> unpinItem(String taskId, String userId) async {
    // Eliminamos al usuario de la lista de fijados de esta tarea
    await _firestore.collection('tasks').doc(taskId).update({
      'pinnedBy.$userId': FieldValue.delete(),
    });
  }
}
