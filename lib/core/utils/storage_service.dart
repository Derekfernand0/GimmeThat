// lib/core/utils/storage_service.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

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

  // Sube una imagen recibiendo directamente el XFile (compatible con Web y Móvil)
  Future<String?> uploadTaskImageXFile(String taskId, XFile imageFile) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage
          .ref()
          .child('task_images')
          .child(taskId)
          .child(fileName);

      // Leemos los bytes directamente (funciona en Web, Android e iOS)
      final Uint8List fileBytes = await imageFile.readAsBytes();

      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      final UploadTask uploadTask = ref.putData(fileBytes, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error al subir la imagen: $e');
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
