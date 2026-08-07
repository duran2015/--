import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nertc_core/nertc_core.dart'
    if (dart.library.html) 'nertc_core_web.dart';

import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_state.dart';
import 'consult_room_service.dart';
import 'nertc_room_engine.dart'
    if (dart.library.html) 'nertc_room_engine_web.dart';

/// Flutter 咨询室页（NERtc 1v1 语音/视频）—— 按 Figma #571:5052 重做（@2x → ÷2）。
///
/// 深色背景：模糊对端头像 + ~90% 黑遮罩；视频模式在其上叠对端/本端视频画面。
/// 中间：大头像 + 对端昵称（语音恒显；视频仅无画面时作为等待/关摄像头态）。
/// 顶栏：左最小化、中间胶囊(咨询室名)+时长、右侧无「...」。
/// 底部控制栏：麦克风/(摄像头|扬声器)/聊天/挂断。
///
/// 引擎生命周期由 [ConsultRoomService] 会话级管理；本页仅持有 [NertcRoomEngine] 渲染/控制。
class ConsultRoomPage extends ConsumerStatefulWidget {
  const ConsultRoomPage({
    super.key,
    required this.engine,
    required this.params,
    required this.onLeave,
    required this.onMinimize,
    required this.onOpenChat,
  });

  final NertcRoomEngine engine;
  final ConsultRoomParams params;

  /// 挂断：离房 + 收尾（由 service 处理 pop）。
  final VoidCallback onLeave;

  /// 最小化：保留会话仅退出页面（由 service 处理 pop + onMinimized）。
  final VoidCallback onMinimize;

  /// 会议内「聊天」：打开与对端的 IM 会话。
  final VoidCallback onOpenChat;

  @override
  ConsumerState<ConsultRoomPage> createState() => _ConsultRoomPageState();
}

class _ConsultRoomPageState extends ConsumerState<ConsultRoomPage> {
  /// 字幕浮层默认隐藏（ASR 仅采集上报到后端，不在 app 端展示）。需要展示时改 true。
  static const bool _showCaptionsOverlay = false;
  bool _aiPanelOpen = false;
  final TextEditingController _notesController = TextEditingController(
    text: '来访者提到近期工作调整后睡眠变差，晚间反复担心自己做不好。',
  );

  bool get _isCounselor => ref.read(currentIdentityProvider) == 'consultant';

