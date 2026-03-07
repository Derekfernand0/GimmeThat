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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Cargar preferencias desde Firebase
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
      });
    }
  }

  // Guardar preferencias en Firebase
  Future<void> _saveSettings() async {
    await FirebaseFirestore.instance.collection('users').doc(currentUserId).set(
      {
        'notificationSettings': {
          'mentions': _notifyMentions,
          'newMembers': _notifyNewMembers,
          'taskCompleted': _notifyTaskCompleted,
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

          SwitchListTile(
            activeColor: const Color(0xFFF8BBD0),
            title: const Text('Menciones (@)'),
            subtitle: const Text(
              'Cuando alguien te menciona en un apunte o tarea.',
            ),
            value: _notifyMentions,
            onChanged: (val) {
              setState(() => _notifyMentions = val);
              _saveSettings();
            },
          ),
          SwitchListTile(
            activeColor: const Color(0xFFF8BBD0),
            title: const Text('Nuevos Integrantes'),
            subtitle: const Text('Cuando alguien se une a tu sala.'),
            value: _notifyNewMembers,
            onChanged: (val) {
              setState(() => _notifyNewMembers = val);
              _saveSettings();
            },
          ),
          SwitchListTile(
            activeColor: const Color(0xFFF8BBD0),
            title: const Text('Tareas Completadas'),
            subtitle: const Text(
              'Cuando alguien termina una tarea de tu grupo.',
            ),
            value: _notifyTaskCompleted,
            onChanged: (val) {
              setState(() => _notifyTaskCompleted = val);
              _saveSettings();
            },
          ),
        ],
      ),
    );
  }
}
