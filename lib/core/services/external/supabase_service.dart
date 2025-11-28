import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase show User;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'network/logging_http_client.dart';

class SupabaseService {
  static SupabaseClient? _client;

  static Future<void> initialize() async {
    if(_client != null) return;

    try {
      try {
        await dotenv.load();
        debugPrint('.env 파일 로드 성공 (assets)');
      } catch (e) {
        debugPrint('assets에서 .env 파일 로드 실패: $e');
        // assets에서 로드 실패 시 프로젝트 루트에서 시도 (개발 환경용)
        try {
          await dotenv.load(fileName: '.env');
          debugPrint('.env 파일 로드 성공 (프로젝트 루트)');
        } catch (e2) {
          debugPrint('.env 파일 로드 실패: $e2');
        }
      }

      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
      
      if (supabaseUrl == null || supabaseAnonKey == null) {
        final errorMsg = 'Supabase URL 또는 Anon Key가 설정되지 않았습니다.\n'
            'SUPABASE_URL: ${supabaseUrl ?? "없음"}\n'
            'SUPABASE_ANON_KEY: ${supabaseAnonKey != null ? "설정됨" : "없음"}\n'
            '.env 파일을 확인하고 flutter clean && flutter pub get을 실행한 후 앱을 다시 빌드하세요.';
        debugPrint('$errorMsg');
        throw Exception(errorMsg);
      }

      final httpClient = kDebugMode
          ? LoggingHttpClient(http.Client())
          : http.Client();

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
        httpClient: httpClient,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
          detectSessionInUri: true,
        ),
      );

      _client = Supabase.instance.client;
      debugPrint('Supabase 초기화 완료');
      
      final redirectUrl = dotenv.env['REDIRECT_URL'] ?? 'com.example.communityapp://callback';
      debugPrint('Deep link URL Scheme: $redirectUrl');
    } catch (e) {
      debugPrint('Supabase 초기화 실패: $e');
      rethrow;
    }
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase가 초기화되지 않았습니다. SupabaseService.initialize()를 먼저 호출하세요.');
    }
    return _client!;
  }

  static supabase.User? get currentUser {
    return client.auth.currentUser;
  }

  static Stream<AuthState> get authStateChanges {
    return client.auth.onAuthStateChange;
  }

  static Future<FunctionResponse> invokeFunction(
      String functionName, {
        Map<String, dynamic>? body,
      }) async {
    return await client.functions.invoke(
      functionName,
      body: body,
    );
  }
}