import 'package:flutter/foundation.dart';
// Firebase 패키지 필요:
// flutter pub add firebase_core firebase_auth firebase_storage
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart' hide User;
// import 'package:firebase_auth/firebase_auth.dart' as firebase show User;
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

/// SupabaseService와 유사한 구조로 Firebase를 초기화하고 접근
/// 
/// 사용 방법:
/// 1. pubspec.yaml에 Firebase 패키지 추가
/// 2. Firebase 프로젝트 설정 (google-services.json, GoogleService-Info.plist)
/// 3. main.dart에서 초기화: await FirebaseService.initialize();
class FirebaseService {
  // Firebase 앱 인스턴스
  // static FirebaseApp? _app;
  
  // Firebase Auth 인스턴스
  // static FirebaseAuth? _auth;
  
  // static FirebaseStorage? _storage;

  /// Firebase 프로젝트 설정 파일을 사용하여 Firebase 초기화
  static Future<void> initialize() async {
    // if (_app != null) return;

    try {
      // .env 파일 로드 (선택사항 - Firebase는 보통 설정 파일 사용)
      // try {
      //   await dotenv.load();
      //   debugPrint('.env 파일 로드 성공 (assets)');
      // } catch (e) {
      //   debugPrint('assets에서 .env 파일 로드 실패: $e');
      // }

      // _app = await Firebase.initializeApp(
      //   options: DefaultFirebaseOptions.currentPlatform,
      // );
      // _auth = FirebaseAuth.instance;
      // _storage = FirebaseStorage.instance;

      debugPrint('Firebase 초기화 완료');
    } catch (e) {
      debugPrint('Firebase 초기화 실패: $e');
      rethrow;
    }
  }

  /// Firebase Auth 인스턴스 가져오기
  // static FirebaseAuth get auth {
  //   if (_auth == null) {
  //     throw Exception('Firebase가 초기화되지 않았습니다. FirebaseService.initialize()를 먼저 호출하세요.');
  //   }
  //   return _auth!;
  // }

  /// Firebase Storage 인스턴스 가져오기
  // static FirebaseStorage get storage {
  //   if (_storage == null) {
  //     throw Exception('Firebase가 초기화되지 않았습니다. FirebaseService.initialize()를 먼저 호출하세요.');
  //   }
  //   return _storage!;
  // }

  /// 현재 사용자 가져오기
  // static firebase.User? get currentUser {
  //   return auth.currentUser;
  // }

  /// 사용자 로그인/로그아웃 상태 변경을 감지하는 스트림
  // static Stream<User?> get authStateChanges {
  //   return auth.authStateChanges();
  // }
}

