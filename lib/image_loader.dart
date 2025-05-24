import 'package:flutter/material.dart';

class ImageLoader {
  Widget loadNetworkImage(
    String url, {
    BoxFit fit = BoxFit.cover,
    Widget? loadingWidget,
  }) {
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        return progress == null
            ? child
            : (loadingWidget ?? const Center(child: CircularProgressIndicator()));
      },
    );
  }
}
