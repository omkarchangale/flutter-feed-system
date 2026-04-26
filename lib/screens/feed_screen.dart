// lib/screens/feed_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/feed_provider.dart';
import '../widgets/post_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();

  bool _loadMoreCalled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Only trigger once per page — reset the flag after load completes
    if (currentScroll >= maxScroll - 200 && !_loadMoreCalled) {
      _loadMoreCalled = true;
      ref.read(feedProvider.notifier).loadMore().then((_) {
        // Reset flag so the next page can trigger again
        if (mounted) _loadMoreCalled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Feed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _buildBody(feedState),
    );
  }

  Widget _buildBody(FeedState feedState) {
    // First page loading
    if (feedState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error with no posts loaded
    if (feedState.error != null && feedState.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Could not load feed.\n${feedState.error}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(feedProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (feedState.posts.isEmpty) {
      return const Center(child: Text('No posts yet.'));
    }

    // Feed list
    return RefreshIndicator(
      onRefresh: () {
        // Also reset the load-more guard on full refresh
        _loadMoreCalled = false;
        return ref.read(feedProvider.notifier).refresh();
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: feedState.posts.length + 1,
        itemBuilder: (context, index) {
          if (index == feedState.posts.length) {
            return _buildFooter(feedState);
          }
          return PostCard(post: feedState.posts[index]);
        },
      ),
    );
  }

  Widget _buildFooter(FeedState feedState) {
    if (feedState.isFetchingMore) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!feedState.hasMore) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            "You're all caught up! 🎉",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
