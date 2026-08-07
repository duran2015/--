import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nertc_core/nertc_core.dart'
    if (dart.library.html) 'nertc_core_web.dart';

import '../theme/app_colors.dart';
import 'consult_room_service.dart';
import 'nertc_room_engine.dart'
    if (dart.library.html) 'nertc_room_engine_web.dart';

/// 咨询室通话最小化悬浮窗：netease（Flutter）咨询室最小化/点聊天后，通话引擎
/// 仍在跑（音频继续），本组件在所有路由之上提供一个可拖动的回入口 ——
/// 点它恢复全屏咨询室，通话结束自动消失。
///
/// 显隐由 [ConsultRoomService]（ChangeNotifier）的 isSessionActive && isMinimized 驱动；
/// 挂载点见 app.dart 的 MaterialApp.router.builder Stack（在所有 GoRoute 之上，含 /chat）。
class ConsultRoomFloatHost extends StatelessWidget {
  const ConsultRoomFloatHost({super.key, required this.service});

  final ConsultRoomService service;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        // 仅网易云信会话最小化时显示悬浮窗回入口。
        if (!service.isSessionActive || !service.isMinimized) {
          return const SizedBox.shrink();
        }
        final engine = service.nertcEngine;
        final params = service.activeParams;
        if (engine == null || params == null) {
          return const SizedBox.shrink();
        }
        return ConsultRoomFloat(service: service, engine: engine, params: params);
      },
    );
  }
}

/// 可拖动视频 PiP / 语音胶囊。
class ConsultRoomFloat extends StatefulWidget {
  const ConsultRoomFloat({
    super.key,
    required this.service,
    required this.engine,
    required this.params,
  });

  final ConsultRoomService service;
  final NertcRoomEngine engine;
  final ConsultRoomParams params;

  @override
  State<ConsultRoomFloat> createState() => _ConsultRoomFloatState();
}

class _ConsultRoomFloatState extends State<ConsultRoomFloat> {
  // 视频 PiP 尺寸；语音胶囊尺寸。
  static const double _videoW = 120, _videoH = 160;
  static const double _voiceW = 88, _voiceH = 120;

  /// 悬浮窗左上角位置（屏幕坐标）。null 表示尚未初始化（didChangeDependencies 首次算）。
  Offset? _position;

  double _maxW = 0, _maxH = 0;
  EdgeInsets _pad = EdgeInsets.zero;

  bool get _isVideo => widget.engine.mediaType == ConsultRoomMediaType.video;
  double get _w => _isVideo ? _videoW : _voiceW;
  double get _h => _isVideo ? _videoH : _voiceH;

