import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../utils/load_image.dart';
import '../cards/chat_card_logic.dart';
import '../chat_voice_recorder.dart';
import 'chat_face_panel.dart';

/// 通用聊天输入栏：文字 / 语音两种输入态 +「+」展开面板 + 表情面板。
/// iOS 参照：XYChatModule/Classes/View/XYChatInputBar.swift（1:1 还原）：
/// - 51 高白胶囊（圆角 25.5、#F9F9F9 边、#E6EAEE 投影 offset(0,4) blur6 α0.6）；
/// - 语音/文字切换：按住说话、上滑取消（阈值 40）、最短 0.5s、500ms 后出计时；
/// - 表情面板（XYFacePanel 高 287，内置 emoji 网格）；
/// - 「+」面板：普通三格（相册/拍摄/文件，高 100）；咨询师工具面板
///   两行四列（高 200），工具项发送 question_assistant 卡片；
/// - 面板/表情/键盘三者互斥。
///
/// 语音录制：record 插件 AAC/m4a，松手回调 [onSendSound]（iOS didSendVoice）。
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSendText,
    required this.onSendImage,
    this.onSendSound,
    this.onSendFile,
    this.onSendAssistantCard,
    this.onComposerHeightChanged,
    this.counselorToolsEnabled = false,
  });

  /// 发送文本（iOS 参照：chatInputBar(didSendText:)）
  final ValueChanged<String> onSendText;

  /// 发送图片（本地路径；iOS 参照：chatInputBar(didSendImage:)）
  final ValueChanged<String> onSendImage;

  /// 发送语音（本地 path + 时长秒；iOS 参照：chatInputBar(didSendVoice:duration:)）
  final void Function(String path, int duration)? onSendSound;

  /// 发送文件（本地 path + 文件名 + 文件大小字节数）
  final void Function(String path, String name, int size)? onSendFile;

  /// 发送咨询师工具卡（question_assistant payload；
  /// iOS 参照：chatInputBar(didSendAssistantCard:)）
  final ValueChanged<Map<String, Object>>? onSendAssistantCard;

  /// 键盘弹起 / 表情或「+」面板展开时回调（父级据此把消息列表贴底）。
  final VoidCallback? onComposerHeightChanged;

  /// 是否启用咨询师工具面板（两行四列；iOS 参照：counselorToolsEnabled）
  final bool counselorToolsEnabled;

  /// 输入胶囊最小高度（Figma 102÷2）
  static const double inputRowHeight = 60;

  /// 表情面板高（iOS XYFacePanel.standardHeight）
  static const double facePanelHeight = ChatFacePanel.panelHeight;

  @override
  State<ChatInputBar> createState() => ChatInputBarState();
}

class ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  final ChatVoiceRecorder _voiceRecorder = ChatVoiceRecorder();

  bool _isVoiceMode = false;
  bool _hasText = false;
  bool _panelOpen = false;
  bool _faceOpen = false;

  // 语音按住态（iOS 参照：XYChatInputBar isRecording/isCancelZone 状态机）
  bool _recording = false;
  bool _cancelZone = false;
  bool _timerActive = false;
  int _recordSeconds = 0;
  DateTime? _pressStart;
  Timer? _delayTimer;
  Timer? _tickTimer;
  int? _activePointer;
  bool _voiceStartBlocked = false;
  Future<bool>? _voiceStartFuture;

  /// 上滑取消阈值（iOS cancelSlideUpThreshold = 40）
  static const double _cancelSlideUpThreshold = 40;

  /// 最短按住时长（iOS voiceMinPressDuration = 0.5s）
  static const Duration _minPressDuration = Duration(milliseconds: 500);

  /// 按住后延迟出计时（iOS voiceTimerDelay = 0.5s）
  static const Duration _timerDelay = Duration(milliseconds: 500);

  /// 「+」面板展开高度（普通 100 / 咨询师 200；iOS basicPanelHeight/
  /// counselorPanelHeight）
  double get _panelHeight => widget.counselorToolsEnabled ? 200 : 100;

  /// 是否处于输入活跃态（键盘或面板展开）
  bool get isInputActive => _focusNode.hasFocus || _panelOpen || _faceOpen;

  /// 收起键盘与所有展开面板（点击聊天区空白处时调用。
  /// iOS 参照：dismissActiveInputState）
  void dismissActiveInputState() {
    _focusNode.unfocus();
    if (_panelOpen) setState(() => _panelOpen = false);
    if (_faceOpen) setState(() => _faceOpen = false);
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _tickTimer?.cancel();
    unawaited(_voiceRecorder.dispose());
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final has = _controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      widget.onComposerHeightChanged?.call();
    }
  }

  void _notifyComposerHeightChanged() {
    widget.onComposerHeightChanged?.call();
  }

  // ---------------- 发送 ----------------

  void _sendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _controller.clear();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source);
      if (file != null) widget.onSendImage(file.path);
    } catch (_) {
      // 权限拒绝/无摄像头等：iOS presentCamera 有「当前设备不支持拍照」提示
      if (mounted) {
        AppToast.show(
          context,
          '无法打开${source == ImageSource.camera ? '相机' : '相册'}',
        );
      }
    }
  }

  /// 选择文件并发送（iOS 走 UIDocumentPicker / Android 走 SAF 系统选择器，由原生框架授权只读权限）
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null && file.path!.isNotEmpty) {
          widget.onSendFile?.call(
            file.path!,
            file.name,
            file.size,
          );
        }
      }
    } catch (_) {
      if (mounted) AppToast.show(context, '选择文件失败');
    }
  }

  // ---------------- 面板互斥 ----------------

  void _togglePanel() {
    setState(() {
      if (_panelOpen) {
        _panelOpen = false;
        _focusNode.requestFocus();
      } else {
        _focusNode.unfocus();
        _faceOpen = false;
        _leaveVoiceMode();
        _panelOpen = true;
      }
    });
    if (_panelOpen) _notifyComposerHeightChanged();
  }

  void _toggleFace() {
    setState(() {
      if (_faceOpen) {
        _faceOpen = false;
        _focusNode.requestFocus();
      } else {
        _focusNode.unfocus();
        _panelOpen = false;
        _leaveVoiceMode();
        _faceOpen = true;
      }
    });
    if (_faceOpen) _notifyComposerHeightChanged();
  }

  void _onEndTapped() {
    if (_isVoiceMode) {
      // 语音态 = 切回文字并弹键盘（iOS endTapped）
      setState(() => _isVoiceMode = false);
      _focusNode.requestFocus();
    } else if (_hasText) {
      _sendText();
    } else {
      // 文字态无文本 = 切语音态
      setState(() {
        _isVoiceMode = true;
        _panelOpen = false;
        _faceOpen = false;
      });
      _focusNode.unfocus();
    }
  }

  /// 展开键盘/面板时退出语音按住态（iOS leaveVoiceModeIfNeeded）
  void _leaveVoiceMode() {
    if (!_isVoiceMode) return;
    _stopRecording();
    _isVoiceMode = false;
  }

  // ---------------- 语音按住手势 ----------------
  // 用 Listener 跟指针，避免 LongPress 在部分机型松手走 cancel 丢 Toast。

  void _beginVoicePress() {
    _focusNode.unfocus();
    _delayTimer?.cancel();
    setState(() {
      _recording = true;
      _cancelZone = false;
      _timerActive = false;
      _recordSeconds = 0;
      _pressStart = DateTime.now();
      _voiceStartBlocked = false;
    });
    _voiceStartFuture = _voiceRecorder.start().then((ok) {
      if (!mounted) return ok;
      if (!ok) {
        _voiceStartBlocked = true;
        _stopRecordingUi();
        AppToast.show(context, '请在设置中开启麦克风权限');
      }
      return ok;
    });
    // 延迟 500ms 后开始展示计时（iOS scheduleVoiceTimerDisplay）
    _delayTimer = Timer(_timerDelay, () {
      if (!mounted || !_recording) return;
      setState(() => _timerActive = true);
      _tickTimer?.cancel();
      _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted || !_recording) return;
        final start = _pressStart;
        if (start == null) return;
        final elapsedMs = DateTime.now().difference(start).inMilliseconds;
        final shown =
            ((elapsedMs - _timerDelay.inMilliseconds) ~/ 1000).clamp(0, 599);
        if (shown != _recordSeconds) {
          setState(() => _recordSeconds = shown);
        }
      });
    });
  }

  void _updateVoiceCancel(Offset localPosition, Size holdSize) {
    if (!_recording) return;
    final dy = localPosition.dy - holdSize.height / 2;
    final cancel = dy < -_cancelSlideUpThreshold;
    if (cancel != _cancelZone) setState(() => _cancelZone = cancel);
  }

  void _endVoicePress({required bool cancelledBySystem}) {
    if (!_recording && _voiceStartFuture == null) return;
    final pressed = _pressStart == null
        ? Duration.zero
        : DateTime.now().difference(_pressStart!);
    final wasCancel = _cancelZone;
    _stopRecordingUi();
    unawaited(_finishVoicePress(
      pressed: pressed,
      wasCancel: wasCancel,
      cancelledBySystem: cancelledBySystem,
    ));
  }

  Future<void> _finishVoicePress({
    required Duration pressed,
    required bool wasCancel,
    required bool cancelledBySystem,
  }) async {
    final startFuture = _voiceStartFuture;
    _voiceStartFuture = null;
    if (startFuture != null) {
      try {
        await startFuture;
      } catch (_) {}
    }
    if (!mounted) {
      await _voiceRecorder.cancel();
      return;
    }
    if (cancelledBySystem || _voiceStartBlocked) {
      _voiceStartBlocked = false;
      await _voiceRecorder.cancel();
      return;
    }
    if (wasCancel) {
      await _voiceRecorder.cancel();
      if (!mounted) return;
      AppToast.show(context, '已取消发送');
      return;
    }
    if (pressed < _minPressDuration) {
      await _voiceRecorder.cancel();
      if (!mounted) return;
      AppToast.show(context, '说话时间太短');
      return;
    }
    final result = await _voiceRecorder.stop();
    if (!mounted) return;
    if (result == null) {
      AppToast.show(context, '录音失败，请重试');
      return;
    }
    final send = widget.onSendSound;
    if (send == null) return;
    send(result.path, result.duration);
  }

  void _stopRecordingUi() {
    _delayTimer?.cancel();
    _tickTimer?.cancel();
    _activePointer = null;
    if (!mounted) return;
    setState(() {
      _recording = false;
      _cancelZone = false;
      _timerActive = false;
      _recordSeconds = 0;
      _pressStart = null;
    });
  }

  void _stopRecording() {
    _stopRecordingUi();
    _voiceStartFuture = null;
    unawaited(_voiceRecorder.cancel());
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(15, 0, 15, 6 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCapsule(),
          // 「+」展开面板（胶囊下方；iOS panelView 高 0/100/200）
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            height: _panelOpen ? _panelHeight : 0,
            child: ClipRect(
              child: OverflowBox(
                minHeight: _panelHeight,
                maxHeight: _panelHeight,
                alignment: Alignment.topCenter,
                child: _buildPlusPanel(),
              ),
            ),
          ),
          // 表情面板（与「+」面板互斥；iOS faceContainer 高 0/287）
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            height: _faceOpen ? ChatInputBar.facePanelHeight : 0,
            child: ClipRect(
              child: OverflowBox(
                minHeight: ChatInputBar.facePanelHeight,
                maxHeight: ChatInputBar.facePanelHeight,
                alignment: Alignment.topCenter,
                child: ChatFacePanel(
                  onEmoji: (emoji) {
                    final sel = _controller.selection;
                    final text = _controller.text;
                    final insertAt =
                        sel.isValid && sel.start >= 0 ? sel.start : text.length;
                    _controller.value = TextEditingValue(
                      text: text.replaceRange(
                        insertAt,
                        sel.isValid && sel.end >= 0 ? sel.end : insertAt,
                        emoji,
                      ),
                      selection: TextSelection.collapsed(
                        offset: insertAt + emoji.length,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 输入胶囊（白底圆角 25.5 + #F9F9F9 边 + #E6EAEE 投影。
  /// iOS 参照：XYChatInputBar.setupContainer）
  Widget _buildCapsule() {
    final colors = Theme.of(context).colorScheme;
    final capsuleBg = !_isVoiceMode || !_recording
        ? colors.surfaceContainerLowest
        : (_cancelZone
            ? AppColors.chatRecordingCancelBg
            : AppColors.chatRecordingBg);
    return Container(
      height: ChatInputBar.inputRowHeight,
      decoration: BoxDecoration(
        color: capsuleBg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          _composerIconButton(
            key: const Key('chat_plus_button'),
            onTap: _togglePanel,
            icon: _panelOpen ? Icons.close_rounded : Icons.add_rounded,
            selected: _panelOpen,
          ),
          const SizedBox(width: 2),
          // 中间：文字输入框 / 语音按住区
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(22),
              ),
              alignment: Alignment.center,
              child: _isVoiceMode ? _buildVoiceHold() : _buildTextField(),
            ),
          ),
          // 表情按钮（文字态；面板展开时显示键盘图标）
          if (!_isVoiceMode) ...[
            const SizedBox(width: 2),
            _composerIconButton(
              key: const Key('chat_smile_button'),
              onTap: _toggleFace,
              icon: _faceOpen
                  ? Icons.keyboard_alt_outlined
                  : Icons.sentiment_satisfied_alt_outlined,
              selected: _faceOpen,
            ),
          ],
          _composerIconButton(
            key: const Key('chat_send_button'),
            onTap: _onEndTapped,
            icon: _isVoiceMode
                ? Icons.keyboard_alt_outlined
                : (_hasText ? Icons.send_rounded : Icons.graphic_eq_rounded),
            selected: _hasText,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _composerIconButton({
    required Key key,
    required VoidCallback onTap,
    required IconData icon,
    bool selected = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      key: key,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        minimumSize: const Size(42, 42),
        fixedSize: const Size(42, 42),
        foregroundColor:
            selected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
        backgroundColor:
            selected ? colors.primaryContainer : Colors.transparent,
      ),
      icon: Icon(icon, size: 24),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        isCollapsed: true,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        hintText: '发消息…',
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      textInputAction: TextInputAction.send,
      // 用 onEditingComplete 而非 onSubmitted：后者会走框架默认 unfocus，
      // 导致系统/三方键盘「发送」后立刻收起；聊天需保持键盘以便连续输入。
      onEditingComplete: _sendText,
      onTap: () {
        // 弹键盘时收起面板（iOS：键盘/面板/表情互斥）
        if (_panelOpen || _faceOpen) {
          setState(() {
            _panelOpen = false;
            _faceOpen = false;
          });
        }
      },
    );
  }

  /// 语音态「按住说话」长按区（iOS 参照：voiceHoldView + voiceLabel 三态文案）
  Widget _buildVoiceHold() {
    String label;
    if (!_recording) {
      label = '按住说话';
    } else if (_cancelZone) {
      label = '松开手指，取消发送';
    } else if (_timerActive) {
      label = '● 0:${_recordSeconds.toString().padLeft(2, '0')}';
    } else {
      label = '松开发送';
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final holdSize = Size(constraints.maxWidth, 30);
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            if (_activePointer != null) return;
            _activePointer = event.pointer;
            _beginVoicePress();
          },
          onPointerMove: (event) {
            if (event.pointer != _activePointer) return;
            _updateVoiceCancel(event.localPosition, holdSize);
          },
          onPointerUp: (event) {
            if (event.pointer != _activePointer) return;
            _endVoicePress(cancelledBySystem: false);
          },
          onPointerCancel: (event) {
            if (event.pointer != _activePointer) return;
            _endVoicePress(cancelledBySystem: true);
          },
          child: SizedBox(
            height: 30,
            width: double.infinity,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- 「+」面板 ----------------

  /// 面板项配置（iOS 参照：XYChatInputBar.PanelTileConfig）
  static const List<({String icon, String title})> _basicItems = [
    (icon: AppAssets.aiPanelAlbum, title: '相册'),
    (icon: AppAssets.aiPanelCamera, title: '拍摄'),
    (icon: AppAssets.aiPanelFile, title: '文件'),
  ];

  static const List<({String icon, String title})> _counselorItems = [
    (icon: AppAssets.aiPanelAlbum, title: '相册'),
    (icon: AppAssets.aiPanelCamera, title: '拍摄'),
    (icon: AppAssets.aiPanelFile, title: '文件'),
    (icon: AppAssets.chatPanelWoodenFish, title: '敲木鱼'),
    (icon: AppAssets.chatPanelSleep, title: '睡眠指引'),
    (icon: AppAssets.chatPanelBreath, title: '深呼吸'),
    (icon: AppAssets.chatPanelWhiteNoise, title: '白噪音'),
    (icon: AppAssets.chatPanelMeditation, title: '冥想'),
  ];

  Widget _buildPlusPanel() {
    final items = widget.counselorToolsEnabled ? _counselorItems : _basicItems;
    return Container(
      height: _panelHeight,
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        children: [
          for (var row = 0; row * 4 < items.length; row++) ...[
            if (row > 0) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var col = 0; col < 4; col++)
                  Expanded(
                    child: row * 4 + col < items.length
                        ? _buildPanelTile(items[row * 4 + col], row * 4 + col)
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 单个面板 tile（53 白底圆角 16 卡 + 图标 27 + 文案 12。
  /// iOS 参照：XYChatInputBar.makePanelTile）
  Widget _buildPanelTile(({String icon, String title}) item, int tag) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onPanelItemTapped(tag),
      child: Column(
        children: [
          Container(
            width: 53,
            height: 53,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.chatPanelTileShadow,
                  offset: Offset(0, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: _panelIcon(item.icon),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  /// 面板图标（svg 资源以占位图标渲染——chat_panel_meditation/
  /// white_noise 迁移为 svg，未引入 flutter_svg，用 png 兜底缺失时占位）
  Widget _panelIcon(String asset) {
    if (asset.endsWith('.svg')) {
      // TODO(资源)：chat_panel_meditation/white_noise 为 svg 迁移产物，
      // 未引入 flutter_svg 依赖，暂用内置图标近似（视觉差异已记录）。
      return const Icon(Icons.spa_outlined,
          size: 27, color: AppColors.brandTeal);
    }
    return LoadImage(
      asset,
      width: 27,
      height: 27,
      errorWidget: const Icon(
        Icons.image_outlined,
        size: 27,
        color: AppColors.textTertiary,
      ),
    );
  }

  /// 面板 tile 点击分发（iOS 参照：panelItemTapped；点击后面板不收起，
  /// 便于连续操作）。tag 对齐 iOS：0 相册 / 1 拍摄 / 2 文件 / 3 敲木鱼 /
  /// 4 睡眠指引 / 5 深呼吸 / 6 白噪音 / 7 冥想。
  void _onPanelItemTapped(int tag) {
    switch (tag) {
      case 0:
        _pickImage(ImageSource.gallery);
      case 1:
        _pickImage(ImageSource.camera);
      case 2:
        _pickFile();
      case 3:
        _sendAssistantCard(AssistantToolPayload.woodenFish);
      case 4:
        _sendAssistantCard(AssistantToolPayload.sleepGuide);
      case 5:
        _sendAssistantCard(AssistantToolPayload.breathing);
      case 6:
        _sendAssistantCard(AssistantToolPayload.whiteNoise);
      case 7:
        _sendAssistantCard(AssistantToolPayload.meditation);
    }
  }

  /// 发送咨询师工具卡（payload 与 iOS XYChatInputBar:855-884 逐字段一致）
  void _sendAssistantCard(Map<String, Object> payload) {
    widget.onSendAssistantCard?.call(payload);
  }
}
