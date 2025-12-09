
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
import 'package:lionsns/features/chat/presentation/pages/chat_room_list_screen.dart';
import 'package:lionsns/features/chat/presentation/pages/chat_screen.dart';
import 'package:lionsns/presentation/pages/main_navigation_screen.dart';


class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String postCreate = '/post/create';
  static const String likedPosts = '/liked-posts';
  static const String notificationSettings = '/settings/notifications';
  static const String chatRoomList = '/chat';
  static String postDetail(String id) => '/post/$id';
  static String userProfile(String userId) => '/user/$userId';
  static String chat(String chatRoomId) => '/chat/$chatRoomId';
}

final routerProvider = Provider<GoRouter>((ref) {
  // 인증 상태를 watch하여 변경 시 라우터가 다시 빌드되도록 함
  // 이렇게 하면 앱 실행 시 자동 로그인이 작동함
  ref.watch(isLoggedInProvider);

  // 초기 딥링크 경로 확인 (앱 cold start 시 위젯에서 실행된 경우)
  final initialDeepLink = DeepLinkService.getInitialDeepLink();
  final initialLocation = initialDeepLink ?? AppRoutes.home;
  
  if (initialDeepLink != null) {
    debugPrint('routerProvider - 초기 딥링크 경로 사용: $initialDeepLink');
  }

  final router = GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) {
      final currentPath = state.uri.path;
      final isGoingToLogin = currentPath == AppRoutes.login;
      final isGoingToProfile = currentPath == AppRoutes.profile || currentPath == AppRoutes.profileEdit;
      
      // 프로필 관련 경로로 이동하는 경우, redirect 함수에서 바로 반환
      // 인증 확인을 완전히 건너뛰고, 프로필 화면에서만 인증 상태를 확인하도록 함
      // 이렇게 하면 프로필 편집 화면에서 백키를 누를 때 redirect 함수가 실행되더라도
      // 인증 확인을 하지 않으므로 로그인 화면이 나타나지 않음
      if (isGoingToProfile) {
        return null; // 리다이렉트 없음 - 프로필 경로는 항상 허용
      }
      
      // 다른 경로에 대해서만 인증 상태 확인
      // 프로필 관련 경로가 아닌 경우에만 authViewModelProvider를 읽음
      final authResult = ref.read(authViewModelProvider);
      
      // Pending 상태일 때는 리다이렉트를 하지 않음 (인증 진행 중)
      if (authResult is Pending) {
        return null;
      }
      
      // 인증 상태 확인
      final isAuthenticated = authResult.when(
        success: (user) => user != null,
        failure: (_, __) => false,
        pending: (_) => false,
      );

      // 로그인되지 않은 상태에서 로그인 페이지가 아닌 곳으로 가려고 하면 로그인 페이지로 리다이렉트
      if (!isAuthenticated && !isGoingToLogin) {
        return AppRoutes.login;
      }

      // 로그인된 상태에서 로그인 페이지로 가려고 하면 홈으로 리다이렉트
      if (isAuthenticated && isGoingToLogin) {
        return AppRoutes.home;
      }

      return null; // 리다이렉트 없음
    },
    routes: [
      // 로그인 화면
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const AuthScreen(),
      ),
      // 홈 화면 (메인 네비게이션)
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      // 프로필 화면
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      // 프로필 편집
      GoRoute(
        path: AppRoutes.profileEdit,
        name: 'profileEdit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      // 게시글 작성/수정 (create를 id보다 먼저 정의해야 함)
      GoRoute(
        path: AppRoutes.postCreate,
        name: 'postCreate',
        builder: (context, state) {
          final postId = state.uri.queryParameters['postId'];
          return PostFormScreen(postId: postId);
        },
      ),
      // 좋아요한 글 목록
      GoRoute(
        path: AppRoutes.likedPosts,
        name: 'likedPosts',
        builder: (context, state) => const LikedPostsScreen(),
      ),
      // 게시글 상세 (직접 접근용)
      GoRoute(
        path: '/post/:id',
        name: 'postDetail',
        builder: (context, state) {
          final postId = state.pathParameters['id']!;
          return PostDetailScreen(postId: postId);
        },
      ),
      // 다른 사용자 프로필
      GoRoute(
        path: '/user/:userId',
        name: 'userProfile',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ProfileScreen(userId: userId);
        },
      ),
      // 채팅방 목록
      GoRoute(
        path: AppRoutes.chatRoomList,
        name: 'chatRoomList',
        builder: (context, state) => const ChatRoomListScreen(),
      ),
      // 채팅 화면
      GoRoute(
        path: '/chat/:chatRoomId',
        name: 'chat',
        builder: (context, state) {
          final chatRoomId = state.pathParameters['chatRoomId']!;
          return ChatScreen(chatRoomId: chatRoomId);
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
  
  // Deep Link 서비스에 라우터 등록
  DeepLinkService.initialize(router);
  
  return router;
});