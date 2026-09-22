import 'package:flutter/material.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/widgets/app_image.dart';
import 'package:vodou/features/home/domain/models/photo.dart';

/// Carrousel de photos pour la page de détails
class PhotoCarousel extends StatefulWidget {
  final List<Photo> photos;

  const PhotoCarousel({super.key, required this.photos});

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return _buildPlaceholder();
    }

    return Stack(
      children: [
        // PageView des photos
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemCount: widget.photos.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _showFullScreenGallery(context, index),
              child: AppImage(
                url: widget.photos[index].url,
                fit: BoxFit.cover,
                errorWidget: _buildPlaceholder(),
              ),
            );
          },
        ),

        // Indicateur de position
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentIndex + 1} / ${widget.photos.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // Bouton / Badge compact "Photos"
        Positioned(
          bottom: 16,
          left: 16,
          child: InkWell(
            onTap: () => _showFullScreenGallery(context, _currentIndex),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Photos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.greyLight,
      child: const Center(
        child: Icon(Icons.image, size: 80, color: AppColors.grey),
      ),
    );
  }

  void _showFullScreenGallery(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenGallery(
          photos: widget.photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

/// Galerie plein écran
class _FullScreenGallery extends StatefulWidget {
  final List<Photo> photos;
  final int initialIndex;

  const _FullScreenGallery({required this.photos, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '${_currentIndex + 1} / ${widget.photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.photos.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: AppImage(
                url: widget.photos[index].url,
                fit: BoxFit.contain,
                errorWidget: const Icon(
                  Icons.broken_image,
                  size: 80,
                  color: Colors.white54,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
