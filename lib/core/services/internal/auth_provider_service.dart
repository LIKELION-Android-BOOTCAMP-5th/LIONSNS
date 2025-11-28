import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lionsns/features/auth/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase show User;
import 'package:url_launcher/url_launcher.dart';
import '../../utils/result.dart';

class AuthProviderService {
  /// Google 소셜 로그인
  /// 
  /// LaunchMode.platformDefault: Android에서 Chrome Custom Tabs 사용
  /// 로그인 완료 후 deep link로 돌아올 때 브라우저가 자동으로 닫힘
  static Future<Result<AuthResponse>> loginWithGoogle() async {
    try {
      final redirectUrl = dotenv.env['REDIRECT_URL'];
      if (redirectUrl == null) {
        throw Exception('Redirect URL이 설정되지 않았습니다. .env 파일을 확인하세요.');
      }
      
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.platformDefault,
      );
      return Pending('OAuth 로그인이 진행중입니다.브라우저에서 로그인을 완료해주세요!');
    } catch (e) {
      return Failure('Google 로그인에 실패했습니다 : $e');
    }
  }

  /// Apple 소셜 로그인
  static Future<Result<AuthResponse>> loginWithApple() async {
    return Pending('OAuth 로그인이 진행중입니다.브라우저에서 로그인을 완료해주세요!');
  }

  /// Kakao 소셜 로그인
  static Future<Result<AuthResponse>> loginWithKakao() async {
    return Pending('OAuth 로그인이 진행중입니다.브라우저에서 로그인을 완료해주세요!');
  }

  /// Naver 소셜 로그인
  /// 
  /// Supabase는 네이버를 네이티브 지원하지 않으므로 커스텀 OAuth provider 사용
  /// Supabase 대시보드에서 "naver"라는 이름으로 커스텀 OAuth provider 설정 필요
  static Future<Result<AuthResponse>> loginWithNaver() async {
    try {
      final redirectUrl = dotenv.env['REDIRECT_URL'];
      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      if (redirectUrl == null || supabaseUrl == null) {
        throw Exception('Redirect URL 또는 Supabase URL이 설정되지 않았습니다. .env 파일을 확인하세요.');
      }
      
      final customProviderUrl = '$supabaseUrl/auth/v1/authorize?provider=naver&redirect_to=$redirectUrl';
      
      final uri = Uri.parse(customProviderUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
        return Pending('OAuth 로그인이 진행중입니다.브라우저에서 로그인을 완료해주세요!');
      } else {
        throw Exception('URL을 열 수 없습니다: $customProviderUrl');
      }
    } catch (e) {
      return Failure('네이버 로그인에 실패했습니다 : $e');
    }
  }

  /// AuthResponse를 User 모델로 변환
  /// 
  /// 사용자 이름 우선순위: full_name > name > email의 @ 앞부분 > '사용자'
  static User authResponseToUser(AuthResponse authResponse) {
    final user = authResponse.user;
    if(user == null) {
      throw Exception('사용자 정보가 없습니다.');
    }
    final userMetadata = user.userMetadata ?? {};
    return User(
      id: user.id,
      name: userMetadata['full_name'] as String? ??
        userMetadata['name'] as String? ??
          (user.email?.split('@')[0] ?? '사용자'),
      email: user.email ?? '',
      profileImageUrl: userMetadata['avatar_url'] as String?,
      provider: _getProviderFromSupabaseUser(user),
      createdAt: DateTime.parse(user.createdAt)
    );
  }

  static AuthProvider _getProviderFromSupabaseUser(supabase.User supabaseUser) {
    final appMetadata = supabaseUser.appMetadata;
    final provider = appMetadata['provider'] as String? ?? 'email';

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