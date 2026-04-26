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
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          // Navigate to the detail screen with a Hero animation
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailScreen(post: post),
            ),
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
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Hero(
                  // Hero tag must be unique per post so Flutter matches the
                  // correct pair of widgets during the animation.
                  tag: 'post_image_${post.id}',
                  child: _buildThumb(context),
                ),
              ),
              _LikeRow(post: post),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumb(BuildContext context) {
    // Screen width in logical pixels
    final screenWidth = MediaQuery.of(context).size.width;
    // Convert logical px → physical px for memCacheWidth
    final cacheWidth =
        (screenWidth * MediaQuery.of(context).devicePixelRatio).toInt();

    if (post.mediaThumbUrl == null) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.image_not_supported)),
      );
    }

    return CachedNetworkImage(
      imageUrl: post.mediaThumbUrl!,
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
    final latestPost = ref.watch(feedProvider).posts.firstWhere(
          (p) => p.id == post.id,
          orElse: () => post,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Like button
          GestureDetector(
            onTap: () =>
                ref.read(feedProvider.notifier).toggleLike(context, post.id),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.favorite,
                key: ValueKey(latestPost.likeCount),
                color: latestPost.likeCount > 0 ? Colors.red : Colors.grey,
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
