import 'package:flutter/cupertino.dart';
import 'package:lionsns/core/services/external/supabase_service.dart';
import 'package:lionsns/core/utils/result.dart';
import '../../models/comment.dart';


class SupabaseCommentDatasource {
  static const String _tableName = 'comments';

  /// 게시글의 댓글 목록 가져오기
  Future<Result<List<Comment>>> getCommentsByPostId(String postId) async {
    try {
      // 잘못된 postId 체크: 라우트 경로가 아닌 실제 postId인지 확인
      if (postId.isEmpty || postId == 'create' || postId == 'edit') {
        return Success<List<Comment>>([]);
      }

      final response = await SupabaseService.client
          .from(_tableName)
          .select('*, user_profiles!user_id(name, profile_image_url)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      if (response is! List) {
        return Success<List<Comment>>([]);
      }

      final commentsData = response as List;

      // JOIN된 프로필 정보와 함께 댓글 매핑
      final comments = commentsData.map((json) {
        final data = Map<String, dynamic>.from(json);
        
        String? authorName;
        String? authorImageUrl;
        
        // user_profiles는 JOIN으로 객체로 반환됨
        final userProfile = data['user_profiles'];
        if (userProfile != null && userProfile is Map<String, dynamic>) {
          authorName = userProfile['name'] as String?;
          authorImageUrl = userProfile['profile_image_url'] as String?;
        }

        return Comment.fromJson(data).copyWith(
          authorName: authorName,
          authorImageUrl: authorImageUrl,
        );
      }).toList();

      return Success<List<Comment>>(comments);
    } catch (e, stackTrace) {
      debugPrint('[CommentDatasource] 댓글 조회 실패: $e');
      
      // 테이블이 없는 경우 빈 리스트 반환 (초기 설정 단계에서 발생 가능)
      if (e.toString().contains('Could not find the table') || 
          e.toString().contains('PGRST205')) {
        return Success<List<Comment>>([]);
      }
      
      return Failure<List<Comment>>('댓글을 불러오는데 실패했습니다: $e');
    }
  }

  /// 댓글 생성
  Future<Result<Comment>> createComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    try {
      debugPrint('[CommentDatasource] 댓글 생성 시작: postId=$postId');

      final commentData = {
        'post_id': postId,
        'user_id': userId,
        'content': content,
      };

      final response = await SupabaseService.client
          .from(_tableName)
          .insert(commentData)
          .select()
          .single();

      final data = Map<String, dynamic>.from(response);

      // 댓글 작성자 프로필 정보 조회
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
        debugPrint('[CommentDatasource] 댓글 생성 - 프로필 조회 실패: $e');
      }

      final comment = Comment.fromJson(data).copyWith(
        authorName: authorName,
        authorImageUrl: authorImageUrl,
      );

      return Success<Comment>(comment);
    } catch (e, stackTrace) {
      debugPrint('[CommentDatasource] 댓글 생성 실패: $e');
      return Failure<Comment>('댓글 작성에 실패했습니다: $e');
    }
  }

  /// 댓글 수정
  Future<Result<Comment>> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {

      final updateData = {
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await SupabaseService.client
          .from(_tableName)
          .update(updateData)
          .eq('id', commentId)
          .select()
          .single();

      final data = Map<String, dynamic>.from(response);
      final userId = data['user_id'] as String;

      // 댓글 작성자 프로필 정보 조회
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
        debugPrint('[CommentDatasource] 댓글 수정 - 프로필 조회 실패: $e');
      }

      final comment = Comment.fromJson(data).copyWith(
        authorName: authorName,
        authorImageUrl: authorImageUrl,
      );

      return Success<Comment>(comment);
    } catch (e, stackTrace) {
      debugPrint('[CommentDatasource] 댓글 수정 실패: $e');
      return Failure<Comment>('댓글 수정에 실패했습니다: $e');
    }
  }

  /// 댓글 삭제
  Future<Result<void>> deleteComment(String commentId) async {
    try {

      await SupabaseService.client
          .from(_tableName)
          .delete()
          .eq('id', commentId);

      return Success<void>(null as dynamic);
    } catch (e, stackTrace) {
      debugPrint('[CommentDatasource] 댓글 삭제 실패: $e');
      return Failure<void>('댓글 삭제에 실패했습니다: $e');
    }
  }
}



