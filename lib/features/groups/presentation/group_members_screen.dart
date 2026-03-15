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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.edit_note, color: colorScheme.secondary),
                title: const Text('Hacer Administrador (Puede crear tareas)'),
                trailing: currentRole == 'admin'
                    ? Icon(Icons.check, color: colorScheme.tertiary)
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
                leading: Icon(
                  Icons.visibility,
                  color: colorScheme.secondaryContainer,
                ),
                title: const Text('Hacer Miembro (Solo ver y completar)'),
                trailing: currentRole == 'member'
                    ? Icon(Icons.check, color: colorScheme.tertiary)
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
              Divider(color: theme.dividerColor),
              ListTile(
                leading: Icon(Icons.person_remove, color: colorScheme.error),
                title: Text(
                  'Expulsar del grupo',
                  style: TextStyle(color: colorScheme.error),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que la ventana sea más alta
      backgroundColor: theme.scaffoldBackgroundColor,
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
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
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
                          return Center(
                            child: CircularProgressIndicator(
                              color: theme.primaryColor,
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
                            Text(
                              'Pendientes ⏳',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (pendingTasks.isEmpty)
                              Text(
                                '¡No debe nada, está al día! 🌟',
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ...pendingTasks
                                .map(
                                  (t) => ListTile(
                                    leading: Icon(
                                      Icons.circle_outlined,
                                      color: colorScheme.error,
                                    ),
                                    title: Text(
                                      t['title'] ?? 'Tarea',
                                      style: TextStyle(
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),

                            Divider(
                              height: 32,
                              thickness: 2,
                              color: theme.dividerColor,
                            ),

                            // SECCIÓN DE TERMINADAS
                            Text(
                              'Terminadas ✅',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.tertiary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (completedTasks.isEmpty)
                              Text(
                                'Aún no ha terminado nada... 🐢',
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ...completedTasks
                                .map(
                                  (t) => ListTile(
                                    leading: Icon(
                                      Icons.check_circle,
                                      color: colorScheme.tertiary,
                                    ),
                                    title: Text(
                                      t['title'] ?? 'Tarea',
                                      style: TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color:
                                            theme.textTheme.bodyMedium?.color,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Participantes 🌸',
          style: TextStyle(
            color: theme.appBarTheme.titleTextStyle?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryColor),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                final memberUid = member['uid'];
                final role = widget.group.roles[memberUid] ?? 'member';

                Color roleColor = theme.dividerColor;
                String roleName = 'Miembro (Solo ver)';
                if (role == 'host') {
                  roleColor = colorScheme.secondary;
                  roleName = 'Host (Dueño)';
                }
                if (role == 'admin') {
                  roleColor = colorScheme.secondaryContainer;
                  roleName = 'Administrador';
                }

                return Card(
                  elevation: 0,
                  color: theme.cardColor,
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
                      backgroundColor: colorScheme.secondaryContainer,
                      child: Text(
                        member['username'][0].toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      member['username'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    subtitle: Text(
                      roleName,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),

                    // Si YO soy el host y NO soy yo mismo, muestro la tuerca de ajustes de rol
                    trailing: (amIHost && memberUid != currentUserId)
                        ? IconButton(
                            icon: Icon(
                              Icons.settings,
                              color: theme.primaryColor,
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
