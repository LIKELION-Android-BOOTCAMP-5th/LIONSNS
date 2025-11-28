import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lionsns/features/auth/models/user.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/features/auth/data/datasources/supabase_profile_datasource.dart';
import 'package:lionsns/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:lionsns/core/services/internal/storage_service_interface.dart';

/// 프로필 편집 상태
class ProfileEditState {
  final Result<User?> profileResult;
  final bool isLoading;
  final File? selectedImage;
  final String? nickname;

  const ProfileEditState({
    this.profileResult = const Success(null),
    this.isLoading = false,
    this.selectedImage,
    this.nickname,
  });

  ProfileEditState copyWith({
    Result<User?>? profileResult,
    bool? isLoading,
    File? selectedImage,
    String? nickname,
  }) {
    return ProfileEditState(
      profileResult: profileResult ?? this.profileResult,
      isLoading: isLoading ?? this.isLoading,
      selectedImage: selectedImage ?? this.selectedImage,
      nickname: nickname ?? this.nickname,
    );
  }
}

class ProfileEditViewModel extends StateNotifier<ProfileEditState> {
  final SupabaseProfileDatasource _profileDatasource;
  final StorageService _storageService;
  final SupabaseAuthDatasource _authDatasource;

  ProfileEditViewModel(
    this._profileDatasource,
    this._storageService,
    this._authDatasource,
  ) : super(const ProfileEditState()) {
    _loadProfile();
  }

  /// 프로필 로드
  Future<void> _loadProfile() async {
    final currentUserId = _authDatasource.getCurrentUserId();
    if (currentUserId == null) return;

    final result = await _profileDatasource.getProfile(currentUserId);

    result.when(
      success: (user) {
        state = state.copyWith(
          profileResult: result,
          nickname: user?.name,
        );
      },
      failure: (_, __) {
        state = state.copyWith(profileResult: result);
      },
    );
  }

  /// 닉네임 변경
  void setNickname(String nickname) {
    state = state.copyWith(nickname: nickname);
  }

  /// 이미지 선택
  Future<void> pickImage() async {
    try {
      final image = await _storageService.pickImage(ImageSource.gallery);
      if (image != null) {
        state = state.copyWith(selectedImage: image);
      }
    } catch (e) {
      debugPrint('이미지 선택 오류: $e');
    }
  }

  /// 프로필 저장
  Future<Result<User>> saveProfile() async {
    if (state.nickname == null || state.nickname!.isEmpty) {
      return const Failure('닉네임을 입력해주세요');
    }

    final currentUserId = _authDatasource.getCurrentUserId();
    if (currentUserId == null) {
      return const Failure('로그인이 필요합니다');
    }

    state = state.copyWith(isLoading: true);

    try {
      String? imageUrl;

      // 이미지가 선택되었으면 업로드
      if (state.selectedImage != null) {
        imageUrl = await _storageService.uploadProfileImage(
          imageFile: state.selectedImage!,
          userId: currentUserId,
        );
      }

      // 프로필 업데이트
      final result = await _profileDatasource.updateProfile(
        userId: currentUserId,
        name: state.nickname,
        profileImageUrl: imageUrl,
      );

      state = state.copyWith(isLoading: false);

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return Failure('프로필 저장에 실패했습니다: $e');
    }
  }
}
