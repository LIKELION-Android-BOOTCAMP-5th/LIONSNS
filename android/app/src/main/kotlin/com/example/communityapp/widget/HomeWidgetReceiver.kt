package com.example.communityapp.widget

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.state.PreferencesGlanceStateDefinition

/**
 * 위젯 리시버
 * 위젯 업데이트를 처리하고 SharedPreferences에서 데이터를 읽어와 위젯 상태에 저장
 */
class HomeWidgetReceiver : GlanceAppWidgetReceiver() {

    override val glanceAppWidget: GlanceAppWidget = HomeWidget()

}
