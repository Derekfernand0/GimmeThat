// lib/features/groups/domain/group_model.dart

class GroupModel {
  final String id;
  final String name;
  final String inviteCode;
  final List<String> members; // Lista de UIDs de los usuarios
  final Map<String, dynamic> roles; // Ejemplo: {'uid_del_usuario': 'host'}

  GroupModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.members,
    required this.roles,
  });

  // Convierte los datos de Firebase a nuestro Objeto
  factory GroupModel.fromMap(Map<String, dynamic> map, String documentId) {
    return GroupModel(
      id: documentId,
      name: map['name'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
      // Convertimos las listas dinámicas de Firebase a Listas de texto (Strings)
      members: List<String>.from(map['members'] ?? []),
      roles: Map<String, dynamic>.from(map['roles'] ?? {}),
    );
  }

  // Empaqueta nuestro Objeto para guardarlo en Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'inviteCode': inviteCode,
      'members': members,
      'roles': roles,
    };
  }
}
