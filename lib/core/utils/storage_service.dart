// lib/core/utils/storage_service.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> _deleteFolderContents(Reference ref) async {
    final result = await ref.listAll();

    for (final item in result.items) {
      await item.delete();
    }

    for (final prefix in result.prefixes) {
      await _deleteFolderContents(prefix);
    }
  }

  // Función para subir una imagen OPTIMIZADA y obtener su URL (Link)
  Future<String?> uploadTaskImage(String taskId, File imageFile) async {
    try {
      // 1. Preparamos el directorio temporal del celular para trabajar la compresión
      final tempDir = await getTemporaryDirectory();

      // Creamos un nombre único, pero ahora con extensión .webp para máxima eficiencia
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.webp';
      String targetPath = '${tempDir.path}/$fileName';

      // 2. LA MAGIA DE LA COMPRESIÓN 🦋
      // Reducimos el peso drásticamente manteniendo una excelente calidad
      final XFile?
      compressedXFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality:
            75, // Calidad del 75% es el balance perfecto entre peso y nitidez
        format: CompressFormat.webp, // Convertimos a WebP
        minWidth: 1200, // Evitamos que fotos de 4K saturen el servidor
        minHeight: 1200,
      );

      if (compressedXFile == null) {
        print('Error al comprimir la imagen');
        return null;
      }

      File fileToUpload = File(compressedXFile.path);

      // 3. Creamos la "ruta" en Firebase Storage: task_images -> ID_de_tarea -> nombre_foto.webp
      Reference ref = _storage
          .ref()
          .child('task_images')
          .child(taskId)
          .child(fileName);

      // 4. Subimos el archivo COMPRIMIDO
      UploadTask uploadTask = ref.putFile(fileToUpload);
      TaskSnapshot snapshot = await uploadTask;

      // 5. Pedimos el link público para poder mostrarla en la app
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 6. Limpieza: Borramos el archivo temporal para no llenar el celular del usuario
      if (await fileToUpload.exists()) {
        await fileToUpload.delete();
      }

      return downloadUrl;
    } catch (e) {
      print('Error al subir la imagen: $e');
      return null;
    }
  }

  Future<void> deleteTaskImages(String taskId) async {
    try {
      final taskImagesRef = _storage.ref().child('task_images').child(taskId);
      await _deleteFolderContents(taskImagesRef);
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        rethrow;
      }
    }
  }

  Future<void> deleteImageByUrl(String imageUrl) async {
    try {
      final imageRef = _storage.refFromURL(imageUrl);
      await imageRef.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        rethrow;
      }
    }
  }
}
