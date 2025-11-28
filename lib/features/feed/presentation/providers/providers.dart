import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lionsns/features/feed/models/post.dart';
import 'package:lionsns/features/feed/data/datasources/supabase_post_datasource.dart';
import 'package:lionsns/features/feed/data/datasources/supabase_comment_datasource.dart';
import 'package:lionsns/features/feed/data/datasources/supabase_like_datasource.dart';
import 'package:lionsns/core/services/internal/storage_service_provider.dart';
import 'package:lionsns/core/utils/result.dart';
import '../viewmodels/post_list_viewmodel.dart';
import '../viewmodels/post_detail_viewmodel.dart';
import '../viewmodels/post_form_viewmodel.dart';
import '../viewmodels/liked_posts_viewmodel.dart';

final supabasePostDatasourceProvider = Provider<SupabasePostDatasource>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return SupabasePostDatasource(storageService);
});

final supabaseCommentDatasourceProvider = Provider<SupabaseCommentDatasource>((ref) {
  return SupabaseCommentDatasource();
});

final supabaseLikeDatasourceProvider = Provider<SupabaseLikeDatasource>((ref) {
  return SupabaseLikeDatasource();
});

final postListViewModelProvider = StateNotifierProvider.autoDispose<PostListViewModel, Result<List<Post>>>((ref) {
  final datasource = ref.watch(supabasePostDatasourceProvider);
  final viewModel = PostListViewModel(datasource);
  viewModel.loadPosts();
  return viewModel;
});

final postDetailViewModelProvider = StateNotifierProvider.autoDispose.family<PostDetailViewModel, PostDetailState, String>((ref, postId) {
  final postDatasource = ref.watch(supabasePostDatasourceProvider);
  final commentDatasource = ref.watch(supabaseCommentDatasourceProvider);
  final likeDatasource = ref.watch(supabaseLikeDatasourceProvider);
  return PostDetailViewModel(postDatasource, commentDatasource, likeDatasource, postId);
});

final postFormViewModelProvider = StateNotifierProvider.autoDispose<PostFormViewModel, PostFormState>((ref) {
  final datasource = ref.watch(supabasePostDatasourceProvider);
  return PostFormViewModel(datasource);
});

final likedPostsViewModelProvider = StateNotifierProvider.autoDispose<LikedPostsViewModel, Result<List<Post>>>((ref) {
  final datasource = ref.watch(supabasePostDatasourceProvider);
  final viewModel = LikedPostsViewModel(datasource);
  viewModel.loadLikedPosts();
  return viewModel;
});

/// 하위 호환성을 위한 별칭
final postListProvider = postListViewModelProvider;
final postFormProvider = postFormViewModelProvider;
final likedPostsProvider = likedPostsViewModelProvider;
