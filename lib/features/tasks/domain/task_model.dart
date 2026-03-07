// lib/features/tasks/domain/task_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final DateTime deadline;
  final String priority;
  final bool isCompleted;
  final String createdBy;

  final List<Map<String, dynamic>> subtasks;
  final List<String> tags;
  final List<String> completedBy;
  // ¡NUEVO CAMPO PARA LAS FOTOS! 📸
  final List<String> imageUrls;

  TaskModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.deadline,
    required this.priority,
    this.isCompleted = false,
    required this.createdBy,
    this.subtasks = const [],
    this.tags = const [],
    this.completedBy = const [],
    this.imageUrls = const [], // Vacío por defecto al crearla
  });

  factory TaskModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TaskModel(
      id: documentId,
      groupId: map['groupId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      deadline: (map['deadline'] as Timestamp).toDate(),
      priority: map['priority'] ?? 'media',
      isCompleted: map['isCompleted'] ?? false,
      createdBy: map['createdBy'] ?? '',

      subtasks: List<Map<String, dynamic>>.from(map['subtasks'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      completedBy: List<String>.from(map['completedBy'] ?? []),
      // Leemos las fotos de Firebase
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'title': title,
      'description': description,
      'deadline': Timestamp.fromDate(deadline),
      'priority': priority,
      'isCompleted': isCompleted,
      'createdBy': createdBy,
      'subtasks': subtasks,
      'tags': tags,
      'completedBy': completedBy,
      'imageUrls': imageUrls, // Guardamos las fotos en Firebase
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
