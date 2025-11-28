import '../../models/user.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/core/services/external/supabase_service.dart';

class SupabaseProfileDatasource {
  static const String _tableName = 'user_profiles';

  /// 프로필 조회
  Future<Result<User?>> getProfile(String userId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return Success<User?>(null);
      }

      final profile = Map<String, dynamic>.from(response);
      final user = User(
        id: profile['id'] as String,
        name: profile['name'] as String? ?? '사용자',
        email: '', // email은 auth.users에서 가져와야 함 (user_profiles 테이블에는 저장하지 않음)
        profileImageUrl: profile['profile_image_url'] as String?,
        provider: _getProviderFromString(profile['provider'] as String?),
        createdAt: DateTime.parse(profile['created_at'] as String),
      );

      return Success<User?>(user);
    } catch (e) {
      return Failure<User?>('프로필을 불러오는데 실패했습니다: $e');
    }
  }

  /// 프로필 생성 또는 업데이트
  Future<Result<User>> upsertProfile({
    required String userId,
    required String name,
    required String email,
    String? profileImageUrl,
    required AuthProvider provider,
  }) async {
    try {
      final profileData = {
        'id': userId,
        'name': name,
        'profile_image_url': profileImageUrl,
        'provider': provider.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await SupabaseService.client
          .from(_tableName)
          .upsert(profileData)
          .select()
          .single();

      final profile = Map<String, dynamic>.from(response);
      final user = User(
        id: profile['id'] as String,
        name: profile['name'] as String? ?? name,
        email: email,
        profileImageUrl: profile['profile_image_url'] as String?,
        provider: _getProviderFromString(profile['provider'] as String?),
        createdAt: DateTime.parse(profile['created_at'] as String),
      );

      return Success<User>(user);
    } catch (e) {
      return Failure<User>('프로필 저장에 실패했습니다: $e');
    }
  }

  /// 프로필 업데이트
  Future<Result<User>> updateProfile({
    required String userId,
    String? name,
    String? profileImageUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) {
        updateData['name'] = name;
      }
      if (profileImageUrl != null) {
        updateData['profile_image_url'] = profileImageUrl;
      }

      final response = await SupabaseService.client
          .from(_tableName)
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      final profile = Map<String, dynamic>.from(response);

      // email은 auth.users에서 가져오기
      final currentUser = SupabaseService.currentUser;

      final user = User(
        id: profile['id'] as String,
        name: profile['name'] as String? ?? '사용자',
        email: currentUser?.email ?? '',
        profileImageUrl: profile['profile_image_url'] as String?,
        provider: _getProviderFromString(profile['provider'] as String?),
        createdAt: DateTime.parse(profile['created_at'] as String),
      );

      return Success<User>(user);
    } catch (e) {
      return Failure<User>('프로필 업데이트에 실패했습니다: $e');
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

