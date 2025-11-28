import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lionsns/core/services/internal/widget_update_service.dart';

final widgetUpdateServiceProvider = Provider<WidgetUpdateService>((ref) {
  return WidgetUpdateService();
});

