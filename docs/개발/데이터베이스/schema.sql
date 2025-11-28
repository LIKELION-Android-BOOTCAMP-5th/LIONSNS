-- =====================================================
-- Supabase 데이터베이스 스키마 초기화 및 재생성
-- =====================================================
-- 이 스크립트는 기존 스키마를 모두 제거하고 새로 생성합니다.
-- 주의: 모든 데이터가 삭제됩니다!
-- =====================================================

-- =====================================================
-- 1. 기존 객체 제거 (역순으로)
-- =====================================================

-- 트리거 제거
DROP TRIGGER IF EXISTS new_post_notification ON posts;
DROP TRIGGER IF EXISTS update_posts_updated_at ON posts;
DROP TRIGGER IF EXISTS update_comments_updated_at ON comments;
DROP TRIGGER IF EXISTS update_device_tokens_updated_at ON device_tokens;
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;

-- 정책 제거
DROP POLICY IF EXISTS "Users can view own tokens" ON device_tokens;
DROP POLICY IF EXISTS "Users can manage own tokens" ON device_tokens;
DROP POLICY IF EXISTS "Anyone can view posts" ON posts;
DROP POLICY IF EXISTS "Authenticated users can create posts" ON posts;
DROP POLICY IF EXISTS "Users can update own posts" ON posts;
DROP POLICY IF EXISTS "Users can delete own posts" ON posts;
DROP POLICY IF EXISTS "Anyone can view likes" ON post_likes;
DROP POLICY IF EXISTS "Authenticated users can create likes" ON post_likes;
DROP POLICY IF EXISTS "Users can delete own likes" ON post_likes;
DROP POLICY IF EXISTS "Anyone can view comments" ON comments;
DROP POLICY IF EXISTS "Authenticated users can create comments" ON comments;
DROP POLICY IF EXISTS "Users can update own comments" ON comments;
DROP POLICY IF EXISTS "Users can delete own comments" ON comments;
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Anyone can view profiles" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Anyone can view follows" ON follows;
DROP POLICY IF EXISTS "Authenticated users can follow" ON follows;
DROP POLICY IF EXISTS "Users can unfollow" ON follows;

-- 인덱스 제거
DROP INDEX IF EXISTS idx_device_tokens_user_id;
DROP INDEX IF EXISTS idx_device_tokens_token;
DROP INDEX IF EXISTS idx_posts_user_id;
DROP INDEX IF EXISTS idx_posts_created_at;
DROP INDEX IF EXISTS idx_post_likes_post_id;
DROP INDEX IF EXISTS idx_post_likes_user_id;
DROP INDEX IF EXISTS idx_post_likes_post_user;
DROP INDEX IF EXISTS idx_comments_post_id;
DROP INDEX IF EXISTS idx_comments_user_id;
DROP INDEX IF EXISTS idx_comments_created_at;
DROP INDEX IF EXISTS idx_follows_follower_id;
DROP INDEX IF EXISTS idx_follows_following_id;
DROP INDEX IF EXISTS idx_follows_follower_following;

-- 테이블 제거 (외래키 관계 고려)
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS post_likes CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS follows CASCADE;
DROP TABLE IF EXISTS device_tokens CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;

-- 함수 제거
DROP FUNCTION IF EXISTS notify_new_post() CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- Storage 정책 제거 (storage.objects 테이블의 정책)
DROP POLICY IF EXISTS "Authenticated users can upload post images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own post images" ON storage.objects;

-- =====================================================
-- 2. 함수 생성
-- =====================================================

-- updated_at 자동 업데이트 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- 게시글 생성 시 푸시 알림 함수 (선택사항 - Edge Function 필요)
-- 주의: YOUR_PROJECT_ID를 실제 프로젝트 ID로 변경해야 합니다.
CREATE OR REPLACE FUNCTION notify_new_post()
RETURNS TRIGGER AS $$
DECLARE
  device_token_record RECORD;
BEGIN
  -- 모든 사용자의 device token 가져오기
  FOR device_token_record IN
    SELECT device_token FROM device_tokens
    WHERE user_id != auth.uid()  -- 작성자 제외
  LOOP
    -- Edge Function을 통해 푸시 알림 발송
    -- 주의: net.http_post 확장이 필요합니다 (pg_net 또는 http 확장)
    -- 실제 프로젝트에서는 Edge Function을 직접 호출하거나 비활성화할 수 있습니다.
    -- PERFORM net.http_post(
    --   url := 'https://YOUR_PROJECT_ID.supabase.co/functions/v1/send-push-notification',
    --   headers := jsonb_build_object(
    --     'Content-Type', 'application/json',
    --     'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
    --   ),
    --   body := jsonb_build_object(
    --     'token', device_token_record.device_token,
    --     'title', '새 게시글이 작성되었습니다',
    --     'body', NEW.title,
    --     'data', jsonb_build_object('postId', NEW.id, 'type', 'new_post')
    --   )
    -- );
    NULL; -- 현재는 비활성화 (필요시 주석 해제)
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. 테이블 생성
-- =====================================================

