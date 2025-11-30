import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// 이미지 업로드 및 관리를 위한 추상화 레이어
/// 
/// Supabase, Firebase 등 다양한 백엔드 서비스를 지원할 수 있습니다.
abstract class StorageService {
  /// 프로필 이미지 업로드
  /// 
  /// [imageFile] 업로드할 이미지 파일
  /// [userId] 사용자 ID
  /// 
  /// Returns 업로드된 이미지의 public URL
  Future<String> uploadProfileImage({
    required File imageFile,
    required String userId,
  });

  /// 게시글 이미지 업로드
  /// 
  /// [imageFile] 업로드할 이미지 파일
  /// [postId] 게시글 ID
  /// [userId] 사용자 ID
  /// 
  /// Returns 업로드된 이미지의 public URL
  Future<String> uploadPostImage({
    required File imageFile,
    required String postId,
    required String userId,
  });

  /// 게시글 이미지 삭제
  /// 
  /// [imageUrl] 삭제할 이미지의 URL
  Future<void> deletePostImage(String imageUrl);

  /// 이미지 선택 (갤러리 또는 카메라)
  /// 
  /// [source] 이미지 소스 (ImageSource.gallery 또는 ImageSource.camera)
  /// 
  /// Returns 선택된 이미지 파일
  Future<File?> pickImage(ImageSource source);

  /// 게시글 이미지 썸네일 URL 생성
  /// 
  /// [imageUrl] 원본 이미지 URL
  /// [width] 썸네일 너비 (기본값: 400)
  /// [height] 썸네일 높이 (기본값: 300)
  /// 
  /// Returns 썸네일 이미지 URL
  String getPostThumbnailUrl(String imageUrl, {int width = 400, int height = 300});
}

