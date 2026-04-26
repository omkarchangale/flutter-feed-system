class Post {
  final String id;
  final String? mediaThumbUrl;  // small thumbnail shown in the feed
  final String? mediaMobileUrl; // 1080x1080 shown on detail screen
  final String? mediaRawUrl;    // full-res for download
  final int likeCount;

  const Post({
    required this.id,
    this.mediaThumbUrl,
    this.mediaMobileUrl,
    this.mediaRawUrl,
    required this.likeCount,
  });

  // Build a Post from the JSON map that Supabase returns
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      mediaThumbUrl: json['media_thumb_url'] as String?,
      mediaMobileUrl: json['media_mobile_url'] as String?,
      mediaRawUrl: json['media_raw_url'] as String?,
      likeCount: (json['like_count'] as int?) ?? 0,
    );
  }

  Post copyWith({
    String? id,
    String? mediaThumbUrl,
    String? mediaMobileUrl,
    String? mediaRawUrl,
    int? likeCount,
  }) {
    return Post(
      id: id ?? this.id,
      mediaThumbUrl: mediaThumbUrl ?? this.mediaThumbUrl,
      mediaMobileUrl: mediaMobileUrl ?? this.mediaMobileUrl,
      mediaRawUrl: mediaRawUrl ?? this.mediaRawUrl,
      likeCount: likeCount ?? this.likeCount,
    );
  }
}
