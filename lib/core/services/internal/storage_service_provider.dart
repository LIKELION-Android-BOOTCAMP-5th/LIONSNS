import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service_interface.dart';
import 'supabase_storage_service.dart';
import 'firebase_storage_service.dart';

/// 백엔드 교체 시 이 부분만 변경하면 됩니다
/// 
/// Supabase 사용: SupabaseStorageService()
/// Firebase 사용: FirebaseStorageService()
final storageServiceProvider = Provider<StorageService>((ref) {
  return SupabaseStorageService();
  
  // Firebase로 교체: return FirebaseStorageService();
});

