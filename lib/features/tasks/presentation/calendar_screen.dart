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
      // Normalizamos la fecha para ignorar la hora y los minutos
      final date = DateTime(
        task.deadline.year,
        task.deadline.month,
        task.deadline.day,
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7), // Crema pastel
      appBar: AppBar(
        title: const Text(
          'Calendario 📅',
          style: TextStyle(
            color: Color(0xFF5D4037),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5D4037)),
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: _taskService.getTasksForGroup(widget.group.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.brown),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
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

                  // ¡Estilos Pastel Pony! 🦋
                  calendarStyle: CalendarStyle(
                    todayDecoration: const BoxDecoration(
                      color: Color(0xFFFFF59D),
                      shape: BoxShape.circle,
                    ), // Amarillo
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFFF8BBD0),
                      shape: BoxShape.circle,
                    ), // Rosa
                    markerDecoration: const BoxDecoration(
                      color: Color(0xFFC8E6C9),
                      shape: BoxShape.circle,
                    ), // Puntos verdes
                    todayTextStyle: const TextStyle(
                      color: Color(0xFF5D4037),
                      fontWeight: FontWeight.bold,
                    ),
                    selectedTextStyle: const TextStyle(
                      color: Color(0xFF5D4037),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible:
                        false, // Ocultamos el botón de "2 weeks"
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      color: Color(0xFF5D4037),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                  color: Colors.grey.shade700,
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
                            const Icon(
                              Icons.nightlight_round,
                              size: 60,
                              color: Color(0xFFFFF59D),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Día libre. ¡A descansar!',
                              style: TextStyle(color: Colors.grey.shade500),
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
                          return Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: const BorderSide(
                                color: Color(0xFFC8E6C9),
                                width: 2,
                              ), // Verde suave
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                task.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5D4037),
                                ),
                              ),
                              subtitle: Text(
                                'Prioridad: ${task.priority}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFFF8BBD0),
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
