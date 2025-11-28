import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lionsns/config/router.dart';
import 'package:lionsns/core/services/internal/widget_update_service_provider.dart';
import 'package:lionsns/features/feed/presentation/pages/post_list_screen.dart';
import 'package:lionsns/features/feed/presentation/pages/search_screen.dart';
import 'package:lionsns/features/feed/presentation/providers/providers.dart';
import 'package:lionsns/features/auth/presentation/pages/profile_screen.dart';
import 'package:lionsns/l10n/app_localizations.dart';

/// 메인 네비게이션 화면 (BottomNavigationBar 포함)
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressedTime; // 마지막 백키 누른 시간

  final List<Widget> _screens = [
    const PostListScreen(),
    const SearchScreen(),
    const SizedBox.shrink(), // 게시글 작성은 네비게이션으로 처리
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 위젯 업데이트
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(widgetUpdateServiceProvider).updateWidget();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return PopScope(
      canPop: _currentIndex != 0, // 홈 탭이 아니면 일반 백키 처리 (GoRouter가 처리)
      onPopInvoked: (didPop) {
        // 홈 탭일 때만 두 번 백키 처리
        if (!didPop && _currentIndex == 0) {
          final now = DateTime.now();
          
          // 첫 번째 백키이거나 2초 이상 지났으면 안내 메시지 표시
          if (_lastBackPressedTime == null || 
              now.difference(_lastBackPressedTime!) > const Duration(seconds: 2)) {
            _lastBackPressedTime = now;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n?.exitMessage ?? '한 번 더 누르면 종료됩니다'),
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            // 2초 내에 두 번째 백키를 누르면 앱 종료
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            // 게시글 작성 화면으로 이동
            context.push(AppRoutes.postCreate).then((_) {
              // 작성 후 홈 화면의 게시글 리스트 새로고침 및 위젯 업데이트
              if (mounted) {
                ref.read(postListProvider.notifier).loadPosts();
                ref.read(widgetUpdateServiceProvider).updateWidget();
              }
            });
            // 인덱스는 변경하지 않음 (현재 화면 유지)
          } else {
            setState(() {
              _currentIndex = index;
              // 탭 전환 시 백키 타이머 리셋
              _lastBackPressedTime = null;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: 28),
            activeIcon: Icon(Icons.add_circle, size: 28),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
        ],
        ),
      ),
    );
  }
}

