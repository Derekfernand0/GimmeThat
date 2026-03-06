// lib/features/tasks/presentation/create_task_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/task_model.dart';
import '../data/task_service.dart';

class CreateTaskScreen extends StatefulWidget {
  final String groupId; // Necesitamos saber en qué grupo se va a guardar

  const CreateTaskScreen({super.key, required this.groupId});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TaskService _taskService = TaskService();

  // Controladores para los textos
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // Variables para la fecha y la prioridad (con valores por defecto)
  DateTime? _selectedDate;
  String _selectedPriority = 'media'; // alta, media, baja
  bool _isLoading = false;

  // Función mágica de Flutter para abrir el calendario
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(
        const Duration(days: 1),
      ), // Sugiere mañana
      firstDate: DateTime.now(), // No deja elegir fechas del pasado
      lastDate: DateTime(2030),
      builder: (context, child) {
        // Le damos un toque de color a nuestro calendario
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF8BBD0), // Rosa suave
              onPrimary: Color(0xFF5D4037),
              onSurface: Color(0xFF5D4037),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Función para guardar la tarea en Firebase
  void _saveTask() async {
    if (_titleController.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ponle un título y una fecha límite 🌸'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUserUid = FirebaseAuth.instance.currentUser!.uid;

      // Armamos nuestro "paquete" (TaskModel)
      final newTask = TaskModel(
        id: '', // Firebase generará el ID automáticamente
        groupId: widget.groupId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        deadline: _selectedDate!,
        priority: _selectedPriority,
        createdBy: currentUserUid,
      );

      // Lo enviamos a Firebase
      await _taskService.createTask(newTask);

      // Si todo sale bien, cerramos esta pantalla y regresamos al grupo
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nueva Tarea ✨',
          style: TextStyle(
            color: Color(0xFF5D4037),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5D4037)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la tarea
            const Text(
              '¿Qué necesitamos hacer?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Ej. Investigar sobre la fotosíntesis',
              ),
            ),
            const SizedBox(height: 20),

            // Descripción
            const Text(
              'Detalles (Opcional)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 3, // Caja más grande
              decoration: const InputDecoration(
                hintText: 'Añade notas o instrucciones aquí...',
              ),
            ),
            const SizedBox(height: 20),

            // Fecha límite (Botón que abre el calendario)
            const Text(
              'Fecha límite',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Color(0xFFF8BBD0)),
                    const SizedBox(width: 10),
                    Text(
                      _selectedDate == null
                          ? 'Toca para elegir una fecha'
                          // Formato simple de fecha (Día/Mes/Año)
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: TextStyle(
                        color: _selectedDate == null
                            ? Colors.grey
                            : const Color(0xFF5D4037),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Prioridad
            const Text(
              'Prioridad',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPriorityButton(
                  'Baja',
                  'baja',
                  const Color(0xFFC8E6C9),
                ), // Verde
                _buildPriorityButton(
                  'Media',
                  'media',
                  const Color(0xFFFFF59D),
                ), // Amarillo
                _buildPriorityButton(
                  'Alta',
                  'alta',
                  const Color(0xFFF8BBD0),
                ), // Rosa/Rojo
              ],
            ),
            const SizedBox(height: 40),

            // Botón de Guardar
            // Botón de Guardar
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTask,
                // ¡Aquí está la magia corregida! 👇
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC8E6C9), // Verde suave
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.brown)
                    : const Text(
                        'Plantar esta tarea 🌱',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Un pequeño "widget" ayudante para dibujar los botones de prioridad
  Widget _buildPriorityButton(String label, String value, Color color) {
    bool isSelected = _selectedPriority == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPriority = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: const Color(0xFF5D4037),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
