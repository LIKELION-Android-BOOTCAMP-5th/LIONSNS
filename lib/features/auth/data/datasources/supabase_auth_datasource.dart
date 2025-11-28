import 'package:flutter/foundation.dart';
import 'package:lionsns/features/auth/models/user.dart';
import 'package:lionsns/features/auth/data/datasources/supabase_profile_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase show User, AuthChangeEvent;
import 'package:lionsns/core/services/external/supabase_service.dart';
import 'package:lionsns/core/services/internal/auth_provider_service.dart';
import 'package:lionsns/core/utils/result.dart';

class SupabaseAuthDatasource {
  final SupabaseProfileDatasource _profileDatasource = SupabaseProfileDatasource();
  
  /// 소셜 로그인 처리
  /// 
  /// 로그인 성공 시 프로필 동기화 및 FCM 토큰 저장 수행
  Future<Result<User?>> snsLogin(AuthProvider provider) async {
    try {
      Result<AuthResponse> result;

      switch (provider) {
        case AuthProvider.google:
          result = await AuthProviderService.loginWithGoogle();
          break;
        case AuthProvider.apple:
          result = await AuthProviderService.loginWithApple();
          break;
        case AuthProvider.kakao:
          result = await AuthProviderService.loginWithKakao();
          break;
        case AuthProvider.naver:
          result = await AuthProviderService.loginWithNaver();
          break;
      }

      if (result is Pending<AuthResponse>) {
        final message = result.message ?? 'OAuth 로그인 진행 중입니다. 브라우저에서 로그인을 완료해주세요.';
        return Pending<User?>(message);
      }
      return await result.when(
        success: (authResponse) async {
          final user = AuthProviderService.authResponseToUser(authResponse);
          await _syncProfile(user);
          _saveFcmToken();
          return Success<User?>(user);
        },
        failure: (message, error) {
          return Future.value(Failure<User?>(message, error));
        },
      );
    } catch (e) {
      return Failure<User?>('SNS 로그인에 실패했습니다: $e');
    }
  }

  /// 현재 로그인된 사용자 정보 조회
  /// 
  /// 1. user_profiles 테이블에서 프로필 조회 시도
  /// 2. 프로필이 없으면 userMetadata에서 생성 후 DB에 저장
  /// 3. email은 auth.users에서 가져옴
  Future<Result<User?>> getCurrentUser() async {
    try {
      final supabaseUser = SupabaseService.currentUser;

      if (supabaseUser == null) {
        return Success<User?>(null);
      }

      final session = SupabaseService.client.auth.currentSession;

      if (session == null) {
        return Success<User?>(null);
      }

      final profileResult = await _profileDatasource.getProfile(supabaseUser.id);

      if (profileResult is Success<User?>) {
        final profileUser = profileResult.data;
        if (profileUser != null) {
          // email은 auth.users에서 가져오기
          final user = User(
            id: profileUser.id,
            name: profileUser.name,
            email: supabaseUser.email ?? '',
            profileImageUrl: profileUser.profileImageUrl,
            provider: profileUser.provider,
            createdAt: profileUser.createdAt,
          );
          return Success<User?>(user);
        }
      }

      // 프로필이 없거나 조회 실패한 경우 userMetadata에서 생성
      final user = User(
        id: supabaseUser.id,
        name: supabaseUser.userMetadata?['full_name'] as String? ??
            supabaseUser.userMetadata?['name'] as String? ??
            supabaseUser.email?.split('@')[0] ?? '사용자',
        email: supabaseUser.email ?? '',
        profileImageUrl: supabaseUser.userMetadata?['avatar_url'] as String?,
        provider: _getProviderFromSupabaseUser(supabaseUser),
        createdAt: DateTime.parse(supabaseUser.createdAt),
      );

      // 프로필 동기화 (데이터베이스에 저장)
      try {
        await _syncProfile(user);
        // 프로필 저장 후 다시 조회하여 최신 정보 반환
        final savedProfileResult = await _profileDatasource.getProfile(user.id);
        if (savedProfileResult is Success<User?>) {
          final savedProfile = savedProfileResult.data;
          if (savedProfile != null) {
            final savedUser = User(
              id: savedProfile.id,
              name: savedProfile.name,
              email: supabaseUser.email ?? '',
              profileImageUrl: savedProfile.profileImageUrl,
              provider: savedProfile.provider,
              createdAt: savedProfile.createdAt,
            );
            return Success<User?>(savedUser);
          }
        }
      } catch (e) {
        // 프로필 동기화 실패해도 로그인은 가능
        debugPrint('[SupabaseAuthDatasource] 프로필 동기화 실패: $e');
      }

      return Success<User?>(user);
    } catch (e) {
      return Failure<User?>('사용자 정보를 불러오는데 실패했습니다: $e');
    }
  }
  
