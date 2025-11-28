// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Community App';

  @override
  String get login => 'Login';

  @override
  String get welcomeMessage => 'Welcome to\nour community!';

  @override
  String get loginInProgress =>
      'Login in progress...\nPlease complete login in the browser.';

  @override
  String get googleLogin => 'Login with Google';

  @override
  String get appleLogin => 'Login with Apple';

  @override
  String get kakaoLogin => 'Login with Kakao';

  @override
  String get naverLogin => 'Login with Naver';

  @override
  String get profile => 'Profile';

  @override
  String get profileEdit => 'Edit Profile';

  @override
  String get profileView => 'View Profile';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get post => 'Post';

  @override
  String get postCreate => 'Create Post';

  @override
  String get postEdit => 'Edit Post';

  @override
  String get postDetail => 'Post Detail';

  @override
  String get postCreated => 'Post created';

  @override
  String get postUpdated => 'Post updated';

  @override
  String get postDeleteConfirm => 'Are you sure you want to delete?';

  @override
  String get postDeleteTitle => 'Delete Confirmation';

  @override
  String get postListTitle => 'Lion SNS';

  @override
  String get postEmpty => 'No posts';

  @override
  String get postEmptyHint => 'Create your first post!';

  @override
  String get postLoading => 'Loading posts...';

  @override
  String get postError => 'An error occurred';

  @override
  String get retry => 'Retry';

  @override
  String get comment => 'Comment';

  @override
  String get commentDelete => 'Delete Comment';

  @override
  String get commentDeleteConfirm =>
      'Are you sure you want to delete this comment?';

  @override
  String get commentEmpty => 'No comments';

  @override
  String get commentInputHint => 'Enter a comment...';

  @override
  String get commentInputError => 'Please enter a comment';

  @override
  String commentLoadError(String message) {
    return 'Failed to load comments: $message';
  }

  @override
  String get like => 'Like';

  @override
  String get likedPosts => 'Liked Posts';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Enter search term';

  @override
  String get searchNoResults => 'No search results';

  @override
  String get searchError => 'An error occurred while searching';

  @override
  String get searchLoading => 'Searching...';

  @override
  String get tabPost => 'Post';

  @override
  String get tabComment => 'Comment';

  @override
  String get tabUser => 'User';

  @override
  String get likedPostsEmpty => 'No liked posts';

  @override
  String get likedPostsEmptyHint => 'Like posts you find interesting!';

  @override
  String get likedPostsLoading => 'Loading liked posts...';

  @override
  String get title => 'Title';

  @override
  String get titleHint => 'Enter title';

  @override
  String get titleError => 'Please enter a title';

  @override
  String get content => 'Content';

  @override
  String get contentHint => 'Enter content';

  @override
  String get contentError => 'Please enter content';

  @override
  String get image => 'Image';

  @override
  String get imageAttach => 'Attach Image';

  @override
  String get imageSelect => 'Select Image';

  @override
  String get imageSelectGallery => 'Choose from Gallery';

  @override
  String get imageSelectCamera => 'Take Photo';

  @override
  String imageSelectError(String error) {
    return 'Image selection failed: $error';
  }

  @override
  String get create => 'Create';

  @override
  String get update => 'Update';

  @override
  String get loginRequired => 'Login required';

  @override
  String get dataLoadError => 'Unable to load data';

  @override
  String get profileLoadError => 'Failed to load profile';

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String get goBack => 'Go Back';

  @override
  String get close => 'Close';

  @override
  String get name => 'Name';

  @override
  String get email => 'Email';

  @override
  String get loginMethod => 'Login Method';

  @override
  String get follower => 'Follower';

  @override
  String get following => 'Following';

  @override
  String get follow => 'Follow';

  @override
  String get unfollow => 'Unfollow';

  @override
  String get followersEmpty => 'No followers';

  @override
  String get followingEmpty => 'Not following anyone';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String errorOccurred(String error) {
    return 'An error occurred: $error';
  }

  @override
  String pageNotFound(String uri) {
    return 'Page not found: $uri';
  }

  @override
  String get anonymous => 'Anonymous';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String dateFormat(int year, int month, int day) {
    return '$year/$month/$day';
  }

  @override
  String get nickname => 'Nickname';

  @override
  String get nicknameHint => 'Enter nickname';

  @override
  String get nicknameError => 'Please enter a nickname';

  @override
  String get nicknameErrorEmpty => 'Please enter a nickname';

  @override
  String get nicknameErrorLength => 'Nickname must be 20 characters or less';

  @override
  String get user => 'User';

  @override
  String get titleAndContentRequired => 'Please enter title and content';

  @override
  String get postNotFound => 'Post not found';

  @override
  String get exitMessage => 'Press back again to exit';
}
