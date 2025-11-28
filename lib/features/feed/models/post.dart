import 'package:json_annotation/json_annotation.dart';

part 'post.g.dart';

/// 게시글 모델
@JsonSerializable()
class Post {
  final String id;
  final String title;
  final String content;
  @JsonKey(name: 'user_id')
  final String authorId;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // 조인된 데이터 (선택적)
  final String? authorName;
  final String? authorImageUrl;
  final int? likesCount;
  final int? commentsCount;
  final bool? isLiked;

  const Post({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.authorName,
    this.authorImageUrl,
    this.likesCount,
    this.commentsCount,
    this.isLiked,
  });

  /// JSON에서 객체로 변환
  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() => _$PostToJson(this);

  /// 생성용 팩토리 (ID와 날짜를 자동 생성)
  factory Post.create({
    required String title,
    required String content,
    required String authorId,
    String? imageUrl,
  }) {
    final now = DateTime.now();
    return Post(
      id: '', // 서버에서 생성
      title: title,
      content: content,
      authorId: authorId,
      imageUrl: imageUrl,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 업데이트용 copyWith
  Post copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorName,
    String? authorImageUrl,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorName: authorName ?? this.authorName,
      authorImageUrl: authorImageUrl ?? this.authorImageUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  /// author 필드 (하위 호환성)
  String get author => authorName ?? '익명';
}