  /// 사용자 프로필을 데이터베이스에 동기화
  /// 
  /// 프로필 동기화 실패는 로그인을 막지 않음
  Future<void> _syncProfile(User user) async {
    try {
      await _profileDatasource.upsertProfile(
        userId: user.id,
        name: user.name,
        email: user.email,
        profileImageUrl: user.profileImageUrl,
        provider: user.provider,
      );
    } catch (e, stackTrace) {
      // 프로필 동기화 실패는 로그인을 막지 않음
      debugPrint('[SupabaseAuthDatasource] 프로필 동기화 실패: $e');
    }
  }

  void _saveFcmToken() {
    // 비동기 작업이므로 await하지 않음 (로그인 속도에 영향 없도록)
    // PushNotificationService.getToken().then((token) {
    //   if (token != null) {
    //     PushNotificationService.saveTokenToSupabase(token);
    //   }
    // }).catchError((error) {
    //   // 토큰 저장 실패는 로그인을 막지 않음
    // });
  }

  /// 로그아웃 처리
  Future<Result<void>> logout() async {
    try {
      await SupabaseService.client.auth.signOut();
      return Success<void>(null as dynamic);
    } catch (e) {
      return Failure<void>('로그아웃에 실패했습니다: $e');
    }
  }

  /// 현재 로그인된 사용자 ID 조회 (동기)
  /// 로그인되지 않은 경우 null 반환
  String? getCurrentUserId() {
    return SupabaseService.currentUser?.id;
  }

  /// 인증 상태 변경 스트림
  Stream<AuthStateChange> get authStateChanges {
    return SupabaseService.authStateChanges.map((authState) {
      final supabaseEvent = authState.event;
      if (supabaseEvent == supabase.AuthChangeEvent.signedIn) {
        return AuthStateChange(AuthChangeEvent.signedIn);
      } else if (supabaseEvent == supabase.AuthChangeEvent.signedOut) {
        return AuthStateChange(AuthChangeEvent.signedOut);
      } else if (supabaseEvent == supabase.AuthChangeEvent.tokenRefreshed) {
        return AuthStateChange(AuthChangeEvent.tokenRefreshed);
      } else if (supabaseEvent == supabase.AuthChangeEvent.userUpdated) {
        return AuthStateChange(AuthChangeEvent.userUpdated);
      } else {
        return AuthStateChange(AuthChangeEvent.signedOut);
      }
    });
  }

  AuthProvider _getProviderFromSupabaseUser(supabase.User supabaseUser) {
    final appMetadata = supabaseUser.appMetadata;
    final provider = appMetadata['provider'] as String?;
    final providerName = provider ?? 'email';

    switch (providerName) {
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

/// 인증 상태 변경 이벤트
enum AuthChangeEvent {
  signedIn,
  signedOut,
  tokenRefreshed,
  userUpdated,
}

/// 인증 상태 변경 데이터
class AuthStateChange {
  final AuthChangeEvent event;
  AuthStateChange(this.event);
}

