import 'package:flutter/cupertino.dart';
import 'package:lionsns/core/services/external/supabase_service.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/features/auth/models/user.dart';

class SupabaseFollowDatasource {
  static const String _tableName = 'follows';

  /// 팔로우하기
  Future<Result<void>> follow(String followerId, String followingId) async {
    try {
      debugPrint('[SupabaseFollowDatasource] 팔로우 시작: followerId=$followerId, followingId=$followingId');

      if (followerId == followingId) {
        return Failure<void>('자기 자신을 팔로우할 수 없습니다');
      }

      await SupabaseService.client.from(_tableName).insert({
        'follower_id': followerId,
        'following_id': followingId,
      });

      debugPrint('[SupabaseFollowDatasource] 팔로우 완료');
      return Success<void>(null as dynamic);
    } catch (e, stackTrace) {
      debugPrint('[SupabaseFollowDatasource] 팔로우 실패: $e');
      debugPrint('   스택: $stackTrace');
      // 이미 팔로우한 경우 중복 에러 무시
      if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
        return Success<void>(null as dynamic);
      }
      return Failure<void>('팔로우에 실패했습니다: $e');
    }
  }

  /// 언팔로우하기
  Future<Result<void>> unfollow(String followerId, String followingId) async {
    try {
      debugPrint('[SupabaseFollowDatasource] 언팔로우 시작: followerId=$followerId, followingId=$followingId');

      await SupabaseService.client
          .from(_tableName)
          .delete()
          .eq('follower_id', followerId)
          .eq('following_id', followingId);

      debugPrint('[SupabaseFollowDatasource] 언팔로우 완료');
      return Success<void>(null as dynamic);
    } catch (e, stackTrace) {
      debugPrint('[SupabaseFollowDatasource] 언팔로우 실패: $e');
      debugPrint('   스택: $stackTrace');
      return Failure<void>('언팔로우에 실패했습니다: $e');
    }
  }

  /// 팔로우 토글 (팔로우 중이면 언팔로우, 아니면 팔로우)
  Future<Result<bool>> toggleFollow(String followerId, String followingId) async {
    try {
      final isFollowingResult = await isFollowing(followerId, followingId);

      return await isFollowingResult.when(
        success: (isFollowing) async {
          if (isFollowing) {
            final result = await unfollow(followerId, followingId);
            return result.when(
              success: (_) => Success<bool>(false),
              failure: (message, error) => Failure<bool>(message, error),
            );
          } else {
            final result = await follow(followerId, followingId);
            return result.when(
              success: (_) => Success<bool>(true),
              failure: (message, error) => Failure<bool>(message, error),
            );
          }
        },
        failure: (message, error) => Future.value(Failure<bool>(message, error)),
      );
    } catch (e) {
      return Failure<bool>('팔로우 토글에 실패했습니다: $e');
    }
  }

  /// 팔로우 상태 확인
  Future<Result<bool>> isFollowing(String followerId, String followingId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('follower_id', followerId)
          .eq('following_id', followingId)
          .maybeSingle();

      return Success<bool>(response != null);
    } catch (e) {
      debugPrint('[SupabaseFollowDatasource] 팔로우 상태 확인 오류: $e');
      return Failure<bool>('팔로우 상태를 확인하는데 실패했습니다: $e');
    }
  }

  /// 팔로워 수 조회
  Future<Result<int>> getFollowerCount(String userId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('following_id', userId);

      final count = (response as List).length;
      return Success<int>(count);
    } catch (e) {
      debugPrint('[SupabaseFollowDatasource] 팔로워 수 조회 오류: $e');
      return Failure<int>('팔로워 수를 불러오는데 실패했습니다: $e');
    }
  }

  /// 팔로잉 수 조회
  Future<Result<int>> getFollowingCount(String userId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('follower_id', userId);

      final count = (response as List).length;
      return Success<int>(count);
    } catch (e) {
      debugPrint('[SupabaseFollowDatasource] 팔로잉 수 조회 오류: $e');
      return Failure<int>('팔로잉 수를 불러오는데 실패했습니다: $e');
    }
  }

  /// 팔로워 목록 조회
  Future<Result<List<User>>> getFollowers(String userId) async {
    try {
      debugPrint('[SupabaseFollowDatasource] 팔로워 목록 조회 시작: userId=$userId');

      final response = await SupabaseService.client
          .from(_tableName)
          .select('*, user_profiles!follower_id(id, name, profile_image_url, provider, created_at)')
          .eq('following_id', userId);

      if (response is! List) {
        debugPrint('[SupabaseFollowDatasource] 팔로워 목록 조회 결과가 리스트가 아님: ${response.runtimeType}');
        return Success<List<User>>([]);
      }

      final followers = (response as List).map((json) {
        final data = Map<String, dynamic>.from(json);
        final userProfile = data['user_profiles'];
        
        if (userProfile == null || userProfile is! Map<String, dynamic>) {
          return null;
        }

        try {
          final profile = Map<String, dynamic>.from(userProfile);
          final user = User(
            id: profile['id'] as String,
            name: profile['name'] as String? ?? '사용자',
            email: '', // email은 auth.users에서 가져와야 하지만 팔로워 목록에서는 불필요
            profileImageUrl: profile['profile_image_url'] as String?,
            provider: _getProviderFromString(profile['provider'] as String?),
            createdAt: DateTime.parse(profile['created_at'] as String),
          );
          return user;
        } catch (e) {
          debugPrint('[SupabaseFollowDatasource] 팔로워 프로필 파싱 실패: $e');
          return null;
        }
      }).whereType<User>().toList();

      debugPrint('[SupabaseFollowDatasource] 팔로워 목록 조회 완료: ${followers.length}명');
      return Success<List<User>>(followers);
    } catch (e, stackTrace) {
      debugPrint('[SupabaseFollowDatasource] 팔로워 목록 조회 실패: $e');
      debugPrint('   스택: $stackTrace');
      return Failure<List<User>>('팔로워 목록을 불러오는데 실패했습니다: $e');
    }
  }

  /// 팔로잉 목록 조회
  Future<Result<List<User>>> getFollowing(String userId) async {
    try {
      debugPrint('[SupabaseFollowDatasource] 팔로잉 목록 조회 시작: userId=$userId');

      final response = await SupabaseService.client
          .from(_tableName)
          .select('*, user_profiles!following_id(id, name, profile_image_url, provider, created_at)')
          .eq('follower_id', userId);

      if (response is! List) {
        debugPrint('[SupabaseFollowDatasource] 팔로잉 목록 조회 결과가 리스트가 아님: ${response.runtimeType}');
        return Success<List<User>>([]);
      }

      final following = (response as List).map((json) {
        final data = Map<String, dynamic>.from(json);
        final userProfile = data['user_profiles'];
        
        if (userProfile == null || userProfile is! Map<String, dynamic>) {
          return null;
        }

        try {
          final profile = Map<String, dynamic>.from(userProfile);
          final user = User(
            id: profile['id'] as String,
            name: profile['name'] as String? ?? '사용자',
            email: '', // email은 auth.users에서 가져와야 하지만 팔로잉 목록에서는 불필요
            profileImageUrl: profile['profile_image_url'] as String?,
            provider: _getProviderFromString(profile['provider'] as String?),
            createdAt: DateTime.parse(profile['created_at'] as String),
          );
          return user;
        } catch (e) {
          debugPrint('[SupabaseFollowDatasource] 팔로잉 프로필 파싱 실패: $e');
          return null;
        }
      }).whereType<User>().toList();

      debugPrint('[SupabaseFollowDatasource] 팔로잉 목록 조회 완료: ${following.length}명');
      return Success<List<User>>(following);
    } catch (e, stackTrace) {
      debugPrint('[SupabaseFollowDatasource] 팔로잉 목록 조회 실패: $e');
      debugPrint('   스택: $stackTrace');
      return Failure<List<User>>('팔로잉 목록을 불러오는데 실패했습니다: $e');
    }
  }

  AuthProvider _getProviderFromString(String? provider) {
    switch (provider) {
      case 'google':
        return AuthProvider.google;
      case 'apple':
        return AuthProvider.apple;
      case 'kakao':
        return AuthProvider.kakao;
      case 'naver':
        return AuthProvider.naver;
      default:
        return AuthProvider.google;
    }
  }
}

