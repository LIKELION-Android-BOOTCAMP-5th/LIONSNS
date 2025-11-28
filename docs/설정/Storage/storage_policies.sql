-- =====================================================
-- Supabase Storage 정책 설정
-- =====================================================
-- 이 스크립트는 게시글 이미지 저장소(post-images)의 정책을 설정합니다.
-- 주의: 먼저 Supabase 대시보드에서 'post-images' 버킷을 생성해야 합니다.
-- =====================================================

-- =====================================================
-- 1. 기존 Storage 정책 제거
-- =====================================================

DROP POLICY IF EXISTS "Authenticated users can upload post images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own post images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own post images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view post images" ON storage.objects;

-- =====================================================
-- 2. Storage 정책 생성
-- =====================================================

-- 모든 사용자는 이미지를 조회 가능 (Public bucket이므로)
-- 주의: 버킷이 Public으로 설정되어 있으면 이 정책은 필요 없을 수 있습니다.
CREATE POLICY "Anyone can view post images"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'post-images');

-- 인증된 사용자는 이미지 업로드 가능
CREATE POLICY "Authenticated users can upload post images"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'post-images' AND
    auth.role() = 'authenticated'
  );

-- 작성자만 자신이 업로드한 이미지 수정 가능
-- 주의: 파일 경로가 'userId/postId/timestamp.extension' 형식이어야 합니다.
CREATE POLICY "Users can update own post images"
  ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'post-images' AND
    auth.role() = 'authenticated' AND
    (
      -- 파일 경로에서 userId 추출: userId/postId/timestamp.extension
      auth.uid()::text = (string_to_array(name, '/'))[1]
    )
  )
  WITH CHECK (
    bucket_id = 'post-images' AND
    auth.role() = 'authenticated' AND
    (
      -- 파일 경로에서 userId 추출: userId/postId/timestamp.extension
      auth.uid()::text = (string_to_array(name, '/'))[1]
    )
  );

-- 작성자만 자신이 업로드한 이미지 삭제 가능
-- 주의: 파일 경로가 'userId/postId/timestamp.extension' 형식이어야 합니다.
CREATE POLICY "Users can delete own post images"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'post-images' AND
    auth.role() = 'authenticated' AND
    (
      -- 파일 경로에서 userId 추출: userId/postId/timestamp.extension
      auth.uid()::text = (string_to_array(name, '/'))[1]
    )
  );

-- =====================================================
-- 완료 메시지
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE 'Storage 정책 설정이 완료되었습니다!';
  RAISE NOTICE '버킷 이름: post-images';
  RAISE NOTICE '정책: 조회(모든 사용자), 업로드(인증된 사용자), 수정(작성자), 삭제(작성자)';
END $$;