  @override
  void initState() {
    super.initState();
    widget.engine.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.engine.removeListener(_onChanged);
    _notesController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;
    final isVideo = engine.mediaType == ConsultRoomMediaType.video;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: isVideo ? _buildVideoBody(engine) : _buildVoiceBody(engine),
      ),
    );
  }

  // ---------------- 语音咨询 ----------------

  Widget _buildVoiceBody(NertcRoomEngine engine) {
    return Stack(
      children: [
        Positioned.fill(child: _blurredAvatarBg()),
        Positioned.fill(child: _centerAvatarName(engine)),
        _topBar(engine),
        if (_isCounselor) _emotionStatusChip(),
        if (_showCaptionsOverlay) _captionsOverlay(engine),
        if (_isCounselor && _aiPanelOpen) _aiAssistantPanel(engine),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _controlBar(engine, video: false),
        ),
      ],
    );
  }

  // ---------------- 视频咨询 ----------------

  Widget _buildVideoBody(NertcRoomEngine engine) {
    // 等待对方（对端未加入）：大屏看自己、不显示右上小窗；
    // 对端接入后：大屏看对方、右上小窗看自己（点小窗可互换）。
    final peerHere = engine.remoteUid != null;
    final bigLocal = !peerHere || engine.swapped;
    final bigHasVideo =
        bigLocal ? !engine.camOff : (engine.remoteVideoActive && peerHere);
    return Stack(
      children: [
        Positioned.fill(child: _blurredAvatarBg()),
        // 大画面（有视频时满铺，覆盖模糊头像）
        if (bigHasVideo)
          Positioned.fill(
              child: _videoSurface(engine, local: bigLocal, big: true)),
        // 无大画面时：中间大头像 + 昵称（等待且关摄像头 / 对方关摄像头）
        if (!bigHasVideo) Positioned.fill(child: _centerAvatarName(engine)),
        // 右上小窗：仅对端接入后展示（等待时隐藏）
        if (peerHere)
          _PipWindow(
            onTap: engine.toggleSwap,
            child: _videoSurface(engine, local: !bigLocal, big: false),
          ),
        _topBar(engine),
        if (_isCounselor) _emotionStatusChip(),
        // 等待接听且自己摄像头开（大屏被本地视频占住）：顶部居中浮「等待接听...」。
        // 摄像头关时中间头像区(_centerAvatarName)自带该文案，不重复。
        if (!peerHere && !engine.camOff) _videoWaitingBadge(),
        if (_showCaptionsOverlay) _captionsOverlay(engine),
        if (_isCounselor && _aiPanelOpen) _aiAssistantPanel(engine),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _controlBar(engine, video: true),
        ),
      ],
    );
  }

  /// 取本端或对端的视频/占位（big=true 给满铺大画面，false 给小窗）。
  /// 关键：关摄像头用 enableLocalVideo（真正关采集）→ 对端收 onUserVideoStop →
  /// remoteVideoActive=false；大画面无视频时由外层改用 [_centerAvatarName]。
  Widget _videoSurface(NertcRoomEngine engine,
      {required bool local, required bool big}) {
    if (local) {
      return engine.camOff
          ? (big ? _videoPlaceholder(text: '摄像头已关闭') : _smallCameraOff())
          : NERtcVideoView.withInternalRenderer(
              uid: null, // null = 本端
              fitType: NERtcVideoViewFitType.cover,
            );
    }
    // 对端
    if (engine.remoteVideoActive && engine.remoteUid != null) {
      return NERtcVideoView.withInternalRenderer(
        uid: engine.remoteUid,
        fitType: NERtcVideoViewFitType.cover,
      );
    }
    // 对端无视频：曾发布过=关了摄像头；否则=连接中/未加入
    if (big) {
      return (engine.remoteUid != null && engine.remoteVideoEverStarted)
          ? _videoPlaceholder(text: '对方已关闭摄像头')
          : _waitingPeer(engine);
    }
    return _smallCameraOff();
  }

  // ---------------- 背景 + 中间头像 ----------------

  /// 模糊对端头像（放大铺满）+ ~90% 黑遮罩（figma：blur 27px ÷2≈13.5、黑 0.9048）。
  Widget _blurredAvatarBg() {
    final url = widget.params.userAvatar?.trim();
    final hasUrl = url != null && url.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasUrl)
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 13.5, sigmaY: 13.5),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Colors.black),
            ),
          )
        else
          const ColoredBox(color: Colors.black),
        // 黑遮罩（0xE6 ≈ 0.90）
        const ColoredBox(color: Color(0xE6000000)),
      ],
    );
  }

  /// 中间大头像(105) + 对端昵称(#E5E5E5 18px Semibold) + 状态。
  /// 语音恒显；视频在无大画面时（等待/关摄像头）显示。说话时头像轻微放大。
  Widget _centerAvatarName(NertcRoomEngine engine) {
    final speaking = engine.localVolume > 15 || engine.remoteVolume > 15;
    return Align(
      alignment: const Alignment(0, -0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: speaking ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: _peerAvatarCircle(105,
                  borderColor: AppColors.accentTeal,
                  borderWidth: speaking ? 3 : 1.5),
            ),
            const SizedBox(height: 16),
            Text(
              _peerDisplayName,
              style: const TextStyle(
                color: Color(0xFFE5E5E5),
                fontSize: 18, // figma 36 ÷2
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (engine.remoteUid != null) ...[
              const SizedBox(height: 8),
              Text(
                engine.mediaType == ConsultRoomMediaType.video
                    ? '正在视频咨询中'
                    : '正在语音咨询中',
                style: const TextStyle(
                  color: Color(0xFFD0BCFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: Color(0xFF20E3A2)),
                    SizedBox(width: 8),
                    Text('网络质量良好',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
            // 未接听时在姓名下方提示「等待接听...」；对端接听后整段隐藏（通话中不再重复状态）
            if (engine.remoteUid == null) ...[
              const SizedBox(height: 8),
              const Text(
                '等待接听...',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------- 顶栏 ----------------

  /// 顶栏：左最小化、中间胶囊(咨询室名)+时长、右侧无「...」（figma：去掉顶部操作2）。
  Widget _topBar(NertcRoomEngine engine) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: widget.onMinimize,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    // 左 15（Figma x:30÷2）；上下撑满 56 顶栏作点击热区
                    padding: const EdgeInsets.fromLTRB(15, 10, 16, 10),
                    child: Image.asset(AppAssets.icRoomMinimize,
                        width: 36, height: 36), // Figma 72 → 36
                  ),
                ),
              ),
              _topCenterBlock(engine),
            ],
          ),
        ),
      ),
    );
  }

  /// 中间块：上方胶囊(咨询室名) + 下方时长（figma「中间」frame：标签在上、28:56 在下）。
  Widget _topCenterBlock(NertcRoomEngine engine) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 胶囊：白 10% 底、圆角 9、#999 11px
        Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '🔒 预约会议 · $_meetingCode',
            style: const TextStyle(color: Color(0xFF999999), fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // 计时仅在接听后展示；未接听顶栏只露房间名（等待态提示移至头像下方）
        if (engine.remoteUid != null) ...[
          const SizedBox(height: 4),
          Text(
            _fmtDur(engine.callSeconds),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14, // figma 28 ÷2
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ],
    );
  }

  /// 视频等待浮层：本地视频满屏时（等待接听且摄像头开），顶部居中显示「等待接听...」。
  /// 复用 _centerAvatarName 同款样式（white70 / 13px），与头像下方文案保持一致。
  Widget _videoWaitingBadge() {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 60, // 顶栏 56 下方留 4
      left: 0,
      right: 0,
      child: const Align(
        alignment: Alignment.topCenter,
        child: Text(
          '等待接听...',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ),
    );
  }

  String get _meetingCode {
    final raw = widget.params.orderId?.replaceAll(RegExp(r'\D'), '') ?? '';
    final suffix = raw.isEmpty ? '000101' : raw.padLeft(6, '0');
    return 'KL-$suffix';
  }

  // ---------------- 占位 / 头像组件 ----------------

  /// 大画面无视频占位（关摄像头/对端关摄像头）。
  Widget _videoPlaceholder({required String text}) {
    return Container(
      color: const Color(0xFF15161A),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off, color: Colors.white54, size: 40),
          const SizedBox(height: 10),
          Text(text,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  /// 小窗无视频占位（仅图标）。
  Widget _smallCameraOff() {
    return const ColoredBox(
      color: Colors.black87,
      child: Center(child: Icon(Icons.videocam_off, color: Colors.white54)),
    );
  }

  /// 视频等待占位：对端头像 + 昵称 + 等待文案（_videoSurface 大画面回退用）。
  Widget _waitingPeer(NertcRoomEngine engine) {
    return Container(
      color: const Color(0xFF15161A),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _peerAvatarCircle(120),
          const SizedBox(height: 16),
          Text(
            _peerDisplayName,
            style: const TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            engine.isJoining ? '正在连接…' : '等待对方加入…',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// 对端头像圆（有 url 用网络图，无则 spa 图标占位）。size=直径。
  /// 可选 borderColor/borderWidth（中间大头像加青色描边，随说话态加粗）。
  Widget _peerAvatarCircle(double size,
      {Color? borderColor, double borderWidth = 0}) {
    final url = widget.params.userAvatar?.trim();
    final hasUrl = url != null && url.isNotEmpty;
    final fallback = ColoredBox(
      color: AppColors.brandTealLight,
      child: Center(
        child: Text(
          _peerDisplayName.characters.firstOrNull ?? '对',
          style: TextStyle(
            color: const Color(0xFF21005D),
            fontSize: size * 0.34,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasUrl
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            )
          : fallback,
    );
  }

  /// 对端展示名：优先 userName，回退 roomName，再回退「对方」。
  String get _peerDisplayName {
    final n = widget.params.userName?.trim();
    if (n != null && n.isNotEmpty) return n;
    final rn = widget.params.roomName?.trim();
    if (rn != null && rn.isNotEmpty) return rn;
    return '对方';
  }

  /// 通话时长格式化：MM:SS（≥1h 则 HH:MM:SS）。
  static String _fmtDur(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = sec.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  // ---------------- 字幕 / 控制栏 ----------------

  /// 字幕浮层（有字幕时显示最近 2 条，靠近底部控制栏上方）。
  Widget _captionsOverlay(NertcRoomEngine engine) {
    final caps = engine.captions;
    if (caps.isEmpty) return const SizedBox.shrink();
    final recent = caps.length >= 2 ? caps.sublist(caps.length - 2) : caps;
    return Positioned(
      left: 16,
      right: 16,
      bottom: 124,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in recent)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  c,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.3),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _controlBar(NertcRoomEngine engine, {required bool video}) {
    return Container(
      // 底部避开 Home 指示条
      padding: EdgeInsets.fromLTRB(
          16, 18, 16, 18 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black54],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _circleButton(
            asset:
                engine.micMuted ? AppAssets.icRoomMicOff : AppAssets.icRoomMic,
            active: !engine.micMuted,
            onTap: engine.toggleMic,
            label: engine.micMuted ? '麦克风已关' : '麦克风已开',
          ),
          // 视频独有摄像头；语音无对应 figma 切图（本 frame 为视频），省略扬声器
          if (video)
            _circleButton(
              asset: engine.camOff
                  ? AppAssets.icRoomCameraOff
                  : AppAssets.icRoomCamera,
              active: !engine.camOff,
              onTap: engine.toggleCamera,
              label: engine.camOff ? '摄像头已关' : '摄像头已开',
            ),
          if (!video)
            _circleButton(
              icon: engine.speakerOn
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              active: engine.speakerOn,
              onTap: engine.toggleSpeaker,
              label: '扬声器',
            ),
          _circleButton(
            asset: AppAssets.icRoomChat,
            active: true,
            onTap: widget.onOpenChat,
            label: '聊天',
          ),
          if (_isCounselor)
            _circleButton(
              icon: Icons.auto_awesome_rounded,
              active: _aiPanelOpen,
              accent: true,
              onTap: () => setState(() => _aiPanelOpen = !_aiPanelOpen),
              label: 'AI 助手',
            ),
          if (_isCounselor)
            _circleButton(
              icon: Icons.warning_amber_rounded,
              active: true,
              danger: true,
              onTap: _showRiskDialog,
              label: '风险上报',
            ),
          _circleButton(
            asset: AppAssets.icRoomHangup,
            active: true,
            onTap: widget.onLeave,
            label: '挂断',
          ),
        ],
      ),
    );
  }

  /// 圆形控制按钮：直接用 figma 切图（整图含圆形底+字形，116÷2=58）。
  /// 状态用透明度区分（figma 仅给「已开」态：关态整体降到 0.4）。
  Widget _circleButton({
    String? asset,
    IconData? icon,
    required bool active,
    required VoidCallback onTap,
    required String label,
    bool accent = false,
    bool danger = false,
  }) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 48,
          height: 48,
          decoration: icon == null
              ? null
              : BoxDecoration(
                  color: danger
                      ? const Color(0xFF5C1A1A)
                      : accent
                          ? const Color(0xFF6750A4)
                          : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: danger
                      ? Border.all(color: const Color(0xFFD92D20))
                      : null,
                ),
          child: Opacity(
            opacity: active ? 1.0 : 0.4,
            child: asset != null
                ? Image.asset(asset, width: 58, height: 58)
                : Icon(
                    icon,
                    color: danger ? const Color(0xFFFF8A80) : Colors.white,
                    size: 22,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _emotionStatusChip() {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 60,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () => setState(() => _aiPanelOpen = true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insights_rounded,
                    size: 15, color: Color(0xFFD0BCFF)),
                SizedBox(width: 6),
                Text(
                  '情绪：焦虑 · 波动上升',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _aiAssistantPanel(NertcRoomEngine engine) {
    final transcript = engine.captions.isEmpty
        ? const [
            '我：上次你提到工作调整后睡眠变差，这周最明显的变化是什么？',
            '来访者：一到晚上就会反复想第二天的工作，担心自己做不好。',
          ]
        : engine.captions.take(4).toList();
    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: math.min(MediaQuery.sizeOf(context).width * 0.86, 360),
      child: Material(
        color: const Color(0xFFFAF8F5),
        elevation: 16,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          left: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFEADDFF),
                      child: Icon(Icons.auto_awesome_rounded,
                          size: 17, color: Color(0xFF4F378B)),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('AI 咨询助手',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _aiPanelOpen = false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _assistantCard(
                      title: '实时情绪洞察',
                      trailing: engine.mediaType == ConsultRoomMediaType.video
                          ? '多模态情绪识别'
                          : '语音情绪识别',
                      child: const Text(
                        '当前以焦虑和紧张为主，谈及工作评价时波动明显。',
                        style: TextStyle(height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _assistantCard(
                      title: '实时转录流',
                      trailing: 'Recording',
                      child: Column(
                        children: [
                          for (final text in transcript)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(text,
                                    style: const TextStyle(height: 1.45)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _assistantCard(
                      title: '咨询笔记（仅自己可见）',
                      trailing: 'AI 提取重点',
                      child: TextField(
                        controller: _notesController,
                        minLines: 6,
                        maxLines: 10,
                        decoration: InputDecoration(
                          hintText: '记录临床观察或会谈重点',
                          filled: true,
                          fillColor: const Color(0xFFFAF8F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Color(0xFFECE6DC)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _assistantCard({
    required String title,
    required String trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE6DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Text(trailing,
                  style:
                      const TextStyle(fontSize: 10, color: Color(0xFF6750A4))),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Future<void> _showRiskDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD92D20)),
        title: const Text('危机风险上报'),
        content: const Text('此操作不会中断当前通话。提交后将触发平台安全干预流程。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD92D20),
            ),
            child: const Text('确认上报'),
          ),
        ],
      ),
    );
  }
}

/// 视频小窗（右上 PiP）：可拖动、点击切换大小画面。
/// 切换大小时（child 变化）State 保留，拖动位置不丢失。
class _PipWindow extends StatefulWidget {
  const _PipWindow({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PipWindow> createState() => _PipWindowState();
}

class _PipWindowState extends State<_PipWindow> {
  static const double _w = 108, _h = 152;

  Offset? _position;
  double _maxW = 0, _maxH = 0;
  EdgeInsets _pad = EdgeInsets.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mq = MediaQuery.of(context);
    _maxW = mq.size.width;
    _maxH = mq.size.height;
    _pad = mq.padding;
    _position = _clamp(_position ?? _default());
  }

  Offset _default() =>
      Offset(_maxW - _w - 12 - _pad.right, _pad.top + 64); // 默认右上、顶栏下

  /// 限定在安全区内，并避开顶栏（上）与底部控制栏（下）。
  Offset _clamp(Offset p) {
    final minX = _pad.left;
    final maxX = math.max(minX, _maxW - _w - _pad.right);
    final minY = _pad.top + 60; // 顶栏
    final maxY = math.max(minY, _maxH - _h - _pad.bottom - 116); // 控制栏
    return Offset(p.dx.clamp(minX, maxX), p.dy.clamp(minY, maxY));
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _position = _clamp((_position ?? Offset.zero) + d.delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _position ?? _default();
    return Positioned(
      left: p.dx,
      top: p.dy,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanUpdate: _onPanUpdate,
        child: SizedBox(
          width: _w,
          height: _h,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
