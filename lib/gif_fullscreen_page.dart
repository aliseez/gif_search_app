import 'package:flutter/material.dart';
import 'image_loader.dart';
class GifFullscreenPage extends StatelessWidget {
  final String gifUrl;
  final Widget? imageWidget;

  const GifFullscreenPage({super.key, required this.gifUrl, this.imageWidget,});

  @override
  Widget build(BuildContext context) {
    final imageLoader = ImageLoader();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: imageLoader.loadNetworkImage(
            gifUrl,
            fit: BoxFit.contain,
            loadingWidget: const CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
