import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/features/auth/data/datasources/supabase_follow_datasource.dart';

/// 팔로우 상태
class FollowState {
  final Result<bool> isFollowingResult;
  final Result<int> followerCountResult;
  final Result<int> followingCountResult;
  final bool isLoading;

  FollowState({
    required this.isFollowingResult,
    required this.followerCountResult,
    required this.followingCountResult,
    required this.isLoading,
  });

  FollowState copyWith({
    Result<bool>? isFollowingResult,
    Result<int>? followerCountResult,
    Result<int>? followingCountResult,
    bool? isLoading,
  }) {
    return FollowState(
      isFollowingResult: isFollowingResult ?? this.isFollowingResult,
      followerCountResult: followerCountResult ?? this.followerCountResult,
      followingCountResult: followingCountResult ?? this.followingCountResult,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FollowViewModel extends StateNotifier<FollowState> {
  final SupabaseFollowDatasource _datasource;
  final String _targetUserId;
  final String? _currentUserId;
  bool _isDisposed = false;

  FollowViewModel(
    this._datasource,
    this._targetUserId,
    this._currentUserId,
  ) : super(FollowState(
          isFollowingResult: const Pending<bool>(),
          followerCountResult: const Pending<int>(),
          followingCountResult: const Pending<int>(),
          isLoading: false,
        )) {
    unawaited(loadFollowData());
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// 팔로우 데이터 로드
  Future<void> loadFollowData() async {
    if (_isDisposed) return;
    
    try {
      state = state.copyWith(isLoading: true);
    } catch (e) {
      // dispose된 상태에서 state 접근 시 방지
      return;
    }

    if (_currentUserId != null && _currentUserId != _targetUserId) {
      final isFollowingResult = await _datasource.isFollowing(
        _currentUserId!,
        _targetUserId,
      );
      if (_isDisposed) return;
      try {
        state = state.copyWith(isFollowingResult: isFollowingResult);
      } catch (e) {
        return;
      }
    } else {
      // 자기 자신이면 팔로우 상태는 항상 false
      if (_isDisposed) return;
      try {
        state = state.copyWith(isFollowingResult: Success<bool>(false));
      } catch (e) {
        return;
      }
    }

    final followerCountResult = await _datasource.getFollowerCount(_targetUserId);
    if (_isDisposed) return;
    try {
      state = state.copyWith(followerCountResult: followerCountResult);
    } catch (e) {
      return;
    }

    final followingCountResult = await _datasource.getFollowingCount(_targetUserId);
    if (_isDisposed) return;
    try {
      state = state.copyWith(followingCountResult: followingCountResult);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // dispose된 상태에서 state 접근 시 방지
      return;
    }
  }

  /// 팔로우 토글
  Future<void> toggleFollow() async {
    if (_isDisposed || _currentUserId == null || _currentUserId == _targetUserId) {
      return;
    }

    try {
      state = state.copyWith(isLoading: true);
    } catch (e) {
      return;
    }

    final currentIsFollowing = state.isFollowingResult.when(
      success: (value) => value,
      failure: (_, __) => false,
      pending: (_) => false,
    );

    // 낙관적 UI 업데이트: 서버 응답 전에 UI 먼저 업데이트
    try {
      state = state.copyWith(
        isFollowingResult: Success<bool>(!currentIsFollowing),
        followerCountResult: state.followerCountResult.when(
          success: (count) => Success<int>(currentIsFollowing ? count - 1 : count + 1),
          failure: (message, error) => Failure<int>(message, error),
          pending: (_) => const Pending<int>(),
        ),
      );
    } catch (e) {
      return;
    }

    final result = await _datasource.toggleFollow(_currentUserId!, _targetUserId);
    if (_isDisposed) return;

    result.when(
      success: (isFollowing) {
        // 성공: 이미 낙관적 업데이트로 반영됨
        if (_isDisposed) return;
        try {
          state = state.copyWith(
            isFollowingResult: Success<bool>(isFollowing),
          );
        } catch (e) {
          return;
        }
      },
      failure: (message, error) {
        // 실패: 원래 상태로 복원
        if (_isDisposed) return;
        try {
          state = state.copyWith(
            isFollowingResult: Success<bool>(currentIsFollowing),
            followerCountResult: state.followerCountResult.when(
              success: (count) => Success<int>(currentIsFollowing ? count + 1 : count - 1),
              failure: (_, __) => state.followerCountResult,
              pending: (_) => state.followerCountResult,
            ),
          );
        } catch (e) {
          return;
        }
      },
    );

    if (_isDisposed) return;
    try {
      state = state.copyWith(isLoading: false);
    } catch (e) {
      return;
    }
  }

  /// 데이터 새로고침
  Future<void> refresh() async {
    if (_isDisposed) return;
    await loadFollowData();
  }
}

