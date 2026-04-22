// lib/features/tasks/presentation/group_tasks_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'calendar_screen.dart';
import '../../groups/domain/group_model.dart';
import '../data/task_service.dart';
import '../domain/task_model.dart';
import 'create_task_screen.dart';
import 'task_details_screen.dart';
import '../../groups/presentation/group_members_screen.dart';
import '../../groups/data/group_service.dart';

class GroupTasksScreen extends StatefulWidget {
  final GroupModel group;

  const GroupTasksScreen({super.key, required this.group});

  @override
  State<GroupTasksScreen> createState() => _GroupTasksScreenState();
}

class _GroupTasksScreenState extends State<GroupTasksScreen> {
  final TaskService _taskService = TaskService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final GroupService _groupService = GroupService();

  String _searchQuery = '';
  String _selectedPriority = 'Todas';

  Color _getTaskColor(DateTime? deadline, String type, ThemeData theme) {
    if (type == 'announcement') return Colors.blueAccent.shade200;
    if (deadline == null) return theme.primaryColor;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(deadline.year, deadline.month, deadline.day);
    final difference = taskDate.difference(today).inDays;

    if (difference < 0) return const Color(0xFFEF9A9A);
    if (difference <= 1) return const Color(0xFFFFCC80);
    return const Color(0xFFA5D6A7);
  }

  bool _isItemPinned(TaskModel task) {
    if (!task.pinnedBy.containsKey(currentUserId)) return false;
    final pinData = task.pinnedBy[currentUserId];

    if (pinData == 'indefinite') return true;
    if (pinData is Timestamp) {
      if (pinData.toDate().isAfter(DateTime.now())) return true;
    }
    return false;
  }

