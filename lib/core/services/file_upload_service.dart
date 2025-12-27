import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

/// Service pour gérer l'upload de fichiers vers Supabase Storage
class FileUploadService {
  final SupabaseService _supabaseService;
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  FileUploadService(this._supabaseService);

  /// Sélectionner une image depuis la galerie
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la sélection de l\'image: $e');
    }
  }

  /// Prendre une photo avec la caméra
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la prise de photo: $e');
    }
  }

  /// Sélectionner un fichier (document)
  Future<File?> pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la sélection du fichier: $e');
    }
  }

  /// Upload un fichier vers Supabase Storage
  /// Retourne l'URL publique du fichier uploadé
  Future<String> uploadFile({
    required File file,
    required String bucket,
    String? folder,
  }) async {
    try {
      // Générer un nom de fichier unique
      final String fileExtension = file.path.split('.').last;
      final String fileName = '${_uuid.v4()}.$fileExtension';
      final String filePath = folder != null ? '$folder/$fileName' : fileName;

      // Upload vers Supabase Storage
      await _supabaseService.client.storage.from(bucket).upload(filePath, file);

      // Récupérer l'URL publique
      final String publicUrl = _supabaseService.client.storage
          .from(bucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Erreur lors de l\'upload du fichier: $e');
    }
  }

  /// Upload une image de message
  Future<String> uploadMessageAttachment(File file, int conversationId) async {
    return uploadFile(
      file: file,
      bucket: 'message-attachments',
      folder: 'conversation_$conversationId',
    );
  }

  /// Supprimer un fichier de Supabase Storage
  Future<void> deleteFile({
    required String bucket,
    required String filePath,
  }) async {
    try {
      await _supabaseService.client.storage.from(bucket).remove([filePath]);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du fichier: $e');
    }
  }

  /// Obtenir la taille d'un fichier en format lisible
  String getFileSize(File file) {
    final int bytes = file.lengthSync();
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Vérifier si un fichier est une image
  bool isImage(String filePath) {
    final String extension = filePath.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }

  /// Obtenir le type de fichier
  String getFileType(String filePath) {
    final String extension = filePath.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension)) {
      return 'image';
    } else if (['pdf'].contains(extension)) {
      return 'pdf';
    } else if (['doc', 'docx'].contains(extension)) {
      return 'document';
    } else if (['xls', 'xlsx'].contains(extension)) {
      return 'spreadsheet';
    } else if (['txt'].contains(extension)) {
      return 'text';
    } else {
      return 'file';
    }
  }
}
