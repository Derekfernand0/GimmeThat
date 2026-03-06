// lib/features/tasks/presentation/task_details_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/task_model.dart';
import '../data/task_service.dart';

class TaskDetailsScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final TaskService _taskService = TaskService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  final TextEditingController _subtaskController = TextEditingController();
  final TextEditingController _commentController =
      TextEditingController(); // Controlador para el chat

  late List<Map<String, dynamic>> _currentSubtasks;

  @override
  void initState() {
    super.initState();
    _currentSubtasks = List.from(widget.task.subtasks);
  }

  void _addSubtask() async {
    if (_subtaskController.text.trim().isEmpty) return;
    final newSubtask = {
      'title': _subtaskController.text.trim(),
      'isDone': false,
    };
    setState(() {
      _currentSubtasks.add(newSubtask);
      _subtaskController.clear();
    });
    await _taskService.updateTaskFields(widget.task.id, {
      'subtasks': _currentSubtasks,
    });
  }

  void _toggleSubtask(int index, bool? value) async {
    setState(() => _currentSubtasks[index]['isDone'] = value ?? false);
    await _taskService.updateTaskFields(widget.task.id, {
      'subtasks': _currentSubtasks,
    });
  }

  // Función para enviar comentario
  void _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear(); // Limpia la caja rápido para mejor experiencia
    await _taskService.addComment(widget.task.id, currentUserId, text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      appBar: AppBar(
        title: const Text(
          'Detalles de la tarea 🌸',
          style: TextStyle(
            color: Color(0xFF5D4037),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5D4037)),
      ),
      // Usamos un Column principal para separar los detalles (arriba) de la caja de comentarios (abajo)
      body: Column(
        children: [
          // 1. ZONA SCROLLEABLE (Detalles, Checklists y Lista de Comentarios)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (widget.task.description.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFF59D),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        widget.task.description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Row(
                    children: [
                      Icon(Icons.checklist_rtl, color: Color(0xFFF8BBD0)),
                      SizedBox(width: 8),
                      Text(
                        'Pasos para lograrlo 🌱',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _currentSubtasks.length,
                    itemBuilder: (context, index) {
                      final subtask = _currentSubtasks[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade100,
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CheckboxListTile(
                          title: Text(
                            subtask['title'],
                            style: TextStyle(
                              color: subtask['isDone']
                                  ? Colors.grey
                                  : const Color(0xFF5D4037),
                              decoration: subtask['isDone']
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          value: subtask['isDone'],
                          activeColor: const Color(0xFFC8E6C9),
                          checkColor: const Color(0xFF5D4037),
                          onChanged: (val) => _toggleSubtask(index, val),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subtaskController,
                          decoration: const InputDecoration(
                            hintText: 'Ej. Hacer portada...',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                          onSubmitted: (_) => _addSubtask(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8BBD0),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Color(0xFF5D4037)),
                          onPressed: _addSubtask,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFFFFF59D), thickness: 2),
                  const SizedBox(height: 16),

                  // SECCIÓN DE COMENTARIOS
                  const Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, color: Color(0xFFC8E6C9)),
                      SizedBox(width: 8),
                      Text(
                        'Comentarios 🦋',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Escuchador de comentarios en tiempo real
                  StreamBuilder<QuerySnapshot>(
                    stream: _taskService.getTaskComments(widget.task.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.brown),
                        );

                      final comments = snapshot.data!.docs;
                      if (comments.isEmpty)
                        return const Text(
                          'Sé el primero en comentar algo...',
                          style: TextStyle(color: Colors.grey),
                        );

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final data =
                              comments[index].data() as Map<String, dynamic>;
                          final isMe = data['userId'] == currentUserId;

                          // TODO: Más adelante implementaremos el resaltado azul para "@menciones" aquí

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              // Si soy yo, el globo es rosa. Si es otro, es blanco.
                              color: isMe
                                  ? const Color(0xFFF8BBD0).withOpacity(0.3)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isMe
                                    ? const Color(0xFFF8BBD0)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['username'] ?? 'Usuario',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isMe
                                        ? const Color(0xFF5D4037)
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['text'] ?? '',
                                  style: const TextStyle(
                                    color: Color(0xFF5D4037),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 2. CAJA DE TEXTO INFERIOR (Fija abajo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Escribe un comentario o usa @...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFFFDF7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLines:
                          null, // Permite que la caja crezca si el texto es muy largo
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFC8E6C9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF5D4037)),
                      onPressed: _sendComment,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
