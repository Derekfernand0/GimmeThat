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
}
