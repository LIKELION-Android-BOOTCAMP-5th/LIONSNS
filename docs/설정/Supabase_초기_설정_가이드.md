#  Supabase 초기 설정 가이드

**버전**: 2.1.0  
**마지막 업데이트**: 2024-12-19  
**대상**: 최초 프로젝트 설정자

---

##  목차

1. [사전 준비사항](#1-사전-준비사항)
2. [Supabase 프로젝트 생성](#2-supabase-프로젝트-생성)
3. [프로젝트 정보 확인](#3-프로젝트-정보-확인)
4. [다음 단계](#4-다음-단계)

---

## 1. 사전 준비사항

### 필요한 것
-  Supabase 계정 (무료 플랜으로도 가능)
-  이 가이드 문서

### 확인 사항
- [ ] Supabase 대시보드 접속 가능
- [ ] 프로젝트 생성 권한

---

## 2. Supabase 프로젝트 생성

### 2.1 프로젝트 생성

#### Step 1: Supabase 대시보드 접속
1. [Supabase 대시보드](https://app.supabase.com) 접속
2. GitHub 계정으로 로그인 (또는 이메일 가입)

#### Step 2: 새 프로젝트 생성
1. **"New Project"** 클릭
2. 프로젝트 설정 입력:
   - **Organization**: 조직 선택 (없으면 새로 생성)
   - **Name**: 프로젝트 이름 (예: `community-app` 또는 `lion-sns`)
   - **Database Password**: 강력한 비밀번호 입력 ( 잃어버리지 마세요!)
   - **Region**: 가장 가까운 리전 선택 (예: `Northeast Asia (Seoul)`)
   - **Pricing Plan**: 무료 플랜 선택 가능
3. **"Create new project"** 클릭
4. 프로젝트 생성 완료까지 1-2분 대기

---

## 3. 프로젝트 정보 확인

### 3.1 프로젝트 URL 및 API 키 확인

#### Step 1: Settings 페이지 접속
1. 프로젝트 대시보드에서 좌측 메뉴 **"Settings"** 클릭
2. **"API"** 탭 선택

#### Step 2: 프로젝트 정보 복사
다음 정보를 복사해두세요 (나중에 Flutter 앱 설정에 필요):

- **Project URL**: `https://[프로젝트-id].supabase.co`
- **anon public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

** 중요**: 
- `anon public key`는 공개되어도 안전합니다 (클라이언트에서 사용)
- `service_role key`는 절대 공개하지 마세요! (서버에서만 사용)

#### Step 3: .env 파일 생성

프로젝트 루트에 `.env` 파일을 생성하고 다음 내용을 추가:

```env
SUPABASE_URL=https://[프로젝트-id].supabase.co
SUPABASE_ANON_KEY=[anon public key]
REDIRECT_URL=com.example.communityapp://callback
```

** 중요**: 
- `[프로젝트-id]`를 실제 Supabase 프로젝트 ID로 변경
- `[anon public key]`를 Supabase 대시보드에서 복사한 anon public key로 변경
- `com.example.communityapp`을 실제 앱 번들 ID로 변경

---

## 4. 다음 단계

Supabase 프로젝트 생성이 완료되면 다음 단계를 순서대로 진행하세요:

### 4.1 데이터베이스 스키마 설정
1.  [데이터베이스 초기 설정 가이드](../개발/데이터베이스/초기_설정_가이드.md) - 데이터베이스 스키마 생성

### 4.2 Storage 설정
2.  [Storage 초기 설정 가이드](./Storage/초기_설정_가이드.md) - 이미지 업로드 버킷 생성

### 4.3 인증 설정
3.  [소셜 로그인 완전 가이드](./소셜_로그인_완전_가이드.md) - Google, 카카오 로그인 설정

### 4.4 푸시 알림 설정 (선택사항)
4.  [푸시 알림 완전 가이드](./푸시_알림_완전_가이드.md) - Firebase 푸시 알림 설정

---

## 5. 확인 사항

다음 항목들을 확인하여 초기 설정이 완료되었는지 확인하세요:

- [ ] Supabase 프로젝트 생성 완료
- [ ] Project URL 및 anon public key 확인 완료
- [ ] `.env` 파일 생성 및 설정 완료
- [ ] 데이터베이스 스키마 생성 완료 (다음 단계)
- [ ] Storage 버킷 생성 완료 (다음 단계)
- [ ] 소셜 로그인 설정 완료 (다음 단계)

---

## 6. 문제 해결

### 문제 1: 프로젝트 생성이 완료되지 않음
**원인**: 네트워크 문제 또는 Supabase 서버 문제

**해결 방법**:
1. 페이지 새로고침
2. 잠시 후 다시 시도
3. Supabase 상태 페이지 확인: https://status.supabase.com

### 문제 2: API 키를 찾을 수 없음
**원인**: Settings → API 탭에 접근하지 않음

**해결 방법**:
1. 프로젝트 대시보드 → **Settings** 클릭
2. **API** 탭 클릭
3. **Project URL**과 **anon public key** 확인

### 문제 3: .env 파일이 인식되지 않음
**원인**: 파일 위치가 잘못되었거나 파일 이름이 잘못됨

**해결 방법**:
1. `.env` 파일이 프로젝트 루트에 있는지 확인
2. 파일 이름이 정확히 `.env`인지 확인 (`.env.txt` 아님)
3. `flutter clean && flutter pub get` 실행

---

## 7. 참고 자료

- [Supabase 공식 문서](https://supabase.com/docs)
- [Supabase 대시보드](https://app.supabase.com)
- [Supabase 상태 페이지](https://status.supabase.com)

---

## 8. 변경 이력

### v2.1.0 (2024-12-19)
- 최초 설계 문서 형태로 재구성
- 스키마 상세 내용 제거 (데이터베이스 폴더로 위임)
- 프로젝트 생성 → 인증 설정 → 완료 순서로 간소화
- 단계별 설명 강화

### v2.0.0 (2024-11-05)
- Supabase 백엔드 연동
- 스키마 상세 설명 추가

### v1.0.0 (2024-10-27)
- 초기 가이드 작성

