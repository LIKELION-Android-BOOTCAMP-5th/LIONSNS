import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lionsns/l10n/app_localizations.dart';
import 'package:lionsns/config/router.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/features/auth/models/user.dart';
import 'package:lionsns/features/auth/presentation/providers/providers.dart';
import 'package:lionsns/features/chat/presentation/providers/providers.dart' as chat_providers;

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
          
          // 채팅하기 버튼 (자기 자신이 아닐 때만)
          if (!isCurrentUser && currentUserId != null)
            ListTile(
              leading: Icon(
                Icons.chat,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('채팅하기'),
              onTap: () async {
                // Sheet를 닫지 않고 먼저 채팅방 조회
                // 새 화면이 열리면 sheet가 자동으로 닫힘
                await _navigateToChat(context, ref, currentUserId!, user.id);
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

  /// 채팅방으로 이동
  Future<void> _navigateToChat(
    BuildContext context,
    WidgetRef ref,
    String currentUserId,
    String otherUserId,
  ) async {
    // 로딩 다이얼로그를 표시할 때 사용할 Navigator 저장
    final navigator = Navigator.of(context, rootNavigator: true);
    
    try {
      debugPrint('[UserProfileOptionsSheet] 채팅방 이동 시작 - currentUserId: $currentUserId, otherUserId: $otherUserId');
      
      // 로딩 표시
      if (!context.mounted) {
        debugPrint('[UserProfileOptionsSheet] context가 mounted되지 않음');
        return;
      }
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 채팅방 생성 또는 조회
      final datasource = ref.read(chat_providers.chatDatasourceProvider);
      
      debugPrint('[UserProfileOptionsSheet] UseCase 호출 시작');
      final result = await datasource.getOrCreateChatRoom(
        user1Id: currentUserId,
        user2Id: otherUserId,
      );
      debugPrint('[UserProfileOptionsSheet] UseCase 호출 완료');

      // result 처리
      result.when(
        success: (chatRoom) {
          debugPrint('[UserProfileOptionsSheet] 채팅방 조회 성공 - chatRoomId: ${chatRoom.id}');
          
          // 로딩 다이얼로그 닫기
          try {
            navigator.pop();
            debugPrint('[UserProfileOptionsSheet] 로딩 다이얼로그 닫기 완료');
          } catch (e) {
            debugPrint('[UserProfileOptionsSheet] 다이얼로그 닫기 실패: $e');
          }
          
          // Sheet를 닫지 않고 바로 채팅 화면으로 이동
          // 새 화면이 열리면 Sheet가 자동으로 닫힘
          if (context.mounted) {
            debugPrint('[UserProfileOptionsSheet] 채팅 화면으로 이동 시작');
            // push를 사용하여 Sheet 위에 새 화면을 엶
            context.push('/chat/${chatRoom.id}').then((_) {
              // 채팅 화면에서 돌아왔을 때 Sheet가 아직 열려있으면 닫기
              if (context.mounted) {
                try {
                  Navigator.of(context).pop();
                  debugPrint('[UserProfileOptionsSheet] 채팅 화면에서 돌아온 후 Sheet 닫기 완료');
                } catch (e) {
                  debugPrint('[UserProfileOptionsSheet] Sheet 닫기 시도 중 오류 (무시 가능): $e');
                }
              }
            });
            
            // Sheet 닫기 (새 화면이 열린 후 약간의 지연)
            Future.delayed(const Duration(milliseconds: 500), () {
              if (context.mounted) {
                try {
                  Navigator.of(context).pop();
                  debugPrint('[UserProfileOptionsSheet] Sheet 닫기 완료');
                } catch (e) {
                  debugPrint('[UserProfileOptionsSheet] Sheet 닫기 실패 (이미 닫혔을 수 있음): $e');
                }
              }
            });
            
            debugPrint('[UserProfileOptionsSheet] 채팅 화면으로 이동 요청 완료');
          } else {
            debugPrint('[UserProfileOptionsSheet] context가 mounted되지 않아 이동 실패');
          }
        },
        failure: (message, error) {
          debugPrint('[UserProfileOptionsSheet] 채팅방 조회 실패 - message: $message, error: $error');
          
          // 로딩 다이얼로그 닫기
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          
          // 에러 메시지 표시
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        },
      );
    } catch (e, stackTrace) {
      debugPrint('[UserProfileOptionsSheet] 예외 발생: $e');
      debugPrint('[UserProfileOptionsSheet] 스택 트레이스: $stackTrace');
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // 로딩 다이얼로그 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채팅방을 열 수 없습니다: $e')),
      );
    }
  }
}