  void _showCreateOptions(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¿Qué deseas publicar?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.assignment,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                title: const Text(
                  'Nueva Tarea',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Asigna trabajo con fecha límite y checklist.',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CreateTaskScreen(groupId: widget.group.id),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.campaign, color: Colors.blue.shade800),
                ),
                title: const Text(
                  'Nuevo Anuncio',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Informa al grupo sin necesidad de marcarlo completado.',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateAnnouncementDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPinOptions(TaskModel task) {
    final isPinned = _isItemPinned(task);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isPinned ? 'Modificar Fijado 📌' : 'Fijar en la cima 📌',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              if (isPinned)
                ListTile(
                  leading: const Icon(
                    Icons.push_pin_outlined,
                    color: Colors.grey,
                  ),
                  title: const Text('Desfijar ahora'),
                  onTap: () {
                    _taskService.unpinItem(task.id, currentUserId);
                    Navigator.pop(ctx);
                  },
                ),
              const Divider(),
              ListTile(
                title: const Text('Fijar Indefinidamente'),
                onTap: () {
                  _taskService.pinItem(task.id, currentUserId, null);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Fijar por 1 Hora'),
                onTap: () {
                  _taskService.pinItem(
                    task.id,
                    currentUserId,
                    DateTime.now().add(const Duration(hours: 1)),
                  );
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Fijar por 12 Horas'),
                onTap: () {
                  _taskService.pinItem(
                    task.id,
                    currentUserId,
                    DateTime.now().add(const Duration(hours: 12)),
                  );
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Fijar por 24 Horas'),
                onTap: () {
                  _taskService.pinItem(
                    task.id,
                    currentUserId,
                    DateTime.now().add(const Duration(hours: 24)),
                  );
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateAnnouncementDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? selectedDate;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          // --- FORMATO DE FECHA Y HORA ---
          String dateText = 'No expirará';
          if (selectedDate != null) {
            final day = selectedDate!.day.toString().padLeft(2, '0');
            final month = selectedDate!.month.toString().padLeft(2, '0');
            final year = selectedDate!.year;
            final hour = selectedDate!.hour.toString().padLeft(2, '0');
            final minute = selectedDate!.minute.toString().padLeft(2, '0');
            dateText = '$day/$month/$year a las $hour:$minute';
          }

          return AlertDialog(
            backgroundColor: theme.scaffoldBackgroundColor,
            title: Row(
              children: [
                Icon(Icons.campaign, color: Colors.blue.shade400),
                const SizedBox(width: 8),
                Text(
                  'Crear Anuncio',
                  style: TextStyle(color: theme.primaryColor),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título del Anuncio (Requerido)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (Opcional)',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 15),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Expiración (Opcional)'),
                    subtitle: Text(
                      dateText,
                      style: TextStyle(color: theme.colorScheme.secondary),
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      // 1. Pedimos la fecha
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );

                      // 2. Si eligió fecha, pedimos la HORA
                      if (date != null && context.mounted) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );

                        if (time != null) {
                          setStateDialog(() {
                            selectedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  final newAnnouncement = TaskModel(
                    id: '',
                    groupId: widget.group.id,
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    deadline: selectedDate,
                    priority: 'alta',
                    createdBy: currentUserId,
                    type: 'announcement',
                  );
                  _taskService.createTask(newAnnouncement);
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'Publicar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar esta sala? ⚠️'),
        content: const Text('Esta acción es permanente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              await _groupService.deleteGroup(widget.group.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'Eliminar Todo',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final amIAdmin =
        widget.group.roles[currentUserId] == 'host' ||
        widget.group.roles[currentUserId] == 'admin';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            widget.group.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.appBarTheme.titleTextStyle?.color,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: theme.primaryColor),
          actions: [
            IconButton(
              icon: Icon(Icons.calendar_month, color: colorScheme.secondary),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CalendarScreen(group: widget.group),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.people_alt, color: theme.primaryColor),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupMembersScreen(group: widget.group),
                ),
              ),
            ),
            if (widget.group.roles[currentUserId] == 'host')
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                onPressed: () => _confirmDeleteGroup(context),
                tooltip: 'Eliminar esta sala',
              ),
          ],
          bottom: TabBar(
            labelColor: theme.primaryColor,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color,
            indicatorColor: colorScheme.secondary,
            tabs: const [
              Tab(text: 'Pendientes 🌱'),
              Tab(text: 'Completadas 🌸'),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: colorScheme.secondary,
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: theme.dividerColor,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: theme.dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          color: theme.textTheme.bodyMedium?.color,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip('Todas', context),
                        _buildFilterChip('alta', context),
                        _buildFilterChip('media', context),
                        _buildFilterChip('baja', context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<TaskModel>>(
                stream: _taskService.getTasksForGroup(widget.group.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: theme.primaryColor,
                      ),
                    );
                  }

                  final allTasks = snapshot.data ?? [];
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);

                  final activeItems = allTasks.where((task) {
                    final matchesSearch =
                        task.title.toLowerCase().contains(_searchQuery) ||
                        task.description.toLowerCase().contains(_searchQuery);
                    final matchesPriority =
                        _selectedPriority == 'Todas' ||
                        task.priority == _selectedPriority;

                    if (task.deadline != null) {
                      // Si es anuncio, se oculta en cuanto pasa la fecha/hora exacta
                      if (task.type == 'announcement' &&
                          task.deadline!.isBefore(now)) {
                        return false;
                      }

                      // Si es tarea, le damos 60 días de gracia
                      final taskDate = DateTime(
                        task.deadline!.year,
                        task.deadline!.month,
                        task.deadline!.day,
                      );
                      if (task.type == 'task' &&
                          today.difference(taskDate).inDays > 60 &&
                          !task.completedBy.contains(currentUserId)) {
                        return false;
                      }
                    }

                    return matchesSearch && matchesPriority;
                  }).toList();

                  activeItems.sort((a, b) {
                    if (a.deadline == null && b.deadline == null) return 0;
                    if (a.deadline == null) return 1;
                    if (b.deadline == null) return -1;
                    return a.deadline!.compareTo(b.deadline!);
                  });

                  final pinnedItems = activeItems
                      .where((t) => _isItemPinned(t))
                      .toList();
                  final unpinnedItems = activeItems
                      .where((t) => !_isItemPinned(t))
                      .toList();
                  final sortedItems = [...pinnedItems, ...unpinnedItems];

                  final pendingTasks = sortedItems
                      .where((t) => !t.completedBy.contains(currentUserId))
                      .toList();
                  final completedTasks = sortedItems
                      .where(
                        (t) =>
                            t.type == 'task' &&
                            t.completedBy.contains(currentUserId),
                      )
                      .toList();

                  return TabBarView(
                    children: [
                      _buildTaskList(
                        pendingTasks,
                        "No hay pendientes 🌱",
                        false,
                        context,
                      ),
                      _buildTaskList(
                        completedTasks,
                        "No hay tareas completadas 🌸",
                        true,
                        context,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: amIAdmin
            ? FloatingActionButton.extended(
                onPressed: () => _showCreateOptions(context),
                backgroundColor: colorScheme.secondaryContainer,
                icon: Icon(Icons.add, color: colorScheme.onSecondaryContainer),
                label: Text(
                  'Nuevo',
                  style: TextStyle(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildFilterChip(String label, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedPriority == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isSelected
                ? colorScheme.onSecondaryContainer
                : theme.textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
        selected: isSelected,
        selectedColor: colorScheme.secondaryContainer,
        backgroundColor: theme.cardColor,
        side: BorderSide(
          color: isSelected ? colorScheme.secondary : theme.dividerColor,
        ),
        onSelected: (bool selected) =>
            setState(() => _selectedPriority = label),
      ),
    );
  }

  Widget _buildTaskList(
    List<TaskModel> tasks,
    String emptyMessage,
    bool isCompletedList,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('lib/assets/images/empty_tasks.png', height: 150),
            const SizedBox(height: 20),
            Text(
              emptyMessage,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isAnnouncement = task.type == 'announcement';
        final isPinned = _isItemPinned(task);

        final taskColor = _getTaskColor(task.deadline, task.type, theme);

        // --- FORMATO DE FECHA CON HORA ---
        String dateText = 'Sin límite';
        if (task.deadline != null) {
          final d = task.deadline!;
          final day = d.day.toString().padLeft(2, '0');
          final month = d.month.toString().padLeft(2, '0');
          final year = d.year;
          final hour = d.hour.toString().padLeft(2, '0');
          final minute = d.minute.toString().padLeft(2, '0');
          dateText = '$day/$month/$year $hour:$minute';
        }

        final amIDone = task.completedBy.contains(currentUserId);

        return Card(
          color: isAnnouncement
              ? (theme.brightness == Brightness.dark
                    ? const Color(0xFF1A3B5C)
                    : Colors.blue.shade50)
              : theme.cardColor,
          elevation: isPinned ? 4 : 2,
          shadowColor: taskColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isCompletedList
                  ? Colors.grey.shade300
                  : taskColor.withOpacity(isPinned ? 1.0 : 0.5),
              width: isPinned ? 3 : 2,
            ),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCompletedList
                        ? Colors.grey.shade400
                        : taskColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAnnouncement ? Icons.campaign : Icons.assignment,
                    color: isCompletedList ? Colors.grey : taskColor,
                  ),
                ),
                if (isPinned)
                  const Positioned(
                    top: -2,
                    right: -2,
                    child: Icon(
                      Icons.push_pin,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                  ),
              ],
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isAnnouncement ? 18 : 16,
                color: isCompletedList
                    ? theme.textTheme.bodyMedium?.color
                    : theme.primaryColor,
                decoration: isCompletedList ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    maxLines: isAnnouncement ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                  ),
                ],
                const SizedBox(height: 8),
                if (task.deadline != null)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.8,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateText,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            trailing: isAnnouncement
                ? null
                : Checkbox(
                    value: amIDone,
                    activeColor: theme.colorScheme.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    onChanged: (bool? value) async {
                      if (value == null) return;
                      if (value == true) {
                        bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              '¡Misión Cumplida! 🎉',
                              style: TextStyle(color: theme.primaryColor),
                            ),
                            content: const Text(
                              '¿Estás seguro de que quieres marcar esta tarea como completada?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Aún me falta'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('¡Sí, lo logré!'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                      }
                      _taskService.toggleTaskCompletion(
                        task.id,
                        currentUserId,
                        value,
                      );
                    },
                  ),
            onLongPress: () => _showPinOptions(task),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TaskDetailsScreen(task: task, group: widget.group),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
