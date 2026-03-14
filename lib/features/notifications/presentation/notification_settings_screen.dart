// lib/features/notifications/presentation/notification_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Opciones por defecto (todas encendidas)
  bool _notifyMentions = true;
  bool _notifyNewMembers = true;
  bool _notifyTaskCompleted = true;
  bool _notifyNewTasks = true;
  bool _notifyNewComments = true;
  bool _notifyTaskExpiring = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    if (doc.exists && doc.data()!.containsKey('notificationSettings')) {
      final settings = doc.data()!['notificationSettings'];
      setState(() {
        _notifyMentions = settings['mentions'] ?? true;
        _notifyNewMembers = settings['newMembers'] ?? true;
        _notifyTaskCompleted = settings['taskCompleted'] ?? true;
        _notifyNewTasks = settings['newTasks'] ?? true;
        _notifyNewComments = settings['newComments'] ?? true;
        _notifyTaskExpiring = settings['taskExpiring'] ?? true;
      });
    }
  }

  Future<void> _saveSettings() async {
    await FirebaseFirestore.instance.collection('users').doc(currentUserId).set(
      {
        'notificationSettings': {
          'mentions': _notifyMentions,
          'newMembers': _notifyNewMembers,
          'taskCompleted': _notifyTaskCompleted,
          'newTasks': _notifyNewTasks,
          'newComments': _notifyNewComments,
          'taskExpiring': _notifyTaskExpiring,
        },
      },
      SetOptions(merge: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      appBar: AppBar(
        title: const Text(
          'Ajustes de Notificaciones',
          style: TextStyle(color: Color(0xFF5D4037)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5D4037)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Elige qué quieres que te avisemos 🦋',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),

          _buildSwitch(
            'Menciones (@)',
            'Cuando alguien te menciona.',
            _notifyMentions,
            (v) {
              setState(() => _notifyMentions = v);
              _saveSettings();
            },
          ),
          _buildSwitch(
            'Comentarios',
            'Cuando alguien comenta en una tarea.',
            _notifyNewComments,
            (v) {
              setState(() => _notifyNewComments = v);
              _saveSettings();
            },
          ),
          _buildSwitch(
            'Nuevas Tareas',
            'Cuando se crea una tarea nueva.',
            _notifyNewTasks,
            (v) {
              setState(() => _notifyNewTasks = v);
              _saveSettings();
            },
          ),
          _buildSwitch(
            'Tareas Completadas',
            'Cuando alguien termina una tarea.',
            _notifyTaskCompleted,
            (v) {
              setState(() => _notifyTaskCompleted = v);
              _saveSettings();
            },
          ),
          _buildSwitch(
            'Vencimientos Urgentes',
            'Cuando a una tarea le queda 1 día.',
            _notifyTaskExpiring,
            (v) {
              setState(() => _notifyTaskExpiring = v);
              _saveSettings();
            },
          ),
          _buildSwitch(
            'Nuevos Integrantes',
            'Cuando alguien se une a la sala.',
            _notifyNewMembers,
            (v) {
              setState(() => _notifyNewMembers = v);
              _saveSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      activeColor: const Color(0xFFF8BBD0),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF5D4037),
        ),
      ),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}
