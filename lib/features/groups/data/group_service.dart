// lib/features/groups/data/group_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../domain/group_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Generar un código aleatorio de 5 caracteres
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

    final existing = await _firestore
        .collection('groups')
        .where('inviteCode', isEqualTo: inviteCode)
        .get();
    if (existing.docs.isNotEmpty) {
      inviteCode = _generateInviteCode();
    }

    await _firestore.collection('groups').add({
      'name': groupName,
      'inviteCode': inviteCode,
      'members': [creatorUid],
      'roles': {creatorUid: 'host'},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 3. Unirse a un grupo usando el código (¡CON NOTIFICACIONES! 🔔)
  Future<String> joinGroup(String inviteCode, String userUid) async {
    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
          .get();

      if (querySnapshot.docs.isEmpty) {
        return "Código de invitación no válido 😔";
      }

      final groupDoc = querySnapshot.docs.first;
      final groupData = groupDoc.data();
      final List<String> members = List<String>.from(
        groupData['members'] ?? [],
      );

      if (members.contains(userUid)) {
        return "Ya eres miembro de este grupo 🌸";
      }

      // Lo agregamos a la base de datos
      await groupDoc.reference.update({
        'members': FieldValue.arrayUnion([userUid]),
        'roles.$userUid': 'member',
      });

      // --- ¡NUEVA MAGIA! 🦋 Notificar a los miembros anteriores ---
      try {
        // Obtenemos el nombre del usuario nuevo
        final userDoc = await _firestore.collection('users').doc(userUid).get();
        final newUserName = userDoc.data()?['username'] ?? 'Alguien nuevo';
        final groupName = groupData['name'] ?? 'el grupo';

        // Le mandamos la alerta a cada miembro que YA estaba en el grupo
        for (String memberId in members) {
          await _firestore
              .collection('users')
              .doc(memberId)
              .collection('notifications')
              .add({
                'type': 'newMember',
                'title': '¡Nuevo integrante en $groupName! 👋',
                'message': '$newUserName se ha unido a la sala.',
                'groupId': groupDoc.id,
                'groupName': groupName,
                'createdAt': FieldValue.serverTimestamp(),
                'isRead': false,
                // Ponemos taskId en null porque esta alerta no pertenece a una tarea específica
                'taskId': null,
              });
        }
      } catch (e) {
        print("Error al enviar notificación de nuevo miembro: $e");
      }
      // -------------------------------------------------------------

      return "¡Te has unido al grupo con éxito! 🦋";
    } catch (e) {
      return "Hubo un error al unirse: $e";
    }
  }

  // 4. Escuchar los grupos del usuario
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

  // 5. Obtener los perfiles (nombres) de los miembros
  Future<List<Map<String, dynamic>>> getGroupMembersDetails(
    List<String> memberUids,
  ) async {
    List<Map<String, dynamic>> membersData = [];
    for (String uid in memberUids) {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        membersData.add({'uid': uid, ...doc.data()!});
      }
    }
    return membersData;
  }

  // 6. Cambiar el rol
  Future<void> changeUserRole(
    String groupId,
    String targetUid,
    String newRole,
  ) async {
    await _firestore.collection('groups').doc(groupId).update({
      'roles.$targetUid': newRole,
    });
  }

  // 7. Expulsar a un miembro
  Future<void> removeMember(String groupId, String targetUid) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([targetUid]),
      'roles.$targetUid': FieldValue.delete(),
    });
  }

  // 8. BORRAR SALA
  Future<void> deleteGroup(String groupId) async {
    final tasksQuery = await _firestore
        .collection('tasks')
        .where('groupId', isEqualTo: groupId)
        .get();

    for (var doc in tasksQuery.docs) {
      await doc.reference.delete();
    }

    await _firestore.collection('groups').doc(groupId).delete();
  }
}
