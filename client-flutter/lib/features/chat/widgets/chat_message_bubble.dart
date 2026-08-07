import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/im/im_models.dart';
import '../../../core/im/im_service.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../utils/image_utils.dart';
import '../../../utils/load_image.dart';
import '../chat_image_bubble_size.dart';
import '../chat_voice_player.dart';
import 'chat_image_preview.dart';

/// 聊天气泡（文字/图片/语音/文件）。
///
/// 圆角：自己 12/2/12/12、对方 2/16/16/16（Android 参照：themes.xml
/// ShapeAppearance.ChatBubble.Self/Robot；iOS TUIKit 自绘 radius=10 圆角 +
/// 独立尖角，未按方向做非对称圆角，按任务约定取 Android 语义）。
///
/// 配色以 iOS TUIKit 代码实值为准（iOS 参照：TIMCommon/UI_Minimalist/
/// TUIBubbleMessageCell_Minimalist.swift bubbleColor）：
/// 自己 #00C5D5（白字）、对方 #FFFFFF（#222 字）。
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isCounselorMessage,
    this.onResend,
    this.imageGallery = const [],
  });

  final ImMessage message;
  final bool isCounselorMessage;

  /// 发送失败时点击感叹号重发（仅图片乐观消息）
  final VoidCallback? onResend;

  /// 会话内图片消息列表（预览左右滑切换；iOS TUIMediaView）
  final List<ImMessage> imageGallery;

  /// 气泡圆角（自己右上 2；对方左上 2）
  static BorderRadius bubbleRadius(bool isSelf) {
    return isSelf
        ? const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(2),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(2),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );
  }

  @override
  Widget build(BuildContext context) {
    switch (message.kind) {
      case ImMessageKind.image:
        return _ImageBubble(
          message: message,
          onResend: onResend,
          imageGallery: imageGallery,
        );
      case ImMessageKind.sound:
        return _SoundBubble(
          message: message,
          isCounselorMessage: isCounselorMessage,
        );
      case ImMessageKind.file:
        return _FileBubble(
          message: message,
          isCounselorMessage: isCounselorMessage,
        );
      default:
        return _TextBubble(
          message: message,
          isCounselorMessage: isCounselorMessage,
        );
    }
  }
}

/// 文字气泡
class _TextBubble extends StatelessWidget {
  const _TextBubble({
    required this.message,
    required this.isCounselorMessage,
  });

  final ImMessage message;
  final bool isCounselorMessage;

  @override
  Widget build(BuildContext context) {
    final isSelf = message.isSelf;
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 140,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCounselorMessage
            ? const Color(0xFF006A67)
            : AppColors.chatBubbleOther,
        borderRadius: ChatMessageBubble.bubbleRadius(isSelf),
        border: isCounselorMessage
            ? null
            : Border.all(color: const Color(0xFFECE6DC)),
      ),
      child: Text(
        message.text ?? '',
        style: AppTextStyles.bodyLarge.copyWith(
          color: isCounselorMessage ? Colors.white : AppColors.textPrimary,
          height: 1.4,
        ),
      ),
    );
  }
}

/// 图片气泡（本地路径 / assets / 远端 URL；圆角同文字气泡）。
/// 尺寸对齐 iOS TUIImageMessageCell_Minimalist.getContentSize：
/// 最长边 kScale390(180)，按解码后真实宽高比缩放；BoxFit.cover 铺满气泡。
/// 加载失败不展示破图占位；点击 → 全屏预览；失败感叹号 → 重发。
class _ImageBubble extends ConsumerStatefulWidget {
  const _ImageBubble({
    required this.message,
    this.onResend,
    this.imageGallery = const [],
  });

  final ImMessage message;
  final VoidCallback? onResend;
  final List<ImMessage> imageGallery;

  @override
  ConsumerState<_ImageBubble> createState() => _ImageBubbleState();
}

class _ImageBubbleState extends ConsumerState<_ImageBubble> {
  String? _source;
  bool _resolving = false;
  bool _resolveFailed = false;
  bool _imageLoadFailed = false;

