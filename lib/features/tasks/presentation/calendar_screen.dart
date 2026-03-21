// lib/features/tasks/presentation/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../groups/domain/group_model.dart';
import '../domain/task_model.dart';
import '../data/task_service.dart';
import 'task_details_screen.dart';

class CalendarScreen extends StatefulWidget {
  final GroupModel group;

  const CalendarScreen({super.key, required this.group});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TaskService _taskService = TaskService();

  // Variables para controlar el calendario
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Aquí guardaremos las tareas ordenadas por fecha
  Map<DateTime, List<TaskModel>> _tasksByDate = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // Función para agrupar la lista de tareas en fechas exactas (sin horas)
  Map<DateTime, List<TaskModel>> _groupTasksByDate(List<TaskModel> tasks) {
    Map<DateTime, List<TaskModel>> data = {};
    for (var task in tasks) {
      // ¡CORRECCIÓN! Si el elemento (como un anuncio) no tiene fecha, lo ignoramos en el calendario
      if (task.deadline == null) continue;

      // Normalizamos la fecha (ahora estamos seguros de que no es null usando !)
      final date = DateTime(
        task.deadline!.year,
        task.deadline!.month,
        task.deadline!.day,
      );
      if (data[date] == null) {
        data[date] = [];
      }
      data[date]!.add(task);
    }
    return data;
  }

  // Función que el calendario usa para saber cuántos puntitos dibujar
  List<TaskModel> _getTasksForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _tasksByDate[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Calendario 📅',
          style: TextStyle(
            color: theme.appBarTheme.titleTextStyle?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryColor),
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: _taskService.getTasksForGroup(widget.group.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            );
          }

          final tasks = snapshot.data ?? [];
          // Agrupamos las tareas cada vez que hay cambios en Firebase
          _tasksByDate = _groupTasksByDate(tasks);

          // Obtenemos las tareas del día que el usuario tocó
          final selectedTasks = _getTasksForDay(_selectedDay ?? _focusedDay);

          return Column(
            children: [
              // --- EL CALENDARIO ---
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.12),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: TableCalendar<TaskModel>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader:
                      _getTasksForDay, // Le dice al calendario dónde poner puntos
                  startingDayOfWeek: StartingDayOfWeek.monday,

                  // ¡Estilos! 🦋
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                    selectedTextStyle: TextStyle(
                      color: colorScheme.onSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                    defaultTextStyle: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    weekendTextStyle: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible:
                        false, // Ocultamos el botón de "2 weeks"
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: theme.primaryColor,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: theme.primaryColor,
                    ),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                ),
              ),

              const SizedBox(height: 10),
              Text(
                'Tareas para este día 🌸',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 10),

              // --- LISTA DE TAREAS DEL DÍA SELECCIONADO ---
              Expanded(
                child: selectedTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.nightlight_round,
                              size: 60,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Día libre. ¡A descansar!',
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: selectedTasks.length,
                        itemBuilder: (context, index) {
                          final task = selectedTasks[index];
                          final isAnnouncement = task.type == 'announcement';

                          return Card(
                            elevation: 0,
                            color: theme.cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(
                                color: isAnnouncement
                                    ? Colors.blueAccent
                                    : colorScheme.secondary,
                                width: 2,
                              ),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Icon(
                                isAnnouncement
                                    ? Icons.campaign
                                    : Icons.assignment,
                                color: isAnnouncement
                                    ? Colors.blueAccent
                                    : colorScheme.secondary,
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                              subtitle: Text(
                                isAnnouncement
                                    ? '📢 Anuncio Especial'
                                    : 'Prioridad: ${task.priority}',
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                color: colorScheme.secondary,
                                size: 16,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TaskDetailsScreen(
                                      task: task,
                                      group: widget.group,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
