import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lionsns/features/auth/models/user.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/core/services/internal/widget_update_service.dart';
import 'package:lionsns/core/services/internal/push_notification_service.dart';
import 'package:lionsns/features/auth/data/datasources/supabase_auth_datasource.dart';

enum AuthState {
  unauthenticated,
  authenticated,
  loading,
}

class AuthViewModel extends StateNotifier<Result<User?>> {
  final SupabaseAuthDatasource _datasource;
  final WidgetUpdateService? _widgetUpdateService;
  StreamSubscription? _authStateSubscription;

  AuthViewModel(
    this._datasource, {
    WidgetUpdateService? widgetUpdateService,
  })  : _widgetUpdateService = widgetUpdateService,
        super(Success<User?>(null)) {
    _loadCurrentUser();
    _listenToAuthStateChanges();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  /// 소셜 로그인 실행
  Future<void> signIn(AuthProvider provider) async {
    state = Pending<User?>('OAuth 로그인 진행 중...');
    final result = await _datasource.snsLogin(provider);

    result.when(
      success: (user) {},
      failure: (message, error) {
        debugPrint('SNS 로그인 실패: $message');
      },
      pending: (message) {},
    );

    state = result;
  }

  /// 현재 로그인된 사용자 정보 로드
  Future<void> _loadCurrentUser() async {
    final result = await _datasource.getCurrentUser();

    result.when(
      success: (user) {
        if (user != null) {
          _widgetUpdateService?.updateWidget();
          // 사용자 정보 로드 성공 시 FCM 토큰 저장
          _saveFcmToken();
        }
      },
      failure: (message, error) {
        debugPrint('사용자 로드 실패: $message');
      },
      pending: (_) {},
    );

    try {
      state = result;
    } catch (e) {
      // dispose된 상태에서 상태 업데이트 시도 방지
    }
  }

  /// 인증 상태 변경 리스너 등록
  void _listenToAuthStateChanges() {
    _authStateSubscription = _datasource.authStateChanges.listen(
      (authStateChange) {
        if (authStateChange.event == AuthChangeEvent.signedIn) {
          _loadCurrentUser().then((_) {
            _widgetUpdateService?.updateWidget();
            
            // 로그인 성공 시 FCM 토큰 저장
            _saveFcmToken();
            
            // 위젯 업데이트가 완료되기 전에 데이터가 반영되지 않을 수 있어 1초 후 재시도
            Future.delayed(const Duration(seconds: 1), () {
              _widgetUpdateService?.updateWidget();
            });
          });
        } else if (authStateChange.event == AuthChangeEvent.signedOut) {
          try {
            state = Success<User?>(null);
            _widgetUpdateService?.clearWidget();
          } catch (e) {
            // dispose된 상태에서 상태 업데이트 시도 무시
          }
        } else if (authStateChange.event == AuthChangeEvent.tokenRefreshed) {
          _loadCurrentUser().then((_) {
            _widgetUpdateService?.updateWidget();
            // 토큰 갱신 시에도 FCM 토큰 저장 (세션 복원 후)
            _saveFcmToken();
          });
        } else if (authStateChange.event == AuthChangeEvent.userUpdated) {
          _loadCurrentUser().then((_) {
            _widgetUpdateService?.updateWidget();
          });
        }
      },
      onError: (error) {
        // Deep link 처리 중 발생하는 오류는 무시
      },
    );
  }

  String _getProviderName(AuthProvider provider) {
    switch (provider) {
      case AuthProvider.google:
        return 'Google';
      case AuthProvider.apple:
        return 'Apple';
      case AuthProvider.kakao:
        return '카카오';
      case AuthProvider.naver:
        return '네이버';
    }
  }

  /// 로그아웃 처리
  Future<void> logout() async {
    final result = await _datasource.logout();
    result.when(
      success: (_) {
        try {
          state = Success<User?>(null);
        } catch (e) {
          // dispose된 상태에서 상태 업데이트 시도 방지
        }
      },
      failure: (message, error) {
        debugPrint('로그아웃 실패: $message');
      },
      pending: (_) {},
    );
  }

  /// 인증 상태 새로고침
  Future<void> refresh() async {
    try {
      await _loadCurrentUser();
    } catch (e) {
      // dispose된 상태에서 refresh 시도 방지
    }
  }

  /// FCM 토큰 저장
  /// 
  /// 로그인 성공 시 또는 사용자 정보 로드 시 FCM 토큰을 Supabase에 저장합니다.
  void _saveFcmToken() {
    try {
      // 비동기로 처리하되 결과는 기다리지 않음 (실패해도 로그인 플로우에 영향 없음)
      PushNotificationService.getToken().then((token) {
        if (token != null) {
          PushNotificationService.saveTokenToSupabase(token);
        }
      }).catchError((error) {
        debugPrint('FCM 토큰 저장 실패: $error');
      });
    } catch (e) {
      // FCM 토큰 저장 실패는 무시
    }
  }
}
