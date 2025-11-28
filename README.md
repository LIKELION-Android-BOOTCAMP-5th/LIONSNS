# Lion SNS

소셜 네트워크 서비스(SNS) Flutter 애플리케이션 - MVVM 아키텍처

## 프로젝트 소개

Lion SNS는 Flutter로 개발된 소셜 네트워크 서비스 애플리케이션입니다. 사용자들이 게시글을 작성하고, 서로 소통하며, 팔로우할 수 있는 기능을 제공합니다.

**아키텍처**: MVVM (Model-View-ViewModel) + Feature-Based

## 주요 기능

### 인증 및 프로필
- **소셜 로그인**: Google, Apple, Kakao, Naver 소셜 로그인 지원
- **프로필 관리**: 프로필 정보 조회, 편집
- **프로필 이미지**: 프로필 이미지 업로드 및 변경
- **팔로우/언팔로우**: 사용자 팔로우 및 언팔로우 기능

### 게시글
- **게시글 작성/수정/삭제**: 텍스트 및 이미지가 포함된 게시글 작성
- **게시글 목록**: 모든 게시글 목록 조회 (작성자 정보 포함)
- **게시글 상세**: 게시글 상세 정보 조회
- **이미지 업로드**: 게시글에 이미지 첨부 기능
- **내가 좋아요한 게시글**: 좋아요한 게시글 모아보기

### 댓글
- **댓글 작성**: 게시글에 댓글 작성
- **댓글 조회**: 게시글별 댓글 목록 조회
- **작성자 정보**: 댓글 작성자 프로필 정보 표시

### 좋아요
- **좋아요/좋아요 취소**: 게시글 좋아요 기능
- **좋아요 개수**: 게시글별 좋아요 개수 표시

### 검색
- **게시글 검색**: 게시글 내용 검색
- **사용자 검색**: 사용자 이름 검색
- **댓글 검색**: 댓글 내용 검색

### 홈 화면 위젯
- **통계 정보**: 총 게시글 수, 좋아요 수, 댓글 수 표시
- **최근 게시물**: 가장 최근에 작성한 게시물 정보 표시
- **바로가기**: 위젯에서 앱 실행 및 게시물 상세 화면 이동
- **로그인 상태**: 비로그인 시 로그인 버튼 표시

### 푸시 알림
- **Firebase Cloud Messaging**: 댓글, 좋아요 등 알림 수신

### 다국어 지원
- **한국어/영어**: 앱 전체 다국어 지원 (i18n)

## 기술 스택

### 프론트엔드
- **Flutter**: 크로스 플랫폼 모바일 앱 개발 프레임워크
- **Riverpod**: 상태 관리 및 의존성 주입
- **GoRouter**: 선언적 라우팅

### 백엔드
- **Supabase**: 백엔드 서비스 (인증, 데이터베이스, Storage)
- **PostgreSQL**: 관계형 데이터베이스
- **Supabase Storage**: 이미지 및 파일 저장

### 인증
- **Supabase Auth**: OAuth 및 소셜 로그인 지원
- **소셜 로그인**: Google, Apple, Kakao, Naver

### 푸시 알림
- **Firebase Cloud Messaging**: 푸시 알림 서비스

### 위젯
- **Android**: Jetpack Compose Glance 1.1.1
- **iOS**: WidgetKit (SwiftUI)

## 프로젝트 구조

```
lib/
├── main.dart                    # 앱 진입점
├── config/                      # 앱 설정 (라우터 등)
├── core/                        # 공통 모듈
│   ├── constants/               # 상수 정의
│   ├── services/                # 서비스 레이어
│   ├── utils/                   # 유틸리티
│   └── widgets/                 # 공통 위젯
└── features/                    # 기능별 모듈
    ├── auth/                    # 인증 기능
    ├── feed/                    # 피드 기능
    ├── navigation/              # 네비게이션
    └── search/                  # 검색 기능
```

## 시작하기

### 사전 요구사항
- Flutter SDK (3.9.2 이상)
- Dart SDK
- Android Studio / Xcode
- Supabase 계정
- Firebase 계정 (푸시 알림 사용 시)

