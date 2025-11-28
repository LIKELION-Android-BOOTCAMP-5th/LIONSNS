import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Supabase 네트워크 요청/응답을 로깅하는 HTTP 클라이언트
/// 
/// 개발 환경에서만 상세한 네트워크 로그를 출력합니다.
/// 프로덕션 환경에서는 로깅을 비활성화하여 성능에 영향을 주지 않습니다.
class LoggingHttpClient extends http.BaseClient {
  final http.Client _inner;
  final bool _enableLogging;

  LoggingHttpClient(this._inner, {bool? enableLogging})
      : _enableLogging = enableLogging ?? kDebugMode;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!_enableLogging) {
      return await _inner.send(request);
    }

    final startTime = DateTime.now();
    final requestId = _generateRequestId();

    // 요청 로깅
    _logRequest(request, requestId);

    try {
      // 실제 요청 전송
      final response = await _inner.send(request);

      // 응답 시간 계산
      final duration = DateTime.now().difference(startTime);

      // 응답 로깅 및 새로운 StreamedResponse 반환
      final loggedResponse = await _logResponse(response, requestId, duration);

      return loggedResponse;
    } catch (e, stackTrace) {
      // 에러 로깅
      final duration = DateTime.now().difference(startTime);
      _logError(e, stackTrace, request, requestId, duration);
      rethrow;
    }
  }

  /// 요청 로깅
  void _logRequest(http.BaseRequest request, String requestId) {
    debugPrint('');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[REQUEST] $requestId');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('Method: ${request.method}');
    debugPrint('URL: ${request.url}');

    // 헤더 로깅 (민감 정보 마스킹)
    if (request.headers.isNotEmpty) {
      debugPrint('Headers:');
      request.headers.forEach((key, value) {
        final maskedValue = _maskSensitiveData(key, value);
        debugPrint('  $key: $maskedValue');
      });
    }

    // 바디 로깅
    if (request is http.Request && request.body.isNotEmpty) {
      try {
        final body = request.body;
        // JSON 포맷팅 시도
        if (body.startsWith('{') || body.startsWith('[')) {
          final jsonData = jsonDecode(body);
          final formattedBody = const JsonEncoder.withIndent('  ').convert(jsonData);
          debugPrint('Body:');
          debugPrint(formattedBody);
        } else {
          // JSON이 아닌 경우 그대로 출력 (크기 제한)
          final displayBody = body.length > 1000 
              ? '${body.substring(0, 1000)}... (truncated, total: ${body.length} bytes)'
              : body;
          debugPrint('Body: $displayBody');
        }
      } catch (e) {
        // JSON 파싱 실패 시 원본 출력 (크기 제한)
        final body = request.body;
        final displayBody = body.length > 500 
            ? '${body.substring(0, 500)}... (truncated, total: ${body.length} bytes)'
            : body;
        debugPrint('Body: $displayBody');
      }
    }

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// 응답 로깅 및 새로운 StreamedResponse 반환
  Future<http.StreamedResponse> _logResponse(
    http.StreamedResponse response,
    String requestId,
    Duration duration,
  ) async {
    debugPrint('');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[RESPONSE] $requestId');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('Status: ${response.statusCode} ${response.reasonPhrase ?? ""}');
    debugPrint('Duration: ${duration.inMilliseconds}ms');

    // 헤더 로깅
    if (response.headers.isNotEmpty) {
      debugPrint('Headers:');
      response.headers.forEach((key, value) {
        final maskedValue = _maskSensitiveData(key, value);
        debugPrint('  $key: $maskedValue');
      });
    }

    // 응답 바디 로깅 및 새로운 StreamedResponse 생성
    http.StreamedResponse loggedResponse;
    try {
      // 응답 바디를 바이트로 읽기
      final responseBytes = await response.stream.toList();
      final responseBodyBytes = responseBytes.expand((x) => x).toList();
      final responseBody = utf8.decode(responseBodyBytes);

      // 로깅
      if (responseBody.isNotEmpty) {
        try {
          // JSON 포맷팅 시도
          final jsonData = jsonDecode(responseBody);
          final formattedBody = const JsonEncoder.withIndent('  ').convert(jsonData);
          
          // 큰 응답은 요약만 출력
          if (formattedBody.length > 2000) {
            debugPrint('Body: (truncated, total: ${formattedBody.length} chars)');
            debugPrint(formattedBody.substring(0, 2000));
            debugPrint('...');
          } else {
            debugPrint('Body:');
            debugPrint(formattedBody);
          }
        } catch (e) {
          // JSON이 아닌 경우 그대로 출력 (크기 제한)
          final displayBody = responseBody.length > 1000 
              ? '${responseBody.substring(0, 1000)}... (truncated, total: ${responseBody.length} chars)'
              : responseBody;
          debugPrint('Body: $displayBody');
        }
      }

      // 읽은 바이트로부터 새로운 StreamedResponse 생성
      loggedResponse = http.StreamedResponse(
        http.ByteStream.fromBytes(responseBodyBytes),
        response.statusCode,
        reasonPhrase: response.reasonPhrase,
        headers: response.headers,
        contentLength: response.contentLength,
        request: response.request,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
      );
    } catch (e) {
      debugPrint('Body: (읽기 실패: $e)');
      // 에러 발생 시 원본 응답 반환
      loggedResponse = response;
    }

    // 상태 코드 로깅
    debugPrint('Status: ${response.statusCode}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('');

    return loggedResponse;
  }

  /// 에러 로깅
  void _logError(
    Object error,
    StackTrace stackTrace,
    http.BaseRequest request,
    String requestId,
    Duration duration,
  ) {
    debugPrint('');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[ERROR] $requestId');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('URL: ${request.url}');
    debugPrint('Method: ${request.method}');
    debugPrint('Duration: ${duration.inMilliseconds}ms');
    debugPrint('Error: $error');
    if (kDebugMode) {
      debugPrint('StackTrace:');
      debugPrint(stackTrace.toString());
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('');
  }

  /// 민감한 정보 마스킹
  String _maskSensitiveData(String key, String value) {
    final lowerKey = key.toLowerCase();
    
    // Authorization 헤더 마스킹
    if (lowerKey == 'authorization' || lowerKey == 'apikey') {
      if (value.length > 20) {
        return '${value.substring(0, 10)}...${value.substring(value.length - 4)}';
      }
      return '***';
    }
    
    // 비밀번호 관련 필드 마스킹
    if (lowerKey.contains('password') || 
        lowerKey.contains('secret') || 
        lowerKey.contains('token')) {
      return '***';
    }
    
    return value;
  }

  /// 요청 ID 생성
  String _generateRequestId() {
    return DateTime.now().millisecondsSinceEpoch.toString().substring(7);
  }

  @override
  void close() {
    _inner.close();
  }
}

