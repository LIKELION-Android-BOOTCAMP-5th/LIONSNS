import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/features/auth/models/user.dart';
import 'package:lionsns/core/services/internal/widget_update_service_provider.dart';
import 'package:lionsns/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:lionsns/features/auth/data/datasources/supabase_profile_datasource.dart';
import 'package:lionsns/features/auth/data/datasources/supabase_follow_datasource.dart';
import 'package:lionsns/core/services/internal/storage_service_provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/profile_edit_viewmodel.dart';
import '../viewmodels/follow_viewmodel.dart';

final supabaseAuthDatasourceProvider = Provider<SupabaseAuthDatasource>((ref) {
  return SupabaseAuthDatasource();
});

final supabaseProfileDatasourceProvider = Provider<SupabaseProfileDatasource>((ref) {
  return SupabaseProfileDatasource();
});

final supabaseFollowDatasourceProvider = Provider<SupabaseFollowDatasource>((ref) {
  return SupabaseFollowDatasource();
});

final authViewModelProvider = StateNotifierProvider<AuthViewModel, Result<User?>>((ref) {
  final datasource = ref.watch(supabaseAuthDatasourceProvider);
  final widgetUpdateService = ref.watch(widgetUpdateServiceProvider);
  return AuthViewModel(datasource, widgetUpdateService: widgetUpdateService);
});

/// 현재 로그인 상태를 boolean으로 제공
final isLoggedInProvider = Provider<bool>((ref) {
  final authResult = ref.watch(authViewModelProvider);
  return authResult.when(
    success: (user) => user != null,
    failure: (_, __) => false,
    pending: (_) => false,
  );
});

/// Auth Provider (하위 호환성을 위한 별칭)
final authProvider = authViewModelProvider;

/// autoDispose: 화면을 벗어나면 자동으로 dispose되어 메모리 효율성 향상
final profileEditViewModelProvider = StateNotifierProvider.autoDispose<ProfileEditViewModel, ProfileEditState>((ref) {
  final profileDatasource = ref.watch(supabaseProfileDatasourceProvider);
  final storageService = ref.watch(storageServiceProvider);
  final authDatasource = ref.watch(supabaseAuthDatasourceProvider);
  return ProfileEditViewModel(profileDatasource, storageService, authDatasource);
});

/// autoDispose: 위젯이 dispose되면 자동으로 dispose되어 메모리 효율성 향상
final followViewModelProvider = StateNotifierProvider.autoDispose.family<FollowViewModel, FollowState, String>((ref, userId) {
  final datasource = ref.watch(supabaseFollowDatasourceProvider);
  final currentUser = ref.watch(authViewModelProvider).when(
        success: (user) => user?.id,
        failure: (_, __) => null,
        pending: (_) => null,
      );
  return FollowViewModel(datasource, userId, currentUser);
});
