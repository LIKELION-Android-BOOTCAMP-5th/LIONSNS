import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/features/search/data/datasources/supabase_search_datasource.dart';
import 'package:lionsns/features/search/presentation/viewmodels/search_viewmodel.dart';

final supabaseSearchDatasourceProvider = Provider<SupabaseSearchDatasource>((ref) {
  return SupabaseSearchDatasource();
});

final searchViewModelProvider = StateNotifierProvider.autoDispose<SearchViewModel, Result<SearchResults>>((ref) {
  final datasource = ref.watch(supabaseSearchDatasourceProvider);
  return SearchViewModel(datasource);
});

/// 하위 호환성을 위한 별칭
final searchProvider = searchViewModelProvider;

