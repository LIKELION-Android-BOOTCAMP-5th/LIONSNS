import 'package:flutter/cupertino.dart';
import 'package:lionsns/core/services/external/supabase_service.dart';
import 'package:lionsns/core/utils/result.dart';

class SupabaseLikeDatasource {
  static const String _tableName = 'post_likes';

  /// 게시글 좋아요 수 가져오기
  Future<Result<int>> getLikeCount(String postId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('post_id', postId);

      final count = (response as List).length;
      return Success<int>(count);
    } catch (e) {
      debugPrint('좋아요 수 조회 오류: $e');
      return Failure<int>('좋아요 수를 불러오는데 실패했습니다: $e');
    }
  }

  /// 사용자가 게시글을 좋아요 했는지 확인
  Future<Result<bool>> isLiked(String postId, String userId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      return Success<bool>(response != null);
    } catch (e) {
      debugPrint('좋아요 확인 오류: $e');
      return Failure<bool>('좋아요 상태를 확인하는데 실패했습니다: $e');
    }
  }
  /// 좋아요 추가
  Future<Result<void>> addLike(String postId, String userId) async {
    try {
      await SupabaseService.client
          .from(_tableName)
          .insert({
        'post_id': postId,
        'user_id': userId,
      });

      return Success<void>(null as dynamic);
    } catch (e, stackTrace) {
      debugPrint('[LikeDatasource] 좋아요 추가 실패: $e');
      // 이미 좋아요한 경우 중복 에러 무시
      if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
        return Success<void>(null as dynamic);
      }
      return Failure<void>('좋아요에 실패했습니다: $e');
    }
  }

  /// 좋아요 제거
  Future<Result<void>> removeLike(String postId, String userId) async {
    try {
      await SupabaseService.client
          .from(_tableName)
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);

      return Success<void>(null as dynamic);
    } catch (e, stackTrace) {
      debugPrint('[LikeDatasource] 좋아요 제거 실패: $e');
      return Failure<void>('좋아요 취소에 실패했습니다: $e');
    }
  }

  /// 좋아요 토글 (있으면 제거, 없으면 추가)
  Future<Result<bool>> toggleLike(String postId, String userId) async {
    try {
      final isLikedResult = await isLiked(postId, userId);

      return await isLikedResult.when(
        success: (liked) async {
          if (liked) {
            final result = await removeLike(postId, userId);
            return result.when(
              success: (_) => Success<bool>(false),
              failure: (message, error) => Failure<bool>(message, error),
            );
          } else {
            final result = await addLike(postId, userId);
            return result.when(
              success: (_) => Success<bool>(true),
              failure: (message, error) => Failure<bool>(message, error),
            );
          }
        },
        failure: (message, error) => Future.value(Failure<bool>(message, error)),
      );
    } catch (e) {
      return Failure<bool>('좋아요 토글에 실패했습니다: $e');
    }
  }
}