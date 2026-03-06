// lib/features/tasks/presentation/group_tasks_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../groups/domain/group_model.dart';
import '../data/task_service.dart';
import '../domain/task_model.dart';
import 'create_task_screen.dart';
import 'task_details_screen.dart';

class GroupTasksScreen extends StatelessWidget {
  final GroupModel group;
  final TaskService _taskService = TaskService();

  GroupTasksScreen({super.key, required this.group});

  // Obtenemos tu ID de usuario actual
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Color _getTaskColor(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(deadline.year, deadline.month, deadline.day);
    final difference = taskDate.difference(today).inDays;

    if (difference < 0) return const Color(0xFFEF9A9A);
    if (difference <= 1) return const Color(0xFFFFCC80);
    return const Color(0xFFA5D6A7);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            group.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF5D4037)),
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
        body: StreamBuilder<List<TaskModel>>(
          stream: _taskService.getTasksForGroup(group.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.brown),
              );
            }

            final tasks = snapshot.data ?? [];

            // ¡EL CAMBIO MÁGICO! 🦋
            // Si la lista 'completedBy' NO contiene tu ID, está pendiente para ti.
            final pendingTasks = tasks
                .where((t) => !t.completedBy.contains(currentUserId))
                .toList();
            // Si SÍ lo contiene, ya la terminaste.
            final completedTasks = tasks
                .where((t) => t.completedBy.contains(currentUserId))
                .toList();

            return TabBarView(
              children: [
                _buildTaskList(
                  pendingTasks,
                  "¡Todo listo por aquí! 🦋",
                  false,
                  context,
                ),
                _buildTaskList(
                  completedTasks,
                  "Aún no hay tareas terminadas",
                  true,
                  context,
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateTaskScreen(groupId: group.id),
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
        ),
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
            const Icon(Icons.auto_awesome, size: 80, color: Color(0xFFFFF59D)),
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

        // Verificamos si TÚ la completaste
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
              value: amIDone, // La casilla depende de si tu ID está en la lista
              activeColor: const Color(0xFFF8BBD0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: (bool? value) {
                if (value != null) {
                  // Enviamos tu ID para que Firebase te anote o te borre
                  _taskService.toggleTaskCompletion(
                    task.id,
                    currentUserId,
                    value,
                  );
                }
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailsScreen(task: task),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
