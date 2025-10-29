import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'
    show CachedNetworkImage;

/// A widget that optimizes image loading and caching
class OptimizedImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget Function(BuildContext, String)? errorBuilder;
  final Widget Function(BuildContext, String)? loadingBuilder;
  final int? cacheWidth;
  final int? cacheHeight;

  const OptimizedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit,
    this.errorBuilder,
    this.loadingBuilder,
    this.cacheWidth,
    this.cacheHeight,
  });

  String get _optimizedUrl {
    if (!url.startsWith('http')) return url;

    final Uri uri = Uri.parse(url);
    final Map<String, String> queryParams = Map.from(uri.queryParameters);

    // Add width and height if provided
    if (cacheWidth != null) queryParams['w'] = cacheWidth.toString();
    if (cacheHeight != null) queryParams['h'] = cacheHeight.toString();

    // Add quality parameter if not present
    if (!queryParams.containsKey('q')) queryParams['q'] = '80';

    // Add format parameter if not present
    if (!queryParams.containsKey('fm')) queryParams['fm'] = 'webp';

    return uri.replace(queryParameters: queryParams).toString();
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: _optimizedUrl,
      width: width,
      height: height,
      fit: fit,
      errorWidget: (context, url, error) =>
          errorBuilder?.call(context, url) ??
          const Center(child: Icon(Icons.error_outline)),
      progressIndicatorBuilder: (context, url, progress) =>
          loadingBuilder?.call(context, url) ??
          Center(child: CircularProgressIndicator(value: progress.progress)),
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      fadeInDuration: const Duration(milliseconds: 300),
      fadeInCurve: Curves.easeOut,
      placeholderFadeInDuration: const Duration(milliseconds: 300),
    );
  }
}
