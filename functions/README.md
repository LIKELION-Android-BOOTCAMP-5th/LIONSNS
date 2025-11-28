#  Supabase Edge Functions

이 폴더는 Supabase Edge Functions를 정의합니다.

##  목차

1. [개요](#개요)
2. [설치 및 설정](#설치-및-설정)
3. [Functions 목록](#functions-목록)
4. [배포 방법](#배포-방법)
5. [환경 변수 설정](#환경-변수-설정)

---

## 개요

Supabase Edge Functions는 Deno 런타임에서 실행되는 서버리스 함수입니다. 이 프로젝트에서는 다음과 같은 기능을 위해 Edge Functions를 사용합니다:

- **푸시 알림 전송**: Firebase Cloud Messaging을 통한 푸시 알림 발송
- **이벤트 처리**: 데이터베이스 트리거에서 호출되는 함수들
- **소셜 로그인 처리**: 네이버 로그인 후 사용자 프로필 동기화

---

## 설치 및 설정

### 1. Supabase CLI 설치

```bash
npm install -g supabase
```

### 2. Supabase 로그인

```bash
supabase login
```

### 3. 프로젝트 연결

```bash
supabase link --project-ref YOUR_PROJECT_REF
```

---

## Functions 목록

### 1. `send-push-notification`

**용도**: 일반적인 푸시 알림 전송

**호출 방법**:
- 데이터베이스 트리거에서 호출
- 다른 Edge Function에서 호출
- 클라이언트에서 직접 호출

**요청 형식**:
```json
{
  "userId": "user-uuid",
  "title": "알림 제목",
  "body": "알림 내용",
  "data": {
    "type": "comment|like|post",
    "postId": "post-uuid",
    "commentId": "comment-uuid"
  }
}
```

### 2. `send-comment-notification`

**용도**: 댓글 작성 시 알림 전송

**호출 방법**:
- 데이터베이스 트리거에서 자동 호출 (comments 테이블 INSERT 시)

**요청 형식**:
```json
{
  "postId": "post-uuid",
  "commentId": "comment-uuid",
  "commenterId": "user-uuid",
  "postAuthorId": "user-uuid"
}
```

### 3. `send-like-notification`

**용도**: 좋아요 시 알림 전송

**호출 방법**:
- 데이터베이스 트리거에서 자동 호출 (post_likes 테이블 INSERT 시)

**요청 형식**:
```json
{
  "postId": "post-uuid",
  "likerId": "user-uuid",
  "postAuthorId": "user-uuid"
}
```

### 4. `sync-naver-profile`

**용도**: 네이버 로그인 후 사용자 프로필 정보 동기화

**호출 방법**:
- 네이버 로그인 성공 후 클라이언트에서 호출
- 데이터베이스 트리거에서 자동 호출 (선택사항)

**요청 형식**:
```json
{
  "userId": "user-uuid",
  "accessToken": "naver-access-token"  // 선택사항
}
```

**응답 형식**:
```json
{
  "success": true,
  "message": "네이버 프로필 동기화 완료",
  "profile": {
    "id": "user-uuid",
    "name": "사용자 이름",
    "email": "user@example.com",
    "profile_image_url": "https://...",
    "provider": "naver"
  }
}
```

**참고**: 
- `accessToken`이 제공되면 네이버 API에서 최신 정보를 가져옵니다.
- `accessToken`이 없으면 Supabase의 `user_metadata`에서 정보를 사용합니다.
- 네이버 로그인 사용자만 사용 가능합니다.

### 5. `naver-auth-callback`

**용도**: 네이버 OAuth 콜백 처리 (선택사항)

**참고**: 
- Supabase가 기본적으로 OAuth를 처리하므로 이 함수는 선택사항입니다.
- 추가적인 후처리가 필요한 경우에만 사용합니다.
- 일반적으로는 `sync-naver-profile` 함수를 사용하는 것이 권장됩니다.

---

## 배포 방법

### 1. 개별 함수 배포

```bash
# send-push-notification 배포
supabase functions deploy send-push-notification

# send-comment-notification 배포
supabase functions deploy send-comment-notification

# send-like-notification 배포
supabase functions deploy send-like-notification

# sync-naver-profile 배포
supabase functions deploy sync-naver-profile

# naver-auth-callback 배포 (선택사항)
supabase functions deploy naver-auth-callback
```

### 2. 모든 함수 배포

```bash
supabase functions deploy
```

---

## 환경 변수 설정

Supabase 대시보드에서 환경 변수를 설정해야 합니다:

1. **Supabase 대시보드** → **Edge Functions** → **Settings**
2. 다음 환경 변수 추가:

### 필수 환경 변수

- `FCM_SERVER_KEY`: Firebase Cloud Messaging 서버 키
  - Firebase Console → 프로젝트 설정 → 클라우드 메시징 → 서버 키

### 자동 설정되는 환경 변수

다음 환경 변수는 Supabase에서 자동으로 제공됩니다:
- `SUPABASE_URL`: Supabase 프로젝트 URL
- `SUPABASE_SERVICE_ROLE_KEY`: Supabase 서비스 역할 키

---

## 로컬 개발

### 1. 로컬에서 함수 실행

```bash
supabase functions serve send-push-notification
```

### 2. 함수 테스트

```bash
curl -i --location --request POST 'http://localhost:54321/functions/v1/send-push-notification' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "userId": "user-uuid",
    "title": "테스트 알림",
    "body": "이것은 테스트 알림입니다"
  }'
```

---

## 참고 자료

- [Supabase Edge Functions 문서](https://supabase.com/docs/guides/functions)
- [Deno 문서](https://deno.land/manual)
- [Firebase Cloud Messaging 문서](https://firebase.google.com/docs/cloud-messaging)

