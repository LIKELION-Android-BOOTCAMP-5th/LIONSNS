import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lionsns/l10n/app_localizations.dart';
import 'package:lionsns/config/router.dart';
import 'package:lionsns/core/widgets/common_app_bar.dart';
import 'package:lionsns/features/feed/models/post.dart';
import 'package:lionsns/core/utils/result.dart';
import '../providers/providers.dart';
import '../viewmodels/post_detail_viewmodel.dart';
import 'package:lionsns/features/auth/presentation/providers/providers.dart' as auth_providers;
import 'package:lionsns/features/auth/presentation/widgets/user_profile_options_sheet.dart';
import 'package:lionsns/features/auth/data/datasources/supabase_profile_datasource.dart';
import 'package:lionsns/features/auth/models/user.dart';

/// 게시글 상세 화면
class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _commentFocusNode = FocusNode();

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLike() async {
    final viewModel = ref.read(postDetailViewModelProvider(widget.postId).notifier);
    await viewModel.toggleLike(widget.postId);
  }

  Future<void> _handleAddComment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 키보드 닫기
    FocusScope.of(context).unfocus();

    final viewModel = ref.read(postDetailViewModelProvider(widget.postId).notifier);
    await viewModel.addComment(widget.postId, _commentController.text);
    _commentController.clear();
  }

  Future<void> _handleDeleteComment(String commentId) async {
    // 키보드 닫기 (댓글 삭제 다이얼로그 표시 전)
    FocusScope.of(context).unfocus();
    // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        // 다국어: 댓글 삭제 다이얼로그 제목
        title: Text(l10n.commentDelete),
        // 다국어: 댓글 삭제 확인 메시지
        content: Text(l10n.commentDeleteConfirm),
        actions: [
          // 다국어: 취소 버튼
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          // 다국어: 삭제 버튼
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final viewModel = ref.read(postDetailViewModelProvider(widget.postId).notifier);
      await viewModel.deleteComment(commentId, widget.postId);
      // 댓글 삭제 후에도 키보드가 닫혀있도록 보장
      if (mounted) {
        _commentFocusNode.unfocus();
        FocusScope.of(context).unfocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
    final l10n = AppLocalizations.of(context)!;
    final authDatasource = ref.read(auth_providers.supabaseAuthDatasourceProvider);
    final currentUserId = authDatasource.getCurrentUserId();
    final state = ref.watch(postDetailViewModelProvider(widget.postId));

    // 에러 메시지 표시
    ref.listen<PostDetailState>(
      postDetailViewModelProvider(widget.postId),
      (previous, next) {
        if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: CommonAppBar(
        // 다국어: 게시글 상세 화면 제목
        title: Text(l10n.postDetail),
        actions: [
          // 수정 버튼 (작성자만)
          state.postResult == null
              ? const SizedBox.shrink()
              : state.postResult!.when(
                  success: (post) {
                    if (post.authorId == currentUserId) {
                      return IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          context.push('${AppRoutes.postCreate}?postId=${widget.postId}').then((_) {
                            ref.invalidate(postDetailViewModelProvider(widget.postId));
                            ref.read(postListViewModelProvider.notifier).loadPosts();
                          });
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  failure: (_, __) => const SizedBox.shrink(),
                  pending: (_) => const SizedBox.shrink(),
                ),
        ],
      ),
      body: Column(
        children: [
          // 게시글 내용 영역 (전체 화면을 채움)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 게시글 및 좋아요/댓글 카운트 영역 (전체 화면 채움)
                        LayoutBuilder(
                          builder: (context, innerConstraints) {
                            final isLoading = state.postResult == null && state.isLoading || 
                                            (state.postResult != null && state.postResult!.when(
                                              success: (_) => false,
                                              failure: (_, __) => false,
                                              pending: (_) => true,
                                            ));
                            
                            return Stack(
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // 게시글 로딩 상태에 따른 표시
                                            state.postResult == null
                                                ? _buildPostLoadingSkeleton(context)
                                                : state.postResult!.when(
                                                    success: (Post post) => _buildPostContent(context, post, state, currentUserId),
                                                    failure: (message, error) => _buildPostError(context, message, error),
                                                    pending: (_) => _buildPostLoadingSkeleton(context),
                                                  ),

                                            const SizedBox(height: 24),
                                            const Divider(),
                                            const SizedBox(height: 16),

                                            // 좋아요 및 댓글 수
                                            state.postResult?.when(
                                                  success: (post) => Row(
                                                    children: [
                                                      state.isLiking
                                                          ? const Padding(
                                                              padding: EdgeInsets.all(12.0),
                                                              child: SizedBox(
                                                                width: 24,
                                                                height: 24,
                                                                child: CircularProgressIndicator(strokeWidth: 2),
                                                              ),
                                                            )
                                                          : IconButton(
                                                              icon: Icon(
                                                                post.isLiked == true ? Icons.favorite : Icons.favorite_border,
                                                                color: post.isLiked == true ? Colors.red : null,
                                                              ),
                                                              onPressed: currentUserId != null && 
                                                                  !state.isLiking && 
                                                                  post.authorId != currentUserId
                                                                  ? _handleLike
                                                                  : null,
                                                            ),
                                                      Text('${post.likesCount ?? 0}'),
                                                      const SizedBox(width: 24),
                                                      const Icon(Icons.comment_outlined),
                                                      const SizedBox(width: 8),
                                                      Text('${post.commentsCount ?? 0}'),
                                                    ],
                                                  ),
                                                  failure: (_, __) => const SizedBox.shrink(),
                                                  pending: (_) => const SizedBox.shrink(),
                                                ) ??
                                                const SizedBox.shrink(),

                                            // 댓글 목록 (좋아요/댓글 카운트 바로 밑에)
                                            const SizedBox(height: 16),
                                            const Divider(height: 1),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                                              // 다국어: 댓글 섹션 제목
                                              child: Text(
                                                l10n.comment,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const Divider(height: 1),
                                            state.commentsResult == null
                                                ? state.isLoading
                                                    ? const Padding(
                                                        padding: EdgeInsets.all(16.0),
                                                        child: Center(
                                                          child: CircularProgressIndicator(),
                                                        ),
                                                      )
                                                    : const SizedBox.shrink()
                                                : state.commentsResult!.when(
                                                    success: (comments) {
                                                      if (comments.isEmpty) {
                                                        return Padding(
                                                          padding: const EdgeInsets.all(32.0),
                                                          child: Center(
                                                            // 다국어: 댓글이 없을 때 메시지
                                                            child: Text(
                                                              l10n.commentEmpty,
                                                              style: TextStyle(
                                                                color: Colors.grey[600],
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      }

                                                      return ListView.separated(
                                                        shrinkWrap: true,
                                                        physics: const NeverScrollableScrollPhysics(),
                                                        itemCount: comments.length,
                                                        separatorBuilder: (context, index) => const Divider(),
                                                        itemBuilder: (context, index) {
                                                          final comment = comments[index];
                                                          final isAuthor = comment.userId == currentUserId;
                                                          final isCommentAuthorCurrentUser = comment.userId == currentUserId;
                                                          
                                                          return ListTile(
                                                            leading: GestureDetector(
                                                              onTap: !isCommentAuthorCurrentUser && currentUserId != null
                                                                  ? () => _showUserProfileOptions(
                                                                        context,
                                                                        comment.userId,
                                                                        // 다국어: 익명 사용자 이름 (이름이 없을 때)
                                                                        comment.authorName ?? l10n.anonymous,
                                                                        comment.authorImageUrl,
                                                                        currentUserId,
                                                                      )
                                                                  : null,
                                                              child: Stack(
                                                                children: [
                                                                  _buildAvatar(
                                                                    context,
                                                                    imageUrl: comment.authorImageUrl,
                                                                    radius: 20,
                                                                    fallbackText: (comment.authorName ?? 'U')[0].toUpperCase(),
                                                                  ),
                                                                  if (!isCommentAuthorCurrentUser && currentUserId != null)
                                                                    Positioned(
                                                                      right: 0,
                                                                      bottom: 0,
                                                                      child: _buildFollowIndicator(context, ref, comment.userId, currentUserId),
                                                                    ),
                                                                ],
                                                              ),
                                                            ),
                                                            title: GestureDetector(
                                                              onTap: !isCommentAuthorCurrentUser && currentUserId != null
                                                                  ? () => _showUserProfileOptions(
                                                                        context,
                                                                        comment.userId,
                                                                        // 다국어: 익명 사용자 이름 (이름이 없을 때)
                                                                        comment.authorName ?? l10n.anonymous,
                                                                        comment.authorImageUrl,
                                                                        currentUserId,
                                                                      )
                                                                  : null,
                                                              // 다국어: 익명 사용자 이름 (이름이 없을 때)
                                                              child: Text(
                                                                comment.authorName ?? l10n.anonymous,
                                                                style: const TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ),
                                                            subtitle: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                const SizedBox(height: 4),
                                                                Text(comment.content),
                                                                const SizedBox(height: 4),
                                                                Text(
                                                                  _formatDate(context, comment.createdAt),
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    color: Colors.grey[600],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            trailing: isAuthor
                                                                ? IconButton(
                                                                    icon: const Icon(Icons.delete_outline, size: 20),
                                                                    onPressed: () => _handleDeleteComment(comment.id),
                                                                  )
                                                                : null,
                                                          );
                                                        },
                                                      );
                                                    },
                                                    failure: (message, _) => Padding(
                                                      padding: const EdgeInsets.all(16.0),
                                                      // 다국어: 댓글 로드 오류 메시지
                                                      child: Text(
                                                        l10n.commentLoadError(message),
                                                        style: TextStyle(color: Colors.red[700]),
                                                      ),
                                                    ),
                                                    pending: (_) => const Padding(
                                                      padding: EdgeInsets.all(16.0),
                                                      child: Center(
                                                        child: CircularProgressIndicator(),
                                                      ),
                                                    ),
                                                  ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // 로딩 인디케이터 오버레이
                                if (isLoading)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.white.withOpacity(0.7),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 댓글 작성 폼
          if (currentUserId != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                key: _formKey,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _commentController,
                        focusNode: _commentFocusNode,
                        decoration: InputDecoration(
                          // 다국어: 댓글 입력 필드 힌트
                          hintText: l10n.commentInputHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onFieldSubmitted: (_) {
                          // 엔터 키를 눌렀을 때도 키보드가 자동으로 닫히도록
                          _handleAddComment();
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            // 다국어: 댓글 입력 오류 메시지
                            return l10n.commentInputError;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    state.isCommenting
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: state.isCommenting ? null : _handleAddComment,
                            color: Theme.of(context).primaryColor,
                          ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 게시글 로딩 스켈레톤 UI
  Widget _buildPostLoadingSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목 스켈레톤
        Container(
          width: double.infinity,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 16),
        // 작성자 정보 스켈레톤
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // 내용 스켈레톤
        Container(
          width: double.infinity,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 200,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  /// 게시글 내용 UI
  Widget _buildPostContent(BuildContext context, Post post, PostDetailState state, String? currentUserId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        Text(
          post.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // 작성자 정보 (터치 가능)
        GestureDetector(
          onTap: currentUserId != null && currentUserId != post.authorId
              ? () => _showUserProfileOptions(
                    context,
                    post.authorId,
                    post.authorName ?? post.author,
                    post.authorImageUrl,
                    currentUserId,
                  )
              : null,
          child: Row(
            children: [
              Stack(
                children: [
                  _buildAvatar(
                    context,
                    imageUrl: post.authorImageUrl,
                    radius: 20,
                    fallbackText: (post.authorName ?? post.author)[0].toUpperCase(),
                  ),
                  if (currentUserId != null && currentUserId != post.authorId)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: _buildFollowIndicator(context, ref, post.authorId, currentUserId),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName ?? post.author,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(context, post.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 내용
        Text(
          post.content,
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
          ),
        ),

        // 이미지 표시
        Builder(
          builder: (context) {
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
              return Column(
                children: [
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      post.imageUrl!,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: double.infinity,
                          height: 300,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        final l10n = AppLocalizations.of(context)!;
                        return Container(
                          width: double.infinity,
                          height: 300,
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              // 다국어: 이미지 라벨
                              Text(
                                l10n.image,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  /// 게시글 에러 UI
  Widget _buildPostError(BuildContext context, String message, Object? error) {
    // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(postDetailViewModelProvider(widget.postId).notifier).loadPost(widget.postId);
              },
              icon: const Icon(Icons.refresh),
              // 다국어: 다시 시도 버튼
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  // 다국어 지원: 날짜 포맷팅 함수
  String _formatDate(BuildContext context, DateTime date) {
    // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (l10n == null) {
      // 다국어를 사용할 수 없을 때 폴백 (영어)
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Just now';
          }
          return '${difference.inMinutes} minutes ago';
        }
        return '${difference.inHours} hours ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.year}/${date.month}/${date.day}';
      }
    }

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
  Widget _buildFollowIndicator(BuildContext context, WidgetRef ref, String userId, String currentUserId) {
    final followState = ref.watch(auth_providers.followViewModelProvider(userId));
    
    return followState.isFollowingResult.when(
      success: (isFollowing) {
        if (!isFollowing) return const SizedBox.shrink();
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
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
    String userId,
    String userName,
    String? userImageUrl,
    String? currentUserId,
  ) async {
    if (currentUserId == null) return;

    // 프로필 정보 가져오기
    final profileDatasource = SupabaseProfileDatasource();
    final profileResult = await profileDatasource.getProfile(userId);
    
    final user = profileResult.when(
      success: (user) => user,
      failure: (_, __) => null,
      pending: (_) => null,
    );

    if (user == null) {
      // 프로필이 없으면 기본 정보로 User 생성
      final defaultUser = User(
        id: userId,
        name: userName,
        email: '',
        profileImageUrl: userImageUrl,
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

  Widget _buildAvatar(
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
            fontSize: radius * 0.5,
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
                  // 디폴트 아이콘 (작은 크기)
                  Center(
                    child: Icon(
                      Icons.person_outline,
                      size: radius,
                      color: Colors.grey[400],
                    ),
                  ),
                  // 로딩 인디케이터
                  Center(
                    child: SizedBox(
                      width: radius * 0.6,
                      height: radius * 0.6,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
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
                    fontSize: radius * 0.5,
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
}
