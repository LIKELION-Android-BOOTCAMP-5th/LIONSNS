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

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.lionsns/widget"
    private val DEEP_LINK_CHANNEL = "com.lionsns/deep_link"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        val initialData = intent?.data
        if (initialData != null && initialData.scheme == "glance-action") {
            val processedIntent = Intent(intent).apply {
                setData(null)
            }
            setIntent(processedIntent)
        }
        
        super.configureFlutterEngine(flutterEngine)
        
        val deepLinkChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEEP_LINK_CHANNEL)
        
        deepLinkChannel.setMethodCallHandler { call, result ->
            result.notImplemented()
        }
        
        val extractedDeepLinkPath = _extractDeepLinkPath(intent)
        if (extractedDeepLinkPath != null) {
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                deepLinkChannel.invokeMethod("setInitialDeepLink", extractedDeepLinkPath, object : MethodChannel.Result {
                    override fun success(result: Any?) {}
                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}
                    override fun notImplemented() {}
                })
            }, 100)
        }
        
        val initialPostId = intent?.getStringExtra("postId")
        val initialDeepLinkPath = intent?.getStringExtra("deepLinkPath")
        val intentData = intent?.data
        
        if (initialPostId != null || initialDeepLinkPath != null) {
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                handleDeepLink(intent, deepLinkChannel)
            }, 1000)
        } else if (intentData != null && intentData.scheme != "glance-action") {
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                handleDeepLink(intent, deepLinkChannel)
            }, 1000)
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    CoroutineScope(Dispatchers.Main).launch {
                        try {
                            kotlinx.coroutines.delay(1000)
                            
                            val appWidgetManager = android.appwidget.AppWidgetManager.getInstance(applicationContext)
                            val widgetReceiver = HomeWidgetReceiver()
                            val componentName = android.content.ComponentName(applicationContext, HomeWidgetReceiver::class.java)
                            val widgetIds = appWidgetManager.getAppWidgetIds(componentName)
                            
                            if (widgetIds.isNotEmpty()) {
                                val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", android.content.Context.MODE_PRIVATE)
                                val currentTimestamp = System.currentTimeMillis().toString()
                                prefs.edit().putString("flutter.widget_data_updateTimestamp", currentTimestamp).commit()
                                
                                kotlinx.coroutines.delay(500)
                                widgetReceiver.glanceAppWidget.updateAll(applicationContext)
                            }
                            
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", "위젯 업데이트 실패: ${e.message}", null)
                        }
                    }
                }
                "clearWidget" -> {
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
        
        val data = intent.data
        val processedIntent = if (data != null && data.scheme == "glance-action") {
            Intent(intent).apply {
                setData(null)
            }
        } else {
            intent
        }
        
        setIntent(processedIntent)
        
        val postId = intent.getStringExtra("postId")
        val deepLinkPath = intent.getStringExtra("deepLinkPath")
        
        if (data != null && data.scheme == "glance-action" && postId == null && deepLinkPath == null) {
            return
        }
        
        val messenger = flutterEngine?.dartExecutor?.binaryMessenger
        if (messenger != null) {
            val deepLinkChannel = MethodChannel(messenger, DEEP_LINK_CHANNEL)
            handleDeepLink(intent, deepLinkChannel)
        }
    }

    private fun _extractDeepLinkPath(intent: Intent?): String? {
        if (intent == null) return null
        
        val data = intent.data
        val deepLinkPath = intent.getStringExtra("deepLinkPath")
        val postId = intent.getStringExtra("postId")
        
        if (deepLinkPath != null && deepLinkPath.isNotEmpty()) {
            return deepLinkPath
        }
        
        if (postId != null && postId.isNotEmpty()) {
            return "/post/$postId"
        }
        
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
            return
        }
        
        val data = intent.data
        val deepLinkPath = intent.getStringExtra("deepLinkPath")
        val postId = intent.getStringExtra("postId")
        
        if (deepLinkPath != null && deepLinkPath.isNotEmpty()) {
            _sendDeepLinkToFlutter(channel, deepLinkPath, immediate = true)
            return
        }
        
        if (postId != null && postId.isNotEmpty()) {
            val path = "/post/$postId"
            _sendDeepLinkToFlutter(channel, path, immediate = true)
            return
        }
        
        if (data != null && data.scheme == "lionsns") {
            val path = data.path ?: ""
            if (path.isNotEmpty()) {
                _sendDeepLinkToFlutter(channel, path)
            }
        }
    }
    
    private fun _sendDeepLinkToFlutter(channel: MethodChannel, path: String, immediate: Boolean = false) {
        val delayMillis = if (immediate) 0 else 300
        
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            channel.invokeMethod("handleDeepLink", path, object : MethodChannel.Result {
                override fun success(result: Any?) {}
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}
                override fun notImplemented() {}
            })
        }, delayMillis.toLong())
    }
}
