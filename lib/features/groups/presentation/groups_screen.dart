// lib/features/groups/presentation/groups_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ¡Añadido!
import '../data/group_service.dart';
import '../domain/group_model.dart';
import '../../auth/data/auth_service.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../tasks/presentation/group_tasks_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

// Agregamos SingleTickerProviderStateMixin para poder usar animaciones
class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  final GroupService _groupService = GroupService();
  final AuthService _authService = AuthService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // --- VARIABLES DE ANIMACIÓN ---
  late AnimationController _bellController;
  late Animation<double> _bellAnimation;

  @override
  void initState() {
    super.initState();

    // Configuramos la animación (meneo de campana)
    _bellController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _bellAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: -0.2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.2, end: 0.0), weight: 1),
    ]).animate(_bellController);

    // Hacemos que la campana se mueva cada 5 segundos si el controlador está activo
    _startBellTimer();
  }

  void _startBellTimer() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        _bellController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _bellController.dispose();
    super.dispose();
  }

  // --- MÉTODOS DE DIÁLOGO ---
  void _showCreateGroupDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF7),
        title: const Text(
          'Crear nuevo grupo 🌱',
          style: TextStyle(color: Color(0xFF5D4037)),
        ),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nombre del grupo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _groupService.createGroup(
                  nameController.text.trim(),
                  currentUserId,
                );
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showJoinGroupDialog() {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF7),
        title: const Text(
          'Unirse a un grupo 🦋',
          style: TextStyle(color: Color(0xFF5D4037)),
        ),
        content: TextField(
          controller: codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Código de invitación'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isNotEmpty) {
                String message = await _groupService.joinGroup(
                  codeController.text.trim(),
                  currentUserId,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                }
              }
            },
            child: const Text('Unirme'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      appBar: AppBar(
        title: const Text(
          'Mis Grupos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // --- CAMPANITA ANIMADA CON CONTADOR ---
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId)
                .collection('notifications')
                .where(
                  'isRead',
                  isEqualTo: false,
                ) // Solo contamos las no leídas
                .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.docs.length ?? 0;
              final hasNotifications = unreadCount > 0;

              return RotationTransition(
                turns: hasNotifications
                    ? _bellAnimation
                    : const AlwaysStoppedAnimation(0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        hasNotifications
                            ? Icons.notifications_active
                            : Icons.notifications_none,
                        color: hasNotifications
                            ? const Color(0xFFF8BBD0)
                            : Colors.grey,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    if (hasNotifications)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF5D4037)),
            onPressed: () async => await _authService.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<GroupModel>>(
        stream: _groupService.getUserGroupsStream(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = snapshot.data ?? [];
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('lib/assets/images/empty_tasks.png', height: 150),
                  const SizedBox(height: 20),
                  const Text(
                    'No estás en ningún grupo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  Text(
                    'Crea uno o únete con un código 🌸',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFFFF59D), width: 2),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFC8E6C9),
                    child: Text(
                      group.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF5D4037),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    group.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  subtitle: Text('Código: ${group.inviteCode}'),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFFF8BBD0),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupTasksScreen(group: group),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "btn1",
            onPressed: _showJoinGroupDialog,
            backgroundColor: const Color(0xFFF8BBD0),
            icon: const Icon(Icons.group_add, color: Color(0xFF5D4037)),
            label: const Text(
              'Unirse',
              style: TextStyle(
                color: Color(0xFF5D4037),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: "btn2",
            onPressed: _showCreateGroupDialog,
            backgroundColor: const Color(0xFFFFF59D),
            icon: const Icon(Icons.add, color: Color(0xFF5D4037)),
            label: const Text(
              'Crear',
              style: TextStyle(
                color: Color(0xFF5D4037),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