-- user_profiles 테이블 (선택사항)
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  name TEXT,
  profile_image_url TEXT,
  provider TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- device_tokens 테이블 (푸시 알림용)
CREATE TABLE IF NOT EXISTS device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_token TEXT NOT NULL UNIQUE,
  device_type TEXT CHECK (device_type IN ('ios', 'android', 'web')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- posts 테이블
-- user_id는 user_profiles.id를 참조 (JOIN을 위해)
CREATE TABLE IF NOT EXISTS posts (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  image_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- post_likes 테이블 (좋아요)
CREATE TABLE IF NOT EXISTS post_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- comments 테이블 (댓글)
-- user_id는 user_profiles.id를 참조 (JOIN을 위해)
CREATE TABLE IF NOT EXISTS comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- follows 테이블 (팔로우/팔로잉)
-- follower_id와 following_id는 user_profiles.id를 참조 (JOIN을 위해)
CREATE TABLE IF NOT EXISTS follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(follower_id, following_id),
  CHECK (follower_id != following_id) -- 자기 자신을 팔로우할 수 없음
);

-- =====================================================
-- 4. RLS (Row Level Security) 활성화
-- =====================================================

ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 5. 정책 생성
-- =====================================================

-- device_tokens 정책
CREATE POLICY "Users can view own tokens"
  ON device_tokens
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own tokens"
  ON device_tokens
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- posts 정책
CREATE POLICY "Anyone can view posts"
  ON posts
  FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can create posts"
  ON posts
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update own posts"
  ON posts
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own posts"
  ON posts
  FOR DELETE
  USING (auth.uid() = user_id);

-- post_likes 정책
CREATE POLICY "Anyone can view likes"
  ON post_likes
  FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can create likes"
  ON post_likes
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

CREATE POLICY "Users can delete own likes"
  ON post_likes
  FOR DELETE
  USING (auth.uid() = user_id);

-- comments 정책
CREATE POLICY "Anyone can view comments"
  ON comments
  FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can create comments"
  ON comments
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

CREATE POLICY "Users can update own comments"
  ON comments
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments"
  ON comments
  FOR DELETE
  USING (auth.uid() = user_id);

-- user_profiles 정책
CREATE POLICY "Anyone can view profiles"
  ON user_profiles
  FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON user_profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON user_profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- follows 정책
CREATE POLICY "Anyone can view follows"
  ON follows
  FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can follow"
  ON follows
  FOR INSERT
  WITH CHECK (
    auth.role() = 'authenticated' AND
    auth.uid() = follower_id AND
    follower_id != following_id
  );

CREATE POLICY "Users can unfollow"
  ON follows
  FOR DELETE
  USING (auth.uid() = follower_id);

-- =====================================================
-- 6. 인덱스 생성 (성능 향상)
-- =====================================================

-- device_tokens 인덱스
CREATE INDEX idx_device_tokens_user_id ON device_tokens(user_id);
CREATE INDEX idx_device_tokens_token ON device_tokens(device_token);

-- post_likes 인덱스
CREATE INDEX idx_post_likes_post_id ON post_likes(post_id);
CREATE INDEX idx_post_likes_user_id ON post_likes(user_id);
CREATE INDEX idx_post_likes_post_user ON post_likes(post_id, user_id);

-- comments 인덱스
CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_comments_created_at ON comments(created_at);

-- posts 인덱스
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at);

-- follows 인덱스
CREATE INDEX idx_follows_follower_id ON follows(follower_id);
CREATE INDEX idx_follows_following_id ON follows(following_id);
CREATE INDEX idx_follows_follower_following ON follows(follower_id, following_id);

-- =====================================================
-- 7. 트리거 생성
-- =====================================================

-- device_tokens updated_at 트리거
CREATE TRIGGER update_device_tokens_updated_at
  BEFORE UPDATE ON device_tokens
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- posts updated_at 트리거
CREATE TRIGGER update_posts_updated_at
  BEFORE UPDATE ON posts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- comments updated_at 트리거
CREATE TRIGGER update_comments_updated_at
  BEFORE UPDATE ON comments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- user_profiles updated_at 트리거
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- posts 생성 시 푸시 알림 트리거 (선택사항)
-- 주의: notify_new_post 함수가 활성화되어 있어야 합니다.
CREATE TRIGGER new_post_notification
  AFTER INSERT ON posts
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_post();

-- =====================================================
-- 완료 메시지
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '스키마 초기화 및 재생성이 완료되었습니다!';
  RAISE NOTICE '생성된 테이블: user_profiles, device_tokens, posts, post_likes, comments, follows';
  RAISE NOTICE '생성된 함수: update_updated_at_column, notify_new_post';
  RAISE NOTICE 'RLS 정책이 활성화되었습니다.';
END $$;

