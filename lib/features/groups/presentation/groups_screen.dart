// lib/features/groups/presentation/groups_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/group_service.dart';
import '../domain/group_model.dart';
import '../../auth/data/auth_service.dart';
import '../../tasks/presentation/group_tasks_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final GroupService _groupService = GroupService();
  final AuthService _authService = AuthService();

  // Obtenemos el ID del usuario actual que tiene la sesión iniciada
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Función para mostrar el cuadrito emergente (Dialog) para CREAR grupo
  void _showCreateGroupDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF7), // Crema pastel
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

  // Función para mostrar el cuadrito emergente para UNIRSE a un grupo
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
          textCapitalization:
              TextCapitalization.characters, // Fuerza mayúsculas
          decoration: const InputDecoration(
            labelText: 'Código de invitación (Ej. A7K29)',
          ),
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
          // ¡LA NUEVA CAMPANITA! 🔔
          IconButton(
            icon: const Icon(
              Icons.notifications_active,
              color: Color(0xFFF8BBD0),
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
          // Botón de cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF5D4037)),
            onPressed: () async => await _authService.signOut(),
          ),
        ],
      ),
      // StreamBuilder escucha la base de datos en tiempo real.
      // ¡Si alguien se une o crea un grupo, la pantalla se actualiza sola!
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
                  const Icon(
                    Icons.group_outlined,
                    size: 80,
                    color: Color(0xFFF8BBD0),
                  ),
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
              final miRol = group.roles[currentUserId] ?? 'member';

              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(
                    color: Color(0xFFFFF59D),
                    width: 2,
                  ), // Borde amarillo pastel
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFC8E6C9), // Verde suave
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
                  subtitle: Text('Código: ${group.inviteCode} • Rol: $miRol'),
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
      // Botones flotantes
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "btn1",
            onPressed: _showJoinGroupDialog,
            backgroundColor: const Color(0xFFF8BBD0), // Rosa suave
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
            backgroundColor: const Color(0xFFFFF59D), // Amarillo pastel
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
