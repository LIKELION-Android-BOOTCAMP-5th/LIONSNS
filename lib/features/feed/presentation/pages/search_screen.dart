import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lionsns/l10n/app_localizations.dart';
import 'package:lionsns/config/router.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/features/search/data/datasources/supabase_search_datasource.dart';
import 'package:lionsns/features/search/presentation/providers/providers.dart';
import 'package:lionsns/features/feed/presentation/widgets/post_card.dart';
import 'package:lionsns/features/search/presentation/widgets/comment_search_item.dart';
import 'package:lionsns/features/search/presentation/widgets/user_search_item.dart';

/// 검색 화면
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim() != _currentQuery) {
      _currentQuery = query.trim();
      if (_currentQuery.isNotEmpty) {
        ref.read(searchProvider.notifier).search(_currentQuery);
      } else {
        ref.read(searchProvider.notifier).clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
    final l10n = AppLocalizations.of(context)!;
    final searchResult = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        // 다국어: 검색 화면 제목
        title: Text(l10n.search),
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            // 다국어: 포스트 탭
            Tab(text: l10n.tabPost),
            // 다국어: 댓글 탭
            Tab(text: l10n.tabComment),
            // 다국어: 사용자 탭
            Tab(text: l10n.tabUser),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                // 다국어: 검색어 입력 힌트
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _currentQuery = '';
                          ref.read(searchProvider.notifier).clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {});
                // 디바운싱: 500ms 후 검색 실행
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted && _searchController.text == value) {
                    _performSearch(value);
                  }
                });
              },
              onSubmitted: (value) {
                _performSearch(value);
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 포스트 탭
                _buildPostsTab(searchResult, l10n),
                // 댓글 탭
                _buildCommentsTab(searchResult, l10n),
                // 사용자 탭
                _buildUsersTab(searchResult, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab(Result<SearchResults> searchResult, AppLocalizations l10n) {
    return searchResult.when(
      success: (results) {
        if (_currentQuery.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                // 다국어: 검색어 입력 안내 메시지
                Text(
                  l10n.searchHint,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        if (results.posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                // 다국어: 검색 결과 없음 메시지
                Text(
                  l10n.searchNoResults,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: results.posts.length,
          itemBuilder: (context, index) {
            final post = results.posts[index];
            return PostCard(
              post: post,
              onTap: () => context.push(AppRoutes.postDetail(post.id)),
            );
          },
        );
      },
      failure: (message, error) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              // 다국어: 검색 오류 메시지
              Text(
                l10n.searchError,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
      pending: (_) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              // 다국어: 검색 중 메시지
              Text(
                l10n.searchLoading,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentsTab(Result<SearchResults> searchResult, AppLocalizations l10n) {
    return searchResult.when(
      success: (results) {
        if (_currentQuery.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                // 다국어: 검색어 입력 안내 메시지
                Text(
                  l10n.searchHint,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        if (results.comments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.comment_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                // 다국어: 검색 결과 없음 메시지
                Text(
                  l10n.searchNoResults,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: results.comments.length,
          itemBuilder: (context, index) {
            final comment = results.comments[index];
            return CommentSearchItem(comment: comment);
          },
        );
      },
      failure: (message, error) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              // 다국어: 검색 오류 메시지
              Text(
                l10n.searchError,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        );
      },
      pending: (_) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              // 다국어: 검색 중 메시지
              Text(
                l10n.searchLoading,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsersTab(Result<SearchResults> searchResult, AppLocalizations l10n) {
    return searchResult.when(
      success: (results) {
        if (_currentQuery.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                // 다국어: 검색어 입력 안내 메시지
                Text(
                  l10n.searchHint,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        if (results.users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                // 다국어: 검색 결과 없음 메시지
                Text(
                  l10n.searchNoResults,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: results.users.length,
          itemBuilder: (context, index) {
            final user = results.users[index];
            return UserSearchItem(user: user);
          },
        );
      },
      failure: (message, error) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              // 다국어: 검색 오류 메시지
              Text(
                l10n.searchError,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        );
      },
      pending: (_) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              // 다국어: 검색 중 메시지
              Text(
                l10n.searchLoading,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
