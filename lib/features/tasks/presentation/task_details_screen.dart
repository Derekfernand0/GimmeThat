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
  DateTime? _currentDeadline;
  bool _isUploadingImage = false;

  List<Map<String, dynamic>> _groupMembers = [];
  bool _isMentioning = false;
  String _mentionQuery = '';

  @override
  void initState() {
    super.initState();
    _currentDeadline = widget.task.deadline;
    _currentSubtasks = List.from(widget.task.subtasks);
    _currentImages = List.from(widget.task.imageUrls);
    _loadGroupMembers();
    _commentController.addListener(_onCommentChanged);
  }

  void _loadGroupMembers() async {
    final members = await _groupService.getGroupMembersDetails(
      widget.group.members,
    );
    if (mounted) setState(() => _groupMembers = members);
  }

  void _onCommentChanged() {
    final text = _commentController.text;
    if (text.isEmpty) {
      setState(() => _isMentioning = false);
      return;
    }

    final words = text.split(' ');
    final lastWord = words.last;

    if (lastWord.startsWith('@')) {
      setState(() {
        _isMentioning = true;
        _mentionQuery = lastWord.substring(1).toLowerCase();
      });
    } else {
      setState(() => _isMentioning = false);
    }
  }

  Future<void> _confirmDeleteTask() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar', style: TextStyle(color: colorScheme.error)),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este elemento permanentemente?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Eliminar',
              style: TextStyle(color: colorScheme.onError),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Se eliminó correctamente.')),
          );
          await Future<void>.delayed(const Duration(milliseconds: 500));
          if (mounted) Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
        }
      }
    }
  }

  void _insertMention(String username) {
    final text = _commentController.text;
    final words = text.split(' ');
    words.removeLast();
    words.add('@$username ');

    _commentController.text = words.join(' ');
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
    setState(() => _isMentioning = false);
  }

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

  // --- NUEVA EDICIÓN CON HORA ---
  Future<void> _editDeadline() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 1. Pedimos la fecha
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _currentDeadline ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: colorScheme,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: theme.primaryColor),
            ),
          ),
          child: child!,
        );
      },
    );

    // 2. Pedimos la hora si la fecha fue seleccionada
    if (pickedDate != null && mounted) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _currentDeadline != null
            ? TimeOfDay.fromDateTime(_currentDeadline!)
            : TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: colorScheme,
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() => _currentDeadline = finalDateTime);
        await _taskService.updateTaskFields(widget.task.id, {
          'deadline': Timestamp.fromDate(finalDateTime),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Fecha y hora actualizadas! ⏰')),
          );
        }
      }
    }
  }

  Widget _buildCommentText(String text) {
    final theme = Theme.of(context);
    final words = text.split(' ');
    return Wrap(
      children: words.map((word) {
        final isMention = word.startsWith('@');
        return Text(
          '$word ',
          style: TextStyle(
            color: isMention
                ? theme.primaryColor
                : theme.textTheme.bodyLarge?.color,
            fontWeight: isMention ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

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

  Future<void> _toggleSubtask(int index, bool? value) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (value == null) return;
    if (value == true) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            '¿Subtarea terminada? ✨',
            style: TextStyle(color: theme.primaryColor),
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
              child: Text(
                'Aún no',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Sí, confirmar',
                style: TextStyle(color: colorScheme.onSecondary),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final myRole = widget.group.roles[currentUserId] ?? 'member';
    final canEdit = myRole == 'host' || myRole == 'admin';

    bool isDeadlineOverdue = false;
    String formattedDeadline = 'Sin límite';

    // --- CÁLCULO DE FECHA Y HORA ---
    if (_currentDeadline != null) {
      final now = DateTime.now();
      isDeadlineOverdue = _currentDeadline!.isBefore(now);

      final d = _currentDeadline!;
      final day = d.day.toString().padLeft(2, '0');
      final month = d.month.toString().padLeft(2, '0');
      final year = d.year;
      final hour = d.hour.toString().padLeft(2, '0');
      final minute = d.minute.toString().padLeft(2, '0');
      formattedDeadline = '$day/$month/$year a las $hour:$minute';
    }

    final List<Map<String, dynamic>> allMentionables = [
      {'username': 'everyone', 'uid': 'todos_id'},
      ..._groupMembers,
    ];
    final filteredMembers = allMentionables.where((m) {
      final name = m['username'].toString().toLowerCase();
      return name.contains(_mentionQuery) && m['uid'] != currentUserId;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Detalles 🌸',
          style: TextStyle(
            color: theme.appBarTheme.titleTextStyle?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryColor),
        actions: [
          if (canEdit)
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
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
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formattedDeadline,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDeadlineOverdue
                              ? colorScheme.error
                              : theme.textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (canEdit)
                        TextButton.icon(
                          onPressed: _editDeadline,
                          icon: Icon(
                            Icons.edit_calendar,
                            size: 16,
                            color: colorScheme.secondary,
                          ),
                          label: Text(
                            'Editar',
                            style: TextStyle(color: colorScheme.secondary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (widget.task.type == 'task') ...[
                    Row(
                      children: [
                        Icon(
                          Icons.stars,
                          size: 18,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Completada por: ${_getCompletedNames()}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodyMedium?.color,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (widget.task.description.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.dividerColor, width: 2),
                      ),
                      child: Text(
                        widget.task.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (widget.task.type == 'task') ...[
                    Row(
                      children: [
                        Icon(Icons.checklist_rtl, color: colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text(
                          'Pasos para lograrlo 🌱',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
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
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor.withValues(
                                  alpha: 0.08,
                                ),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: CheckboxListTile(
                            title: Text(
                              subtask['title'],
                              style: TextStyle(
                                color: isDoneByMe
                                    ? theme.textTheme.bodyMedium?.color
                                    : theme.primaryColor,
                                decoration: isDoneByMe
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            value: isDoneByMe,
                            activeColor: colorScheme.secondaryContainer,
                            checkColor: colorScheme.onSecondaryContainer,
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
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.add,
                              color: colorScheme.onSecondaryContainer,
                            ),
                            onPressed: _addSubtask,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Divider(color: theme.dividerColor, thickness: 2),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.photo_library,
                            color: colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Fotos y Apuntes 📸',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      _isUploadingImage
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: theme.primaryColor,
                                strokeWidth: 2,
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.add_a_photo,
                                color: theme.primaryColor,
                              ),
                              onPressed: _pickAndUploadImage,
                            ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_currentImages.isEmpty && !_isUploadingImage)
                    Text(
                      'Aún no hay fotos. ¡Sube la primera!',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
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
                                    if (canEdit)
                                      Positioned(
                                        top: 40,
                                        right: 20,
                                        child: IconButton(
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
                                                  '¿Seguro que quieres eliminar esta foto?',
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
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              colorScheme.error,
                                                        ),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    child: Text(
                                                      'Eliminar',
                                                      style: TextStyle(
                                                        color:
                                                            colorScheme.onError,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              try {
                                                await _storageService
                                                    .deleteImageByUrl(imageUrl);
                                                setState(
                                                  () => _currentImages.removeAt(
                                                    index,
                                                  ),
                                                );
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
                                                        'Error: $e',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                    Positioned(
                                      top: 40,
                                      left: 20,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                        onPressed: () => Navigator.pop(context),
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
                                      color: theme.cardColor,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: colorScheme.secondary,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 32),
                  Divider(color: theme.dividerColor, thickness: 2),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Comentarios 🦋',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  StreamBuilder<QuerySnapshot>(
                    stream: _taskService.getTaskComments(widget.task.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: theme.primaryColor,
                          ),
                        );
                      }
                      final comments = snapshot.data!.docs;
                      if (comments.isEmpty) {
                        return Text(
                          'Sé el primero en comentar algo...',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
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
                                  ? colorScheme.secondaryContainer.withValues(
                                      alpha: 0.4,
                                    )
                                  : theme.cardColor,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isMe
                                    ? colorScheme.secondary
                                    : theme.dividerColor,
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
                                        ? colorScheme.onSecondaryContainer
                                        : theme.textTheme.bodyMedium?.color,
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
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.2),
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
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.person,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    title: Text(
                      member['username'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
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
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.12),
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
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Escribe un comentario o usa @...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.send,
                        color: colorScheme.onSecondaryContainer,
                      ),
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
