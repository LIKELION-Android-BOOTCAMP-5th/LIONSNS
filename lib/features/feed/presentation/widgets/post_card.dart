import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lionsns/l10n/app_localizations.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/features/feed/models/post.dart';
import 'package:lionsns/features/auth/models/user.dart';
import 'package:lionsns/features/auth/presentation/providers/providers.dart' as auth_providers;
import 'package:lionsns/features/auth/presentation/widgets/user_profile_options_sheet.dart';
import 'package:lionsns/features/auth/data/datasources/supabase_profile_datasource.dart';

/// 게시글 카드 위젯
class PostCard extends ConsumerWidget {
  final Post post;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authResult = ref.watch(auth_providers.authViewModelProvider);
    final currentUser = authResult.when(
      success: (user) => user,
      failure: (_, __) => null,
      pending: (_) => null,
    );
    
    final currentUserId = currentUser?.id;
    final isCurrentUser = currentUserId != null && currentUserId == post.authorId;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      onPressed: () {
                        // 삭제 확인 다이얼로그
                        // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
                        final l10n = AppLocalizations.of(context)!;
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            // 다국어: 삭제 확인 다이얼로그 제목
                            title: Text(l10n.postDeleteTitle),
                            // 다국어: 삭제 확인 메시지
                            content: Text(l10n.postDeleteConfirm),
                            actions: [
                              // 다국어: 취소 버튼
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(l10n.cancel),
                              ),
                              // 다국어: 삭제 버튼
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onDelete!();
                                },
                                child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // 이미지 표시
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.imageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 디폴트 이미지 아이콘
                            Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 48,
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
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  // 프로필 이미지 및 이름 (터치 가능)
                  GestureDetector(
                    onTap: isCurrentUser
                        ? null
                        : () => _showUserProfileOptions(context, ref, post.authorId, post.authorName ?? post.author, post.authorImageUrl, currentUserId),
                    child: Row(
                      children: [
                        // 프로필 이미지
                        Builder(
                          builder: (context) {
                            final authorInitial = (post.authorName ?? post.author).isNotEmpty
                                ? (post.authorName ?? post.author)[0].toUpperCase()
                                : 'U';
                            
                            if (post.authorImageUrl == null || post.authorImageUrl!.isEmpty) {
                              return Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                    child: Text(
                                      authorInitial,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                  if (!isCurrentUser && currentUserId != null)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: _buildFollowIndicator(context, ref, post.authorId, currentUserId),
                                    ),
                                ],
                              );
                            }
                            
                            return Stack(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  child: ClipOval(
                                    child: Image.network(
                                      post.authorImageUrl!,
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 24,
                                          height: 24,
                                          color: Colors.grey[200],
                                          child: Center(
                                            child: Text(
                                              authorInitial,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).primaryColor,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          width: 24,
                                          height: 24,
                                          color: Colors.grey[200],
                                          child: Center(
                                            child: SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                if (!isCurrentUser && currentUserId != null)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: _buildFollowIndicator(context, ref, post.authorId, currentUserId),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          post.authorName ?? post.author,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // 좋아요 수
                  Icon(
                    post.isLiked == true ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: post.isLiked == true ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likesCount ?? 0}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 댓글 수
                  const Icon(Icons.comment_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentsCount ?? 0}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(context, post.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 다국어 지원: 날짜 포맷팅 함수
  String _formatDate(BuildContext context, DateTime date) {
    // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      // 다국어를 사용할 수 없을 때 폴백
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inDays > 0) {
        return '${difference.inDays}일 전';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}시간 전';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}분 전';
      } else {
        return '방금 전';
      }
    }
    
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          // 다국어: 방금 전
          return l10n.justNow;
        }
        // 다국어: N분 전
        return l10n.minutesAgo(difference.inMinutes);
      }
      // 다국어: N시간 전
      return l10n.hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      // 다국어: N일 전
      return l10n.daysAgo(difference.inDays);
    } else {
      // 다국어: 날짜 포맷 (년/월/일)
      return l10n.dateFormat(date.year, date.month, date.day);
    }
  }

  /// 팔로우 상태 인디케이터
  Widget _buildFollowIndicator(BuildContext context, WidgetRef ref, String authorId, String currentUserId) {
    final followState = ref.watch(auth_providers.followViewModelProvider(authorId));
    
    return followState.isFollowingResult.when(
      success: (isFollowing) {
        if (!isFollowing) return const SizedBox.shrink();
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
        );
      },
      failure: (_, __) => const SizedBox.shrink(),
      pending: (_) => const SizedBox.shrink(),
    );
  }

  /// 사용자 프로필 옵션 표시
  Future<void> _showUserProfileOptions(
    BuildContext context,
    WidgetRef ref,
    String authorId,
    String authorName,
    String? authorImageUrl,
    String? currentUserId,
  ) async {
    if (currentUserId == null) return;

    // 프로필 정보 가져오기
    final profileDatasource = SupabaseProfileDatasource();
    final profileResult = await profileDatasource.getProfile(authorId);
    
    final user = profileResult.when(
      success: (user) => user,
      failure: (_, __) => null,
      pending: (_) => null,
    );

    if (user == null) {
      // 프로필이 없으면 기본 정보로 User 생성
      final defaultUser = User(
        id: authorId,
        name: authorName,
        email: '',
        profileImageUrl: authorImageUrl,
        provider: AuthProvider.google, // 기본값
        createdAt: DateTime.now(),
      );
      
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          builder: (context) => UserProfileOptionsSheet(
            user: defaultUser,
            currentUserId: currentUserId,
          ),
        );
      }
    } else {
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          builder: (context) => UserProfileOptionsSheet(
            user: user,
            currentUserId: currentUserId,
          ),
        );
      }
    }
  }
}

