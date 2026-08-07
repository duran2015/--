import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';
import '../../core/widgets/app_tab_bar.dart';
import '../home/home_page.dart';
import '../consultant/consultant_list_page.dart';
import '../message/message_page.dart';
import '../message/message_view_model.dart';
import '../mine/mine_page.dart';

/// 用户端主壳：IndexedStack 四 Tab（首页 / 真人咨询 / 消息 / 我的）+ 底栏。
/// iOS 参照：HeartHealingMain/XYMainTabBarController.swift。
///
/// Tab 结构：首页 / 小鹿(动作入口) / 真人咨询 / 消息 / 我的。
/// - 小鹿按钮是动作入口：不切换 Tab，push /ai（AI 咨询页，阶段 4 实现）；
/// - 消息 Tab 角标 = 普通对话未读总数（不含机器人与系统通知），
///   iOS 参照：XYUnreadMessageTotalChanged 通知 → Tab 角标。
class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({super.key});

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

/// 联调驱动接口（IM 复验走查专用）：供 app/navigation.dart 的元素树
/// 查找器定位主壳 State 并切换底部 Tab。不参与业务逻辑。
abstract class MainShellDebugHandle {
  /// 切换底部 Tab（等价于点击；0 首页 / 1 真人咨询 / 2 消息 / 3 我的）
  void selectTabForDebug(int index);
}

class _MainShellPageState extends ConsumerState<MainShellPage>
    implements MainShellDebugHandle {
  /// 当前 Tab：0 首页、1 真人咨询、2 消息、3 我的（小鹿不占 Tab 位）
  int _currentIndex = 0;

  /// 联调驱动（阶段 IM 复验）：等价于点击底部 Tab。
  @override
  void selectTabForDebug(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // 消息未读总数（普通对话 + 系统通知；不含机器人；
    // iOS 参照：XYMessageViewModel.conversationUnreadTotal）
    final unreadCount = ref.watch(messageUnreadTotalProvider);
    // 机器人未读 → 底部小鹿按钮角标（进入小鹿页即清零）
    final robotUnread = ref.watch(robotUnreadCountProvider);
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomePage(),
          ConsultantTabPage(),
          // 消息 Tab（iOS 参照：XYMessageViewController；
          // IndexedStack 同步建三个子页，对齐 iOS messageVC 提前 loadViewIfNeeded）
          MessagePage(),
          MinePage(),
        ],
      ),
      bottomNavigationBar: AppTabBar(
        currentIndex: _currentIndex,
        unreadCount: unreadCount,
        deerBadge: robotUnread,
        onTap: (index) => setState(() => _currentIndex = index),
        // 小鹿（iOS index 1）是动作入口：不切换 Tab，路由跳 AI 咨询页
        onDeerTap: () => context.push(RoutePaths.ai),
      ),
    );
  }
}
