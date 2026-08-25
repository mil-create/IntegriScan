import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/retry_util.dart';

/// A widget that displays an image from the network with retry capability.
///
/// This widget wraps network image loading and provides retry functionality for
/// transient network failures using RetryUtil.
class RetryNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext context, String error) errorBuilder;
  final Widget Function(BuildContext context, Widget child, ImageChunkEvent? loadingProgress) loadingBuilder;

  const RetryNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    required this.errorBuilder,
    required this.loadingBuilder,
  }) : assert(imageUrl.length > 0);

  @override
  State<RetryNetworkImage> createState() => _RetryNetworkImageState();
}

class _RetryNetworkImageState extends State<RetryNetworkImage> {
  bool _hasError = false;
  bool _isLoading = true;
  static const int _maxRetries = 2; // 2 retries = 3 total attempts

  @override
  void initState() {
    super.initState();
    _loadImageWithRetry();
  }

  @override
  void didUpdateWidget(covariant RetryNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _hasError = false;
      _isLoading = true;
      _loadImageWithRetry();
    }
  }

  Future<void> _loadImageWithRetry() async {
    try {
      await RetryUtil.retryOperation(
        () async {
          final uri = Uri.parse(widget.imageUrl);
          if (!uri.isAbsolute) {
            throw const FormatException('Invalid image URL');
          }

          // Preload image bytes via NetworkImage to force actual network 
          // resolution and catch connection errors inside the retry loop
          final Completer<void> completer = Completer<void>();
          final ImageStream stream = NetworkImage(widget.imageUrl).resolve(ImageConfiguration.empty);

          late ImageStreamListener listener;
          listener = ImageStreamListener(
            (ImageInfo image, bool synchronousCall) {
              stream.removeListener(listener);
              if (!completer.isCompleted) completer.complete();
            },
            onError: (dynamic exception, StackTrace? stackTrace) {
              stream.removeListener(listener);
              if (!completer.isCompleted) completer.completeError(exception);
            },
          );

          stream.addListener(listener);
          await completer.future;
        },
        maxAttempts: _maxRetries + 1, // Initial attempt + retries
        initialDelay: 500, // Start with 500ms delay
        maxDelay: 5000, // Cap at 5 seconds
        backoffMultiplier: 2.0, // Exponential backoff
      );

      // Network loading and caching succeeded
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      // All retries exhausted
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorBuilder(
        context,
        'Failed to load image after multiple attempts. Please try again later.',
      );
    }

    if (_isLoading) {
      return widget.loadingBuilder(
        context,
        const SizedBox(
          width: 24.0,
          height: 24.0,
          child: CircularProgressIndicator(strokeWidth: 2.0),
        ),
        null,
      );
    }

    // Render the cached/preloaded image
    return Image.network(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: widget.loadingBuilder,
      errorBuilder: (context, error, stackTrace) => widget.errorBuilder(
        context,
        'Unable to load image. Please try again.',
      ),
    );
  }
}