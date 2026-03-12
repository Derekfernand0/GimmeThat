// lib/features/tasks/presentation/task_details_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/task_model.dart';
import '../data/task_service.dart';
import '../../../core/utils/storage_service.dart';
import '../../groups/domain/group_model.dart';
import '../../groups/data/group_service.dart';

class TaskDetailsScreen extends StatefulWidget {
  final TaskModel task;
  final GroupModel group;

  const TaskDetailsScreen({super.key, required this.task, required this.group});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final TaskService _taskService = TaskService();
  final StorageService _storageService = StorageService();
  final GroupService _groupService = GroupService();
  final ImagePicker _picker = ImagePicker();

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _subtaskController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  late List<Map<String, dynamic>> _currentSubtasks;
  late List<String> _currentImages;
  late DateTime _currentDeadline;
  bool _isUploadingImage = false;

  // --- VARIABLES PARA MENCIONES ---
  List<Map<String, dynamic>> _groupMembers = [];
  bool _isMentioning = false;
  String _mentionQuery = '';

  @override
  void initState() {
    super.initState();
    _currentDeadline = widget.task.deadline;
    _currentSubtasks = List.from(widget.task.subtasks);
    _currentImages = List.from(widget.task.imageUrls);

    // Cargamos los miembros para poder mencionarlos
    _loadGroupMembers();

    // Escuchamos el teclado para buscar el "@"
    _commentController.addListener(_onCommentChanged);
  }

  // Descarga la lista de participantes del grupo
  void _loadGroupMembers() async {
    final members = await _groupService.getGroupMembersDetails(
      widget.group.members,
    );
    if (mounted) {
      setState(() => _groupMembers = members);
    }
  }

  // Detecta si estás escribiendo un "@"
  void _onCommentChanged() {
    final text = _commentController.text;
    if (text.isEmpty) {
      setState(() => _isMentioning = false);
      return;
    }

    // Buscamos la última palabra que se está escribiendo
    final words = text.split(' ');
    final lastWord = words.last;

    if (lastWord.startsWith('@')) {
      setState(() {
        _isMentioning = true;
        _mentionQuery = lastWord
            .substring(1)
            .toLowerCase(); // Quitamos el @ para buscar el nombre
      });
    } else {
      setState(() => _isMentioning = false);
    }
  }

