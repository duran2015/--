import 'package:flutter/material.dart';

/// 注释：通用底部 TabBar（全屏幕 ScreenUtil 响应式规范）
/// 时间：2026/8/4
/// 作者：郭翰林
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onDeerTap,
    this.unreadCount = 0,
    this.deerBadge = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onDeerTap;
  final int unreadCount;

  /// 小鹿（中央按钮）角标：机器人 rbt_xinyu001 未读数。
  final int deerBadge;

  static const int _badgeMax = 99;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = switch (currentIndex) {
      0 => 0,
      1 => 2,
      2 => 3,
      _ => 4,
    };
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            onTap(0);
          case 1:
            onDeerTap();
          case 2:
            onTap(1);
          case 3:
            onTap(2);
          case 4:
            onTap(3);
        }
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: '首页',
        ),
        NavigationDestination(
          icon: _badgeIcon(Icons.auto_awesome_outlined, deerBadge),
          selectedIcon: _badgeIcon(Icons.auto_awesome, deerBadge),
          label: '小鹿',
        ),
        const NavigationDestination(
          icon: Icon(Icons.support_agent_outlined),
          selectedIcon: Icon(Icons.support_agent_rounded),
          label: '真人咨询',
        ),
        NavigationDestination(
          icon: _badgeIcon(Icons.forum_outlined, unreadCount),
          selectedIcon: _badgeIcon(Icons.forum_rounded, unreadCount),
          label: '消息',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: '我的',
        ),
      ],
    );
  }

  Widget _badgeIcon(IconData icon, int count) {
    final child = Icon(icon);
    if (count <= 0) return child;
    return Badge(
      label: Text(count > _badgeMax ? '99+' : '$count'),
      child: child,
    );
  }
}
