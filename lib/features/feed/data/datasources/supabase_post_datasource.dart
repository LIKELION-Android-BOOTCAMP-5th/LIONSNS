import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../models/post.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/core/services/external/supabase_service.dart';
import 'package:lionsns/core/services/internal/storage_service_interface.dart';

class SupabasePostDatasource {
  final StorageService _storageService;
  static const String _tableName = 'posts';

  SupabasePostDatasource(this._storageService);

  /// 모든 게시글 가져오기
  Future<Result<List<Post>>> getPosts() async {
    try {
      final currentUserId = SupabaseService.currentUser?.id;

      // 게시글 조회 (JOIN으로 프로필 정보 포함)
      final response = await SupabaseService.client
          .from(_tableName)
          .select('*, user_profiles!user_id(name, profile_image_url)')
          .order('created_at', ascending: false);


      final postsData = response as List;

      final posts = await Future.wait(postsData.map((json) async {
        final data = Map<String, dynamic>.from(json);
        
        // JOIN된 프로필 정보 추출
        String? authorName;
        String? authorImageUrl;
        
        // user_profiles는 JOIN으로 객체로 반환됨
        final userProfile = data['user_profiles'];
        if (userProfile != null && userProfile is Map<String, dynamic>) {
          authorName = userProfile['name'] as String?;
          authorImageUrl = userProfile['profile_image_url'] as String?;
        }

        final likesResponse = await SupabaseService.client
            .from('post_likes')
            .select()
            .eq('post_id', data['id']);
        final likes = likesResponse as List;

        bool? isLiked;
        if (currentUserId != null) {
          final userLike = await SupabaseService.client
              .from('post_likes')
              .select()
              .eq('post_id', data['id'])
              .eq('user_id', currentUserId)
              .maybeSingle();
          isLiked = userLike != null;
        }

        int commentsCount = 0;
        try {
          final commentsResponse = await SupabaseService.client
              .from('comments')
              .select('id')
              .eq('post_id', data['id']);
          final comments = commentsResponse as List;
          commentsCount = comments.length;
        } catch (e) {
          // comments 테이블이 없을 경우 0으로 설정 (초기 설정 단계에서 발생 가능)
          debugPrint('댓글 수 조회 실패 (postId: ${data['id']}): $e');
        }

        final post = Post.fromJson(data);
        
        // 썸네일 URL 생성 (이미지가 있는 경우)
        String? thumbnailUrl;
        if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
          thumbnailUrl = _storageService.getPostThumbnailUrl(
            post.imageUrl!,
            width: 800,
            height: 400,
          );
        }
        
        return post.copyWith(
          authorName: authorName,
          authorImageUrl: authorImageUrl,
          likesCount: likes.length,
          commentsCount: commentsCount,
          isLiked: isLiked,
          thumbnailUrl: thumbnailUrl,
        );
      }));

      return Success<List<Post>>(posts);
    } catch (e) {
      debugPrint('게시글 조회 오류: $e');
      return Failure<List<Post>>('게시글을 불러오는데 실패했습니다: $e');
    }
  }

  /// 사용자가 좋아요한 게시글 목록 가져오기
  Future<Result<List<Post>>> getUserLikedPosts(String userId) async {
    try {
      final likesResponse = await SupabaseService.client
          .from('post_likes')
          .select('post_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (likesResponse.isEmpty) {
        return Success<List<Post>>([]);
      }

      final likedPostIds = (likesResponse as List)
          .map((like) => like['post_id'] as String)
          .toList();

      // 각 게시글을 개별 조회 (Supabase는 여러 ID를 한 번에 필터링하는 기능이 제한적)
      final posts = <Post>[];
      for (final postId in likedPostIds) {
        final postResult = await getPostById(postId);
        postResult.when(
          success: (post) => posts.add(post),
          failure: (_, __) => {}, // 개별 게시글 조회 실패는 무시 (삭제된 게시글 등)
          pending: (_) => {},
        );
      }

      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return Success<List<Post>>(posts);
    } catch (e) {
      debugPrint('좋아요한 게시글 조회 오류: $e');
      return Failure<List<Post>>('좋아요한 게시글을 불러오는데 실패했습니다: $e');
    }
  }

  /// 게시글 ID로 가져오기
  Future<Result<Post>> getPostById(String id) async {
    try {
      final currentUserId = SupabaseService.currentUser?.id;

      // 게시글 조회 (JOIN으로 프로필 정보 포함)
      final response = await SupabaseService.client
          .from(_tableName)
          .select('*, user_profiles!user_id(name, profile_image_url)')
          .eq('id', id)
          .single();

      final data = Map<String, dynamic>.from(response);
      
      // JOIN된 프로필 정보 추출
      String? authorName;
      String? authorImageUrl;
      
      // user_profiles는 객체로 반환됨
      final userProfile = data['user_profiles'];
      if (userProfile != null && userProfile is Map<String, dynamic>) {
        authorName = userProfile['name'] as String?;
        authorImageUrl = userProfile['profile_image_url'] as String?;
      }

      // 좋아요 수 조회
      final likesResponse = await SupabaseService.client
          .from('post_likes')
          .select()
          .eq('post_id', id);
      final likes = likesResponse as List;

      // 현재 사용자가 좋아요 했는지 확인
      bool? isLiked;
      if (currentUserId != null) {
        final userLike = await SupabaseService.client
            .from('post_likes')
            .select()
            .eq('post_id', id)
            .eq('user_id', currentUserId)
            .maybeSingle();
        isLiked = userLike != null;
      }

      // 댓글 수 조회
      try {
        final commentsResponse = await SupabaseService.client
            .from('comments')
            .select('id')
            .eq('post_id', id);
        final comments = commentsResponse as List;

        // Post.fromJson은 'author_id' 컬럼을 사용 (이미 post.g.dart에서 매핑됨)
        final post = Post.fromJson(data);
        
        // 썸네일 URL 생성 (이미지가 있는 경우)
        String? thumbnailUrl;
        if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
          thumbnailUrl = _storageService.getPostThumbnailUrl(
            post.imageUrl!,
            width: 800,
            height: 400,
          );
        }
        
        return Success<Post>(post.copyWith(
          authorName: authorName,
          authorImageUrl: authorImageUrl,
          likesCount: likes.length,
          commentsCount: comments.length,
          isLiked: isLiked,
          thumbnailUrl: thumbnailUrl,
        ));
      } catch (e) {
        // comments 테이블이 없을 경우
        final post = Post.fromJson(data);
        
        // 썸네일 URL 생성 (이미지가 있는 경우)
        String? thumbnailUrl;
        if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
          thumbnailUrl = _storageService.getPostThumbnailUrl(
            post.imageUrl!,
            width: 800,
            height: 400,
          );
        }
        
        return Success<Post>(post.copyWith(
          authorName: authorName,
          authorImageUrl: authorImageUrl,
          likesCount: likes.length,
          commentsCount: 0,
          isLiked: isLiked,
          thumbnailUrl: thumbnailUrl,
        ));
      }
    } catch (e) {
      debugPrint('게시글 조회 오류: $e');
      return Failure<Post>('게시글을 불러오는데 실패했습니다: $e');
    }
  }

  /// 게시글 생성
  Future<Result<Post>> createPost(Post post) async {
    try {
      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId == null) {
        return Failure<Post>('로그인이 필요합니다');
      }

      // posts 테이블 스키마에 맞게 데이터 생성
      // id는 TEXT PRIMARY KEY이므로 UUID를 생성하거나 서버에서 생성하도록 함
      // user_id는 UUID 타입이고 user_profiles.id를 참조
      final postId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // 이미지가 있으면 먼저 업로드
      String? imageUrl;
      if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
        // imageUrl이 파일 경로인 경우 업로드
        try {
          final imageFile = File(post.imageUrl!);
          if (await imageFile.exists()) {
            imageUrl = await _storageService.uploadPostImage(
              imageFile: imageFile,
              postId: postId,
              userId: currentUserId,
            );
          } else {
            // 이미 URL인 경우 그대로 사용
            imageUrl = post.imageUrl;
          }
        } catch (e) {
          debugPrint('[PostDatasource] 이미지 업로드 실패: $e');
          // 이미지 업로드 실패 시에도 게시글은 생성 (이미지 없이)
        }
      }

      final postData = {
        'id': postId,
        'title': post.title,
        'content': post.content,
        'user_id': currentUserId, // UUID 타입, user_profiles.id를 참조
        if (imageUrl != null) 'image_url': imageUrl,
      };

      // insert 후 전체 데이터 조회
      final response = await SupabaseService.client
          .from(_tableName)
          .insert(postData)
          .select()
          .single();

      final data = Map<String, dynamic>.from(response);

      // user_id 컬럼에서 작성자 ID 가져오기
      final userId = data['user_id'] as String;

      // 프로필 조회
      String? authorName;
      String? authorImageUrl;
      
      try {
        final profileResponse = await SupabaseService.client
            .from('user_profiles')
            .select('name, profile_image_url')
            .eq('id', userId)
            .maybeSingle();

        if (profileResponse != null) {
          final profile = Map<String, dynamic>.from(profileResponse);
          authorName = profile['name'] as String?;
          authorImageUrl = profile['profile_image_url'] as String?;
        }
      } catch (e) {
        debugPrint('[PostDatasource] 프로필 조회 실패: $e');
      }

      // Post.fromJson은 'author_id' 컬럼을 사용 (이미 post.g.dart에서 매핑됨)
      final createdPost = Post.fromJson(data);
      
      // 썸네일 URL 생성 (이미지가 있는 경우)
      String? thumbnailUrl;
      if (createdPost.imageUrl != null && createdPost.imageUrl!.isNotEmpty) {
        thumbnailUrl = _storageService.getPostThumbnailUrl(
          createdPost.imageUrl!,
          width: 800,
          height: 400,
        );
      }

      return Success<Post>(createdPost.copyWith(
        authorName: authorName,
        authorImageUrl: authorImageUrl,
        likesCount: 0,
        commentsCount: 0,
        isLiked: false,
        thumbnailUrl: thumbnailUrl,
      ));
    } catch (e, stackTrace) {
      debugPrint('게시글 생성 오류: $e');
      return Failure<Post>('게시글 생성에 실패했습니다: $e');
    }
  }


  /// 게시글 업데이트
  Future<Result<Post>> updatePost(Post post) async {
    try {
      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId == null) {
        return Failure<Post>('로그인이 필요합니다');
      }

      // 기존 게시글 정보 가져오기 (이미지 처리용)
      final existingPostResult = await getPostById(post.id);
      final existingPost = existingPostResult.when(
        success: (p) => p,
        failure: (_, __) => null,
      );

      // 이미지 처리
      String? imageUrl;
      
      // post.imageUrl이 로컬 파일 경로인지 확인 (URL이 아닌 경우)
      final isLocalFile = post.imageUrl != null && 
          post.imageUrl!.isNotEmpty && 
          !post.imageUrl!.startsWith('http://') && 
          !post.imageUrl!.startsWith('https://') &&
          !post.imageUrl!.startsWith('/storage/v1/object/public/');
      
      if (isLocalFile) {
        // 로컬 파일인 경우 업로드
        try {
          final imageFile = File(post.imageUrl!);
          if (await imageFile.exists()) {
            // 기존 이미지가 있으면 삭제
            if (existingPost?.imageUrl != null && existingPost!.imageUrl!.isNotEmpty) {
              try {
                // 기존 이미지가 URL인 경우에만 삭제 시도
                if (existingPost.imageUrl!.startsWith('http://') || 
                    existingPost.imageUrl!.startsWith('https://') ||
                    existingPost.imageUrl!.startsWith('/storage/v1/object/public/')) {
                  await _storageService.deletePostImage(existingPost.imageUrl!);
                }
              } catch (e) {
                // 삭제 실패해도 계속 진행
              }
            }
            
            // 새 이미지 업로드
            imageUrl = await _storageService.uploadPostImage(
              imageFile: imageFile,
              postId: post.id,
              userId: currentUserId,
            );
          } else {
            // 파일이 없으면 기존 이미지 유지
            imageUrl = existingPost?.imageUrl;
          }
        } catch (e, stackTrace) {
          debugPrint('[PostDatasource] 이미지 업로드 실패: $e');
          // 이미지 업로드 실패 시 기존 이미지 유지
          imageUrl = existingPost?.imageUrl;
        }
      } else if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
        // URL인 경우 그대로 사용 (기존 이미지 유지)
        imageUrl = post.imageUrl;
      } else {
        // imageUrl이 null이거나 빈 문자열인 경우 기존 이미지 유지
        imageUrl = existingPost?.imageUrl;
      }

      // posts 테이블에 있는 필드만 포함 (조인된 데이터 제외)
      // updated_at은 트리거가 자동으로 업데이트하므로 명시하지 않음
      final postData = <String, dynamic>{
        'title': post.title,
        'content': post.content,
      };
      
      // image_url이 null이 아닌 경우에만 추가 (null인 경우 기존 값 유지를 위해 업데이트하지 않음)
      if (imageUrl != null) {
        postData['image_url'] = imageUrl;
      }

      // 게시글 업데이트
      final response = await SupabaseService.client
          .from(_tableName)
          .update(postData)
          .eq('id', post.id)
          .select()
          .single();

      final data = Map<String, dynamic>.from(response);
      // posts 테이블은 'user_id' 컬럼 사용 (UUID 타입)
      final userId = data['user_id'] as String;

      // 작성자 프로필 조회
      String? authorName;
      String? authorImageUrl;
      
      try {
        final profileResponse = await SupabaseService.client
            .from('user_profiles')
            .select('name, profile_image_url')
            .eq('id', userId)
            .maybeSingle();

        if (profileResponse != null) {
          final profile = Map<String, dynamic>.from(profileResponse);
          authorName = profile['name'] as String?;
          authorImageUrl = profile['profile_image_url'] as String?;
        }
      } catch (e) {
        debugPrint('[PostDatasource] 프로필 조회 실패: $e');
      }

      // 좋아요 수 조회
      final likesResponse = await SupabaseService.client
          .from('post_likes')
          .select()
          .eq('post_id', post.id);
      final likes = likesResponse as List;

      // 현재 사용자가 좋아요 했는지 확인
      bool? isLiked;
      if (currentUserId != null) {
        final userLike = await SupabaseService.client
            .from('post_likes')
            .select()
            .eq('post_id', post.id)
            .eq('user_id', currentUserId)
            .maybeSingle();
        isLiked = userLike != null;
      }

      // Post.fromJson은 'author_id' 컬럼을 사용 (이미 post.g.dart에서 매핑됨)
      // 댓글 수 조회
      try {
        final commentsResponse = await SupabaseService.client
            .from('comments')
            .select('id')
            .eq('post_id', post.id);
        final comments = commentsResponse as List;

        final updatedPost = Post.fromJson(data);
        
        // 썸네일 URL 생성 (이미지가 있는 경우)
        String? thumbnailUrl;
        if (updatedPost.imageUrl != null && updatedPost.imageUrl!.isNotEmpty) {
          thumbnailUrl = _storageService.getPostThumbnailUrl(
            updatedPost.imageUrl!,
            width: 800,
            height: 400,
          );
        }
        
        return Success<Post>(updatedPost.copyWith(
          authorName: authorName,
          authorImageUrl: authorImageUrl,
          likesCount: likes.length,
          commentsCount: comments.length,
          isLiked: isLiked,
          thumbnailUrl: thumbnailUrl,
        ));
      } catch (e) {
        // comments 테이블이 없을 경우
        final updatedPost = Post.fromJson(data);
        
        // 썸네일 URL 생성 (이미지가 있는 경우)
        String? thumbnailUrl;
        if (updatedPost.imageUrl != null && updatedPost.imageUrl!.isNotEmpty) {
          thumbnailUrl = _storageService.getPostThumbnailUrl(
            updatedPost.imageUrl!,
            width: 800,
            height: 400,
          );
        }
        
        return Success<Post>(updatedPost.copyWith(
          authorName: authorName,
          authorImageUrl: authorImageUrl,
          likesCount: likes.length,
          commentsCount: 0,
          isLiked: isLiked,
          thumbnailUrl: thumbnailUrl,
        ));
      }
    } catch (e) {
      debugPrint('게시글 수정 오류: $e');
      return Failure<Post>('게시글 수정에 실패했습니다: $e');
    }
  }

  /// 게시글 삭제
  Future<Result<void>> deletePost(String id) async {
    try {
      await SupabaseService.client
          .from(_tableName)
          .delete()
          .eq('id', id);

      return Success<void>(null as dynamic);
    } catch (e) {
      return Failure<void>('게시글 삭제에 실패했습니다: $e');
    }
  }

  /// 게시글 통계 조회 (Edge Function)
  Future<Result<Map<String, dynamic>>> getPostStats() async {
    try {
      final response = await SupabaseService.invokeFunction('post-stats');

      if (response.data != null) {
        return Success<Map<String, dynamic>>(response.data as Map<String, dynamic>);
      } else {
        return Failure<Map<String, dynamic>>('게시글 통계 조회에 실패했습니다: ${response.status}');
      }
    } catch (e) {
      return Failure<Map<String, dynamic>>('게시글 통계 조회에 실패했습니다: $e');
    }
  }
}

