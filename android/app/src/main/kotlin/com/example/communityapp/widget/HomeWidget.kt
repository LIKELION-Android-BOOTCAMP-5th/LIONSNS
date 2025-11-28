package com.example.communityapp.widget

import android.content.Context
import android.content.Intent
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.appWidgetBackground
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.state.PreferencesGlanceStateDefinition
import com.example.communityapp.MainActivity
import com.example.communityapp.R
import com.example.communityapp.widget.WidgetDataKeys

/**
 * 홈 화면 위젯 - Jetpack Compose Glance로 구현
 */
class HomeWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*> = PreferencesGlanceStateDefinition

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val sharedPrefs = context.getSharedPreferences(
                "FlutterSharedPreferences",
                Context.MODE_PRIVATE
            )
            
            val totalPosts = try {
                sharedPrefs.getInt(WidgetDataKeys.TOTAL_POSTS, 0)
            } catch (e: Exception) {
                try {
                    sharedPrefs.getLong(WidgetDataKeys.TOTAL_POSTS, 0L).toInt()
                } catch (e2: Exception) {
                    0
                }
            }
            val totalLikes = try {
                sharedPrefs.getInt(WidgetDataKeys.TOTAL_LIKES, 0)
            } catch (e: Exception) {
                try {
                    sharedPrefs.getLong(WidgetDataKeys.TOTAL_LIKES, 0L).toInt()
                } catch (e2: Exception) {
                    0
                }
            }
            val totalComments = try {
                sharedPrefs.getInt(WidgetDataKeys.TOTAL_COMMENTS, 0)
            } catch (e: Exception) {
                try {
                    sharedPrefs.getLong(WidgetDataKeys.TOTAL_COMMENTS, 0L).toInt()
                } catch (e2: Exception) {
                    0
                }
            }
            
            val userId = sharedPrefs.getString(WidgetDataKeys.USER_ID, null)
            val isLoggedIn = userId != null && userId.isNotEmpty()
            
            val recentPostId = sharedPrefs.getString(WidgetDataKeys.RECENT_POST_ID, null)
            val recentPostTitle =
                sharedPrefs.getString(WidgetDataKeys.RECENT_POST_TITLE, null) ?: ""
            val recentPostPreview =
                sharedPrefs.getString(WidgetDataKeys.RECENT_POST_PREVIEW, null) ?: ""

            val widgetBg = ColorProvider(R.color.widget_background)
            val textPrimary = ColorProvider(R.color.widget_text_primary)
            val textSecondary = ColorProvider(R.color.widget_text_secondary)
            val statColor = ColorProvider(R.color.widget_stat_color)
            val dividerColor = ColorProvider(R.color.widget_divider)

            val appIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                addCategory(Intent.CATEGORY_DEFAULT)
            }

            Column(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .appWidgetBackground()
                    .background(widgetBg)
                    .cornerRadius(16.dp)
                    .padding(16.dp),
                verticalAlignment = Alignment.Vertical.CenterVertically,
                horizontalAlignment = Alignment.Horizontal.CenterHorizontally
            ) {
                Text(
                    text = "Lion SNS",
                    style = TextStyle(
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp,
                        color = textPrimary
                    ),
                    modifier = GlanceModifier.fillMaxWidth()
                )

                Spacer(modifier = GlanceModifier.height(16.dp))

                if (!isLoggedIn) {
                    val loginIntent = Intent(context, MainActivity::class.java).apply {
                        action = Intent.ACTION_VIEW
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                        addCategory(Intent.CATEGORY_DEFAULT)
                        putExtra("deepLinkPath", "/login")
                    }
                    
                    Column(
                        modifier = GlanceModifier
                            .fillMaxWidth()
                            .clickable(actionStartActivity(loginIntent)),
                        horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
                        verticalAlignment = Alignment.Vertical.CenterVertically
                    ) {
                        Text(
                            text = "로그인이 필요합니다",
                            style = TextStyle(
                                fontSize = 14.sp,
                                color = textSecondary
                            )
                        )
                        Spacer(modifier = GlanceModifier.height(12.dp))
                        Box(
                            modifier = GlanceModifier
                                .background(statColor)
                                .padding(horizontal = 24.dp, vertical = 12.dp)
                                .cornerRadius(8.dp)
                        ) {
                            Text(
                                text = "로그인",
                                style = TextStyle(
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 16.sp,
                                    color = widgetBg
                                )
                            )
                        }
                    }
                } else {
                    Column(
                        modifier = GlanceModifier
                            .fillMaxWidth(),
                        horizontalAlignment = Alignment.Horizontal.CenterHorizontally
                    ) {
                        Row(
                            modifier = GlanceModifier.fillMaxWidth(),
                            horizontalAlignment = Alignment.Horizontal.CenterHorizontally
                        ) {
                    Column(
                        modifier = GlanceModifier.padding(horizontal = 8.dp),
                        horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
                        verticalAlignment = Alignment.Vertical.CenterVertically
                    ) {
                        Text(
                            text = totalPosts.toString(),
                            style = TextStyle(
                                fontWeight = FontWeight.Bold,
                                fontSize = 24.sp,
                                color = statColor
                            )
                        )
                        Spacer(modifier = GlanceModifier.height(4.dp))
                        Text(
                            text = "게시글",
                            style = TextStyle(
                                fontSize = 12.sp,
                                color = textSecondary
                            )
                        )
                    }
                    Column(
                        modifier = GlanceModifier.padding(horizontal = 8.dp),
                        horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
                        verticalAlignment = Alignment.Vertical.CenterVertically
                    ) {
                        Text(
                            text = totalLikes.toString(),
                            style = TextStyle(
                                fontWeight = FontWeight.Bold,
                                fontSize = 24.sp,
                                color = statColor
                            )
                        )
                        Spacer(modifier = GlanceModifier.height(4.dp))
                        Text(
                            text = "좋아요",
                            style = TextStyle(
                                fontSize = 12.sp,
                                color = textSecondary
                            )
                        )
                    }
                    Column(
                        modifier = GlanceModifier.padding(horizontal = 8.dp),
                        horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
                        verticalAlignment = Alignment.Vertical.CenterVertically
                    ) {
                        Text(
                            text = totalComments.toString(),
                            style = TextStyle(
                                fontWeight = FontWeight.Bold,
                                fontSize = 24.sp,
                                color = statColor
                            )
                        )
                        Spacer(modifier = GlanceModifier.height(4.dp))
                        Text(
                            text = "댓글", style = TextStyle(
                                fontSize = 12.sp,
                                color = textSecondary
                                )
                            )
                        }
                        }

                        if (recentPostId != null && recentPostId.isNotEmpty()) {
                            Spacer(modifier = GlanceModifier.height(16.dp))

                            Box(
                                modifier = GlanceModifier
                                    .fillMaxWidth()
                                    .height(1.dp)
                                    .background(dividerColor)
                            ) {}

                            Spacer(modifier = GlanceModifier.height(12.dp))

                            val postIntent = Intent(context, MainActivity::class.java).apply {
                                action = Intent.ACTION_VIEW
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                                addCategory(Intent.CATEGORY_DEFAULT)
                                putExtra("postId", recentPostId)
                            }

                            Column(
                                modifier = GlanceModifier
                                    .fillMaxWidth()
                                    .clickable(actionStartActivity(postIntent)),
                                horizontalAlignment = Alignment.Horizontal.CenterHorizontally
                            ) {
                                Text(
                                    text = "최근 게시물",
                                    style = TextStyle(
                                        fontWeight = FontWeight.Medium,
                                        fontSize = 12.sp,
                                        color = textSecondary
                                    )
                                )
                                Spacer(modifier = GlanceModifier.height(4.dp))
                                Text(
                                    text = recentPostTitle,
                                    style = TextStyle(
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 14.sp,
                                        color = textPrimary
                                    ),
                                    maxLines = 1
                                )
                                if (recentPostPreview.isNotEmpty()) {
                                    Spacer(modifier = GlanceModifier.height(4.dp))
                                    Text(
                                        text = recentPostPreview,
                                        style = TextStyle(
                                            fontSize = 12.sp,
                                            color = textSecondary
                                        ),
                                        maxLines = 2
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
