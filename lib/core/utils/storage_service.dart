// lib/core/utils/storage_service.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Función para subir una imagen y obtener su URL (Link)
  Future<String?> uploadTaskImage(String taskId, File imageFile) async {
    try {
      // 1. Inventamos un nombre único para la foto usando la fecha y hora actual
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 2. Creamos la "ruta" (carpeta) en Firebase Storage: task_images -> ID_de_tarea -> nombre_foto.jpg
      Reference ref = _storage
          .ref()
          .child('task_images')
          .child(taskId)
          .child(fileName);

      // 3. Subimos el archivo
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // 4. Pedimos el link público para poder mostrarla en la app
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error al subir la imagen: $e');
      return null;
    }
  }
}
