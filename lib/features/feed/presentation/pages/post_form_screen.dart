import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lionsns/l10n/app_localizations.dart';
import 'package:lionsns/core/utils/result.dart';
import 'package:lionsns/core/services/internal/storage_service_provider.dart';
import 'package:lionsns/core/services/internal/widget_update_service_provider.dart';
import 'package:lionsns/features/feed/presentation/providers/providers.dart';
import 'package:lionsns/features/feed/presentation/viewmodels/post_form_viewmodel.dart';

/// 게시글 작성/수정 화면
class PostFormScreen extends ConsumerStatefulWidget {
  final String? postId;

  const PostFormScreen({
    super.key,
    this.postId,
  });

  @override
  ConsumerState<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends ConsumerState<PostFormScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // 수정 모드인 경우 게시글 로드
    if (widget.postId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(postFormProvider.notifier).loadPost(widget.postId!);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(postFormProvider);
    final viewModel = ref.read(postFormProvider.notifier);

    // ViewModel 상태와 텍스트 필드 동기화
    if (state.title != _titleController.text) {
      _titleController.text = state.title;
    }
    if (state.content != _contentController.text) {
      _contentController.text = state.content;
    }

    return Scaffold(
      appBar: AppBar(
        // 다국어: 게시글 작성/수정 화면 제목
        title: Text(widget.postId == null ? l10n.postCreate : l10n.postEdit),
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
              onPressed: () => _handleSave(context, viewModel),
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
              // 제목 입력
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  // 다국어: 제목 라벨
                  labelText: l10n.title,
                  // 다국어: 제목 입력 힌트
                  hintText: l10n.titleHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLength: 100,
                onChanged: (value) => viewModel.updateTitle(value),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    // 다국어: 제목 입력 오류 메시지
                    return l10n.titleError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 내용 입력
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  // 다국어: 내용 라벨
                  labelText: l10n.content,
                  // 다국어: 내용 입력 힌트
                  hintText: l10n.contentHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                maxLength: 5000,
                onChanged: (value) => viewModel.updateContent(value),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    // 다국어: 내용 입력 오류 메시지
                    return l10n.contentError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 이미지 첨부
              _buildImageSection(context, state, viewModel),

              // 에러 메시지 표시
              if (state.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 저장 버튼
              ElevatedButton(
                onPressed: state.isLoading ? null : () => _handleSave(context, viewModel),
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
                    // 다국어: 작성하기/수정하기 버튼
                    : Text(
                        widget.postId == null ? l10n.create : l10n.update,
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave(BuildContext context, PostFormViewModel viewModel) async {
    // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }


    final result = widget.postId == null
        ? await viewModel.createPost()
        : await viewModel.updatePost(widget.postId!);

    if (!mounted) return;

    result.when(
      success: (_) {
        // 게시글 작성/수정 성공 시 위젯 업데이트
        ref.read(widgetUpdateServiceProvider).updateWidget();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // 다국어: 게시글 작성/수정 성공 메시지
            content: Text(widget.postId == null ? l10n.postCreated : l10n.postUpdated),
          ),
        );
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

  Widget _buildImageSection(BuildContext context, PostFormState state, PostFormViewModel viewModel) {
    // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 다국어: 이미지 섹션 제목
        Text(
          l10n.image,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // 이미지 표시
        if (state.imagePath != null && state.imagePath!.isNotEmpty)
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImageWidget(state.imagePath!),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                  onPressed: () => viewModel.updateImagePath(null),
                ),
              ),
            ],
          )
        else
          // 이미지 선택 버튼
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () => _showImageSourceDialog(context, viewModel),
                  icon: const Icon(Icons.image),
                  // 다국어: 이미지 첨부 버튼
                  label: Text(l10n.imageAttach),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildImageWidget(String imagePath) {
    // URL인지 파일 경로인지 확인
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Stack(
            fit: StackFit.expand,
            children: [
              // 디폴트 이미지 아이콘
              Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 64,
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
      );
    } else {
      // 로컬 파일 경로
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            ),
          );
        },
      );
    }
  }

  Future<void> _showImageSourceDialog(BuildContext context, PostFormViewModel viewModel) async {
    // 다국어 지원: 현재 언어에 맞는 다국어 객체 가져오기
    final l10n = AppLocalizations.of(context)!;
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        // 다국어: 이미지 선택 다이얼로그 제목
        title: Text(l10n.imageSelect),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 다국어: 갤러리에서 선택 옵션
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.imageSelectGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            // 다국어: 카메라로 촬영 옵션
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.imageSelectCamera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      try {
        final storageService = ref.read(storageServiceProvider);
        final imageFile = await storageService.pickImage(source);
        if (imageFile != null && mounted) {
          viewModel.updateImagePath(imageFile.path);
        }
      } catch (e) {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // 다국어: 이미지 선택 오류 메시지
            content: Text(l10n.imageSelectError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