  double? _pixelW;
  double? _pixelH;

  ImageStream? _stream;
  ImageStreamListener? _listener;
  String? _streamSource;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _detachStream();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final source = _source;
    if (source != null && !_imageLoadFailed) {
      _ensureStream(source);
    }
  }

  @override
  void didUpdateWidget(covariant _ImageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.msgId != widget.message.msgId ||
        oldWidget.message.imagePath != widget.message.imagePath ||
        oldWidget.message.imageUrl != widget.message.imageUrl) {
      setState(_bootstrap);
    }
  }

  void _bootstrap() {
    _detachStream();
    _imageLoadFailed = false;
    final msg = widget.message;
    final previousSource = _source;
    final immediate = _immediateSource(msg);
    _source = immediate;
    _resolveFailed = false;

    // 对齐 iOS TUIImageMessageCell_Minimalist.resolvedLocalImageSize：
    // 本地可读文件优先用解码尺寸。发送成功后 SDK 常带回 thumb 宽高，
    // 且拍摄图 EXIF 方向未校正，会把发送中已正确的气泡比例改坏。
    if (_isLocalDisplaySource(immediate)) {
      if (!_isLocalDisplaySource(previousSource)) {
        _pixelW = null;
        _pixelH = null;
      }
    } else {
      _pixelW = msg.imageWidth?.toDouble();
      _pixelH = msg.imageHeight?.toDouble();
    }

    if (immediate != null) {
      _resolving = false;
      _schedulePreviewPrefetch();
      return;
    }
    if (msg.sendStatus == ImMessageSendStatus.sending ||
        msg.sendStatus == ImMessageSendStatus.failed) {
      _resolving = false;
      return;
    }
    _resolving = true;
    unawaited(_resolveAsync());
  }

  void _schedulePreviewPrefetch() {
    final msg = widget.message;
    if (msg.msgId.isEmpty || msg.msgId.startsWith('local_img_')) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(imServiceProvider).resolveImagePreviewSource(msg));
    });
  }

  static bool _isLocalDisplaySource(String? source) {
    if (source == null || source.isEmpty) return false;
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return false;
    }
    return true;
  }

  Future<void> _resolveAsync() async {
    final msgId = widget.message.msgId;
    try {
      final im = ref.read(imServiceProvider);
      final source = await im.resolveImageDisplaySource(widget.message);
      if (!mounted || widget.message.msgId != msgId) return;
      setState(() {
        _source = source;
        _resolving = false;
        _resolveFailed = source == null || source.isEmpty;
      });
      // 气泡出来后后台预取大图，点开预览时尽量已在缓存
      if (source != null &&
          source.isNotEmpty &&
          msgId.isNotEmpty &&
          !msgId.startsWith('local_img_')) {
        unawaited(im.resolveImagePreviewSource(widget.message));
      }
    } catch (_) {
      if (!mounted || widget.message.msgId != msgId) return;
      setState(() {
        _resolving = false;
        _resolveFailed = true;
      });
    }
  }

  static String? _immediateSource(ImMessage message) {
    final path = message.imagePath?.trim();
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('assets/')) return path;
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return path;
      }
      var filePath = path;
      if (filePath.startsWith('file://')) {
        try {
          filePath = Uri.parse(filePath).toFilePath();
        } catch (_) {}
      }
      if (File(filePath).existsSync()) return filePath;
    }
    final url = message.imageUrl?.trim();
    if (url != null && url.isNotEmpty) return url;
    return null;
  }

  ImageProvider? _providerOf(String source) {
    return ImageUtils.getImageProvider(source);
  }

  void _detachStream() {
    final stream = _stream;
    final listener = _listener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _stream = null;
    _listener = null;
    _streamSource = null;
  }

  void _ensureStream(String source) {
    if (_streamSource == source && _stream != null) return;
    final provider = _providerOf(source);
    if (provider == null) {
      _tryFallbackAfterError();
      return;
    }
    _detachStream();
    final stream = provider.resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener(
      (info, _) {
        final w = info.image.width.toDouble();
        final h = info.image.height.toDouble();
        if (w <= 0 || h <= 0) return;
        if (_pixelW == w && _pixelH == h) return;
        if (!mounted) return;
        setState(() {
          _pixelW = w;
          _pixelH = h;
          _imageLoadFailed = false;
        });
      },
      onError: (_, __) {
        if (mounted) _tryFallbackAfterError();
      },
    );
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
    _streamSource = source;
  }

  void _tryFallbackAfterError() {
    final msg = widget.message;
    final current = _source;
    final url = msg.imageUrl?.trim();
    if (url != null &&
        url.isNotEmpty &&
        current != null &&
        !current.startsWith('http')) {
      setState(() {
        _source = url;
        _imageLoadFailed = false;
      });
      return;
    }
    if (!_imageLoadFailed) {
      setState(() => _imageLoadFailed = true);
    }
  }

  Size _bubbleSize(BuildContext context) {
    return chatImageBubbleSize(
      screenWidth: MediaQuery.sizeOf(context).width,
      imageWidth: _pixelW,
      imageHeight: _pixelH,
    );
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isSelf = message.isSelf;
    final source = _source;
    final size = _bubbleSize(context);
    final showStatusChrome =
        message.sendStatus == ImMessageSendStatus.sending ||
            message.sendStatus == ImMessageSendStatus.failed;

    if (!showStatusChrome &&
        ((source == null && (_resolveFailed || !_resolving)) ||
            _imageLoadFailed)) {
      return const SizedBox.shrink();
    }

    final Widget content;
    if (source != null && !_imageLoadFailed) {
      final provider = _providerOf(source);
      if (provider == null) {
        final url = message.imageUrl?.trim();
        if (url != null && url.isNotEmpty && source != url) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _source == source) {
              setState(() => _source = url);
            }
          });
          content = _loadingBox(size);
        } else if (showStatusChrome) {
          content = _loadingBox(size);
        } else {
          return const SizedBox.shrink();
        }
      } else {
        content = Image(
          image: provider,
          width: size.width,
          height: size.height,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _tryFallbackAfterError();
            });
            return SizedBox(width: size.width, height: size.height);
          },
        );
      }
    } else if (_resolving || showStatusChrome) {
      content = _loadingBox(size);
    } else {
      return const SizedBox.shrink();
    }

    final previewPath =
        (source != null && !source.startsWith('http')) ? source : null;
    final previewUrl =
        (source != null && source.startsWith('http')) ? source : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (message.sendStatus == ImMessageSendStatus.sending) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 6),
        ] else if (message.sendStatus == ImMessageSendStatus.failed) ...[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onResend,
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.error,
                size: 20,
                color: AppColors.priceRed,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: source == null || _imageLoadFailed
              ? null
              : () => ChatImagePreview.open(
                    context,
                    message: message,
                    gallery: widget.imageGallery,
                    placeholderPath: previewPath,
                    placeholderUrl:
                        previewUrl ?? (previewPath == null ? source : null),
                  ),
          child: ClipRRect(
            borderRadius: ChatMessageBubble.bubbleRadius(isSelf),
            child: content,
          ),
        ),
      ],
    );
  }

  Widget _loadingBox(Size size) {
    return Container(
      width: size.width,
      height: size.height,
      color: AppColors.messageAvatarBg,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

/// 语音气泡（HeartHealing TUIVoiceMessageCell_Minimalist：
/// 声波图标 + 时长；点击播放，播放中帧动画）。
class _SoundBubble extends ConsumerStatefulWidget {
  const _SoundBubble({
    required this.message,
    required this.isCounselorMessage,
  });

  final ImMessage message;
  final bool isCounselorMessage;

  @override
  ConsumerState<_SoundBubble> createState() => _SoundBubbleState();
}

class _SoundBubbleState extends ConsumerState<_SoundBubble>
    with SingleTickerProviderStateMixin {
  /// 播放帧动画（iOS voice.animationDuration = 1s，3 帧）
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    ChatVoicePlayer.instance.addListener(_onPlayerChanged);
    _syncAnim();
  }

  @override
  void dispose() {
    ChatVoicePlayer.instance.removeListener(_onPlayerChanged);
    _anim.dispose();
    super.dispose();
  }

  void _onPlayerChanged() {
    if (!mounted) return;
    _syncAnim();
    setState(() {});
  }

  void _syncAnim() {
    final playing = ChatVoicePlayer.instance.isPlaying(widget.message.msgId);
    if (playing) {
      if (!_anim.isAnimating) _anim.repeat();
    } else {
      _anim.stop();
      _anim.value = 0;
    }
  }

  Future<void> _onTap() async {
    final err = await ChatVoicePlayer.instance.toggle(
      message: widget.message,
      im: ref.read(imServiceProvider),
    );
    if (!mounted) return;
    if (err != null) AppToast.show(context, err);
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isSelf = message.isSelf;
    final seconds = message.soundDuration ?? 1;
    // 气泡宽随时长递增（88-148；横向 padding 24 已预留）
    final width = 88.0 + (seconds.clamp(1, 30) * 2.0);
    final playing = ChatVoicePlayer.instance.isPlaying(message.msgId);
    final frames = isSelf
        ? const [
            AppAssets.messageVoiceSenderPlaying1,
            AppAssets.messageVoiceSenderPlaying2,
            AppAssets.messageVoiceSenderPlaying3,
          ]
        : const [
            AppAssets.messageVoiceReceiverPlaying1,
            AppAssets.messageVoiceReceiverPlaying2,
            AppAssets.messageVoiceReceiverPlaying3,
          ];
    final normal = isSelf
        ? AppAssets.messageVoiceSenderNormal
        : AppAssets.messageVoiceReceiverNormal;
    final counselorStyle = widget.isCounselorMessage;
    final fg = counselorStyle ? Colors.white : AppColors.textPrimary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: counselorStyle
              ? const Color(0xFF006A67)
              : AppColors.chatBubbleOther,
          borderRadius: ChatMessageBubble.bubbleRadius(isSelf),
          border: counselorStyle
              ? null
              : Border.all(color: const Color(0xFFECE6DC)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          // 自己：图标靠右（声波朝外）；对方：图标靠左
          textDirection: isSelf ? TextDirection.rtl : TextDirection.ltr,
          children: [
            AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                final asset = playing
                    ? frames[
                        (_anim.value * frames.length).floor() % frames.length]
                    : normal;
                return LoadImage(
                  asset,
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                  color: counselorStyle ? Colors.white : null,
                  colorBlendMode: counselorStyle ? BlendMode.srcIn : null,
                );
              },
            ),
            const SizedBox(width: 6),
            Text(
              '$seconds"',
              style: AppTextStyles.body.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

/// 注释：文件消息气泡
/// 时间：2026/08/06
/// 作者：郭翰林
class _FileBubble extends StatelessWidget {
  const _FileBubble({
    required this.message,
    required this.isCounselorMessage,
  });

  final ImMessage message;
  final bool isCounselorMessage;

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final isSelf = message.isSelf;
    final fileName = message.fileName ??
        (message.filePath != null ? message.filePath!.split('/').last : '文件');
    final fileSizeText = _formatFileSize(message.fileSize);
    final textColor = isCounselorMessage ? Colors.white : AppColors.textPrimary;
    final subTextColor = isCounselorMessage
        ? Colors.white.withValues(alpha: 0.8)
        : AppColors.textSecondary;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 140,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isCounselorMessage
            ? const Color(0xFF006A67)
            : AppColors.chatBubbleOther,
        borderRadius: ChatMessageBubble.bubbleRadius(isSelf),
        border: isCounselorMessage
            ? null
            : Border.all(color: const Color(0xFFECE6DC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 30.w,
            color: textColor,
          ),
          8.horizontalSpace,
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: textColor,
                    height: 1.3,
                  ),
                ),
                if (fileSizeText.isNotEmpty) ...[
                  2.verticalSpace,
                  Text(
                    fileSizeText,
                    style: AppTextStyles.caption.copyWith(
                      color: subTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
