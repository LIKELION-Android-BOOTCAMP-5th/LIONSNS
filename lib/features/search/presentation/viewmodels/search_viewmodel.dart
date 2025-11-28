import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/features/search/data/datasources/supabase_search_datasource.dart';

class SearchViewModel extends StateNotifier<Result<SearchResults>> {
  final SupabaseSearchDatasource _datasource;

  SearchViewModel(this._datasource) : super(const Success<SearchResults>(SearchResults(
    posts: [],
    comments: [],
    users: [],
  )));

  /// 검색 실행
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const Success<SearchResults>(SearchResults(
        posts: [],
        comments: [],
        users: [],
      ));
      return;
    }

    state = const Pending<SearchResults>();
    final result = await _datasource.search(query);
    state = result;
  }

  /// 검색 초기화
  void clear() {
    state = const Success<SearchResults>(SearchResults(
      posts: [],
      comments: [],
      users: [],
    ));
  }
}

