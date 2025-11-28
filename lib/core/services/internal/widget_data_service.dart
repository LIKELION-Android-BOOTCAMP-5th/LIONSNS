import 'package:shared_preferences/shared_preferences.dart';
import 'package:lionsns/core/services/external/supabase_service.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/core/constants/widget_data_keys.dart';

class WidgetData {
  final String userId;
  final int totalPostsCount;
  final int totalLikesCount;
  final int totalCommentsCount;
  final RecentPost? recentPost;

  const WidgetData({
    required this.userId,
    required this.totalPostsCount,
    required this.totalLikesCount,
    required this.totalCommentsCount,
    this.recentPost,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalPostsCount': totalPostsCount,
      'totalLikesCount': totalLikesCount,
      'totalCommentsCount': totalCommentsCount,
      'recentPost': recentPost?.toJson(),
    };
  }

  factory WidgetData.fromJson(Map<String, dynamic> json) {
    return WidgetData(
      userId: json['userId'] as String,
      totalPostsCount: json['totalPostsCount'] as int,
      totalLikesCount: json['totalLikesCount'] as int,
      totalCommentsCount: json['totalCommentsCount'] as int,
      recentPost: json['recentPost'] != null
          ? RecentPost.fromJson(json['recentPost'] as Map<String, dynamic>)
          : null,
    );
  }
}

class RecentPost {
  final String id;
  final String title;
  final String previewText;
  final DateTime createdAt;

