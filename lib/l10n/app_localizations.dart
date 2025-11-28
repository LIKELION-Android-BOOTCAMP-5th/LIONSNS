import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// 앱 제목
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 앱'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get login;

  /// 환영 메시지
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티에 오신 것을\n환영합니다!'**
  String get welcomeMessage;

  /// No description provided for @loginInProgress.
  ///
  /// In ko, this message translates to:
  /// **'로그인 진행 중입니다...\n브라우저에서 로그인을 완료해주세요.'**
  String get loginInProgress;

  /// No description provided for @googleLogin.
  ///
  /// In ko, this message translates to:
  /// **'Google로 로그인'**
  String get googleLogin;

  /// No description provided for @appleLogin.
  ///
  /// In ko, this message translates to:
  /// **'Apple로 로그인'**
  String get appleLogin;

  /// No description provided for @kakaoLogin.
  ///
  /// In ko, this message translates to:
  /// **'카카오로 로그인'**
  String get kakaoLogin;

  /// No description provided for @naverLogin.
  ///
  /// In ko, this message translates to:
  /// **'네이버로 로그인'**
  String get naverLogin;

  /// No description provided for @profile.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get profile;

  /// No description provided for @profileEdit.
  ///
  /// In ko, this message translates to:
  /// **'프로필 편집'**
  String get profileEdit;

  /// No description provided for @profileView.
  ///
  /// In ko, this message translates to:
  /// **'프로필 보기'**
  String get profileView;

  /// No description provided for @profileSaved.
  ///
  /// In ko, this message translates to:
  /// **'프로필이 저장되었습니다'**
  String get profileSaved;

  /// No description provided for @edit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @logout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In ko, this message translates to:
  /// **'정말 로그아웃하시겠습니까?'**
  String get logoutConfirm;

  /// No description provided for @post.
  ///
  /// In ko, this message translates to:
  /// **'게시글'**
  String get post;

  /// No description provided for @postCreate.
  ///
  /// In ko, this message translates to:
  /// **'게시글 작성'**
  String get postCreate;

  /// No description provided for @postEdit.
  ///
  /// In ko, this message translates to:
  /// **'게시글 수정'**
  String get postEdit;

  /// No description provided for @postDetail.
  ///
  /// In ko, this message translates to:
  /// **'게시글 상세'**
  String get postDetail;

  /// No description provided for @postCreated.
  ///
  /// In ko, this message translates to:
  /// **'게시글이 작성되었습니다'**
  String get postCreated;

  /// No description provided for @postUpdated.
  ///
  /// In ko, this message translates to:
  /// **'게시글이 수정되었습니다'**
  String get postUpdated;

  /// No description provided for @postDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'정말 삭제하시겠습니까?'**
  String get postDeleteConfirm;

  /// No description provided for @postDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'삭제 확인'**
  String get postDeleteTitle;

  /// No description provided for @postListTitle.
  ///
  /// In ko, this message translates to:
  /// **'Lion SNS'**
  String get postListTitle;

  /// No description provided for @postEmpty.
  ///
  /// In ko, this message translates to:
  /// **'게시글이 없습니다'**
  String get postEmpty;

  /// No description provided for @postEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'첫 게시글을 작성해보세요!'**
  String get postEmptyHint;

  /// No description provided for @postLoading.
  ///
  /// In ko, this message translates to:
  /// **'게시글을 불러오는 중...'**
  String get postLoading;

  /// No description provided for @postError.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다'**
  String get postError;

  /// No description provided for @retry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retry;

  /// No description provided for @comment.
  ///
  /// In ko, this message translates to:
  /// **'댓글'**
  String get comment;

  /// No description provided for @commentDelete.
  ///
  /// In ko, this message translates to:
  /// **'댓글 삭제'**
  String get commentDelete;

  /// No description provided for @commentDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'정말 이 댓글을 삭제하시겠습니까?'**
  String get commentDeleteConfirm;

  /// No description provided for @commentEmpty.
  ///
  /// In ko, this message translates to:
  /// **'댓글이 없습니다'**
  String get commentEmpty;

  /// No description provided for @commentInputHint.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 입력하세요...'**
  String get commentInputHint;

  /// No description provided for @commentInputError.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 입력해주세요'**
  String get commentInputError;

  /// No description provided for @commentLoadError.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 불러오는데 실패했습니다: {message}'**
  String commentLoadError(String message);

  /// No description provided for @like.
  ///
  /// In ko, this message translates to:
  /// **'좋아요'**
  String get like;

  /// No description provided for @likedPosts.
  ///
  /// In ko, this message translates to:
  /// **'좋아요한 글'**
  String get likedPosts;

  /// No description provided for @search.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In ko, this message translates to:
  /// **'검색어를 입력하세요'**
  String get searchHint;

  /// No description provided for @searchNoResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get searchNoResults;

  /// No description provided for @searchError.
  ///
  /// In ko, this message translates to:
  /// **'검색 중 오류가 발생했습니다'**
  String get searchError;

  /// No description provided for @searchLoading.
  ///
  /// In ko, this message translates to:
  /// **'검색 중...'**
  String get searchLoading;

  /// No description provided for @tabPost.
  ///
  /// In ko, this message translates to:
  /// **'포스트'**
  String get tabPost;

  /// No description provided for @tabComment.
  ///
  /// In ko, this message translates to:
  /// **'댓글'**
  String get tabComment;

  /// No description provided for @tabUser.
  ///
  /// In ko, this message translates to:
  /// **'사용자'**
  String get tabUser;

  /// No description provided for @likedPostsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'좋아요한 글이 없습니다'**
  String get likedPostsEmpty;

  /// No description provided for @likedPostsEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'마음에 드는 글에 좋아요를 눌러보세요!'**
  String get likedPostsEmptyHint;

  /// No description provided for @likedPostsLoading.
  ///
  /// In ko, this message translates to:
  /// **'좋아요한 글을 불러오는 중...'**
  String get likedPostsLoading;

  /// No description provided for @title.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get title;

  /// No description provided for @titleHint.
  ///
  /// In ko, this message translates to:
  /// **'제목을 입력하세요'**
  String get titleHint;

  /// No description provided for @titleError.
  ///
  /// In ko, this message translates to:
  /// **'제목을 입력해주세요'**
  String get titleError;

  /// No description provided for @content.
  ///
  /// In ko, this message translates to:
  /// **'내용'**
  String get content;

  /// No description provided for @contentHint.
  ///
  /// In ko, this message translates to:
  /// **'내용을 입력하세요'**
  String get contentHint;

  /// No description provided for @contentError.
  ///
  /// In ko, this message translates to:
  /// **'내용을 입력해주세요'**
  String get contentError;

  /// No description provided for @image.
  ///
  /// In ko, this message translates to:
  /// **'이미지'**
  String get image;

  /// No description provided for @imageAttach.
  ///
  /// In ko, this message translates to:
  /// **'이미지 첨부'**
  String get imageAttach;

  /// No description provided for @imageSelect.
  ///
  /// In ko, this message translates to:
  /// **'이미지 선택'**
  String get imageSelect;

  /// No description provided for @imageSelectGallery.
  ///
  /// In ko, this message translates to:
  /// **'갤러리에서 선택'**
  String get imageSelectGallery;

  /// No description provided for @imageSelectCamera.
  ///
  /// In ko, this message translates to:
  /// **'카메라로 촬영'**
  String get imageSelectCamera;

  /// No description provided for @imageSelectError.
  ///
  /// In ko, this message translates to:
  /// **'이미지 선택 실패: {error}'**
  String imageSelectError(String error);

  /// No description provided for @create.
  ///
  /// In ko, this message translates to:
  /// **'작성하기'**
  String get create;

  /// No description provided for @update.
  ///
  /// In ko, this message translates to:
  /// **'수정하기'**
  String get update;

  /// No description provided for @loginRequired.
  ///
  /// In ko, this message translates to:
  /// **'로그인이 필요합니다'**
  String get loginRequired;

  /// No description provided for @dataLoadError.
  ///
  /// In ko, this message translates to:
  /// **'데이터를 불러올 수 없습니다'**
  String get dataLoadError;

  /// No description provided for @profileLoadError.
  ///
  /// In ko, this message translates to:
  /// **'프로필을 불러오는데 실패했습니다'**
  String get profileLoadError;

  /// No description provided for @profileNotFound.
  ///
  /// In ko, this message translates to:
  /// **'프로필을 찾을 수 없습니다'**
  String get profileNotFound;

  /// No description provided for @goBack.
  ///
  /// In ko, this message translates to:
  /// **'돌아가기'**
  String get goBack;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @name.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get name;

  /// No description provided for @email.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get email;

  /// No description provided for @loginMethod.
  ///
  /// In ko, this message translates to:
  /// **'로그인 방법'**
  String get loginMethod;

  /// No description provided for @follower.
  ///
  /// In ko, this message translates to:
  /// **'팔로워'**
  String get follower;

  /// No description provided for @following.
  ///
  /// In ko, this message translates to:
  /// **'팔로잉'**
  String get following;

  /// No description provided for @follow.
  ///
  /// In ko, this message translates to:
  /// **'팔로우'**
  String get follow;

  /// No description provided for @unfollow.
  ///
  /// In ko, this message translates to:
  /// **'언팔로우'**
  String get unfollow;

  /// No description provided for @followersEmpty.
  ///
  /// In ko, this message translates to:
  /// **'팔로워가 없습니다'**
  String get followersEmpty;

  /// No description provided for @followingEmpty.
  ///
  /// In ko, this message translates to:
  /// **'팔로잉이 없습니다'**
  String get followingEmpty;

  /// No description provided for @loading.
  ///
  /// In ko, this message translates to:
  /// **'로딩 중...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In ko, this message translates to:
  /// **'오류'**
  String get error;

  /// No description provided for @errorOccurred.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다: {error}'**
  String errorOccurred(String error);

  /// No description provided for @pageNotFound.
  ///
  /// In ko, this message translates to:
  /// **'페이지를 찾을 수 없습니다: {uri}'**
  String pageNotFound(String uri);

  /// No description provided for @anonymous.
  ///
  /// In ko, this message translates to:
  /// **'익명'**
  String get anonymous;

  /// No description provided for @justNow.
  ///
  /// In ko, this message translates to:
  /// **'방금 전'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In ko, this message translates to:
  /// **'{count}분 전'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In ko, this message translates to:
  /// **'{count}시간 전'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{count}일 전'**
  String daysAgo(int count);

  /// No description provided for @dateFormat.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}월 {day}일'**
  String dateFormat(int year, int month, int day);

  /// No description provided for @nickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get nickname;

  /// No description provided for @nicknameHint.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력하세요'**
  String get nicknameHint;

  /// No description provided for @nicknameError.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력해주세요'**
  String get nicknameError;

  /// No description provided for @nicknameErrorEmpty.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력해주세요'**
  String get nicknameErrorEmpty;

  /// No description provided for @nicknameErrorLength.
  ///
  /// In ko, this message translates to:
  /// **'닉네임은 20자 이하로 입력해주세요'**
  String get nicknameErrorLength;

  /// No description provided for @user.
  ///
  /// In ko, this message translates to:
  /// **'사용자'**
  String get user;

  /// No description provided for @titleAndContentRequired.
  ///
  /// In ko, this message translates to:
  /// **'제목과 내용을 입력해주세요'**
  String get titleAndContentRequired;

  /// No description provided for @postNotFound.
  ///
  /// In ko, this message translates to:
  /// **'게시글을 찾을 수 없습니다'**
  String get postNotFound;

  /// 앱 종료를 위한 백키 두 번 누르기 안내 메시지
  ///
  /// In ko, this message translates to:
  /// **'한 번 더 누르면 종료됩니다'**
  String get exitMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
