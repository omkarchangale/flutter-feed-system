
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post.dart';
import '../providers/feed_provider.dart';
import '../screens/detail_screen.dart';

class PostCard extends ConsumerWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailScreen(post: post)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 30,
              spreadRadius: 2,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RepaintBoundary(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Hero(
                  tag: 'post_image_${post.id}',
                  child: _buildThumb(context),
                ),
              ),
            ),
            _LikeRow(post: post),
          ],
        ),
      ),
    );
  }

  Widget _buildThumb(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cacheWidth =
        (screenWidth * MediaQuery.of(context).devicePixelRatio).toInt();

    if (post.mediaThumbUrl == null) {
      return Container(
        height: 220,
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.image_not_supported)),
      );
    }

    return CachedNetworkImage(
      imageUrl: post.mediaThumbUrl!,
      // Decoded bitmap is sized to exact display pixels — prevents OOM
      memCacheWidth: cacheWidth,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 220,
      placeholder: (context, url) => Container(
        height: 220,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        height: 220,
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.broken_image)),
      ),
    );
  }
}

class _LikeRow extends ConsumerWidget {
  final Post post;

  const _LikeRow({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for count changes
    final latestPost = ref.watch(feedProvider).posts.firstWhere(
          (p) => p.id == post.id,
          orElse: () => post,
        );

    final isLiked =
        ref.read(feedProvider.notifier).isLikedByUser(post.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${latestPost.likeCount} likes',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
