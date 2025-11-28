import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lionsns/l10n/app_localizations.dart';
import 'package:lionsns/config/router.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/features/auth/models/user.dart';
import 'package:lionsns/features/auth/presentation/providers/providers.dart';

/// 사용자 프로필 옵션 바텀시트
class UserProfileOptionsSheet extends ConsumerWidget {
  final User user;
  final String? currentUserId;

  const UserProfileOptionsSheet({
    super.key,
    required this.user,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
    final l10n = AppLocalizations.of(context)!;
    final isCurrentUser = currentUserId != null && currentUserId == user.id;
    
    // 자기 자신이 아니고 로그인한 경우에만 팔로우 상태 확인
    final followState = !isCurrentUser && currentUserId != null
        ? ref.watch(followViewModelProvider(user.id))
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 프로필 정보
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                // 프로필 이미지
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  backgroundImage: user.profileImageUrl != null &&
                          user.profileImageUrl!.isNotEmpty
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: user.profileImageUrl == null ||
                          user.profileImageUrl!.isEmpty
                      ? Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // 이름
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (user.email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          
          // 옵션 버튼들
          if (!isCurrentUser && currentUserId != null && followState != null) ...[
            // 팔로우/언팔로우 버튼
            ListTile(
              leading: Icon(
                followState.isFollowingResult.when(
                  success: (isFollowing) => isFollowing
                      ? Icons.person_remove
                      : Icons.person_add,
                  failure: (_, __) => Icons.person_add,
                  pending: (_) => Icons.person_add,
                ),
                color: Theme.of(context).primaryColor,
              ),
              // 다국어: 팔로우/언팔로우 버튼 텍스트
              title: Text(
                followState.isFollowingResult.when(
                  success: (isFollowing) => isFollowing ? l10n.unfollow : l10n.follow,
                  failure: (_, __) => l10n.follow,
                  pending: (_) => l10n.loading,
                ),
              ),
              onTap: followState.isLoading
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
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
            ),
            const Divider(),
          ],
          
          // 프로필 보기 버튼
          ListTile(
            leading: Icon(
              Icons.person_outline,
              color: Theme.of(context).primaryColor,
            ),
            // 다국어: 프로필 보기 버튼
            title: Text(AppLocalizations.of(context)!.profileView),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.userProfile(user.id));
            },
          ),
          
          const SizedBox(height: 8),
          
          // 취소 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                // 다국어: 취소 버튼
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

