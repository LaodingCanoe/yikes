import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';

class ProductImageCarousel extends StatefulWidget {
  final List<String> imageUrls;

  ProductImageCarousel({required this.imageUrls});

  @override
  _ProductImageCarouselState createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  int _currentIndex = 0;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _initializeVideoController();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

void _initializeVideoController() {
  if (widget.imageUrls.isNotEmpty &&
      widget.imageUrls[_currentIndex].endsWith('.webm')) {
    _videoController?.dispose(); // Dispose previous controller
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(widget.imageUrls[_currentIndex]))
          ..initialize().then((_) {
            setState(() {}); // Rebuild when video is ready
            _videoController?.play();
          });
  }
}


  @override
  Widget build(BuildContext context) {
    final double imageSize = MediaQuery.of(context).size.width * 0.6;

    return Stack(
      children: [
        CarouselSlider.builder(
          itemCount: widget.imageUrls.length,
          itemBuilder: (context, index, _) {
            final isVideo = widget.imageUrls[index].endsWith('.webm');
            return Container(
              width: imageSize,
              height: imageSize,
              color: const Color(0xFFF6F5F3),
              alignment: Alignment.center,
              child: isVideo
                  ? (_videoController != null &&
                          _videoController!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        )
                      : const CircularProgressIndicator())
                  : Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.contain,
                      width: imageSize,
                      height: imageSize,
                    ),
            );
          },
          options: CarouselOptions(
            height: imageSize,
            viewportFraction: 1.0,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
              _initializeVideoController();
            },
          ),
        ),
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.imageUrls.map((url) {
              final index = widget.imageUrls.indexOf(url);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                width: _currentIndex == index ? 12.0 : 8.0,
                height: _currentIndex == index ? 12.0 : 8.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index
                      ? Color(0xFF333333)
                      : Color(0xFFC7C7C7),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
