// lib/features/groups/presentation/groups_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/group_service.dart';
import '../domain/group_model.dart';
import '../../auth/data/auth_service.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../tasks/presentation/group_tasks_screen.dart';
import '../../notifications/presentation/notification_settings_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  final GroupService _groupService = GroupService();
  final AuthService _authService = AuthService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  late AnimationController _bellController;
  late Animation<double> _bellAnimation;

  // --- NUEVO: LISTA DE GRUPOS SILENCIADOS ---
  List<String> _mutedGroups = [];

  @override
  void initState() {
    super.initState();

    // Escuchamos tu perfil para saber qué grupos tienes silenciados
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .listen((doc) {
          if (doc.exists && mounted) {
            setState(() {
              _mutedGroups = List<String>.from(
                doc.data()?['mutedGroups'] ?? [],
              );
            });
          }
        });

    _bellController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bellAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: -0.2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.2, end: 0.0), weight: 1),
    ]).animate(_bellController);

    _startBellTimer();
  }

  void _startBellTimer() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) _bellController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _bellController.dispose();
    super.dispose();
  }

  // --- NUEVO: FUNCIÓN PARA SILENCIAR/ACTIVAR GRUPO ---
  Future<void> _toggleMuteGroup(String groupId) async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId);

    if (_mutedGroups.contains(groupId)) {
      await userRef.update({
        'mutedGroups': FieldValue.arrayRemove([groupId]),
      });
    } else {
      await userRef.update({
        'mutedGroups': FieldValue.arrayUnion([groupId]),
      });
    }
  }

  void _showGroupOptions(GroupModel group, String myRole) {
    final isMuted = _mutedGroups.contains(group.id);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Opciones de ${group.name} ⚙️',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),

              // BOTÓN 1: SILENCIAR GRUPO 🤫
              ListTile(
                leading: Icon(
                  isMuted
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  color: isMuted ? const Color(0xFFF8BBD0) : Colors.grey,
                ),
                title: Text(
                  isMuted ? 'Activar notificaciones' : 'Silenciar grupo',
                ),
                subtitle: Text(
                  isMuted
                      ? 'Volverás a recibir alertas.'
                      : 'No recibirás alertas de esta sala.',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleMuteGroup(group.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isMuted
                            ? 'Notificaciones activadas 🔔'
                            : 'Grupo silenciado 🤫',
                      ),
                    ),
                  );
                },
              ),

              const Divider(),

              // BOTÓN 2: SALIR DEL GRUPO 👋
              if (myRole != 'host')
                ListTile(
                  leading: const Icon(
                    Icons.exit_to_app,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Salir del grupo',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('¿Salir de la sala? 👋'),
                        content: Text(
                          'Ya no tendrás acceso a las tareas de ${group.name}.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Me quedo'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'Sí, salir',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true)
                      await _groupService.removeMember(group.id, currentUserId);
                  },
                ),

              if (myRole == 'host')
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Eres el dueño de la sala. Para salir, debes eliminarla desde adentro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Mis Grupos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId)
                .collection('notifications')
                .where('isRead', isEqualTo: false)
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
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      ),
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
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationSettingsScreen(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: theme.primaryColor),
            onPressed: () async => await _authService.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<GroupModel>>(
        stream: _groupService.getUserGroupsStream(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final groups = snapshot.data ?? [];
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('lib/assets/images/empty_tasks.png', height: 150),
                  const SizedBox(height: 20),
                  Text(
                    'No estás en ningún grupo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
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
              final isMuted = _mutedGroups.contains(
                group.id,
              ); // Verificamos si está silenciado

              return Card(
                elevation: 0,
                color: theme.cardColor,
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
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        group.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: theme.primaryColor,
                        ),
                      ),
                      // ¡SI ESTÁ SILENCIADO LE PONEMOS EL ICONITO AL LADO DEL NOMBRE! 🔇
                      if (isMuted) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.notifications_off,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text('Código: ${group.inviteCode}'),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFFF8BBD0),
                  ),
                  onLongPress: () {
                    final myRole = group.roles[currentUserId] ?? 'member';
                    _showGroupOptions(group, myRole);
                  },
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
            icon: Icon(Icons.group_add, color: theme.primaryColor),
            label: Text(
              'Unirse',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: "btn2",
            onPressed: _showCreateGroupDialog,
            backgroundColor: const Color(0xFFFFF59D),
            icon: Icon(Icons.add, color: theme.primaryColor),
            label: Text(
              'Crear',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