  @override
  void initState() {
    super.initState();
    // 远端 uid / 连接态 / 大小画面切换变化时重建。
    widget.engine.addListener(_onEngineChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mq = MediaQuery.of(context);
    _maxW = mq.size.width;
    _maxH = mq.size.height;
    _pad = mq.padding;
    _position = _clamp(_position ?? _defaultPosition());
  }

  @override
  void dispose() {
    widget.engine.removeListener(_onEngineChanged);
    super.dispose();
  }

  void _onEngineChanged() {
    if (mounted) setState(() {});
  }

  Offset _defaultPosition() =>
      Offset(_maxW - _w - 12 - _pad.right, _pad.top + 12); // 默认右上角，避开状态栏

  /// 限定在安全区内（不压刘海/Home 指示条）。
  Offset _clamp(Offset p) {
    final maxX = math.max(_pad.left, _maxW - _w - _pad.right);
    final maxY = math.max(_pad.top, _maxH - _h - _pad.bottom);
    return Offset(p.dx.clamp(_pad.left, maxX), p.dy.clamp(_pad.top, maxY));
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _position = _clamp((_position ?? Offset.zero) + d.delta);
    });
  }

  void _restore() => widget.service.presentOrRestore(widget.params);

  @override
  Widget build(BuildContext context) {
    final pos = _position ?? _clamp(_defaultPosition());
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      // builder Stack 内无 Material 祖先，外层包透明 Material（避免文字双下划线）。
      child: Material(
        type: MaterialType.transparency,
        child: _isVideo ? _buildVideo() : _buildVoice(),
      ),
    );
  }

  // ---------------- 视频 PiP ----------------

  Widget _buildVideo() {
    final engine = widget.engine;
    final peerJoined = engine.remoteUid != null;
    final mainLocal = engine.swapped;
    // 主画面：切换过→本端；否则对端。对端未加入且未切换时回退本端，避免空画面。
    final showLocalMain = mainLocal || !peerJoined;
    return GestureDetector(
      onTap: _restore,
      onPanUpdate: _onPanUpdate,
      child: SizedBox(
        width: _w,
        height: _h,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24, width: 1),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 主画面（与全屏大画面一致：默认对端，切换后本端）
                _videoFor(engine, local: showLocalMain),
                // 对端已加入：右上角小窗显示另一个画面（自己/对方取决于是否切换过）
                if (peerJoined)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _smallPip(engine, local: !mainLocal),
                  ),
                // 底部：接通显示通话时长；未接听显示「等待接听」（字号更小，区别于时长）
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xB3000000), Colors.transparent],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      peerJoined ? _fmtDur(engine.callSeconds) : '等待接听',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: peerJoined ? 11 : 9,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 取本端或对端的视频/占位（小窗友好：占位用小图标）。
  Widget _videoFor(NertcRoomEngine engine, {required bool local}) {
    if (local) {
      return engine.camOff ? _pipCamOff() : _localView(engine);
    }
    return (engine.remoteVideoActive && engine.remoteUid != null)
        ? _remoteView(engine)
        : _pipCamOff();
  }

  Widget _localView(NertcRoomEngine engine) =>
      NERtcVideoView.withInternalRenderer(
        uid: null, // 本端
        fitType: NERtcVideoViewFitType.cover,
      );

  Widget _remoteView(NertcRoomEngine engine) =>
      NERtcVideoView.withInternalRenderer(
        uid: engine.remoteUid,
        fitType: NERtcVideoViewFitType.cover,
      );

  /// 悬浮窗内无视频占位（黑底 + 小摄像关闭图标）。
  Widget _pipCamOff() {
    return const ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Icon(Icons.videocam_off, color: Colors.white54, size: 20),
      ),
    );
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

  /// 悬浮窗右上角小窗（另一个画面的缩略，40×54）。
  Widget _smallPip(NertcRoomEngine engine, {required bool local}) {
    return Container(
      width: 40,
      height: 54,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: _videoFor(engine, local: local),
    );
  }

  // ---------------- 语音卡片（figma #571:4824，@2x → 一律 ÷2） ----------------

  Widget _buildVoice() {
    final engine = widget.engine;
    return GestureDetector(
      onTap: _restore,
      onPanUpdate: _onPanUpdate,
      child: SizedBox(
        width: _w, // figma 176 ÷2 = 88
        height: _h, // figma 240 ÷2 = 120
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12), // figma 24 ÷2
          child: DecoratedBox(
            decoration: BoxDecoration(
              // figma：黑底 opacity≈0.80（#000000 @ 0.8037）
              color: const Color(0xCC000000),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            // 纵向(÷2)：15 顶部 → 头像环(58) → 15 间距 → 时长(14)。
            // 设计稿无昵称、无挂断按钮，点卡片恢复全屏（与视频浮窗一致）。
            child: Column(
              children: [
                const SizedBox(height: 15),
                _voiceAvatarRing(),
                const SizedBox(height: 15),
                Text(
                  engine.remoteUid != null
                      ? _fmtDur(engine.callSeconds)
                      : '等待接听',
                  // 接通：PingFang SC Semibold 28÷2=14（行高1.0、字距≈1px）；
                  // 未接听：「等待接听」字号更小（11），区别于通话时长。
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: engine.remoteUid != null ? 14 : 11,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                    letterSpacing: engine.remoteUid != null ? 1.0 : 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 头像 + 青色环（figma @2x → ÷2）。
  /// 外层淡晕：figma「圈」#571:4826 = 116÷2=58，#00BBC8 1px(÷2=0.5)@50%。
  /// 头像环：figma 头像 80÷2=40 + 蒙版描边 6px÷2=3（白+青双层简化为青单环）。
  Widget _voiceAvatarRing() {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accentTeal.withValues(alpha: 0.50),
                width: 1.0, // ÷2=0.5，取 1.0 保证渲染可见
              ),
            ),
          ),
          Container(
            width: 46, // 40 头像 + 2×3 描边
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accentTeal, width: 3),
            ),
            child: _avatar(20), // 直径 40
          ),
        ],
      ),
    );
  }

  Widget _avatar(double radius) {
    final url = widget.params.userAvatar?.trim();
    final d = radius * 2;
    return SizedBox(
      width: d,
      height: d,
      child: ClipOval(
        child: (url != null && url.isNotEmpty)
            ? Image.network(
                url,
                width: d,
                height: d,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarFallback(radius),
              )
            : _avatarFallback(radius),
      ),
    );
  }

  Widget _avatarFallback(double radius) => Container(
        width: radius * 2,
        height: radius * 2,
        decoration: const BoxDecoration(
          color: AppColors.brandTealLight,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(Icons.spa, color: AppColors.consultVoice, size: radius),
      );
}
