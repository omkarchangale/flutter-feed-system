// lib/screens/detail_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post.dart';
import '../providers/feed_provider.dart';

class DetailScreen extends ConsumerWidget {
  final Post post;

  const DetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Post Detail'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroImageArea(post: post),
            const SizedBox(height: 24),
            _LikeSection(post: post),
            const SizedBox(height: 32),
            if (post.mediaRawUrl != null) _DownloadButton(post: post),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
class _LikeSection extends ConsumerWidget {
  final Post post;

  const _LikeSection({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestPost = ref.watch(feedProvider).posts.firstWhere(
          (p) => p.id == post.id,
          orElse: () => post,
        );
    final isLiked =
        ref.read(feedProvider.notifier).isLikedByUser(post.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                ref.read(feedProvider.notifier).toggleLike(context, post.id),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.favorite,
                key: ValueKey(isLiked),
                color: isLiked ? Colors.red : Colors.grey,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${latestPost.likeCount} likes',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
class _HeroImageArea extends StatefulWidget {
  final Post post;

  const _HeroImageArea({required this.post});

  @override
  State<_HeroImageArea> createState() => _HeroImageAreaState();
}

class _HeroImageAreaState extends State<_HeroImageArea> {
  bool _mobileImageLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'post_image_${widget.post.id}',
      child: SizedBox(
        height: 400,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Thumbnail — always shown instantly from cache
            if (widget.post.mediaThumbUrl != null)
              CachedNetworkImage(
                imageUrl: widget.post.mediaThumbUrl!,
                fit: BoxFit.cover,
              ),

            // Layer 2: Mobile quality — fades in when downloaded
            if (widget.post.mediaMobileUrl != null)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _mobileImageLoaded ? 1.0 : 0.0,
                child: CachedNetworkImage(
                  imageUrl: widget.post.mediaMobileUrl!,
                  fit: BoxFit.cover,
                  imageBuilder: (context, imageProvider) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_mobileImageLoaded && mounted) {
                        setState(() => _mobileImageLoaded = true);
                      }
                    });
                    return Image(image: imageProvider, fit: BoxFit.cover);
                  },
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DownloadButton extends StatefulWidget {
  final Post post;

  const _DownloadButton({required this.post});

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  bool _isLoading = false;
  bool _downloaded = false;

  Future<void> _downloadHighRes() async {
    setState(() => _isLoading = true);
    try {
      await precacheImage(
        NetworkImage(widget.post.mediaRawUrl!),
        context,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _downloaded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('High-res image loaded! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load high-res image.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        onPressed: _downloaded || _isLoading ? null : _downloadHighRes,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(_downloaded ? Icons.check : Icons.download),
        label: Text(
          _downloaded
              ? 'High-Res Loaded'
              : _isLoading
                  ? 'Loading…'
                  : 'Download High-Res',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
