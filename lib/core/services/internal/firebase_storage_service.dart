import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
// Firebase 패키지 필요:
// flutter pub add firebase_storage
// import 'package:firebase_storage/firebase_storage.dart';
// import '../external/firebase_service.dart';
import 'storage_service_interface.dart';

/// SupabaseStorageService와 유사한 구조로 Firebase Storage를 사용
/// 
/// 사용 방법:
/// 1. pubspec.yaml에 firebase_storage 패키지 추가
/// 2. Firebase 프로젝트에서 Storage 버킷 생성
/// 3. Storage 규칙 설정 (읽기/쓰기 권한)
class FirebaseStorageService implements StorageService {
  static const String _profileBucketName = 'profile-images';
  static const String _postBucketName = 'post-images';

  @override
  Future<String> uploadProfileImage({
    required File imageFile,
    required String userId,
  }) async {
    try {
      debugPrint('[FirebaseStorageService] 프로필 이미지 업로드 시작');
      debugPrint('[FirebaseStorageService] 버킷명: $_profileBucketName');
      debugPrint('[FirebaseStorageService] userId: $userId');
      debugPrint('[FirebaseStorageService] 이미지 파일 경로: ${imageFile.path}');
      debugPrint('[FirebaseStorageService] 이미지 파일 존재: ${await imageFile.exists()}');

      // 파일 존재 확인
      if (!await imageFile.exists()) {
        throw Exception('이미지 파일이 존재하지 않습니다: ${imageFile.path}');
      }

      // 파일 크기 확인
      final fileSize = await imageFile.length();
      debugPrint('[FirebaseStorageService] 이미지 파일 크기: ${fileSize} bytes');

      final filePath = '$_profileBucketName/$userId/profile.jpg';
      debugPrint('[FirebaseStorageService] Storage 파일 경로: $filePath');

      // Firebase Storage에 업로드
      // final storageRef = FirebaseService.storage.ref(filePath);
      // 
      // // 기존 이미지가 있으면 삭제
      // try {
      //   await storageRef.delete();
      //   debugPrint('[FirebaseStorageService] 기존 이미지 삭제 완료');
      // } catch (e) {
      //   // 기존 이미지가 없을 수 있으므로 무시
      //   debugPrint('[FirebaseStorageService] 기존 이미지 없음: $e');
      // }
      // 
      // // 이미지 업로드
      // debugPrint('[FirebaseStorageService] 이미지 업로드 시도 중...');
      // final uploadTask = storageRef.putFile(
      //   imageFile,
      //   SettableMetadata(
      //     contentType: 'image/jpeg',
      //     cacheControl: 'public, max-age=31536000',
      //   ),
      // );
      // 
      // await uploadTask;
      // debugPrint('[FirebaseStorageService] 이미지 업로드 완료');
      // 
      // // Public URL 가져오기
      // final publicUrl = await storageRef.getDownloadURL();
      // debugPrint('[FirebaseStorageService] Public URL: $publicUrl');
      // 
      // return publicUrl;

      // TODO: Firebase 구현 필요
      throw UnimplementedError('Firebase Storage 구현 필요');
    } catch (e, stackTrace) {
      debugPrint('[FirebaseStorageService] 프로필 이미지 업로드 실패: $e');
      debugPrint('[FirebaseStorageService] 에러 타입: ${e.runtimeType}');
      debugPrint('[FirebaseStorageService] 스택: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<String> uploadPostImage({
    required File imageFile,
    required String postId,
    required String userId,
  }) async {
    try {
      debugPrint('[FirebaseStorageService] 게시글 이미지 업로드 시작');
      debugPrint('[FirebaseStorageService] 버킷명: $_postBucketName');
      debugPrint('[FirebaseStorageService] postId: $postId, userId: $userId');
      debugPrint('[FirebaseStorageService] 이미지 파일 경로: ${imageFile.path}');
      debugPrint('[FirebaseStorageService] 이미지 파일 존재: ${await imageFile.exists()}');

      // 파일 존재 확인
      if (!await imageFile.exists()) {
        throw Exception('이미지 파일이 존재하지 않습니다: ${imageFile.path}');
      }

      // 파일 크기 확인
      final fileSize = await imageFile.length();
      debugPrint('[FirebaseStorageService] 이미지 파일 크기: ${fileSize} bytes');

      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      final contentType = _getContentType(fileExtension);
      debugPrint('[FirebaseStorageService] 파일 확장자: $fileExtension, Content-Type: $contentType');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$_postBucketName/$userId/$postId/$timestamp.$fileExtension';
      debugPrint('[FirebaseStorageService] Storage 파일 경로: $filePath');

      // Firebase Storage에 업로드
      // final storageRef = FirebaseService.storage.ref(filePath);
      // 
      // debugPrint('[FirebaseStorageService] 이미지 업로드 시도 중...');
      // final uploadTask = storageRef.putFile(
      //   imageFile,
      //   SettableMetadata(
      //     contentType: contentType,
      //     cacheControl: 'public, max-age=31536000',
      //   ),
      // );
      // 
      // await uploadTask;
      // debugPrint('[FirebaseStorageService] 이미지 업로드 완료');
      // 
      // // Public URL 가져오기
      // final publicUrl = await storageRef.getDownloadURL();
      // debugPrint('[FirebaseStorageService] Public URL: $publicUrl');
      // 
      // return publicUrl;

      // TODO: Firebase 구현 필요
      throw UnimplementedError('Firebase Storage 구현 필요');
    } catch (e, stackTrace) {
      debugPrint('[FirebaseStorageService] 게시글 이미지 업로드 실패: $e');
      debugPrint('[FirebaseStorageService] 에러 타입: ${e.runtimeType}');
      debugPrint('[FirebaseStorageService] 스택: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> deletePostImage(String imageUrl) async {
    try {
      debugPrint('[FirebaseStorageService] 게시글 이미지 삭제 시작: $imageUrl');

      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Firebase Storage URL 형식: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?alt=media
      final bucketIndex = pathSegments.indexOf('post-images');
      if (bucketIndex == -1) {
        throw Exception('Invalid image URL: $imageUrl');
      }

      final filePath = pathSegments.sublist(bucketIndex).join('/');

      // Firebase Storage에서 삭제
      // final storageRef = FirebaseService.storage.ref(filePath);
      // await storageRef.delete();

      debugPrint('[FirebaseStorageService] 게시글 이미지 삭제 완료');
      
      throw UnimplementedError('Firebase Storage 구현 필요');
    } catch (e, stackTrace) {
      debugPrint('[FirebaseStorageService] 게시글 이미지 삭제 실패: $e');
      debugPrint('   스택: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<File?> pickImage(ImageSource source) async {
    try {
      debugPrint('[FirebaseStorageService] 이미지 선택 시작: $source');

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        debugPrint('[FirebaseStorageService] 이미지 선택 취소');
        return null;
      }

      debugPrint('[FirebaseStorageService] 이미지 선택 완료: ${image.path}');
      return File(image.path);
    } catch (e, stackTrace) {
      debugPrint('[FirebaseStorageService] 이미지 선택 실패: $e');
      debugPrint('   스택: $stackTrace');
      rethrow;
    }
  }

  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}

