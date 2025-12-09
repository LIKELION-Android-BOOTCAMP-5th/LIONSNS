import 'package:flutter/material.dart';
import 'package:lionsns/features/chat/presentation/widgets/chat_icon_button.dart';

/// 공통 AppBar 위젯
/// 모든 화면에서 일관된 AppBar를 제공하며, 채팅 아이콘을 자동으로 포함합니다.
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double elevation;
  final bool automaticallyImplyLeading;
  final bool showChatIcon; // 채팅 아이콘 표시 여부

  const CommonAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.elevation = 1,
    this.automaticallyImplyLeading = true,
    this.showChatIcon = true, // 기본값: 표시
  });

  @override
  Widget build(BuildContext context) {
    // 채팅 아이콘을 actions 맨 앞에 추가 (showChatIcon이 true인 경우만)
    final allActions = [
      if (showChatIcon) const ChatIconButton(),
      if (actions != null) ...actions!,
    ];

    return AppBar(
      title: title,
      elevation: elevation,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: allActions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize {
    if (bottom != null) {
      return Size.fromHeight(
        kToolbarHeight + (bottom!.preferredSize.height),
      );
    }
    return const Size.fromHeight(kToolbarHeight);
  }
}