  const RecentPost({
    required this.id,
    required this.title,
    required this.previewText,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'previewText': previewText,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RecentPost.fromJson(Map<String, dynamic> json) {
    return RecentPost(
      id: json['id'] as String,
      title: json['title'] as String,
      previewText: json['previewText'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}



/// 사용자 통계를 집계하고 SharedPreferences에 저장하여 네이티브 위젯에서 사용
class WidgetDataService {

  /// 사용자 통계를 조회하고 저장
  Future<Result<WidgetData>> updateWidgetData() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        return Failure<WidgetData>('로그인이 필요합니다');
      }

      final postsResponse = await SupabaseService.client
          .from('posts')
          .select('id, title, content, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final postsList = postsResponse as List;
      final totalPostsCount = postsList.length;

      RecentPost? recentPost;
      if (postsList.isNotEmpty) {
        final latestPost = postsList[0] as Map<String, dynamic>;
        final title = latestPost['title'] as String? ?? '';
        final content = latestPost['content'] as String? ?? '';
        final previewText = content.length > 50 ? '${content.substring(0, 50)}...' : content;
        final createdAt = DateTime.parse(latestPost['created_at'] as String);

        recentPost = RecentPost(
          id: latestPost['id'] as String,
          title: title,
          previewText: previewText,
          createdAt: createdAt,
        );
      }

      int totalLikesCount = 0;
      if (totalPostsCount > 0) {
        final postIds = postsList.map((p) => (p as Map<String, dynamic>)['id'] as String).toList();
        
        if (postIds.isNotEmpty) {
          // 여러 post_id에 대한 좋아요를 조회하기 위해 or 조건 사용
          String orCondition = postIds
              .map((id) => 'post_id.eq.$id')
              .join(',');
          final likesResponse = await SupabaseService.client
              .from('post_likes')
              .select('id')
              .or(orCondition);
          totalLikesCount = (likesResponse as List).length;
        }
      }

      int totalCommentsCount = 0;
      if (totalPostsCount > 0) {
        final postIds = postsList.map((p) => (p as Map<String, dynamic>)['id'] as String).toList();
        
        if (postIds.isNotEmpty) {
          // 여러 post_id에 대한 댓글을 조회하기 위해 or 조건 사용
          String orCondition = postIds
              .map((id) => 'post_id.eq.$id')
              .join(',');
          final commentsResponse = await SupabaseService.client
              .from('comments')
              .select('id')
              .or(orCondition);
          totalCommentsCount = (commentsResponse as List).length;
        }
      }

      final widgetData = WidgetData(
        userId: userId,
        totalPostsCount: totalPostsCount,
        totalLikesCount: totalLikesCount,
        totalCommentsCount: totalCommentsCount,
        recentPost: recentPost,
      );

      await _saveToSharedPreferences(widgetData);

      return Success<WidgetData>(widgetData);
    } catch (e) {
      return Failure<WidgetData>('위젯 데이터를 업데이트하는데 실패했습니다: $e');
    }
  }

  /// SharedPreferences에 저장
  /// 
  /// 저장 후 검증 및 재시도 로직 포함 (Android 위젯 데이터 동기화 보장)
  Future<void> _saveToSharedPreferences(WidgetData data) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(WidgetDataKeys.userId, data.userId);
    await prefs.setInt(WidgetDataKeys.totalPostsCount, data.totalPostsCount);
    await prefs.setInt(WidgetDataKeys.totalLikesCount, data.totalLikesCount);
    await prefs.setInt(WidgetDataKeys.totalCommentsCount, data.totalCommentsCount);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    final verifyPrefs = await SharedPreferences.getInstance();
    final savedUserId = verifyPrefs.getString(WidgetDataKeys.userId);
    
    if (savedUserId == null || savedUserId.isEmpty || savedUserId != data.userId) {
      for (int i = 0; i < 5; i++) {
        await prefs.setString(WidgetDataKeys.userId, data.userId);
        await Future.delayed(const Duration(milliseconds: 300));
        final retryPrefs = await SharedPreferences.getInstance();
        final retryUserId = retryPrefs.getString(WidgetDataKeys.userId);
        if (retryUserId != null && retryUserId.isNotEmpty && retryUserId == data.userId) {
          break;
        }
      }
    }

    if (data.recentPost != null) {
      await prefs.setString(WidgetDataKeys.recentPostId, data.recentPost!.id);
      await prefs.setString(WidgetDataKeys.recentPostTitle, data.recentPost!.title);
      await prefs.setString(WidgetDataKeys.recentPostPreview, data.recentPost!.previewText);
      await prefs.setString(WidgetDataKeys.recentPostCreatedAt, data.recentPost!.createdAt.toIso8601String());
    }
    
    await prefs.setString(WidgetDataKeys.updateTimestamp, DateTime.now().toIso8601String());
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// SharedPreferences에서 위젯 데이터 로드
  Future<WidgetData?> loadWidgetData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userId = prefs.getString(WidgetDataKeys.userId);
      if (userId == null) {
        return null;
      }

      final totalPostsCount = prefs.getInt(WidgetDataKeys.totalPostsCount) ?? 0;
      final totalLikesCount = prefs.getInt(WidgetDataKeys.totalLikesCount) ?? 0;
      final totalCommentsCount = prefs.getInt(WidgetDataKeys.totalCommentsCount) ?? 0;

      RecentPost? recentPost;
      final recentPostId = prefs.getString(WidgetDataKeys.recentPostId);
      if (recentPostId != null) {
        recentPost = RecentPost(
          id: recentPostId,
          title: prefs.getString(WidgetDataKeys.recentPostTitle) ?? '',
          previewText: prefs.getString(WidgetDataKeys.recentPostPreview) ?? '',
          createdAt: DateTime.parse(prefs.getString(WidgetDataKeys.recentPostCreatedAt) ?? DateTime.now().toIso8601String()),
        );
      }

      return WidgetData(
        userId: userId,
        totalPostsCount: totalPostsCount,
        totalLikesCount: totalLikesCount,
        totalCommentsCount: totalCommentsCount,
        recentPost: recentPost,
      );
    } catch (e) {
      return null;
    }
  }

  /// 위젯 데이터 삭제
  Future<void> clearWidgetData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(WidgetDataKeys.userId);
    await prefs.remove(WidgetDataKeys.totalPostsCount);
    await prefs.remove(WidgetDataKeys.totalLikesCount);
    await prefs.remove(WidgetDataKeys.totalCommentsCount);
    await prefs.remove(WidgetDataKeys.recentPostId);
    await prefs.remove(WidgetDataKeys.recentPostTitle);
    await prefs.remove(WidgetDataKeys.recentPostPreview);
    await prefs.remove(WidgetDataKeys.recentPostCreatedAt);
  }
}

