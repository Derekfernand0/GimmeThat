// lib/features/groups/data/group_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../domain/group_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Generar un código aleatorio de 5 caracteres (Ej. A7K29)
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        5,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // 2. Crear un grupo nuevo
  Future<void> createGroup(String groupName, String creatorUid) async {
    String inviteCode = _generateInviteCode();

    // Verificamos que el código no exista ya (muy raro, pero buena práctica)
    final existing = await _firestore
        .collection('groups')
        .where('inviteCode', isEqualTo: inviteCode)
        .get();
    if (existing.docs.isNotEmpty) {
      inviteCode =
          _generateInviteCode(); // Generamos otro si por casualidad se repite
    }

    // Creamos el grupo en Firestore
    await _firestore.collection('groups').add({
      'name': groupName,
      'inviteCode': inviteCode,
      'members': [creatorUid], // El creador es el primer miembro
      'roles': {creatorUid: 'host'}, // Le damos el rol de "host" (dueño)
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 3. Unirse a un grupo usando el código
  Future<String> joinGroup(String inviteCode, String userUid) async {
    try {
      // Buscamos el grupo que tenga ese código
      final querySnapshot = await _firestore
          .collection('groups')
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
          .get();

      if (querySnapshot.docs.isEmpty) {
        return "Código de invitación no válido 😔";
      }

      final groupDoc = querySnapshot.docs.first;
      final groupData = groupDoc.data();
      List<dynamic> members = groupData['members'] ?? [];

      // Revisamos si el usuario ya está en el grupo
      if (members.contains(userUid)) {
        return "Ya eres miembro de este grupo 🌸";
      }

      // Si no está, lo agregamos como "miembro" normal
      await groupDoc.reference.update({
        'members': FieldValue.arrayUnion([userUid]),
        'roles.$userUid':
            'member', // Esto actualiza el mapa de roles agregando al nuevo usuario
      });

      return "¡Te has unido al grupo con éxito! 🦋";
    } catch (e) {
      return "Hubo un error al unirse: $e";
    }
  }

  // 4. Escuchar los grupos del usuario en Tiempo Real
  Stream<List<GroupModel>> getUserGroupsStream(String userUid) {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: userUid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => GroupModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // 5. NUEVO: Obtener los perfiles (nombres) de los miembros del grupo
  Future<List<Map<String, dynamic>>> getGroupMembersDetails(
    List<String> memberUids,
  ) async {
    List<Map<String, dynamic>> membersData = [];
    // Buscamos el perfil de cada usuario en la base de datos
    for (String uid in memberUids) {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        membersData.add({'uid': uid, ...doc.data()!});
      }
    }
    return membersData;
  }

  // 6. NUEVO: Cambiar el rol de un usuario
  Future<void> changeUserRole(
    String groupId,
    String targetUid,
    String newRole,
  ) async {
    await _firestore.collection('groups').doc(groupId).update({
      'roles.$targetUid':
          newRole, // Esto actualiza solo el rol de ese usuario en el mapa
    });
  }

  // 7. NUEVO: Expulsar a un miembro
  Future<void> removeMember(String groupId, String targetUid) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([targetUid]), // Lo sacamos de la lista
      'roles.$targetUid': FieldValue.delete(), // Borramos su rol
    });
  }

  // 8. BORRAR SALA (Solo para el Host)
  Future<void> deleteGroup(String groupId) async {
    // a. Primero buscamos todas las tareas que pertenecen a esta sala
    final tasksQuery = await _firestore
        .collection('tasks')
        .where('groupId', isEqualTo: groupId)
        .get();

    // b. Borramos cada tarea encontrada
    for (var doc in tasksQuery.docs) {
      await doc.reference.delete();
    }

    // c. Finalmente borramos el documento de la sala
    await _firestore.collection('groups').doc(groupId).delete();
  }
}
