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

// ¡CAMBIO 1: Ahora es un StatefulWidget!
class GroupTasksScreen extends StatefulWidget {
  final GroupModel group;

  const GroupTasksScreen({super.key, required this.group});

  @override
  State<GroupTasksScreen> createState() => _GroupTasksScreenState();
}

class _GroupTasksScreenState extends State<GroupTasksScreen> {
  final TaskService _taskService = TaskService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // ¡NUEVAS VARIABLES PARA EL BUSCADOR Y FILTROS! 🦋
  String _searchQuery = '';
  String _selectedPriority = 'Todas'; // Puede ser: Todas, alta, media, baja

  Color _getTaskColor(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(deadline.year, deadline.month, deadline.day);
    final difference = taskDate.difference(today).inDays;

    if (difference < 0) return const Color(0xFFEF9A9A); // Rojo
    if (difference <= 1) return const Color(0xFFFFCC80); // Naranja
    return const Color(0xFFA5D6A7); // Verde
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFDF7), // Crema pastel
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
            // ¡NUEVO BOTÓN DE CALENDARIO! 📅
            IconButton(
              icon: const Icon(
                Icons.calendar_month,
                color: Color(0xFFC8E6C9),
              ), // Verde suave
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CalendarScreen(group: widget.group),
                  ),
                );
              },
            ),
            // Botón de participantes que ya teníamos
            IconButton(
              icon: const Icon(Icons.people_alt, color: Color(0xFFF8BBD0)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GroupMembersScreen(group: widget.group),
                  ),
                );
              },
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
        // ¡CAMBIO 2: Agregamos una columna para poner el buscador arriba de las listas!
        body: Column(
          children: [
            // LA BARRA DE BÚSQUEDA Y LOS FILTROS
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  // Caja de texto del buscador
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value
                            .toLowerCase(); // Guardamos lo que escribes en minúsculas
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
                  // Botones de filtro de prioridad (Chips horizontales)
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

            // LAS LISTAS DE TAREAS (Envueltas en Expanded para que tomen el resto del espacio)
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

                  // ¡CAMBIO 3: EL CEREBRO DEL FILTRO! 🧠
                  final filteredTasks = allTasks.where((task) {
                    // 1. ¿Coincide con el texto buscado? (Buscamos en el título y en la descripción)
                    final matchesSearch =
                        task.title.toLowerCase().contains(_searchQuery) ||
                        task.description.toLowerCase().contains(_searchQuery);
                    // 2. ¿Coincide con la prioridad seleccionada?
                    final matchesPriority =
                        _selectedPriority == 'Todas' ||
                        task.priority == _selectedPriority;

                    return matchesSearch && matchesPriority;
                  }).toList();

                  // Separamos las tareas filtradas en Pendientes y Completadas
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
                        "No se encontraron tareas 🌱",
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
        // BOTÓN FLOTANTE CON REGLAS DE ROLES
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

  // Pequeño constructor de botones de filtro
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
        selectedColor: const Color(
          0xFFFFF59D,
        ), // Amarillo pastel cuando está seleccionado
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

  // El diseño de la lista de tareas (Se mantiene igual, solo usamos widget.group en vez de group)
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
            // REEMPLAZA EL ICONO POR ESTO:
            Image.asset(
              'lib/assets/images/empty_tasks.png',
              height: 150, // Ajusta el tamaño como prefieras
            ),
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
              onChanged: (bool? value) {
                if (value != null) {
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
                  builder: (context) => TaskDetailsScreen(
                    task: task,
                    group: widget.group, // ¡Le pasamos el grupo aquí!
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