  // Función para confirmar la eliminación de la tarea 🗑️
  Future<void> _confirmDeleteTask() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Eliminar tarea',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta tarea permanentemente? Esta acción no se puede deshacer.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _storageService.deleteTaskImages(widget.task.id);
        await _taskService.deleteTask(widget.task.id);

        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            const SnackBar(content: Text('La tarea se eliminó correctamente.')),
          );
          await Future<void>.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pop(context); // Regresamos a la pantalla anterior
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo eliminar la tarea: $e')),
          );
        }
      }
    }
  }

  // Función para confirmar que la TAREA PRINCIPAL está lista ✨
  Future<void> _confirmCompleteMainTask() async {
    // Verificamos si ya la habías completado antes
    final isAlreadyCompleted = widget.task.completedBy.contains(currentUserId);

    if (isAlreadyCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya marcaste esta tarea como lista. ¡Buen trabajo! 🌸'),
        ),
      );
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '¡Misión Cumplida! 🎉',
          style: TextStyle(color: Color(0xFF5D4037)),
        ),
        content: const Text(
          '¿Estás seguro de que quieres marcar toda esta tarea como completada?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Aún me falta',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF8BBD0),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '¡Sí, lo logré!',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Agregamos al usuario actual a la lista de completedBy
      List<String> updatedCompletedBy = List.from(widget.task.completedBy);
      updatedCompletedBy.add(currentUserId);

      await _taskService.updateTaskFields(widget.task.id, {
        'completedBy': updatedCompletedBy,
        'isCompleted': true, // Si quieres, también cambiamos el estado global
      });

      if (mounted) {
        setState(() {
          // Actualizamos la vista localmente sin necesidad de recargar de Firebase
          widget.task.completedBy.add(currentUserId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Felicidades por terminar tu tarea! 🦋'),
          ),
        );
      }
    }
  }

  // Agrega el nombre seleccionado a la caja de texto
  void _insertMention(String username) {
    final text = _commentController.text;
    final words = text.split(' ');
    words.removeLast(); // Borramos lo que estaba escribiendo
    words.add(
      '@$username ',
    ); // Insertamos el nombre completo con un espacio al final

    _commentController.text = words.join(' ');
    // Movemos el cursor al final del texto
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );

    setState(() => _isMentioning = false);
  }

  // Función para convertir los IDs en nombres legibles 🦋
  String _getCompletedNames() {
    if (widget.task.completedBy.isEmpty) return 'Nadie aún 🌱';

    List<String> names = [];
    for (var uid in widget.task.completedBy) {
      final member = _groupMembers.firstWhere(
        (m) => m['uid'] == uid,
        orElse: () => {'username': 'Usuario'},
      );
      names.add(member['username']);
    }
    return names.join(', ');
  }

  // Función para abrir el calendario y editar la fecha 📅
  Future<void> _editDeadline() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _currentDeadline,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF8BBD0),
              onPrimary: Colors.white,
              onSurface: Color(0xFF5D4037),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _currentDeadline = pickedDate;
      });
      await _taskService.updateTaskFields(widget.task.id, {
        'deadline': Timestamp.fromDate(pickedDate),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Fecha límite actualizada! ⏰')),
        );
      }
    }
  }

  // Esta función pinta los @nombres de color azul
  Widget _buildCommentText(String text) {
    final words = text.split(' ');
    return Wrap(
      children: words.map((word) {
        final isMention = word.startsWith('@');
        return Text(
          '$word ',
          style: TextStyle(
            color: isMention ? Colors.blue : const Color(0xFF5D4037),
            fontWeight: isMention ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  // --- FUNCIONES DE TAREAS Y SUBTAREAS ---
  void _addSubtask() async {
    if (_subtaskController.text.trim().isEmpty) return;
    final newSubtask = {
      'title': _subtaskController.text.trim(),
      'completedBy': [],
    };
    setState(() {
      _currentSubtasks.add(newSubtask);
      _subtaskController.clear();
    });
    await _taskService.updateTaskFields(widget.task.id, {
      'subtasks': _currentSubtasks,
    });
  }

  // Subtareas CON confirmación ✅
  Future<void> _toggleSubtask(int index, bool? value) async {
    if (value == null) return;

    if (value == true) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            '¿Subtarea terminada? ✨',
            style: TextStyle(color: Color(0xFF5D4037)),
          ),
          content: const Text(
            '¿Seguro que quieres marcar este paso como completado?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Aún no', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF8BBD0),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Sí, confirmar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() {
      List<String> completedBy = List<String>.from(
        _currentSubtasks[index]['completedBy'] ?? [],
      );

      if (value == true) {
        if (!completedBy.contains(currentUserId)) {
          completedBy.add(currentUserId);
        }
      } else {
        completedBy.remove(currentUserId);
      }

      _currentSubtasks[index]['completedBy'] = completedBy;
    });

    await _taskService.updateTaskFields(widget.task.id, {
      'subtasks': _currentSubtasks,
    });
  }

  // --- FUNCIÓN MEJORADA: Comentarios y Menciones Globales 🦋 ---
  void _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();
    setState(() => _isMentioning = false);

    List<String> mentionedUsernames = [];
    final words = text.split(' ');

    final containsEveryone = words.any(
      (w) => w.toLowerCase() == '@everyone' || w.toLowerCase() == '@todos',
    );

    if (containsEveryone) {
      for (var member in _groupMembers) {
        if (member['uid'] != currentUserId) {
          mentionedUsernames.add(member['username']);
        }
      }
    } else {
      for (var word in words) {
        if (word.startsWith('@') && word.length > 1) {
          mentionedUsernames.add(word.substring(1));
        }
      }
    }

    await _taskService.addComment(
      widget.task.id,
      currentUserId,
      text,
      mentionedUsernames,
    );
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile == null) return;
    setState(() => _isUploadingImage = true);
    String? downloadUrl = await _storageService.uploadTaskImage(
      widget.task.id,
      File(pickedFile.path),
    );
    if (downloadUrl != null) {
      setState(() => _currentImages.add(downloadUrl));
      await _taskService.updateTaskFields(widget.task.id, {
        'imageUrls': _currentImages,
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir la imagen 😔')),
        );
      }
    }
    setState(() => _isUploadingImage = false);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(
      _currentDeadline.year,
      _currentDeadline.month,
      _currentDeadline.day,
    );
    final isDeadlineOverdue = deadlineDate.isBefore(today);
    final formattedDeadline =
        '${_currentDeadline.day.toString().padLeft(2, '0')}/${_currentDeadline.month.toString().padLeft(2, '0')}/${_currentDeadline.year}';
    final filteredMembers = _groupMembers.where((m) {
      final name = m['username'].toString().toLowerCase();
      return name.contains(_mentionQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      appBar: AppBar(
        title: const Text(
          'Detalles 🌸',
          style: TextStyle(
            color: Color(0xFF5D4037),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5D4037)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _confirmDeleteTask,
          ),
        ],
      ),
      body: Column(
        children: [
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Para el: $formattedDeadline',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDeadlineOverdue
                              ? Colors.redAccent
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _editDeadline,
                        icon: const Icon(
                          Icons.edit_calendar,
                          size: 16,
                          color: Color(0xFFF8BBD0),
                        ),
                        label: const Text(
                          'Editar',
                          style: TextStyle(color: Color(0xFFF8BBD0)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.stars,
                        size: 18,
                        color: Color(0xFFFFF59D),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Completada por: ${_getCompletedNames()}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
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
                      final List<dynamic> completedBy =
                          subtask['completedBy'] ?? [];
                      final bool isDoneByMe =
                          completedBy.contains(currentUserId) ||
                          (subtask['isDone'] == true);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade100,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: CheckboxListTile(
                          title: Text(
                            subtask['title'],
                            style: TextStyle(
                              color: isDoneByMe
                                  ? Colors.grey
                                  : const Color(0xFF5D4037),
                              decoration: isDoneByMe
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          value: isDoneByMe,
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.photo_library, color: Color(0xFFFFCC80)),
                          SizedBox(width: 8),
                          Text(
                            'Fotos y Apuntes 📸',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5D4037),
                            ),
                          ),
                        ],
                      ),
                      _isUploadingImage
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.brown,
                                strokeWidth: 2,
                              ),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.add_a_photo,
                                color: Color(0xFF5D4037),
                              ),
                              onPressed: _pickAndUploadImage,
                            ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_currentImages.isEmpty && !_isUploadingImage)
                    const Text(
                      'Aún no hay fotos. ¡Sube la primera!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  if (_currentImages.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: _currentImages.length,
                      itemBuilder: (context, index) {
                        final imageUrl = _currentImages[index];
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: EdgeInsets.zero,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    InteractiveViewer(
                                      panEnabled: true,
                                      minScale: 0.5,
                                      maxScale: 4.0,
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                                    Positioned(
                                      top: 40,
                                      right: 20,
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.redAccent,
                                              size: 30,
                                            ),
                                            onPressed: () async {
                                              bool?
                                              confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text(
                                                    'Borrar Foto',
                                                  ),
                                                  content: const Text(
                                                    '¿Seguro que quieres eliminar esta foto de la tarea?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      child: const Text(
                                                        'Cancelar',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                      child: const Text(
                                                        'Eliminar',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirm == true) {
                                                try {
                                                  await _storageService
                                                      .deleteImageByUrl(
                                                        imageUrl,
                                                      );
                                                  setState(() {
                                                    _currentImages.removeAt(
                                                      index,
                                                    );
                                                  });
                                                  await _taskService
                                                      .updateTaskFields(
                                                        widget.task.id,
                                                        {
                                                          'imageUrls':
                                                              _currentImages,
                                                        },
                                                      );
                                                  if (mounted) {
                                                    Navigator.pop(context);
                                                  }
                                                } catch (e) {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'No se pudo borrar la foto: $e',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              }
                                            },
                                          ),
                                          const SizedBox(width: 10),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 30,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, p) => p == null
                                  ? child
                                  : Container(
                                      color: Colors.grey.shade100,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFFF8BBD0),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFFFFF59D), thickness: 2),
                  const SizedBox(height: 16),

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

                  StreamBuilder<QuerySnapshot>(
                    stream: _taskService.getTaskComments(widget.task.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.brown),
                        );
                      }
                      final comments = snapshot.data!.docs;
                      if (comments.isEmpty) {
                        return const Text(
                          'Sé el primero en comentar algo...',
                          style: TextStyle(color: Colors.grey),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final data =
                              comments[index].data() as Map<String, dynamic>;
                          final isMe = data['userId'] == currentUserId;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
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
                                _buildCommentText(data['text'] ?? ''),
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

          if (_isMentioning && filteredMembers.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ListView.builder(
                itemCount: filteredMembers.length,
                itemBuilder: (context, index) {
                  final member = filteredMembers[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFC8E6C9),
                      child: Icon(Icons.person, color: Color(0xFF5D4037)),
                    ),
                    title: Text(
                      member['username'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                    onTap: () => _insertMention(member['username']),
                  );
                },
              ),
            ),

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
                      maxLines: null,
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
