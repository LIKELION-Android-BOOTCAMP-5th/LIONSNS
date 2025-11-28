import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lionsns/features/feed/models/post.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/features/feed/data/datasources/supabase_post_datasource.dart';

class PostListViewModel extends StateNotifier<Result<List<Post>>> {
  final SupabasePostDatasource _datasource;

  PostListViewModel(this._datasource) : super(const Pending<List<Post>>());

  /// 게시글 목록 로드
  Future<void> loadPosts() async {
    state = const Pending<List<Post>>();
    final result = await _datasource.getPosts();
    state = result;
  }

  /// 게시글 삭제 및 목록 새로고침
  Future<void> deletePost(String id) async {
    final result = await _datasource.deletePost(id);
    if (result is Success) {
      // 삭제 성공 시 목록을 새로고침하여 UI 동기화
      await loadPosts();
    }
  }
}
