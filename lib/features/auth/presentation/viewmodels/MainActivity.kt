package com.example.communityapp

import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.communityapp.widget.HomeWidgetReceiver
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import androidx.glance.appwidget.updateAll
import androidx.glance.GlanceId

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.lionsns/widget"
    private val DEEP_LINK_CHANNEL = "com.lionsns/deep_link"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Deep Link 채널 설정 및 리스너 등록
        val deepLinkChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEEP_LINK_CHANNEL)
        
        // Deep Link 채널 리스너 설정
        deepLinkChannel.setMethodCallHandler { call, result ->
            // Flutter 쪽에서 호출할 메서드가 있으면 여기서 처리
            result.notImplemented()
        }
        
        // 초기 Intent에서 딥링크 경로 추출 및 Flutter에 전달 (라우터 초기화 전)
        val initialDeepLinkPath = _extractDeepLinkPath(intent)
        if (initialDeepLinkPath != null) {
            android.util.Log.d("MainActivity", "초기 딥링크 경로 추출: $initialDeepLinkPath")
            // Flutter가 준비되면 즉시 초기 딥링크 경로를 전달 (라우터 초기화 전에 전달)
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                deepLinkChannel.invokeMethod("setInitialDeepLink", initialDeepLinkPath, object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        android.util.Log.d("MainActivity", "초기 딥링크 경로 전달 성공")
                    }
                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        android.util.Log.e("MainActivity", "초기 딥링크 경로 전달 실패: $errorMessage")
                    }
                    override fun notImplemented() {
                        android.util.Log.e("MainActivity", "초기 딥링크 경로 전달 - notImplemented")
                    }
                })
            }, 100) // 매우 짧은 지연 (Flutter 바인딩만 준비되면 됨)
        }
        
        // 초기 Intent에서 deep link 처리 (Flutter가 준비될 때까지 약간 지연)
        // glance-action:// Intent는 딥링크 처리를 하지 않음
        val initialData = intent?.data
        if (initialData == null || initialData.scheme != "glance-action") {
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                handleDeepLink(intent, deepLinkChannel)
            }, 1000) // 1초 지연으로 Flutter 초기화 대기
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    // Glance 위젯 업데이트 (suspend 함수이므로 coroutine에서 호출)
                    CoroutineScope(Dispatchers.Main).launch {
                        try {
                            android.util.Log.d("MainActivity", "위젯 업데이트 요청 받음")
                            // 위젯 업데이트 전에 약간의 지연을 두어 SharedPreferences 동기화 보장
                            kotlinx.coroutines.delay(500)
                            
                            // 모든 위젯 ID를 가져와서 각각 업데이트
                            val appWidgetManager = android.appwidget.AppWidgetManager.getInstance(applicationContext)
                            val widgetReceiver = HomeWidgetReceiver()
                            val componentName = android.content.ComponentName(applicationContext, HomeWidgetReceiver::class.java)
                            val widgetIds = appWidgetManager.getAppWidgetIds(componentName)
                            
                            android.util.Log.d("MainActivity", "위젯 ID 목록: ${widgetIds.contentToString()}")
                            
                            if (widgetIds.isNotEmpty()) {
                                // 각 위젯 인스턴스를 개별적으로 업데이트
                                widgetIds.forEach { widgetId ->
                                    android.util.Log.d("MainActivity", "위젯 인스턴스 업데이트: $widgetId")
                                    widgetReceiver.glanceAppWidget.update(applicationContext, androidx.glance.GlanceId(widgetId))
                                }
                            } else {
                                // 위젯 ID가 없으면 updateAll 호출
                                widgetReceiver.glanceAppWidget.updateAll(applicationContext)
                            }
                            
                            android.util.Log.d("MainActivity", "위젯 업데이트 완료")
                            result.success(true)
                        } catch (e: Exception) {
                            android.util.Log.e("MainActivity", "위젯 업데이트 실패: ${e.message}", e)
                            result.error("ERROR", "위젯 업데이트 실패: ${e.message}", null)
                        }
                    }
                }
                "clearWidget" -> {
                    // 위젯 데이터 삭제 후 업데이트
                    CoroutineScope(Dispatchers.Main).launch {
                        try {
                            HomeWidgetReceiver().glanceAppWidget.updateAll(applicationContext)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", "위젯 클리어 실패: ${e.message}", null)
                        }
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Intent 정보 로깅
        android.util.Log.d("MainActivity", "onNewIntent - data: ${intent.data}, postId: ${intent.getStringExtra("postId")}, deepLinkPath: ${intent.getStringExtra("deepLinkPath")}")
        
        // glance-action:// Intent는 무시하지 않고, extra를 확인 후 처리
        val data = intent.data
        // postId나 deepLinkPath가 있으면 처리 (glance-action이어도)
        val postId = intent.getStringExtra("postId")
        val deepLinkPath = intent.getStringExtra("deepLinkPath")
        
        if (data != null && data.scheme == "glance-action" && postId == null && deepLinkPath == null) {
            // glance-action Intent이면서 extra가 없는 경우만 무시
            android.util.Log.d("MainActivity", "glance-action Intent 무시 (extra 없음)")
            return
        }
        
        // Deep Link 처리
        android.util.Log.d("MainActivity", "onNewIntent - flutterEngine: ${flutterEngine != null}, binaryMessenger: ${flutterEngine?.dartExecutor?.binaryMessenger != null}")
        val messenger = flutterEngine?.dartExecutor?.binaryMessenger
        if (messenger != null) {
            android.util.Log.d("MainActivity", "onNewIntent - handleDeepLink 호출 시작")
            val deepLinkChannel = MethodChannel(messenger, DEEP_LINK_CHANNEL)
            handleDeepLink(intent, deepLinkChannel)
        } else {
            android.util.Log.e("MainActivity", "onNewIntent - binaryMessenger가 null이므로 딥링크 처리 불가")
        }
    }

    /// Intent에서 딥링크 경로 추출 (라우터 초기화 전에 사용)
    private fun _extractDeepLinkPath(intent: Intent?): String? {
        if (intent == null) return null
        
        val data = intent.data
        val deepLinkPath = intent.getStringExtra("deepLinkPath")
        val postId = intent.getStringExtra("postId")
        
        // 1. Intent extra에서 deepLinkPath 확인 (가장 우선순위 높음)
        if (deepLinkPath != null && deepLinkPath.isNotEmpty()) {
            return deepLinkPath
        }
        
        // 2. Intent extra에서 postId 확인
        if (postId != null && postId.isNotEmpty()) {
            return "/post/$postId"
        }
        
        // 3. Intent data에서 deep link 확인 (lionsns://post/{postId})
        if (data != null && data.scheme == "lionsns") {
            val path = data.path
            if (path != null && path.isNotEmpty()) {
                return path
            }
        }
        
        return null
    }
    
    private fun handleDeepLink(intent: Intent?, channel: MethodChannel?) {
        if (channel == null || intent == null) {
            android.util.Log.d("MainActivity", "handleDeepLink - channel 또는 intent가 null")
            return
        }
        
        android.util.Log.d("MainActivity", "handleDeepLink 호출됨")
        
        // 0. glance-action:// 스킴은 무시하지 않음 (extra 확인 후 처리)
        val data = intent.data
        val deepLinkPath = intent.getStringExtra("deepLinkPath")
        val postId = intent.getStringExtra("postId")
        
        android.util.Log.d("MainActivity", "handleDeepLink - data: $data, deepLinkPath: $deepLinkPath, postId: $postId")
        
        // 1. Intent extra에서 deepLinkPath 확인 (위젯 로그인 버튼 등) - 가장 우선순위 높음
        if (deepLinkPath != null && deepLinkPath.isNotEmpty()) {
            android.util.Log.d("MainActivity", "deepLinkPath로 딥링크 전달: $deepLinkPath")
            _sendDeepLinkToFlutter(channel, deepLinkPath)
            return
        }
        
        // 2. Intent extra에서 postId 확인 (위젯에서 전달)
        if (postId != null && postId.isNotEmpty()) {
            val path = "/post/$postId"
            android.util.Log.d("MainActivity", "postId로 딥링크 전달: $path")
            _sendDeepLinkToFlutter(channel, path)
            return
        }
        
        // 3. Intent data에서 deep link 확인 (lionsns://post/{postId})
        if (data != null && data.scheme == "lionsns") {
            val path = data.path ?: ""
            if (path.isNotEmpty()) {
                android.util.Log.d("MainActivity", "lionsns 스킴으로 딥링크 전달: $path")
                _sendDeepLinkToFlutter(channel, path)
            }
        }
    }
    
    private fun _sendDeepLinkToFlutter(channel: MethodChannel, path: String) {
        android.util.Log.d("MainActivity", "_sendDeepLinkToFlutter 호출 - path: $path")
        // Flutter가 준비될 때까지 충분한 지연 (1.5초)
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            android.util.Log.d("MainActivity", "Flutter로 딥링크 전달 시도 - path: $path")
            channel.invokeMethod("handleDeepLink", path, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    android.util.Log.d("MainActivity", "딥링크 전달 성공 - result: $result")
                }
                
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    android.util.Log.e("MainActivity", "딥링크 전달 실패 - errorCode: $errorCode, errorMessage: $errorMessage")
                }
                
                override fun notImplemented() {
                    android.util.Log.e("MainActivity", "딥링크 전달 - notImplemented (Flutter에서 처리되지 않음)")
                }
            })
        }, 1500) // Flutter 앱이 완전히 준비될 때까지 1.5초 대기
    }
}
