import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/core/config/supabase_config.dart';
import 'package:vodou/core/utils/app_logger.dart';
import 'package:uuid/uuid.dart';
import 'package:vodou/core/error/error_mapper.dart';

/// Service pour gérer l'upload de fichiers vers Supabase Storage
class FileUploadService {
  final SupabaseService _supabaseService;
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  FileUploadService(this._supabaseService);

  /// Largeur/hauteur maximale des images téléversées, en pixels.
  ///
  /// Sans cette borne, une photo 12 Mpx (~8 Mo) était envoyée telle quelle.
  static const int _maxImageDimension = 1920;

  /// Qualité de recompression JPEG appliquée à la sélection.
  static const int _imageQuality = 85;

  /// Extensions d'image acceptées au téléversement.
  static const Set<String> _allowedImageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
  };

  /// Sélectionner une image depuis la galerie
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: _maxImageDimension.toDouble(),
        maxHeight: _maxImageDimension.toDouble(),
        imageQuality: _imageQuality,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw ErrorMapper.map(e, StackTrace.current, 'la sélection de l\'image');
    }
  }

  /// Prendre une photo avec la caméra
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: _maxImageDimension.toDouble(),
        maxHeight: _maxImageDimension.toDouble(),
        imageQuality: _imageQuality,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      throw ErrorMapper.map(e, StackTrace.current, 'la prise de photo');
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
      throw ErrorMapper.map(e, StackTrace.current, 'la sélection du fichier');
    }
  }

  /// Upload un fichier vers Supabase Storage
  Future<String> uploadFile({
    required File file,
    required String bucket,
    String? folder,
  }) async {
    final String rawPath = file.path;
    final String cleanPath = rawPath.startsWith('file://')
        ? Uri.parse(rawPath).toFilePath()
        : rawPath;
    final File actualFile = File(cleanPath);

    if (!await actualFile.exists()) {
      throw Exception(
        'Le fichier image n\'existe pas sur l\'appareil ($cleanPath)',
      );
    }

    // Contrôle de taille : la constante maxUploadSizeMB était définie mais
    // jamais appliquée, et readAsBytes() charge tout le fichier en mémoire
    // (cf. AUDIT_SECURITE.md — VUL-09).
    const int maxBytes = SupabaseConfig.maxUploadSizeMB * 1024 * 1024;
    final int fileSize = await actualFile.length();
    if (fileSize > maxBytes) {
      throw Exception(
        'Fichier trop volumineux (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} Mo). '
        'La taille maximale autorisée est de ${SupabaseConfig.maxUploadSizeMB} Mo.',
      );
    }

    final String rawExtension = actualFile.path.split('.').last.toLowerCase();
    final String fileExtension = rawExtension.split('?').first;

    if (!_allowedImageExtensions.contains(fileExtension)) {
      throw Exception(
        'Format d\'image non pris en charge : .$fileExtension. '
        'Formats acceptés : ${_allowedImageExtensions.join(', ')}.',
      );
    }

    final String fileName = '${_uuid.v4()}.$fileExtension';
    final String filePath = folder != null ? '$folder/$fileName' : fileName;

    String contentType = 'image/jpeg';
    if (fileExtension == 'png') contentType = 'image/png';
    if (fileExtension == 'webp') contentType = 'image/webp';
    if (fileExtension == 'gif') contentType = 'image/gif';
    if (fileExtension == 'jpg') contentType = 'image/jpg';
    if (fileExtension == 'jpeg') contentType = 'image/jpeg';

    final bytes = await actualFile.readAsBytes();

    debugPrint(
      '🚀 Envoi vers Supabase Storage: bucket="$bucket", path="$filePath", size=${bytes.length} bytes',
    );

    // Le repli silencieux vers le bucket « logements » a été supprimé : une
    // photo de profil pouvait atterrir dans le mauvais bucket sans qu'aucune
    // alerte ne remonte (cf. AUDIT_SECURITE.md — VUL-09). Un échec d'upload
    // doit désormais remonter à l'appelant.
    try {
      await _supabaseService.client.storage
          .from(bucket)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
    } catch (storageErr) {
      AppLogger.e('Échec du téléversement', storageErr);
      throw Exception(
        'Le téléversement a échoué. Vérifiez votre connexion et réessayez.',
      );
    }

    // Récupérer l'URL publique
    final String publicUrl = _supabaseService.client.storage
        .from(bucket)
        .getPublicUrl(filePath);

    AppLogger.d('Fichier téléversé', {'bucket': bucket});
    return publicUrl;
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
      throw ErrorMapper.map(e, StackTrace.current, 'la suppression du fichier');
    }
  }

  /// Supprimer la photo de profil depuis son URL publique
  Future<void> deleteProfilePhoto(String photoUrl) async {
    if (photoUrl.isEmpty || !photoUrl.startsWith('http')) return;
    try {
      String bucket = SupabaseConfig.userPhotosBucket; // 'profils'
      String filePath = '';

      if (photoUrl.contains('/$bucket/')) {
        filePath = photoUrl.split('/$bucket/').last;
      } else if (photoUrl.contains('/logements/')) {
        bucket = 'logements';
        filePath = photoUrl.split('/logements/').last;
      } else {
        final uri = Uri.parse(photoUrl);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 2) {
          filePath = pathSegments.sublist(pathSegments.length - 2).join('/');
        }
      }

      if (filePath.isNotEmpty) {
        debugPrint(
          '🗑️ Suppression du fichier Supabase Storage: bucket="$bucket", path="$filePath"',
        );
        await _supabaseService.client.storage.from(bucket).remove([filePath]);
        debugPrint('✅ Fichier supprimé du Storage Supabase!');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur suppression Storage (non bloquant): $e');
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
