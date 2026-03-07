// lib/features/groups/presentation/group_members_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
                  _loadMembers(); // Recargamos la lista
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

  @override
  Widget build(BuildContext context) {
    // Verificamos si TÚ eres el host para darte permisos de editar
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

                // Colores de los roles para que se vea lindo
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

                    // Si YO soy el host y NO soy yo mismo el de la tarjeta, muestro el botón de ajustes
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
