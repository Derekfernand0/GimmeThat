// lib/features/tasks/presentation/group_tasks_screen.dart
import 'calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Color _getTaskColor(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(deadline.year, deadline.month, deadline.day);
    final difference = taskDate.difference(today).inDays;

    if (difference < 0) return const Color(0xFFEF9A9A); // Rojo
    if (difference <= 1) return const Color(0xFFFFCC80); // Naranja
    return const Color(0xFFA5D6A7); // Verde
  }

  // Función para confirmar la eliminación
  void _confirmDeleteGroup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF7),
        title: const Text(
          '¿Eliminar esta sala? ⚠️',
          style: TextStyle(color: Color(0xFF5D4037)),
        ),
        content: const Text(
          'Esta acción es permanente. Se borrarán todas las tareas, fotos y comentarios de este grupo.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFDF7),
        appBar: AppBar(
          title: Text(
            widget.group.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF5D4037)),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month, color: Color(0xFFC8E6C9)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CalendarScreen(group: widget.group),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.people_alt, color: Color(0xFFF8BBD0)),
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
          bottom: const TabBar(
            labelColor: Color(0xFF5D4037),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFF8BBD0),
            tabs: [
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
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar tareas...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFF8BBD0),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: Color(0xFFFFF59D),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: Color(0xFFFFF59D),
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
                        const Icon(
                          Icons.filter_list,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip('Todas'),
                        _buildFilterChip('alta'),
                        _buildFilterChip('media'),
                        _buildFilterChip('baja'),
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
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.brown),
                    );
                  }

                  final allTasks = snapshot.data ?? [];

                  // Calculamos la fecha de hoy a medianoche para hacer la comparación
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);

                  // EL CEREBRO DEL FILTRO 🧠
                  final filteredTasks = allTasks.where((task) {
                    // 1. Filtro de Búsqueda
                    final matchesSearch =
                        task.title.toLowerCase().contains(_searchQuery) ||
                        task.description.toLowerCase().contains(_searchQuery);

                    // 2. Filtro de Prioridad
                    final matchesPriority =
                        _selectedPriority == 'Todas' ||
                        task.priority == _selectedPriority;

                    // 3. NUEVO FILTRO: Ocultar tareas archivadas (Más de 60 días viejas) 🙈
                    final taskDate = DateTime(
                      task.deadline.year,
                      task.deadline.month,
                      task.deadline.day,
                    );

                    // Calculamos la diferencia en días entre hoy y la fecha de la tarea
                    final differenceInDays = today.difference(taskDate).inDays;

                    // ¿Han pasado MÁS de 60 días (aprox 2 meses) desde que caducó?
                    final isArchived = differenceInDays > 60;

                    final isCompletedByMe = task.completedBy.contains(
                      currentUserId,
                    );

                    // Si la tarea caducó hace MÁS de 2 meses Y NO la has hecho, la ocultamos
                    if (isArchived && !isCompletedByMe) {
                      return false;
                    }

                    return matchesSearch && matchesPriority;
                  }).toList();

                  final pendingTasks = filteredTasks
                      .where((t) => !t.completedBy.contains(currentUserId))
                      .toList();
                  final completedTasks = filteredTasks
                      .where((t) => t.completedBy.contains(currentUserId))
                      .toList();

                  return TabBarView(
                    children: [
                      _buildTaskList(
                        pendingTasks,
                        "No tienes tareas pendientes 🌱",
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
        floatingActionButton:
            (widget.group.roles[currentUserId] == 'host' ||
                widget.group.roles[currentUserId] == 'admin')
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CreateTaskScreen(groupId: widget.group.id),
                    ),
                  );
                },
                backgroundColor: const Color(0xFFC8E6C9),
                icon: const Icon(Icons.add, color: Color(0xFF5D4037)),
                label: const Text(
                  'Nueva Tarea',
                  style: TextStyle(
                    color: Color(0xFF5D4037),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedPriority == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isSelected ? const Color(0xFF5D4037) : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
        selected: isSelected,
        selectedColor: const Color(0xFFFFF59D),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? const Color(0xFFFFF59D) : Colors.grey.shade300,
        ),
        onSelected: (bool selected) {
          setState(() {
            _selectedPriority = label;
          });
        },
      ),
    );
  }

  Widget _buildTaskList(
    List<TaskModel> tasks,
    String emptyMessage,
    bool isCompletedList,
    BuildContext context,
  ) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('lib/assets/images/empty_tasks.png', height: 150),
            const SizedBox(height: 20),
            Text(
              emptyMessage,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
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
        final taskColor = _getTaskColor(task.deadline);
        final dateText =
            '${task.deadline.day}/${task.deadline.month}/${task.deadline.year}';
        final amIDone = task.completedBy.contains(currentUserId);

        return Card(
          elevation: 2,
          shadowColor: taskColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isCompletedList
                  ? Colors.grey.shade300
                  : taskColor.withOpacity(0.5),
              width: 2,
            ),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isCompletedList ? Colors.grey.shade400 : taskColor,
                shape: BoxShape.circle,
                boxShadow: [
                  if (!isCompletedList)
                    BoxShadow(
                      color: taskColor.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                ],
              ),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCompletedList ? Colors.grey : const Color(0xFF5D4037),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Checkbox(
              value: amIDone,
              activeColor: const Color(0xFFF8BBD0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: (bool? value) async {
                if (value == null) return;

                if (value == true) {
                  bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text(
                        '¡Misión Cumplida! 🎉',
                        style: TextStyle(color: Color(0xFF5D4037)),
                      ),
                      content: const Text(
                        '¿Estás seguro de que quieres marcar esta tarea como completada?',
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
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

                  if (confirm != true) return;
                }

                _taskService.toggleTaskCompletion(
                  task.id,
                  currentUserId,
                  value,
                );
              },
            ),
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
