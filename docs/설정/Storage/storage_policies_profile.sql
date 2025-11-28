-- =====================================================
-- Supabase Storage 정책 설정 (프로필 이미지)
-- =====================================================
-- 이 스크립트는 프로필 이미지 저장소(profile-images)의 정책을 설정합니다.
-- 주의: 먼저 Supabase 대시보드에서 'profile-images' 버킷을 생성해야 합니다.
-- =====================================================

-- =====================================================
-- 1. 기존 Storage 정책 제거
-- =====================================================

DROP POLICY IF EXISTS "Authenticated users can upload profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view profile images" ON storage.objects;

-- =====================================================
-- 2. Storage 정책 생성
-- =====================================================

-- 모든 사용자는 이미지를 조회 가능 (Public bucket이므로)
CREATE POLICY "Anyone can view profile images"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'profile-images');

-- 인증된 사용자는 자신의 프로필 이미지 업로드 가능
CREATE POLICY "Authenticated users can upload profile images"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'profile-images' AND
    auth.role() = 'authenticated' AND
    (
      -- 파일 경로에서 userId 추출: userId/profile.jpg
      auth.uid()::text = (string_to_array(name, '/'))[1]
    )
  );

-- 작성자만 자신이 업로드한 프로필 이미지 삭제 가능
-- 주의: 파일 경로가 'userId/profile.jpg' 형식이어야 합니다.
CREATE POLICY "Users can delete own profile images"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'profile-images' AND
    auth.role() = 'authenticated' AND
    (
      -- 파일 경로에서 userId 추출: userId/profile.jpg
      auth.uid()::text = (string_to_array(name, '/'))[1]
    )
  );

-- =====================================================
-- 완료 메시지
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE 'Storage 정책 설정이 완료되었습니다!';
  RAISE NOTICE '버킷 이름: profile-images';
  RAISE NOTICE '정책: 조회(모든 사용자), 업로드(본인만), 삭제(본인만)';
END $$;

