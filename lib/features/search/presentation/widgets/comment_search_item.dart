import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lionsns/l10n/app_localizations.dart';
import 'package:lionsns/config/router.dart';
import 'package:lionsns/features/feed/models/comment.dart';

/// 검색 결과 댓글 아이템
class CommentSearchItem extends StatelessWidget {
  final Comment comment;

  const CommentSearchItem({
    super.key,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => context.push(AppRoutes.postDetail(comment.postId)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (comment.authorImageUrl != null)
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(comment.authorImageUrl!),
                    )
                  else
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      child: Text(
                        (comment.authorName ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    // 다국어: 익명 사용자 이름 (이름이 없을 때)
                    child: Text(
                      comment.authorName ?? l10n.anonymous,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                comment.content,
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
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
      if (difference.inDays > 7) {
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } else if (difference.inDays > 0) {
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
}

