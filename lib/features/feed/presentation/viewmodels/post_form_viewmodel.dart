import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lionsns/features/feed/models/post.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/features/feed/data/datasources/supabase_post_datasource.dart';
import 'package:lionsns/features/auth/data/datasources/supabase_auth_datasource.dart';

/// 게시글 폼 상태
class PostFormState {
  final String title;
  final String content;
  final String? imagePath; // 로컬 파일 경로 또는 URL
  final bool isLoading;
  final String? errorMessage;

  const PostFormState({
    this.title = '',
    this.content = '',
    this.imagePath,
    this.isLoading = false,
    this.errorMessage,
  });

  PostFormState copyWith({
    String? title,
    String? content,
    String? imagePath,
    bool? isLoading,
    String? errorMessage,
    bool clearImagePath = false, // imagePath를 명시적으로 null로 설정하려면 true
  }) {
    return PostFormState(
      title: title ?? this.title,
      content: content ?? this.content,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class PostFormViewModel extends StateNotifier<PostFormState> {
  final SupabasePostDatasource _datasource;
  final SupabaseAuthDatasource _authDatasource = SupabaseAuthDatasource();

  PostFormViewModel(this._datasource) : super(const PostFormState());

  /// 제목 변경
  void updateTitle(String title) {
    state = state.copyWith(title: title, errorMessage: null);
  }

  /// 내용 변경
  void updateContent(String content) {
    state = state.copyWith(content: content, errorMessage: null);
  }

  /// 이미지 경로 변경
  void updateImagePath(String? imagePath) {
    state = state.copyWith(imagePath: imagePath, errorMessage: null);
  }

  /// 게시글 생성
  Future<Result<Post>> createPost() async {
    if (state.title.isEmpty || state.content.isEmpty) {
      state = state.copyWith(
        errorMessage: '제목과 내용을 입력해주세요',
      );
      return const Failure('제목과 내용을 입력해주세요');
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final currentUserId = _authDatasource.getCurrentUserId();
    if (currentUserId == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '로그인이 필요합니다',
      );
      return const Failure('로그인이 필요합니다');
    }

    final post = Post.create(
      title: state.title,
      content: state.content,
      authorId: currentUserId,
      imageUrl: state.imagePath,
    );

    final result = await _datasource.createPost(post);

    state = state.copyWith(
      isLoading: false,
      errorMessage: result.when(
        success: (_) => null,
        failure: (message, _) => message,
      ),
    );

    // 성공시 폼 리셋
    if (result is Success) {
      state = const PostFormState();
    }

    return result;
  }

  /// 게시글 수정
  Future<Result<Post>> updatePost(String id) async {
    if (state.title.isEmpty || state.content.isEmpty) {
      state = state.copyWith(
        errorMessage: '제목과 내용을 입력해주세요',
      );
      return const Failure('제목과 내용을 입력해주세요');
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final getResult = await _datasource.getPostById(id);
    final post = getResult.when(
      success: (p) => p,
      failure: (message, _) {
        state = state.copyWith(isLoading: false, errorMessage: message);
        return null;
      },
    );

    if (post == null) {
      return const Failure('게시글을 찾을 수 없습니다');
    }

    // 이미지 처리: 새 이미지가 있으면 사용, 없으면 기존 이미지 유지
    // state.imagePath가 로컬 파일 경로면 새 이미지로 업로드, URL이면 그대로 사용, null이면 기존 이미지 유지
    final imageUrlToUse = state.imagePath ?? post.imageUrl;
    
    final updatedPost = post.copyWith(
      title: state.title,
      content: state.content,
      imageUrl: imageUrlToUse,
      updatedAt: DateTime.now(),
    );

    final result = await _datasource.updatePost(updatedPost);

    state = state.copyWith(
      isLoading: false,
      errorMessage: result.when(
        success: (_) => null,
        failure: (message, _) => message,
      ),
    );

    // 성공시 폼 리셋
    if (result is Success) {
      state = const PostFormState();
    }

    return result;
  }

  /// 폼 로드 (수정용)
  Future<void> loadPost(String id) async {
    final result = await _datasource.getPostById(id);
    result.when(
      success: (post) {
        // 이미지 처리: 새 이미지가 선택되어 있으면 유지, 없으면 기존 이미지 URL 사용
        final imagePathToUse = state.imagePath ?? post.imageUrl;
        
        state = state.copyWith(
          title: post.title,
          content: post.content,
          imagePath: imagePathToUse,
        );
      },
      failure: (message, _) {
        state = state.copyWith(errorMessage: message);
      },
    );
  }

  /// 폼 리셋
  void reset() {
    state = const PostFormState();
  }
}
