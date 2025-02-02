import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';

class ProductImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final bool isCompact;

  ProductImageCarousel({
    required this.imageUrls,
    this.isCompact = false,
  });

  @override
  _ProductImageCarouselState createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  bool _isVideoLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoController();
  }

  @override
  void dispose() {
    _disposeVideoController();
    super.dispose();
  }

  void _disposeVideoController() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
  }

  void _initializeVideoController() async {
    final isVideo = widget.imageUrls[_currentIndex].endsWith('.webm');

    if (isVideo) {
      _disposeVideoController();
      setState(() => _isVideoLoading = true);

      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.imageUrls[_currentIndex]),
      );

      try {
        await _videoController!.initialize();
        _videoController!.setLooping(true);
        _videoController!.play();
      } catch (e) {
        print("Ошибка загрузки видео: $e");
      }

      setState(() => _isVideoLoading = false);
    } else {
      _disposeVideoController();
    }
  }

void _openFullscreenViewer(int initialIndex) {
  if (widget.isCompact) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black.withOpacity(0.8),
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height, // 80% от высоты экрана
        child: PageView.builder(
          itemCount: widget.imageUrls.length,
          controller: PageController(initialPage: initialIndex),
          itemBuilder: (context, index) {
            return Center(
              child: InteractiveViewer(
                maxScale: 3.0,
                child: Image.network(
                  widget.imageUrls[index],
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CarouselSlider.builder(
          itemCount: widget.imageUrls.length,
          itemBuilder: (context, index, _) {
            final isVideo = widget.imageUrls[index].endsWith('.webm');

            return GestureDetector(
              onTap: () => _openFullscreenViewer(index),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: const Color(0xFFF6F5F3),
                  child: isVideo
                      ? (_videoController != null && _videoController!.value.isInitialized
                          ? AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            )
                          : _isVideoLoading
                              ? const Center(child: CircularProgressIndicator())
                              : const Center(child: Icon(Icons.error, color: Colors.red)))
                      : Image.network(
                          widget.imageUrls[index],
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: widget.isCompact ? MediaQuery.of(context).size.width * 9 / 16 : 550,
            viewportFraction: 1.0,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
              _initializeVideoController();
            },
          ),
        ),
        if (!widget.isCompact)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.imageUrls.asMap().entries.map((entry) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: _currentIndex == entry.key ? 12.0 : 8.0,
                  height: _currentIndex == entry.key ? 12.0 : 8.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == entry.key
                        ? const Color(0xFF333333)
                        : const Color(0xFFC7C7C7),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
