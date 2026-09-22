import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vodou/core/constants/app_colors.dart';

/// Widget universel et sécurisé pour afficher des images provenant de :
/// - HTTP / HTTPS (URLs distantes Supabase, Web)
/// - Fichiers locaux (/data/user/0/..., file://..., etc.)
/// - Assets (assets/...)
class AppImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;

  const AppImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final String? path = url?.trim();

    if (path == null || path.isEmpty) {
      return _buildErrorPlaceholder();
    }

    // 1. URL Web (http:// ou https://)
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
      );
    }

    // 2. Fichier local (/data/user/0/..., file://..., C:\...)
    String localPath = path;
    if (localPath.startsWith('file://')) {
      try {
        localPath = Uri.parse(localPath).toFilePath();
      } catch (_) {}
    }

    if (localPath.startsWith('/') || localPath.contains(':/') || localPath.contains(':\\')) {
      final file = File(localPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
        );
      }
    }

    // 3. Asset local (assets/...)
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
      );
    }

    // 4. Fallback si le format de chemin n'est pas reconnu
    return _buildErrorPlaceholder();
  }

  Widget _buildErrorPlaceholder() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: AppColors.greyLight,
          child: const Center(
            child: Icon(Icons.image, color: AppColors.grey),
          ),
        );
  }

  /// Helper pour obtenir un ImageProvider sécurisé (pour CircleAvatar, etc.)
  static ImageProvider provider(String? url, {String? defaultAsset}) {
    final String fallback = defaultAsset ?? 'assets/images/placeholder.png';

    if (url == null || url.trim().isEmpty) {
      return AssetImage(fallback);
    }
    final path = url.trim();
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    String localPath = path;
    if (localPath.startsWith('file://')) {
      try {
        localPath = Uri.parse(localPath).toFilePath();
      } catch (_) {}
    }
    if (localPath.startsWith('/') || localPath.contains(':/') || localPath.contains(':\\')) {
      final file = File(localPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }
    return AssetImage(fallback);
  }
}
