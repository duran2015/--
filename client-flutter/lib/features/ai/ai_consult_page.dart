import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/im/im_config.dart';
import '../../core/storage/local_flags.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_background.dart';
import '../../utils/load_image.dart';
import '../../utils/ly_cache.dart';
import '../chat/widgets/chat_conversation_view.dart';
import 'ai_api.dart';
import 'ai_settings_page.dart';
import 'widgets/ai_sharing_consent_dialog.dart';

/// 小鹿 AI 咨询页（/ai，由主壳中央小鹿按钮 push 进入）。
/// iOS 参照：XYAIModule/XYAIModule/Classes/ViewController/
/// XYAIConsultViewController.swift
/// （导航双 Tab「小鹿/真人倾听师」+ 渐变页底 + 问候区 + 消息区 +
/// 快捷动作栏 + 底部输入栏）。
///
/// 阶段 5B：AI 页本身就是机器人 IM 会话（@RBT#xinyu001）——
/// 消息区/快捷回复/输入栏由 ChatConversationView 接管：
/// - 历史消息（20 条/页）+ 新消息监听；
/// - GREETING 本地欢迎条（非 IM 消息，Android RobotChatFragment 语义）；
/// - 快捷回复两条（与 iOS 一致）点击直接发送真实文本消息（替换壳阶段 Toast 占位）；
/// - 输入栏文字/表情/图片发送（语音录制为遗留 TODO）。
class AiConsultPage extends ConsumerStatefulWidget {
  const AiConsultPage({super.key});

  @override
  ConsumerState<AiConsultPage> createState() => _AiConsultPageState();
}

class _AiConsultPageState extends ConsumerState<AiConsultPage> {
  /// guidance 只随首帧触发一次
  bool _guidanceScheduled = false;

  /// 是否已同意 AI 服务数据分享（首帧前同步读取，决定弹窗 / 输入 gate）。
  bool _aiConsented = false;

  double _fontScale = AiSettingsSnapshot.load().fontScale;

  // iOS XYAIConsultViewController 实值
  static const double _navBarHeight = 58;

  @override
  void initState() {
    super.initState();
    // 同步读取同意状态（LyCache.getSync，项目已有此模式）：首帧即可正确 gate 输入栏。
    _aiConsented =
        LyCache.getSync<bool>(key: LocalFlags.aiSharingConsented) ?? false;
    // 首帧：未同意则弹「AI 服务数据说明」；同意 / 已同意才触发后端开场消息。
    // iOS 参照：XYAIConsultViewController.viewDidAppear →
    // presentAISharingConsentIfNeeded；viewDidLoad 仅 hasConsentedAISharing
    // 才 triggerFirstTimeGuidance（合规：未同意不向第三方发送数据）。
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFirstFrame());
  }

  /// 首帧：按 AI 服务数据分享同意状态分流。
  Future<void> _onFirstFrame() async {
    if (!mounted) return;
    if (_aiConsented) {
      _triggerGuidance();
      return;
    }
    // 未同意：弹免责声明（遮罩不可关闭，必须二选一）
    final agreed = await AiSharingConsentDialog.show(context);
    if (!mounted) return;
    if (agreed == true) {
      final flags = await ref.read(localFlagsProvider.future);
      await flags.markAiSharingConsented();
      if (!mounted) return;
      setState(() => _aiConsented = true);
      // 同意后才触发后端开场消息（合规：未同意不向第三方发送数据）
      _triggerGuidance();
    } else {
      // 不同意：退出 AI 页（不写标记，下次再进仍弹）
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _triggerGuidance() async {
    if (_guidanceScheduled) return;
    _guidanceScheduled = true;
    final userId = ref.read(authControllerProvider)?.userId;
    final flags = await ref.read(localFlagsProvider.future);
    if (!mounted) return;
    await AiGuidanceTrigger(
      request: () => ref.read(aiApiProvider).triggerGuidance(),
      flags: flags,
    ).triggerIfNeeded(userId);
  }

  Future<void> _moreTapped() async {
    await Navigator.of(context).push<AiSettingsSnapshot>(
      MaterialPageRoute<AiSettingsSnapshot>(
        builder: (_) => const AiSettingsPage(),
      ),
    );
    if (!mounted) return;
    setState(() => _fontScale = AiSettingsSnapshot.load().fontScale);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 键盘弹起时压缩 body，消息区 + 输入栏整体上移（与 /chat 一致）
      resizeToAvoidBottomInset: true,
      body: AppPageBackground(
        // bottom: false —— 聊天输入栏 / 拉黑遮罩延伸盖住 Home 指示条
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildNavTabBar(),
                  // 机器人 IM 会话（消息区 + 快捷回复 + 输入栏）。
                  Expanded(
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(_fontScale),
                      ),
                      child: ChatConversationView(
                        peerUserId: ImConfig.robotUserId,
                        peerName: '心愈小鹿',
                        inputEnabled: _aiConsented,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- 导航双 Tab（iOS setupTabBar / attachTabBarToNavigationBar） ----------------

  Widget _buildNavTabBar() {
    return SizedBox(
      height: _navBarHeight,
      child: Stack(
        children: [
          // 返回键（黑色，iOS gk_backStyle = .black）
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          Positioned(
            left: 50,
            top: 0,
            bottom: 0,
            right: 56,
            child: Row(
              children: [
                ClipOval(
                  child: LoadImage(
                    AppAssets.aiAgentAvatar,
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '小鹿',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '内容由 AI 生成',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 右侧「更多」按钮：字体、音色与朗读设置
          Positioned(
            right: 8.w,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _moreTapped,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: LoadImage(
                    AppAssets.navBarMore,
                    width: 24,
                    height: 24,
                    errorWidget: const Icon(
                      Icons.more_horiz,
                      size: 24,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
