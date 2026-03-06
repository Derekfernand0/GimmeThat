// lib/features/auth/domain/user_model.dart

class UserModel {
  final String uid;
  final String email;
  final String username;

  // Constructor: pide estos datos obligatoriamente para crear un "UserModel"
  UserModel({required this.uid, required this.email, required this.username});

  // Esta función convierte los datos "sueltos" que vienen de Firebase en un objeto ordenado
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      username: map['username'] ?? '',
    );
  }

  // Esta función hace lo opuesto: empaqueta nuestro objeto para enviarlo y guardarlo en Firebase
  Map<String, dynamic> toMap() {
    return {'email': email, 'username': username};
  }
}
