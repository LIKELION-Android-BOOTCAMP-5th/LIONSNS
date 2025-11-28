import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lionsns/core/services/internal/widget_data_service.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/core/constants/widget_data_keys.dart';

/// Method Channel을 통해 네이티브 코드에 위젯 업데이트 요청
class WidgetUpdateService {
  static const MethodChannel _channel = MethodChannel('com.lionsns/widget');

  final WidgetDataService _widgetDataService = WidgetDataService();

  /// 위젯 데이터를 업데이트하고 네이티브 위젯에 알림
  Future<void> updateWidget() async {
    try {
      final result = await _widgetDataService.updateWidgetData();
      
      if (result is Success<WidgetData>) {
        await Future.delayed(const Duration(milliseconds: 1000));
        
        bool isDataSaved = false;
        for (int i = 0; i < 5; i++) {
          final prefs = await SharedPreferences.getInstance();
          final savedUserId = prefs.getString(WidgetDataKeys.userId);
          
          if (savedUserId != null && savedUserId.isNotEmpty) {
            isDataSaved = true;
            break;
          }
          
          if (i < 4) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
        }
        
        if (!isDataSaved) {
          return;
        }
        
        await Future.delayed(const Duration(milliseconds: 500));
        await _channel.invokeMethod('updateWidget');
      }
    } catch (e) {
      // ignore
    }
  }

  /// 위젯 데이터 삭제
  Future<void> clearWidget() async {
    try {
      await _widgetDataService.clearWidgetData();
      _channel.invokeMethod('clearWidget');
    } catch (e) {
      // ignore
    }
  }
}

