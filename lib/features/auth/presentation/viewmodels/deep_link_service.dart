import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Deep Link 처리 서비스
/// Android 네이티브에서 받은 deep link를 Flutter 라우터로 전달
class DeepLinkService {
  static const MethodChannel _channel = MethodChannel('com.lionsns/deep_link');
  static GoRouter? _router;
  static String? _pendingPath;
  static String? _initialDeepLinkPath; // 앱 cold start 시 초기 딥링크 경로
  static Timer? _retryTimer;
  
  /// 초기 딥링크 경로 설정 (앱 cold start 시 호출)
  static void setInitialDeepLink(String? path) {
    _initialDeepLinkPath = path;
    debugPrint('DeepLinkService - 초기 딥링크 경로 설정: $path');
  }
  
  /// 초기 딥링크 경로 가져오기
  static String? getInitialDeepLink() {
    final path = _initialDeepLinkPath;
    _initialDeepLinkPath = null; // 사용 후 제거
    return path;
  }

  /// 라우터 등록 (앱 시작 시 호출)
  static void initialize(GoRouter router) {
    _router = router;
    _setupListener();
    debugPrint('DeepLinkService 초기화 완료');
    
    // 대기 중인 딥링크가 있으면 처리
    if (_pendingPath != null) {
      debugPrint('DeepLinkService - 대기 중인 딥링크 처리: $_pendingPath');
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToPath(_pendingPath!);
        _pendingPath = null;
      });
    }
    
    // 초기 딥링크가 initialLocation으로 사용되지 않은 경우 처리
    // (라우터가 이미 초기 딥링크 경로로 초기화된 경우에는 불필요)
  }

  /// MethodChannel 리스너 설정
  static void _setupListener() {
    _channel.setMethodCallHandler((call) async {
      debugPrint('DeepLinkService - MethodChannel 호출: method=${call.method}, arguments=${call.arguments}');
      if (call.method == 'handleDeepLink' && call.arguments != null) {
        final path = call.arguments as String;
        debugPrint('DeepLinkService - 딥링크 경로 받음: $path');
        _navigateToPath(path);
      } else if (call.method == 'setInitialDeepLink' && call.arguments != null) {
        final path = call.arguments as String;
        debugPrint('DeepLinkService - 초기 딥링크 경로 받음: $path');
        setInitialDeepLink(path);
      }
    });
    debugPrint('DeepLinkService - MethodChannel 리스너 설정 완료');
  }

  /// 경로로 이동 (재시도 로직 포함)
  static void _navigateToPath(String path, {int retryCount = 0}) {
    debugPrint('DeepLinkService - 경로 이동 시도: $path, router: ${_router != null ? "있음" : "없음"}, retryCount: $retryCount');
    
    if (_router == null) {
      // 라우터가 아직 준비되지 않았으면 대기 후 재시도
      if (retryCount < 10) {
        debugPrint('DeepLinkService - 라우터가 없음, 대기 중... ($retryCount/10)');
        _pendingPath = path;
        _retryTimer?.cancel();
        _retryTimer = Timer(Duration(milliseconds: 300 + (retryCount * 100)), () {
          _navigateToPath(path, retryCount: retryCount + 1);
        });
      } else {
        debugPrint('DeepLinkService - 라우터 준비 대기 시간 초과, 딥링크 처리 실패');
        _pendingPath = null;
      }
      return;
    }

    _retryTimer?.cancel();
    _pendingPath = null;

    // 라우터가 준비되었으므로 경로로 이동
    try {
      if (path.startsWith('/post/')) {
        debugPrint('DeepLinkService - 게시물 상세 페이지로 이동: $path');
        // 약간의 지연 후 이동하여 Flutter 위젯 트리가 완전히 빌드되도록 함
        Future.delayed(const Duration(milliseconds: 300), () {
          _router!.go(path);
        });
      } else if (path == '/login') {
        debugPrint('DeepLinkService - 로그인 페이지로 이동: $path');
        Future.delayed(const Duration(milliseconds: 300), () {
          _router!.go(path);
        });
      } else {
        debugPrint('DeepLinkService - 알 수 없는 경로, 홈으로 이동: $path');
        Future.delayed(const Duration(milliseconds: 300), () {
          _router!.go('/');
        });
      }
    } catch (e) {
      debugPrint('DeepLinkService - 경로 이동 중 오류: $e');
      // 오류 발생 시 재시도
      if (retryCount < 5) {
        Future.delayed(Duration(milliseconds: 500), () {
          _navigateToPath(path, retryCount: retryCount + 1);
        });
      }
    }
  }
}

