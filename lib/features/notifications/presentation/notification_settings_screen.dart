// lib/features/notifications/presentation/notification_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/theme_notifier.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Preferencias de Notificaciones
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
    // Usamos el tema actual en lugar de colores fijos
    final theme = Theme.of(context);
    final themeNotifier = ThemeNotifier();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Configuración General',
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ================= SECCIÓN DE APARIENCIA =================
          Text(
            'APARIENCIA 🎨',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 10),

          ListTile(
            title: Text('Modo Claro 🌸', style: theme.textTheme.bodyLarge),
            leading: Radio<AppThemeMode>(
              value: AppThemeMode.light,
              groupValue: themeNotifier.currentMode,
              activeColor: theme.primaryColor,
              onChanged: (val) => setState(() => themeNotifier.setMode(val!)),
            ),
          ),
          ListTile(
            title: Text(
              'Modo Oscuro Profundo 🌙',
              style: theme.textTheme.bodyLarge,
            ),
            leading: Radio<AppThemeMode>(
              value: AppThemeMode.dark,
              groupValue: themeNotifier.currentMode,
              activeColor: theme.primaryColor,
              onChanged: (val) => setState(() => themeNotifier.setMode(val!)),
            ),
          ),
          ListTile(
            title: Text(
              'Modo Noche Azulada 🌌',
              style: theme.textTheme.bodyLarge,
            ),
            leading: Radio<AppThemeMode>(
              value: AppThemeMode.blueDark,
              groupValue: themeNotifier.currentMode,
              activeColor: theme.primaryColor,
              onChanged: (val) => setState(() => themeNotifier.setMode(val!)),
            ),
          ),
          ListTile(
            title: Text(
              'Modo Custom (Tus Colores) 🦋',
              style: theme.textTheme.bodyLarge,
            ),
            leading: Radio<AppThemeMode>(
              value: AppThemeMode.custom,
              groupValue: themeNotifier.currentMode,
              activeColor: theme.primaryColor,
              onChanged: (val) => setState(() => themeNotifier.setMode(val!)),
            ),
          ),

          // Selector de colores Custom (Solo aparece si seleccionas el modo Custom)
          if (themeNotifier.currentMode == AppThemeMode.custom) ...[
            const SizedBox(height: 10),
            _buildCustomColorPicker(
              'Color de Fondo:',
              themeNotifier.customBg,
              (color) => setState(
                () => themeNotifier.setCustomColors(
                  color,
                  themeNotifier.customPrimary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildCustomColorPicker(
              'Color de Acento (Textos/Iconos):',
              themeNotifier.customPrimary,
              (color) => setState(
                () => themeNotifier.setCustomColors(
                  themeNotifier.customBg,
                  color,
                ),
              ),
            ),
          ],

          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 10),

          // ================= SECCIÓN DE NOTIFICACIONES =================
          Text(
            'NOTIFICACIONES 🔔',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 10),

          _buildSwitch(
            'Menciones (@)',
            'Cuando alguien te menciona.',
            _notifyMentions,
            (v) {
              setState(() => _notifyMentions = v);
              _saveSettings();
            },
            theme,
          ),
          _buildSwitch(
            'Comentarios',
            'Cuando alguien comenta.',
            _notifyNewComments,
            (v) {
              setState(() => _notifyNewComments = v);
              _saveSettings();
            },
            theme,
          ),
          _buildSwitch(
            'Nuevas Tareas',
            'Cuando se crea una tarea.',
            _notifyNewTasks,
            (v) {
              setState(() => _notifyNewTasks = v);
              _saveSettings();
            },
            theme,
          ),
          _buildSwitch(
            'Tareas Completadas',
            'Cuando alguien termina.',
            _notifyTaskCompleted,
            (v) {
              setState(() => _notifyTaskCompleted = v);
              _saveSettings();
            },
            theme,
          ),
          _buildSwitch(
            'Vencimientos',
            'Alertas de último día.',
            _notifyTaskExpiring,
            (v) {
              setState(() => _notifyTaskExpiring = v);
              _saveSettings();
            },
            theme,
          ),
          _buildSwitch(
            'Nuevos Integrantes',
            'Cuando alguien entra.',
            _notifyNewMembers,
            (v) {
              setState(() => _notifyNewMembers = v);
              _saveSettings();
            },
            theme,
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
    ThemeData theme,
  ) {
    return SwitchListTile(
      activeColor: theme.primaryColor,
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle, style: theme.textTheme.bodyMedium),
      value: value,
      onChanged: onChanged,
    );
  }

  // Mini componente para elegir colores sin necesidad de paquetes externos
  Widget _buildCustomColorPicker(
    String label,
    Color currentColor,
    Function(Color) onSelect,
  ) {
    List<Color> options = [
      Colors.black,
      const Color(0xFF1E1E1E),
      const Color(0xFF0D1B2A),
      const Color(0xFF5D4037),
      Colors.deepPurple.shade900,
      Colors.teal.shade900,
      const Color(0xFFF8BBD0),
      const Color(0xFFC8E6C9),
      const Color(0xFFFFF59D),
      Colors.white,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((color) {
              final isSelected = color == currentColor;
              return GestureDetector(
                onTap: () => onSelect(color),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.blueAccent
                          : Colors.grey.shade400,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
