// lib/features/tasks/domain/task_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final DateTime? deadline; // ¡Ahora es opcional para los anuncios!
  final String priority;
  final bool isCompleted;
  final String createdBy;

  // --- NUEVOS CAMPOS ---
  final String type; // Puede ser 'task' o 'announcement'
  final Map<String, dynamic> pinnedBy; // Guarda quién lo fijó y hasta cuándo 📌

  final List<Map<String, dynamic>> subtasks;
  final List<String> tags;
  final List<String> completedBy;
  final List<String> imageUrls;

  TaskModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    this.deadline,
    required this.priority,
    this.isCompleted = false,
    required this.createdBy,
    this.type = 'task',
    this.pinnedBy = const {},
    this.subtasks = const [],
    this.tags = const [],
    this.completedBy = const [],
    this.imageUrls = const [],
  });

  factory TaskModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TaskModel(
      id: documentId,
      groupId: map['groupId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      // Manejamos la fecha por si no tiene (como en los anuncios)
      deadline: map['deadline'] != null
          ? (map['deadline'] as Timestamp).toDate()
          : null,
      priority: map['priority'] ?? 'media',
      isCompleted: map['isCompleted'] ?? false,
      createdBy: map['createdBy'] ?? '',
      type: map['type'] ?? 'task',
      pinnedBy: Map<String, dynamic>.from(map['pinnedBy'] ?? {}),
      subtasks: List<Map<String, dynamic>>.from(map['subtasks'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      completedBy: List<String>.from(map['completedBy'] ?? []),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'title': title,
      'description': description,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'priority': priority,
      'isCompleted': isCompleted,
      'createdBy': createdBy,
      'type': type,
      'pinnedBy': pinnedBy,
      'subtasks': subtasks,
      'tags': tags,
      'completedBy': completedBy,
      'imageUrls': imageUrls,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
