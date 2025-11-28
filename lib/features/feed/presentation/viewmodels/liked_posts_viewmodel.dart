import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lionsns/features/feed/models/post.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/features/feed/data/datasources/supabase_post_datasource.dart';
import 'package:lionsns/core/services/external/supabase_service.dart';

class LikedPostsViewModel extends StateNotifier<Result<List<Post>>> {
  final SupabasePostDatasource _datasource;

  LikedPostsViewModel(this._datasource) : super(const Pending<List<Post>>());

  /// 좋아요한 게시글 목록 로드
  Future<void> loadLikedPosts() async {
    final currentUserId = SupabaseService.currentUser?.id;
    if (currentUserId == null) {
      state = Failure<List<Post>>('로그인이 필요합니다');
      return;
    }

    state = const Pending<List<Post>>();
    final result = await _datasource.getUserLikedPosts(currentUserId);
    state = result;
  }
}

