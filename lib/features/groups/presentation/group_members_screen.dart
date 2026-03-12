// lib/features/groups/presentation/group_members_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ¡NUEVO IMPORT para leer las tareas!
import '../domain/group_model.dart';
import '../data/group_service.dart';

class GroupMembersScreen extends StatefulWidget {
  final GroupModel group;

  const GroupMembersScreen({super.key, required this.group});

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  final GroupService _groupService = GroupService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  // Cargamos los nombres de los usuarios
  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    final data = await _groupService.getGroupMembersDetails(
      widget.group.members,
    );
    setState(() {
      _members = data;
      _isLoading = false;
    });
  }

  // Cuadro de diálogo para que el Host cambie el rol
  void _showRoleOptions(String targetUid, String currentRole, String username) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFDF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gestionar a $username 🦋',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit_note, color: Color(0xFFF8BBD0)),
                title: const Text('Hacer Administrador (Puede crear tareas)'),
                trailing: currentRole == 'admin'
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  Navigator.pop(context);
                  await _groupService.changeUserRole(
                    widget.group.id,
                    targetUid,
                    'admin',
                  );
                  _loadMembers();
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility, color: Color(0xFFFFF59D)),
                title: const Text('Hacer Miembro (Solo ver y completar)'),
                trailing: currentRole == 'member'
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  Navigator.pop(context);
                  await _groupService.changeUserRole(
                    widget.group.id,
                    targetUid,
                    'member',
                  );
                  _loadMembers();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.person_remove,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Expulsar del grupo',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _groupService.removeMember(widget.group.id, targetUid);
                  _loadMembers();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- ¡NUEVA FUNCIÓN! Muestra las tareas pendientes y terminadas del usuario ---
  void _showMemberTasksSummary(String memberUid, String username) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que la ventana sea más alta
      backgroundColor: const Color(0xFFFFFDF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6, // Empieza a mitad de pantalla
          maxChildSize: 0.9, // Puede subir casi hasta arriba
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    'Tareas de $username 📋',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Escuchamos las tareas de este grupo en tiempo real
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      // ✅ Buscamos en la colección principal de tareas las que pertenezcan a este grupo
                      stream: FirebaseFirestore.instance
                          .collection('tasks')
                          .where('groupId', isEqualTo: widget.group.id)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.brown,
                            ),
                          );
                        }

                        final tasks = snapshot.data!.docs;

                        // Clasificamos las tareas en Pendientes y Terminadas para ESTE usuario
                        final completedTasks = [];
                        final pendingTasks = [];

                        for (var doc in tasks) {
                          final data = doc.data() as Map<String, dynamic>;
                          final List<dynamic> completedBy =
                              data['completedBy'] ?? [];

                          if (completedBy.contains(memberUid)) {
                            completedTasks.add(data);
                          } else {
                            pendingTasks.add(data);
                          }
                        }

                        return ListView(
                          controller: scrollController,
                          children: [
                            // SECCIÓN DE PENDIENTES
                            const Text(
                              'Pendientes ⏳',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (pendingTasks.isEmpty)
                              const Text(
                                '¡No debe nada, está al día! 🌟',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ...pendingTasks
                                .map(
                                  (t) => ListTile(
                                    leading: const Icon(
                                      Icons.circle_outlined,
                                      color: Colors.redAccent,
                                    ),
                                    title: Text(t['title'] ?? 'Tarea'),
                                  ),
                                )
                                .toList(),

                            const Divider(height: 32, thickness: 2),

                            // SECCIÓN DE TERMINADAS
                            const Text(
                              'Terminadas ✅',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (completedTasks.isEmpty)
                              const Text(
                                'Aún no ha terminado nada... 🐢',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ...completedTasks
                                .map(
                                  (t) => ListTile(
                                    leading: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    title: Text(
                                      t['title'] ?? 'Tarea',
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final myRole = widget.group.roles[currentUserId] ?? 'member';
    final amIHost = myRole == 'host';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      appBar: AppBar(
        title: const Text(
          'Participantes 🌸',
          style: TextStyle(
            color: Color(0xFF5D4037),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5D4037)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.brown))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                final memberUid = member['uid'];
                final role = widget.group.roles[memberUid] ?? 'member';

                Color roleColor = Colors.grey.shade300;
                String roleName = 'Miembro (Solo ver)';
                if (role == 'host') {
                  roleColor = const Color(0xFFF8BBD0);
                  roleName = 'Host (Dueño)';
                }
                if (role == 'admin') {
                  roleColor = const Color(0xFFFFF59D);
                  roleName = 'Administrador';
                }

                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: roleColor, width: 2),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    // Al tocar toda la tarjeta de la persona, vemos sus tareas
                    onTap: () =>
                        _showMemberTasksSummary(memberUid, member['username']),

                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFC8E6C9),
                      child: Text(
                        member['username'][0].toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF5D4037),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      member['username'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                    subtitle: Text(
                      roleName,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),

                    // Si YO soy el host y NO soy yo mismo, muestro la tuerca de ajustes de rol
                    trailing: (amIHost && memberUid != currentUserId)
                        ? IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: Color(0xFF5D4037),
                            ),
                            onPressed: () => _showRoleOptions(
                              memberUid,
                              role,
                              member['username'],
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
