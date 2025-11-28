import 'package:flutter/foundation.dart';
import 'package:lionsns/core/services/external/supabase_service.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/features/feed/models/post.dart';
import 'package:lionsns/features/feed/models/comment.dart';
import 'package:lionsns/features/auth/models/user.dart';

class SupabaseSearchDatasource {
  /// 통합 검색 (포스트, 댓글, 사용자)
  Future<Result<SearchResults>> search(String query) async {
    if (query.trim().isEmpty) {
      return Success<SearchResults>(const SearchResults(
        posts: [],
        comments: [],
        users: [],
      ));
    }

    try {
      final searchTerm = '%$query%';

      final postsResponse = await SupabaseService.client
          .from('posts')
          .select('*, user_profiles!user_id(name, profile_image_url)')
          .or('title.ilike.$searchTerm,content.ilike.$searchTerm')
          .order('created_at', ascending: false)
          .limit(20);

      final commentsResponse = await SupabaseService.client
          .from('comments')
          .select('*, user_profiles!user_id(name, profile_image_url), posts!post_id(id, title)')
          .ilike('content', searchTerm)
          .order('created_at', ascending: false)
          .limit(20);

      final usersResponse = await SupabaseService.client
          .from('user_profiles')
          .select()
          .ilike('name', searchTerm)
          .limit(20);

      final posts = <Post>[];
      if (postsResponse is List) {
        for (final json in postsResponse) {
          try {
            final data = Map<String, dynamic>.from(json);
            
            String? authorName;
            String? authorImageUrl;
            final userProfile = data['user_profiles'];
            if (userProfile != null && userProfile is Map<String, dynamic>) {
              authorName = userProfile['name'] as String?;
              authorImageUrl = userProfile['profile_image_url'] as String?;
            }

            final likesResponse = await SupabaseService.client
                .from('post_likes')
                .select()
                .eq('post_id', data['id']);
            final likesCount = (likesResponse as List).length;

            int commentsCount = 0;
            try {
              final commentsResponse = await SupabaseService.client
                  .from('comments')
                  .select('id')
                  .eq('post_id', data['id']);
              commentsCount = (commentsResponse as List).length;
            } catch (e) {
              debugPrint('댓글 수 조회 실패: $e');
            }

            final post = Post.fromJson(data).copyWith(
              authorName: authorName,
              authorImageUrl: authorImageUrl,
              likesCount: likesCount,
              commentsCount: commentsCount,
            );
            posts.add(post);
          } catch (e) {
            debugPrint('포스트 변환 실패: $e');
          }
        }
      }

      final comments = <Comment>[];
      if (commentsResponse is List) {
        for (final json in commentsResponse) {
          try {
            final data = Map<String, dynamic>.from(json);
            final comment = Comment.fromJson(data);
            
            String? authorName;
            String? authorImageUrl;
            final userProfile = data['user_profiles'];
            if (userProfile != null && userProfile is Map<String, dynamic>) {
              authorName = userProfile['name'] as String?;
              authorImageUrl = userProfile['profile_image_url'] as String?;
            }

            final updatedComment = comment.copyWith(
              authorName: authorName,
              authorImageUrl: authorImageUrl,
            );
            comments.add(updatedComment);
          } catch (e) {
            debugPrint('댓글 변환 실패: $e');
          }
        }
      }

      final users = <User>[];
      if (usersResponse is List) {
        for (final json in usersResponse) {
          try {
            final profile = Map<String, dynamic>.from(json);
            final providerString = profile['provider'] as String? ?? 'google';
            final user = User.fromJson({
              'id': profile['id'],
              'name': profile['name'] ?? '사용자',
              'email': '', // 검색 결과에서는 email 불필요
              'profile_image_url': profile['profile_image_url'],
              'provider': providerString,
              'created_at': profile['created_at'],
            });
            users.add(user);
          } catch (e) {
            debugPrint('사용자 변환 실패: $e');
          }
        }
      }

      return Success<SearchResults>(SearchResults(
        posts: posts,
        comments: comments,
        users: users,
      ));
    } catch (e) {
      debugPrint('검색 오류: $e');
      return Failure<SearchResults>('검색에 실패했습니다: $e');
    }
  }
}

class SearchResults {
  final List<Post> posts;
  final List<Comment> comments;
  final List<User> users;

  const SearchResults({
    required this.posts,
    required this.comments,
    required this.users,
  });
}

