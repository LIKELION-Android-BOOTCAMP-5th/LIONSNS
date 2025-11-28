import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lionsns/l10n/app_localizations.dart';
import 'package:lionsns/core/utils/result.dart';
import '../providers/providers.dart';

/// 프로필 편집 화면
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isNicknameInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final viewModel = ref.read(profileEditViewModelProvider.notifier);
    viewModel.setNickname(_nicknameController.text);

    final result = await viewModel.saveProfile();

    if (!mounted) return;

    result.when(
      success: (user) {
        // AuthViewModel 갱신하여 프로필 화면에 반영
        ref.read(authViewModelProvider.notifier).refresh();
        
        ScaffoldMessenger.of(context).showSnackBar(
          // 다국어: 프로필 저장 성공 메시지
          SnackBar(content: Text(AppLocalizations.of(context)!.profileSaved)),
        );

        // 화면을 먼저 닫기
        context.pop();
      },
      failure: (message, _) {
        // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // 다국어: 오류 메시지 (상세 메시지는 개발자용이므로 일반 오류 메시지 사용)
            content: Text(l10n.errorOccurred(message)),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(profileEditViewModelProvider);
    final viewModel = ref.read(profileEditViewModelProvider.notifier);

    // 프로필이 로드되면 닉네임 초기화 (한 번만)
    if (!_isNicknameInitialized && mounted) {
      state.profileResult.when(
        success: (user) {
          if (user != null && user.name.isNotEmpty && _nicknameController.text.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isNicknameInitialized) {
                _nicknameController.text = user.name;
                _isNicknameInitialized = true;
              }
            });
          }
        },
        failure: (_, __) {},
        pending: (_) {},
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        // 백키를 누르면 context.pop()을 사용하여 프로필 화면으로 돌아감
        // context.pop()을 사용하면 redirect 함수가 실행되지만, 프로필 경로는 이미 처리되므로 문제 없음
        if (!didPop) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          // 다국어: 프로필 편집 화면 제목
          title: Text(l10n.profileEdit),
          actions: [
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              // 다국어: 저장 버튼
              child: Text(
                l10n.save,
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // 프로필 이미지
              Center(
                child: Stack(
                  children: [
                    _buildProfileAvatar(
                      context,
                      selectedImage: state.selectedImage,
                      imageUrl: state.profileResult.when(
                        success: (user) => user?.profileImageUrl,
                        failure: (_, __) => null,
                        pending: (_) => null,
                      ),
                      radius: 60,
                      fallbackText: ((state.nickname?.isNotEmpty ?? false) ? state.nickname![0] : 'U').toUpperCase(),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                          onPressed: () => viewModel.pickImage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 닉네임 입력
              TextFormField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  // 다국어: 닉네임 라벨
                  labelText: l10n.nickname,
                  // 다국어: 닉네임 입력 힌트
                  hintText: l10n.nicknameHint,
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    // 다국어: 닉네임 입력 오류 메시지
                    return l10n.nicknameError;
                  }
                  if (value.length > 20) {
                    // 다국어: 닉네임 길이 오류 메시지
                    return l10n.nicknameErrorLength;
                  }
                  return null;
                },
                onChanged: (value) {
                  viewModel.setNickname(value);
                },
              ),

              const SizedBox(height: 24),

              // 저장 버튼
              ElevatedButton(
                onPressed: state.isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: state.isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                    // 다국어: 저장 버튼
                    : Text(l10n.save, style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildProfileAvatar(
    BuildContext context, {
    required File? selectedImage,
    required String? imageUrl,
    required double radius,
    required String fallbackText,
  }) {
    // 선택된 이미지가 있으면 로컬 파일 표시
    if (selectedImage != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        backgroundImage: FileImage(selectedImage),
      );
    }

    // 이미지 URL이 없으면 기본 텍스트 표시
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

    // 네트워크 이미지 표시 (로딩 인디케이터 포함)
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
}