### 설치 및 실행

1. **의존성 설치**
   ```bash
   flutter pub get
   ```

2. **환경 변수 설정**
   - `.env` 파일 생성
   - Supabase 프로젝트 URL 및 API 키 설정

3. **데이터베이스 설정**
   - `docs/개발/데이터베이스/초기_설정_가이드.md` 참고

4. **앱 실행**
   ```bash
   flutter run
   ```

## 문서

프로젝트 관련 상세 문서는 `docs/` 폴더를 참고하세요.

### 필수 문서
- [문서 폴더 구조](docs/README.md) - 전체 문서 구조 및 빠른 검색
- [아키텍처 가이드](docs/개발/아키텍처.md) - MVVM 아키텍처 상세 설명
- [프로젝트 파일 구조](docs/개발/프로젝트_파일_구조.md) - 디렉토리 구조 설명

### 설정 가이드
- [Supabase 초기 설정](docs/설정/Supabase_초기_설정_가이드.md)
- [데이터베이스 초기 설정](docs/개발/데이터베이스/초기_설정_가이드.md)
- [소셜 로그인 완전 가이드](docs/설정/소셜_로그인_완전_가이드.md)
- [Storage 초기 설정](docs/설정/Storage/초기_설정_가이드.md)
- [홈 화면 위젯 구현 가이드](docs/설정/위젯_구현_가이드.md)
- [푸시 알림 완전 가이드](docs/설정/푸시_알림_완전_가이드.md)
- [다국어 지원 가이드](docs/설정/다국어_가이드.md)
- [앱 환경정보 관리](docs/설정/앱_환경정보_관리_가이드.md)


## 아키텍처

이 프로젝트는 **MVVM (Model-View-ViewModel)** 패턴을 적용합니다.

**레이어 구조**:
```
View → ViewModel → Datasource → Service
```

**주요 특징**:
- Feature-Based 구조로 기능별로 모듈 분리
- Datasource를 직접 사용하여 간결한 구조
- Riverpod을 통한 상태 관리 및 의존성 주입
- Clean Architecture 경량화 (실용적 접근)

### Riverpod 상태 관리

이 프로젝트는 **Riverpod**을 상태 관리 및 의존성 주입에 사용합니다.

#### 주요 개념

1. **Provider**: 의존성 주입 및 상태 제공
   - `Provider<T>`: 단순 값 제공 (의존성 주입)
   - `StateNotifierProvider`: 상태 관리용 (ViewModel)

2. **StateNotifier**: 상태 변경 로직 캡슐화
   - ViewModel이 `StateNotifier`를 상속하여 상태 관리

3. **ConsumerWidget**: Provider를 사용하는 위젯
   - `ref.watch()`: 상태 감시 및 자동 리빌드
   - `ref.read()`: 상태 읽기 (일회성)

4. **Provider 스코프**:
   - 전역 스코프: 앱 전체 생명주기 (예: 인증 상태)
   - `autoDispose`: 위젯 해제 시 자동 dispose (예: 게시글 목록)
   - `family`: 파라미터별 인스턴스 (예: 게시글 상세)

#### 사용 예제

```dart
// Provider 정의
final authViewModelProvider = StateNotifierProvider<AuthViewModel, Result<User?>>((ref) {
  final datasource = ref.watch(supabaseAuthDatasourceProvider);
  return AuthViewModel(datasource);
});

// View에서 사용
class AuthScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authResult = ref.watch(authViewModelProvider);
    
    return authResult.when(
      success: (user) => user == null ? _buildLoginButtons(ref) : _buildLoggedIn(user),
      failure: (message, _) => _buildError(message),
      pending: (_) => _buildLoading(),
    );
  }
}
```

자세한 내용은 [아키텍처 가이드](docs/개발/아키텍처.md)를 참고하세요.

## 관련 프로젝트

- **LionSNS-CA**: Clean Architecture를 완전히 적용한 버전
  - Use Case 패턴
  - Repository 패턴 (인터페이스 + 구현체)
  - DTO 패턴

## 라이선스

이 프로젝트는 교육용으로 제작되었습니다.
