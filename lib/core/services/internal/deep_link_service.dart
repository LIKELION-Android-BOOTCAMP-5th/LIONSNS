import 'dart:async';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lionsns/config/router.dart';

/// Android 네이티브에서 받은 deep link를 Flutter 라우터로 전달
class DeepLinkService {
  static const MethodChannel _channel = MethodChannel('com.lionsns/deep_link');
  static GoRouter? _router;
  static String? _pendingPath;
  static String? _initialDeepLinkPath;
  static Timer? _retryTimer;
  
  /// 초기 딥링크 경로 설정
  static void setInitialDeepLink(String? path) {
    _initialDeepLinkPath = path;
  }
  
  /// 초기 딥링크 경로 가져오기
  static String? getInitialDeepLink() {
    final path = _initialDeepLinkPath;
    _initialDeepLinkPath = null;
    return path;
  }

  /// 라우터 등록
  static void initialize(GoRouter router) {
    _router = router;
    _setupListener();
    
    if (_pendingPath != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToPath(_pendingPath!);
        _pendingPath = null;
      });
    }
  }

  /// MethodChannel 리스너 설정
  static void _setupListener() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'handleDeepLink' && call.arguments != null) {
        final path = call.arguments as String;
        _navigateToPath(path);
      } else if (call.method == 'setInitialDeepLink' && call.arguments != null) {
        final path = call.arguments as String;
        setInitialDeepLink(path);
      }
    });
  }

  /// 경로로 이동
  static void _navigateToPath(String path, {int retryCount = 0}) {
    if (_router == null) {
      if (retryCount < 10) {
        _pendingPath = path;
        _retryTimer?.cancel();
        _retryTimer = Timer(Duration(milliseconds: 300 + (retryCount * 100)), () {
          _navigateToPath(path, retryCount: retryCount + 1);
        });
      } else {
        _pendingPath = null;
      }
      return;
    }

    _retryTimer?.cancel();
    _pendingPath = null;

    try {
      if (path.startsWith('/post/')) {
        String? currentLocation;
        try {
          currentLocation = _router!.routerDelegate.currentConfiguration.uri.path;
        } catch (e) {
          // ignore
        }
        
        if (currentLocation == null || currentLocation != AppRoutes.home) {
          _router!.go(AppRoutes.home);
          Future.delayed(const Duration(milliseconds: 150), () {
            _router!.push(path);
          });
        } else {
          _router!.push(path);
        }
      } else if (path == '/login') {
        _router!.go(path);
      } else {
        _router!.go('/');
      }
    } catch (e, stackTrace) {
      if (retryCount < 5) {
        Future.delayed(Duration(milliseconds: 500), () {
          _navigateToPath(path, retryCount: retryCount + 1);
        });
      }
    }
  }
}

