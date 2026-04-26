
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../models/post.dart';

final supabase = Supabase.instance.client;
const int _pageSize = 10;

class FeedState {
  final List<Post> posts;
  final bool isLoading;
  final bool isFetchingMore;
  final bool hasMore;
  final String? error;

  const FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.isFetchingMore = false,
    this.hasMore = true,
    this.error,
  });

  FeedState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? isFetchingMore,
    bool? hasMore,
    String? error,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier() : super(const FeedState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final posts = await _fetchPage(from: 0);
      state = state.copyWith(
        posts: posts,
        isLoading: false,
        hasMore: posts.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isFetchingMore || !state.hasMore) return;
    state = state.copyWith(isFetchingMore: true);
    try {
      final nextPage = await _fetchPage(from: state.posts.length);
      state = state.copyWith(
        posts: [...state.posts, ...nextPage],
        isFetchingMore: false,
        hasMore: nextPage.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isFetchingMore: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadInitial();

  Future<List<Post>> _fetchPage({required int from}) async {
    final response = await supabase
        .from('posts')
        .select()
        .order('created_at', ascending: false)
        .range(from, from + _pageSize - 1);

    return (response as List)
        .map((json) => Post.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  final Map<String, int> _serverLikeCount = {};
  final Map<String, bool> _isLiked = {};
  final Map<String, Timer> _timers = {};

  // FIX 3 (heart color): expose liked state so UI can read it
  bool isLikedByUser(String postId) => _isLiked[postId] ?? false;

  void toggleLike(BuildContext context, String postId) {
    final idx = state.posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final post = state.posts[idx];

    // Initialize baseline on very first tap for this post
    if (!_serverLikeCount.containsKey(postId)) {
      _serverLikeCount[postId] = post.likeCount;
    }
    if (!_isLiked.containsKey(postId)) {
      _isLiked[postId] = false;
    }

    // Flip liked state
    _isLiked[postId] = !_isLiked[postId]!;

    // Compute display count — always anchored to server baseline
    final displayCount =
        _serverLikeCount[postId]! + (_isLiked[postId]! ? 1 : 0);

    // Update UI immediately (optimistic)
    final updatedPosts = List<Post>.from(state.posts);
    updatedPosts[idx] = post.copyWith(likeCount: displayCount);
    state = state.copyWith(posts: updatedPosts);

    // Debounce — 600ms silence → one network call
    _timers[postId]?.cancel();
    _timers[postId] = Timer(const Duration(milliseconds: 600), () {
      _syncToServer(context, postId);
    });
  }

  Future<void> _syncToServer(BuildContext context, String postId) async {
    // Save the intended state at the moment the timer fires
    final intendedIsLiked = _isLiked[postId] ?? false;
    final previousBaseline = _serverLikeCount[postId] ?? 0;

    try {
      // Single RPC call — server handles race conditions
      await supabase.rpc('toggle_like', params: {
        'p_post_id': postId,
        'p_user_id': currentUserId,
      });

      // Fetch confirmed count from server
      final response = await supabase
          .from('posts')
          .select('like_count')
          .eq('id', postId)
          .single();

      final serverCount = (response['like_count'] as int?) ?? 0;

      _serverLikeCount[postId] = serverCount;
      _isLiked[postId] = serverCount > previousBaseline;

      final idx = state.posts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        final updatedPosts = List<Post>.from(state.posts);
        updatedPosts[idx] = state.posts[idx].copyWith(likeCount: serverCount);
        state = state.copyWith(posts: updatedPosts);
      }
    } catch (_) {
      _isLiked[postId] = !intendedIsLiked;
      final revertCount = _serverLikeCount[postId] ?? 0;

      final idx = state.posts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        final updatedPosts = List<Post>.from(state.posts);
        updatedPosts[idx] =
            state.posts[idx].copyWith(likeCount: revertCount);
        state = state.copyWith(posts: updatedPosts);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet. Like reverted.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      _timers.remove(postId);
    }
  }
}

final feedProvider =
    StateNotifierProvider<FeedNotifier, FeedState>((ref) => FeedNotifier());
