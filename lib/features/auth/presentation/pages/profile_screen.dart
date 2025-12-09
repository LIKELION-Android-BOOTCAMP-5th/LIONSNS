import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lionsns/l10n/app_localizations.dart';
import 'package:lionsns/config/router.dart';
import 'package:lionsns/core/widgets/common_app_bar.dart';
import 'package:lionsns/features/auth/models/user.dart';
import 'package:lionsns/core/utils/result.dart';
import '../providers/providers.dart';
import '../viewmodels/follow_viewmodel.dart';
import 'package:lionsns/features/chat/presentation/providers/providers.dart' as chat_providers;
import '../../data/datasources/supabase_profile_datasource.dart';

/// 프로필 화면
class ProfileScreen extends ConsumerWidget {
  final String? userId; // null이면 현재 사용자, 있으면 해당 사용자
  
  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // userId가 제공되면 해당 사용자의 프로필을 보여주고, 없으면 현재 사용자
    final isViewingOtherUser = userId != null;
    
    if (isViewingOtherUser) {
      // 다른 사용자의 프로필 보기
      return _buildOtherUserProfile(context, ref, userId!);
    } else {
      // 현재 사용자의 프로필 보기
      return _buildCurrentUserProfile(context, ref);
    }
  }

  Widget _buildCurrentUserProfile(BuildContext context, WidgetRef ref) {
    // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
    final l10n = AppLocalizations.of(context)!;
    final authResult = ref.watch(authViewModelProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        // 백 버튼을 누르면 항상 홈으로 이동
        if (!didPop) {
          context.go(AppRoutes.home);
        }
      },
      child: Scaffold(
        appBar: CommonAppBar(
          // 다국어: 프로필 화면 제목
          title: Text(l10n.profile),
          showChatIcon: false, // 프로필 화면에서는 채팅 아이콘 숨김
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push(AppRoutes.profileEdit),
              // 편집 후 프로필 새로고침은 AuthViewModel의 userUpdated 이벤트가 처리함
            ),
          ],
        ),
        body: authResult.when(
          success: (user) {
            if (user == null) {
              return Center(
                // 다국어: 로그인 필요 메시지
                child: Text(l10n.loginRequired),
              );
            }

            // 팔로우 상태 조회
            final followState = ref.watch(followViewModelProvider(user.id));

            return _buildProfileContent(context, ref, user, followState, true);
          },
          failure: (message, error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(authViewModelProvider);
                    },
                    // 다국어: 다시 시도 버튼
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          },
          pending: (_) => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _buildOtherUserProfile(BuildContext context, WidgetRef ref, String targetUserId) {
    // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
    final l10n = AppLocalizations.of(context)!;
    final profileDatasource = SupabaseProfileDatasource();
    final profileFuture = profileDatasource.getProfile(targetUserId);
    final followState = ref.watch(followViewModelProvider(targetUserId));

    return Scaffold(
      appBar: CommonAppBar(
        showChatIcon: false, // 프로필 화면에서는 채팅 아이콘 숨김
        // 다국어: 프로필 화면 제목
        title: Text(l10n.profile),
      ),
      body: FutureBuilder<Result<User?>>(
        future: profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  // 다국어: 프로필 로드 오류 메시지
                  Text(
                    l10n.profileLoadError,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    // 다국어: 돌아가기 버튼
                    child: Text(l10n.goBack),
                  ),
                ],
              ),
            );
          }

          final result = snapshot.data;
          if (result == null) {
            // 다국어: 데이터 로드 오류 메시지
            return Center(child: Text(l10n.dataLoadError));
          }

          return result.when(
            success: (user) {
              if (user == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      // 다국어: 프로필을 찾을 수 없을 때 메시지
                      Text(
                        l10n.profileNotFound,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        // 다국어: 돌아가기 버튼
                        // 다국어: 돌아가기 버튼
                      child: Text(l10n.goBack),
                      ),
                    ],
                  ),
                );
              }

              return _buildOtherUserProfileContent(context, ref, user, followState);
            },
            failure: (message, error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      // 다국어: 돌아가기 버튼
                      child: Text(l10n.goBack),
                    ),
                  ],
                ),
              );
            },
            pending: (_) => const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  /// 다른 사용자 프로필 콘텐츠 (간단한 버전)
  Widget _buildOtherUserProfileContent(
    BuildContext context,
    WidgetRef ref,
    User user,
    FollowState followState,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final authResult = ref.watch(authViewModelProvider);
    final currentUser = authResult.when(
      success: (user) => user,
      failure: (_, __) => null,
      pending: (_) => null,
    );
    final currentUserId = currentUser?.id;
    final isCurrentUser = currentUserId == user.id;
    final canFollow = !isCurrentUser && currentUserId != null;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 32),

        // 프로필 이미지
        Center(
          child: _buildProfileAvatar(
            context,
            imageUrl: user.profileImageUrl,
            radius: 60,
            fallbackText: user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
          ),
        ),

        const SizedBox(height: 24),

        // 이름
        Center(
          child: Text(
            user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // 팔로워/팔로잉 수
        _buildFollowStats(context, ref, user.id, followState),

        const SizedBox(height: 32),

        // 팔로우/언팔로우 버튼 (자기 자신이 아닌 경우만)
        if (canFollow)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: followState.isLoading
                  ? null
                  : () async {
                      final viewModel = ref.read(followViewModelProvider(user.id).notifier);
                      await viewModel.toggleFollow();
                      
                      // 현재 사용자의 팔로잉 수도 갱신
                      final authResult = ref.read(authViewModelProvider);
                      final currentUser = authResult.when(
                        success: (user) => user,
                        failure: (_, __) => null,
                        pending: (_) => null,
                      );
                      if (currentUser != null) {
                        ref.invalidate(followViewModelProvider(currentUser.id));
                      }
                    },
              icon: Icon(
                followState.isFollowingResult.when(
                  success: (isFollowing) => isFollowing
                      ? Icons.person_remove
                      : Icons.person_add,
                  failure: (_, __) => Icons.person_add,
                  pending: (_) => Icons.person_add,
                ),
              ),
              // 다국어: 팔로우/언팔로우 버튼 텍스트
              label: Text(
                followState.isFollowingResult.when(
                  success: (isFollowing) => isFollowing ? l10n.unfollow : l10n.follow,
                  failure: (_, __) => l10n.follow,
                  pending: (_) => l10n.loading,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: followState.isFollowingResult.when(
                  success: (isFollowing) => isFollowing
                      ? Colors.grey[300]
                      : Theme.of(context).primaryColor,
                  failure: (_, __) => Theme.of(context).primaryColor,
                  pending: (_) => Theme.of(context).primaryColor,
                ),
                foregroundColor: followState.isFollowingResult.when(
                  success: (isFollowing) => isFollowing
                      ? Colors.black87
                      : Colors.white,
                  failure: (_, __) => Colors.white,
                  pending: (_) => Colors.white,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 채팅하기 버튼 (자기 자신이 아닐 때만)
          // canFollow가 true이면 currentUserId는 null이 아님 (canFollow = !isCurrentUser && currentUserId != null)
          if (canFollow)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                // ignore: unnecessary_null_comparison
                // canFollow가 true이면 currentUserId는 null이 아님
                onPressed: () => _navigateToChat(context, ref, currentUserId!, user.id),
                icon: const Icon(Icons.chat),
                label: const Text('채팅하기'),
              ),
            ),
      ],
    );
  }

  /// 현재 사용자 프로필 콘텐츠 (전체 정보)
  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    User user,
    FollowState followState,
    bool isCurrentUser,
  ) {
    // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),

        // 프로필 이미지
        Center(
          child: _buildProfileAvatar(
            context,
            imageUrl: user.profileImageUrl,
            radius: 60,
            fallbackText: user.name[0].toUpperCase(),
          ),
        ),

        const SizedBox(height: 24),

        // 팔로워/팔로잉 수
        _buildFollowStats(context, ref, user.id, followState),

        const SizedBox(height: 24),

        // 채팅방 목록으로 이동
        if (isCurrentUser)
          Card(
            child: ListTile(
              leading: Icon(Icons.chat, color: Theme.of(context).primaryColor),
              title: const Text(
                '채팅방',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text('내가 참여중인 채팅방 목록'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/chat');
              },
            ),
          ),

        if (isCurrentUser) const SizedBox(height: 16),

        // 좋아요한 게시글 목록으로 이동
        if (isCurrentUser)
          Card(
            child: ListTile(
              leading: Icon(Icons.favorite, color: Theme.of(context).primaryColor),
              title: const Text(
                '좋아요',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text('내가 좋아요한 게시글 목록'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push(AppRoutes.likedPosts);
              },
            ),
          ),

        if (isCurrentUser) const SizedBox(height: 16),

        // 사용자 정보
        // 다국어: 이름 정보 카드
        _buildInfoCard(
          context,
          Icons.person,
          l10n.name,
          user.name,
        ),

        const SizedBox(height: 16),

        // 다국어: 이메일 정보 카드
        _buildInfoCard(
          context,
          Icons.email,
          l10n.email,
          user.email,
        ),

        const SizedBox(height: 16),

        // 다국어: 로그인 방법 정보 카드
        _buildInfoCard(
          context,
          Icons.login,
          l10n.loginMethod,
          _getProviderName(user.provider, l10n),
        ),

        const SizedBox(height: 32),

        // 로그아웃 버튼 (현재 사용자만)
        if (isCurrentUser)
          ElevatedButton.icon(
            onPressed: () => _showLogoutDialog(context, ref),
            icon: const Icon(Icons.logout),
            // 다국어: 로그아웃 버튼
            label: Text(l10n.logout),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
      ],
    );
  }

  /// 채팅방으로 이동
  Future<void> _navigateToChat(
    BuildContext context,
    WidgetRef ref,
    String currentUserId,
    String otherUserId,
  ) async {
    try {
      // 로딩 표시
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 채팅방 생성 또는 조회
      final datasource = ref.read(chat_providers.chatDatasourceProvider);
      final result = await datasource.getOrCreateChatRoom(
        user1Id: currentUserId,
        user2Id: otherUserId,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // 로딩 다이얼로그 닫기

      result.when(
        success: (chatRoom) {
          // 채팅방으로 이동
          context.push('/chat/${chatRoom.id}');
        },
        failure: (message, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // 로딩 다이얼로그 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채팅방을 열 수 없습니다: $e')),
      );
    }
  }

  Widget _buildInfoCard(
      BuildContext context,
      IconData icon,
      String label,
      String value,
      ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 다국어 지원: 프로바이더 이름 가져오기 (현재는 영어로만 반환)
  String _getProviderName(AuthProvider provider, AppLocalizations? l10n) {
    switch (provider) {
      case AuthProvider.google:
        return 'Google';
      case AuthProvider.apple:
        return 'Apple';
      case AuthProvider.kakao:
        return 'Kakao';
      case AuthProvider.naver:
        return 'Naver';
    }
  }

  Widget _buildProfileAvatar(
    BuildContext context, {
    required String? imageUrl,
    required double radius,
    required String fallbackText,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        child: Text(
          fallbackText,
          style: TextStyle(
            fontSize: radius * 0.6,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      child: ClipOval(
        child: Image.network(
          imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: Colors.grey[200],
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 디폴트 아이콘
                  Center(
                    child: Icon(
                      Icons.person_outline,
                      size: radius * 1.2,
                      color: Colors.grey[400],
                    ),
                  ),
                  // 로딩 인디케이터
                  Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                ],
              ),
            );
          },
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: Colors.grey[200],
              child: Center(
                child: Text(
                  fallbackText,
                  style: TextStyle(
                    fontSize: radius * 0.6,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFollowStats(
    BuildContext context,
    WidgetRef ref,
    String userId,
    FollowState followState,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 팔로워 수
            // 다국어: 팔로워 라벨
            _buildFollowStatItem(
              context,
              ref,
              l10n.follower,
              followState.followerCountResult.when(
                success: (count) => count.toString(),
                failure: (_, __) => '0',
                pending: (_) => '-',
              ),
              () {
                // 팔로워 목록 화면으로 이동 (추후 구현)
                _showFollowListDialog(context, ref, userId, true);
              },
            ),
            const VerticalDivider(),
            // 팔로잉 수
            // 다국어: 팔로잉 라벨
            _buildFollowStatItem(
              context,
              ref,
              l10n.following,
              followState.followingCountResult.when(
                success: (count) => count.toString(),
                failure: (_, __) => '0',
                pending: (_) => '-',
              ),
              () {
                // 팔로잉 목록 화면으로 이동 (추후 구현)
                _showFollowListDialog(context, ref, userId, false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowStatItem(
    BuildContext context,
    WidgetRef ref,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showFollowListDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
    bool isFollowers,
  ) {
    // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // 다국어: 팔로워/팔로잉 목록 다이얼로그 제목
        title: Text(isFollowers ? l10n.follower : l10n.following),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _buildFollowList(context, ref, userId, isFollowers),
        ),
        actions: [
          // 다국어: 닫기 버튼
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowList(
    BuildContext context,
    WidgetRef ref,
    String userId,
    bool isFollowers,
  ) {
    final followDatasource = ref.read(supabaseFollowDatasourceProvider);
    final future = isFollowers
        ? followDatasource.getFollowers(userId)
        : followDatasource.getFollowing(userId);

    return FutureBuilder<Result<List<User>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
          final l10n = AppLocalizations.of(context)!;
          return Center(
            // 다국어: 오류 메시지
            child: Text(
              l10n.errorOccurred(snapshot.error.toString()),
              style: TextStyle(color: Colors.red[700]),
            ),
          );
        }

        // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
        final l10n = AppLocalizations.of(context)!;
        final result = snapshot.data;
        if (result == null) {
          // 다국어: 데이터 로드 오류 메시지
          return Center(child: Text(l10n.dataLoadError));
        }

        return result.when(
          success: (users) {
            if (users.isEmpty) {
              return Center(
                // 다국어: 팔로워/팔로잉 목록이 비어있을 때 메시지
                child: Text(
                  isFollowers ? l10n.followersEmpty : l10n.followingEmpty,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              );
            }

            // 현재 사용자 정보 가져오기
            final authResult = ref.read(authViewModelProvider);
            final currentUser = authResult.when(
              success: (user) => user,
              failure: (_, __) => null,
              pending: (_) => null,
            );
            final currentUserId = currentUser?.id;

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final isCurrentUser = currentUserId == user.id;
                final canFollow = !isCurrentUser && currentUserId != null;
                
                // 팔로우 상태 확인 (현재 사용자가 해당 사용자를 팔로우하는지)
                final followState = canFollow
                    ? ref.watch(followViewModelProvider(user.id))
                    : null;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.profileImageUrl != null &&
                            user.profileImageUrl!.isNotEmpty
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                    child: user.profileImageUrl == null ||
                            user.profileImageUrl!.isEmpty
                        ? Text(user.name[0].toUpperCase())
                        : null,
                  ),
                  title: Text(user.name),
                  subtitle: user.email.isNotEmpty ? Text(user.email) : null,
                  trailing: canFollow && followState != null
                      ? _buildFollowButton(context, ref, user.id, followState)
                      : null,
                );
              },
            );
          },
          failure: (message, error) {
            // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
            final l10n = AppLocalizations.of(context)!;
            return Center(
              // 다국어: 오류 메시지
              child: Text(
                l10n.errorOccurred(message),
                style: TextStyle(color: Colors.red[700]),
              ),
            );
          },
          pending: (_) {
            return const Center(child: CircularProgressIndicator());
          },
        );
      },
    );
  }

  /// 팔로우/언팔로우 버튼
  Widget _buildFollowButton(
    BuildContext context,
    WidgetRef ref,
    String targetUserId,
    FollowState followState,
  ) {
    // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
    final l10n = AppLocalizations.of(context)!;
    final isFollowing = followState.isFollowingResult.when(
      success: (value) => value,
      failure: (_, __) => false,
      pending: (_) => false,
    );

    return followState.isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : TextButton(
            onPressed: () async {
              final viewModel = ref.read(followViewModelProvider(targetUserId).notifier);
              await viewModel.toggleFollow();
              
              // 현재 사용자의 팔로잉 수도 갱신
              final authResult = ref.read(authViewModelProvider);
              final currentUser = authResult.when(
                success: (user) => user,
                failure: (_, __) => null,
                pending: (_) => null,
              );
              if (currentUser != null) {
                ref.invalidate(followViewModelProvider(currentUser.id));
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(80, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            // 다국어: 팔로우/언팔로우 버튼 텍스트
            child: Text(
              isFollowing ? l10n.unfollow : l10n.follow,
              style: TextStyle(
                fontSize: 12,
                color: isFollowing ? Colors.grey[700] : Theme.of(context).primaryColor,
              ),
            ),
          );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // 다국어: 로그아웃 다이얼로그 제목
        title: Text(l10n.logout),
        // 다국어: 로그아웃 확인 메시지
        content: Text(l10n.logoutConfirm),
        actions: [
          // 다국어: 취소 버튼
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          // 다국어: 로그아웃 버튼
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authViewModelProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: Text(
              l10n.logout,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

