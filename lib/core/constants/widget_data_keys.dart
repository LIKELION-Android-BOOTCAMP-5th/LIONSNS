/// 위젯 데이터 키 정의
/// SharedPreferences에서 사용하는 키
/// 
/// 주의: 동기화 필수 - Android의 WidgetDataKeys.kt와 동기화되어야 합니다.
/// 
/// Note: Flutter의 SharedPreferences는 키 앞에 'flutter.' 프리픽스를 자동으로 추가합니다.
/// 따라서 이 파일에서 정의한 키 앞에 'flutter.'가 자동으로 붙어서 저장됩니다.
/// 예: 'widget_data_userId' -> 'flutter.widget_data_userId'
/// 
/// Android 네이티브 코드(WidgetDataKeys.kt)에서는 'flutter.widget_data_xxx' 형태로 읽어야 합니다.
/// 키 값을 변경할 때는 반드시 두 파일을 모두 업데이트하세요.
class WidgetDataKeys {
  static const String _keyPrefix = 'widget_data_';
  
  // SharedPreferences에 저장되는 키 (flutter. 프리픽스는 자동 추가됨)
  static const String userId = '${_keyPrefix}userId';
  static const String totalPostsCount = '${_keyPrefix}totalPostsCount';
  static const String totalLikesCount = '${_keyPrefix}totalLikesCount';
  static const String totalCommentsCount = '${_keyPrefix}totalCommentsCount';
  static const String recentPostId = '${_keyPrefix}recentPostId';
  static const String recentPostTitle = '${_keyPrefix}recentPostTitle';
  static const String recentPostPreview = '${_keyPrefix}recentPostPreview';
  static const String recentPostCreatedAt = '${_keyPrefix}recentPostCreatedAt';
  // Glance 상태 변경 감지를 위한 타임스탬프
  static const String updateTimestamp = '${_keyPrefix}updateTimestamp';
}

