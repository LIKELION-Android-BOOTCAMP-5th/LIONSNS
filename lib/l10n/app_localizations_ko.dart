// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '커뮤니티 앱';

  @override
  String get login => '로그인';

  @override
  String get welcomeMessage => '커뮤니티에 오신 것을\n환영합니다!';

  @override
  String get loginInProgress => '로그인 진행 중입니다...\n브라우저에서 로그인을 완료해주세요.';

  @override
  String get googleLogin => 'Google로 로그인';

  @override
  String get appleLogin => 'Apple로 로그인';

  @override
  String get kakaoLogin => '카카오로 로그인';

  @override
  String get naverLogin => '네이버로 로그인';

  @override
  String get profile => '프로필';

  @override
  String get profileEdit => '프로필 편집';

  @override
  String get profileView => '프로필 보기';

  @override
  String get profileSaved => '프로필이 저장되었습니다';

  @override
  String get edit => '수정';

  @override
  String get save => '저장';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get logout => '로그아웃';

  @override
  String get logoutConfirm => '정말 로그아웃하시겠습니까?';

  @override
  String get post => '게시글';

  @override
  String get postCreate => '게시글 작성';

  @override
  String get postEdit => '게시글 수정';

  @override
  String get postDetail => '게시글 상세';

  @override
  String get postCreated => '게시글이 작성되었습니다';

  @override
  String get postUpdated => '게시글이 수정되었습니다';

  @override
  String get postDeleteConfirm => '정말 삭제하시겠습니까?';

  @override
  String get postDeleteTitle => '삭제 확인';

  @override
  String get postListTitle => 'Lion SNS';

  @override
  String get postEmpty => '게시글이 없습니다';

  @override
  String get postEmptyHint => '첫 게시글을 작성해보세요!';

  @override
  String get postLoading => '게시글을 불러오는 중...';

  @override
  String get postError => '오류가 발생했습니다';

  @override
  String get retry => '다시 시도';

  @override
  String get comment => '댓글';

  @override
  String get commentDelete => '댓글 삭제';

  @override
  String get commentDeleteConfirm => '정말 이 댓글을 삭제하시겠습니까?';

  @override
  String get commentEmpty => '댓글이 없습니다';

  @override
  String get commentInputHint => '댓글을 입력하세요...';

  @override
  String get commentInputError => '댓글을 입력해주세요';

  @override
  String commentLoadError(String message) {
    return '댓글을 불러오는데 실패했습니다: $message';
  }

  @override
  String get like => '좋아요';

  @override
  String get likedPosts => '좋아요한 글';

  @override
  String get search => '검색';

  @override
  String get searchHint => '검색어를 입력하세요';

  @override
  String get searchNoResults => '검색 결과가 없습니다';

  @override
  String get searchError => '검색 중 오류가 발생했습니다';

  @override
  String get searchLoading => '검색 중...';

  @override
  String get tabPost => '포스트';

  @override
  String get tabComment => '댓글';

  @override
  String get tabUser => '사용자';

  @override
  String get likedPostsEmpty => '좋아요한 글이 없습니다';

  @override
  String get likedPostsEmptyHint => '마음에 드는 글에 좋아요를 눌러보세요!';

  @override
  String get likedPostsLoading => '좋아요한 글을 불러오는 중...';

  @override
  String get title => '제목';

  @override
  String get titleHint => '제목을 입력하세요';

  @override
  String get titleError => '제목을 입력해주세요';

  @override
  String get content => '내용';

  @override
  String get contentHint => '내용을 입력하세요';

  @override
  String get contentError => '내용을 입력해주세요';

  @override
  String get image => '이미지';

  @override
  String get imageAttach => '이미지 첨부';

  @override
  String get imageSelect => '이미지 선택';

  @override
  String get imageSelectGallery => '갤러리에서 선택';

  @override
  String get imageSelectCamera => '카메라로 촬영';

  @override
  String imageSelectError(String error) {
    return '이미지 선택 실패: $error';
  }

  @override
  String get create => '작성하기';

  @override
  String get update => '수정하기';

  @override
  String get loginRequired => '로그인이 필요합니다';

  @override
  String get dataLoadError => '데이터를 불러올 수 없습니다';

  @override
  String get profileLoadError => '프로필을 불러오는데 실패했습니다';

  @override
  String get profileNotFound => '프로필을 찾을 수 없습니다';

  @override
  String get goBack => '돌아가기';

  @override
  String get close => '닫기';

  @override
  String get name => '이름';

  @override
  String get email => '이메일';

  @override
  String get loginMethod => '로그인 방법';

  @override
  String get follower => '팔로워';

  @override
  String get following => '팔로잉';

  @override
  String get follow => '팔로우';

  @override
  String get unfollow => '언팔로우';

  @override
  String get followersEmpty => '팔로워가 없습니다';

  @override
  String get followingEmpty => '팔로잉이 없습니다';

  @override
  String get loading => '로딩 중...';

  @override
  String get error => '오류';

  @override
  String errorOccurred(String error) {
    return '오류가 발생했습니다: $error';
  }

  @override
  String pageNotFound(String uri) {
    return '페이지를 찾을 수 없습니다: $uri';
  }

  @override
  String get anonymous => '익명';

  @override
  String get justNow => '방금 전';

  @override
  String minutesAgo(int count) {
    return '$count분 전';
  }

  @override
  String hoursAgo(int count) {
    return '$count시간 전';
  }

  @override
  String daysAgo(int count) {
    return '$count일 전';
  }

  @override
  String dateFormat(int year, int month, int day) {
    return '$year년 $month월 $day일';
  }

  @override
  String get nickname => '닉네임';

  @override
  String get nicknameHint => '닉네임을 입력하세요';

  @override
  String get nicknameError => '닉네임을 입력해주세요';

  @override
  String get nicknameErrorEmpty => '닉네임을 입력해주세요';

  @override
  String get nicknameErrorLength => '닉네임은 20자 이하로 입력해주세요';

  @override
  String get user => '사용자';

  @override
  String get titleAndContentRequired => '제목과 내용을 입력해주세요';

  @override
  String get postNotFound => '게시글을 찾을 수 없습니다';

  @override
  String get exitMessage => '한 번 더 누르면 종료됩니다';
}
