// lib/features/tasks/domain/task_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String groupId; // Para saber a qué grupo pertenece
  final String title;
  final String description;
  final DateTime deadline; // Fecha límite
  final String priority; // 'alta', 'media', 'baja'
  final bool isCompleted; // true si ya se terminó
  final String createdBy; // Quién la creó

  TaskModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.deadline,
    required this.priority,
    this.isCompleted = false, // Por defecto, una tarea nueva no está completada
    required this.createdBy,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TaskModel(
      id: documentId,
      groupId: map['groupId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      // Convertimos el "Timestamp" de Firebase a un "DateTime" de Flutter
      deadline: (map['deadline'] as Timestamp).toDate(),
      priority: map['priority'] ?? 'media',
      isCompleted: map['isCompleted'] ?? false,
      createdBy: map['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'title': title,
      'description': description,
      'deadline': Timestamp.fromDate(
        deadline,
      ), // Convertimos de vuelta para Firebase
      'priority': priority,
      'isCompleted': isCompleted,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(), // Guardamos cuándo se creó
    };
  }
}
