package com.example.communityapp.widget

/**
 * 위젯 데이터 키 정의
 * SharedPreferences에서 읽어올 데이터의 키
 * 
 * 주의: 동기화 필수 - Flutter의 lib/core/constants/widget_data_keys.dart와 동기화되어야 합니다.
 * 
 * Note: Flutter의 SharedPreferences는 키 앞에 'flutter.' 프리픽스를 자동으로 추가합니다.
 * 따라서 Flutter에서 'widget_data_xxx' 형태로 저장하면, 실제로는 'flutter.widget_data_xxx'로 저장됩니다.
 * 이 파일에서는 실제 저장되는 키 값('flutter.widget_data_xxx')을 사용합니다.
 * 
 * 키 값을 변경할 때는 반드시 Flutter의 widget_data_keys.dart도 함께 업데이트하세요.
 */
object WidgetDataKeys {
    const val USER_ID = "flutter.widget_data_userId"
    const val TOTAL_POSTS = "flutter.widget_data_totalPostsCount"
    const val TOTAL_LIKES = "flutter.widget_data_totalLikesCount"
    const val TOTAL_COMMENTS = "flutter.widget_data_totalCommentsCount"
    const val RECENT_POST_ID = "flutter.widget_data_recentPostId"
    const val RECENT_POST_TITLE = "flutter.widget_data_recentPostTitle"
    const val RECENT_POST_PREVIEW = "flutter.widget_data_recentPostPreview"
    const val RECENT_POST_CREATED_AT = "flutter.widget_data_recentPostCreatedAt"
    // Glance 상태 변경 감지를 위한 타임스탬프
    const val UPDATE_TIMESTAMP = "flutter.widget_data_updateTimestamp"
}

