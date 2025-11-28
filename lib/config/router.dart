
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lionsns/l10n/app_localizations.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/core/services/internal/deep_link_service.dart';
import 'package:lionsns/features/auth/presentation/pages/auth_screen.dart';
import 'package:lionsns/features/auth/presentation/pages/profile_screen.dart';
import 'package:lionsns/features/auth/presentation/pages/profile_edit_screen.dart';
import 'package:lionsns/features/auth/presentation/providers/providers.dart';
import 'package:lionsns/features/feed/presentation/pages/post_form_screen.dart';
import 'package:lionsns/features/feed/presentation/pages/post_detail_screen.dart';
import 'package:lionsns/features/feed/presentation/pages/liked_posts_screen.dart';
import 'package:lionsns/presentation/pages/main_navigation_screen.dart';


class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String postCreate = '/post/create';
  static const String likedPosts = '/liked-posts';
  static const String notificationSettings = '/settings/notifications';
  static String postDetail(String id) => '/post/$id';
  static String userProfile(String userId) => '/user/$userId';
}

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(isLoggedInProvider);

  final initialDeepLink = DeepLinkService.getInitialDeepLink();
  final safeInitialLocation = (initialDeepLink != null && initialDeepLink != '/CALLBACK') 
      ? initialDeepLink 
      : AppRoutes.home;
  
  final initialLocation = safeInitialLocation;

  final router = GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) {
      final currentPath = state.uri.path;
      final isGoingToLogin = currentPath == AppRoutes.login;
      final isGoingToProfile = currentPath == AppRoutes.profile || currentPath == AppRoutes.profileEdit;
      final isGoingToPostDetail = currentPath.startsWith('/post/');
      
      if (currentPath == '/CALLBACK') {
        return AppRoutes.home;
      }
      
      if (isGoingToProfile) {
        return null;
      }
      
      if (isGoingToPostDetail) {
        return null;
      }
      
      final authResult = ref.read(authViewModelProvider);
      
      if (authResult is Pending) {
        return null;
      }
      
      final isAuthenticated = authResult.when(
        success: (user) => user != null,
        failure: (_, __) => false,
        pending: (_) => false,
      );

      if (!isAuthenticated && !isGoingToLogin) {
        return AppRoutes.login;
      }

      if (isAuthenticated && isGoingToLogin) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        name: 'profileEdit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: AppRoutes.postCreate,
        name: 'postCreate',
        builder: (context, state) {
          final postId = state.uri.queryParameters['postId'];
          return PostFormScreen(postId: postId);
        },
      ),
      GoRoute(
        path: AppRoutes.likedPosts,
        name: 'likedPosts',
        builder: (context, state) => const LikedPostsScreen(),
      ),
      GoRoute(
        path: '/post/:id',
        name: 'postDetail',
        builder: (context, state) {
          final postId = state.pathParameters['id']!;
          return PostDetailScreen(postId: postId);
        },
      ),
      GoRoute(
        path: '/user/:userId',
        name: 'userProfile',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ProfileScreen(userId: userId);
        },
      ),
    ],
    errorBuilder: (context, state) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        body: Center(
          child: Text(l10n?.pageNotFound(state.uri.toString()) ?? '페이지를 찾을 수 없습니다: ${state.uri}'),
        ),
      );
    },
  );
  
  DeepLinkService.initialize(router);
  
  return router;
});