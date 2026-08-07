import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';

import '../../../core/im/im_models.dart';
import '../../../core/im/im_service.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../utils/image_utils.dart';
import '../../../utils/load_image.dart';

/// 聊天图片全屏预览（点气泡打开；黑底 + 双指缩放；左右滑切其他图；点空白/关闭返回）。
/// iOS 参照：TUIBaseMessageController_Minimalist.showImageMessage → TUIMediaView
///（横向 paging 浏览会话内图片；右下角 download 保存相册）。
class ChatImagePreview {
  ChatImagePreview._();

  /// 打开预览。
  /// [gallery]：会话内可预览的图片消息（时间序）；为空则仅预览 [message]/占位源。
  /// [placeholderPath]/[placeholderUrl]：当前气泡图源（首图可立即展示）。
  static Future<void> open(
    BuildContext context, {
    ImMessage? message,
    List<ImMessage> gallery = const [],
    String? placeholderPath,
    String? placeholderUrl,
  }) {
    final items = _normalizeGallery(
      message: message,
      gallery: gallery,
      placeholderPath: placeholderPath,
      placeholderUrl: placeholderUrl,
    );
    if (items.isEmpty) return Future.value();

    var initialIndex = 0;
    if (message != null) {
      final i = items.indexWhere((e) => e.message?.msgId == message.msgId);
      if (i >= 0) initialIndex = i;
    }

    // 进页面前就开始拉当前±1 的大图（与转场并行）
    final container = ProviderScope.containerOf(context);
    final im = container.read(imServiceProvider);
    for (var i = initialIndex - 1; i <= initialIndex + 1; i++) {
      if (i < 0 || i >= items.length) continue;
      final m = items[i].message;
      if (m == null || m.msgId.isEmpty || m.msgId.startsWith('local_img_')) {
        continue;
      }
      unawaited(im.resolveImagePreviewSource(m));
    }

    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 150),
        reverseTransitionDuration: const Duration(milliseconds: 120),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: ChatImageGalleryPage(
              items: items,
              initialIndex: initialIndex,
            ),
          );
        },
      ),
    );
  }

  static List<ChatImagePreviewItem> _normalizeGallery({
    ImMessage? message,
    required List<ImMessage> gallery,
    String? placeholderPath,
    String? placeholderUrl,
  }) {
    final images = gallery
        .where((m) => m.kind == ImMessageKind.image)
        .where(_messageHasSource)
        .toList();
    if (images.isEmpty && message != null && _messageHasSource(message)) {
      images.add(message);
    }
    if (images.isEmpty) {
      if (!_hasSource(imagePath: placeholderPath, imageUrl: placeholderUrl)) {
        return const [];
      }
      return [
        ChatImagePreviewItem(
          message: message,
          placeholderPath: placeholderPath,
          placeholderUrl: placeholderUrl,
        ),
      ];
    }

    return [
      for (final m in images)
        ChatImagePreviewItem(
          message: m,
          placeholderPath: message != null && m.msgId == message.msgId
              ? placeholderPath
              : null,
          placeholderUrl: message != null && m.msgId == message.msgId
              ? placeholderUrl
              : null,
        ),
    ];
  }

  static bool _messageHasSource(ImMessage m) {
    return _hasSource(imagePath: m.imagePath, imageUrl: m.imageUrl);
  }

  static bool _hasSource({String? imagePath, String? imageUrl}) {
    final path = imagePath?.trim();
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('assets/')) return true;
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return true;
      }
      if (File(path).existsSync()) return true;
    }
    final url = imageUrl?.trim();
    return url != null && url.isNotEmpty;
  }
}

/// 预览画廊中的一张图。
class ChatImagePreviewItem {
  const ChatImagePreviewItem({
    this.message,
    this.placeholderPath,
    this.placeholderUrl,
  });

  final ImMessage? message;
  final String? placeholderPath;
  final String? placeholderUrl;
}

/// 聊天图片画廊页（可左右翻页；右下角下载进相册）。
/// iOS 参照：TUIImageCollectionCell_Minimalist downloadBtn + onDownloadBtnClick。
class ChatImageGalleryPage extends ConsumerStatefulWidget {
  const ChatImageGalleryPage({
    super.key,
    required this.items,
    required this.initialIndex,
  });

  final List<ChatImagePreviewItem> items;
  final int initialIndex;

  @override
  ConsumerState<ChatImageGalleryPage> createState() =>
      _ChatImageGalleryPageState();
}

class _ChatImageGalleryPageState extends ConsumerState<ChatImageGalleryPage> {
  late final PageController _pageController;
  late int _index;
  bool _pageLocked = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.items.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onZoomChanged(bool zoomed) {
    if (_pageLocked == zoomed) return;
    setState(() => _pageLocked = zoomed);
  }

  Future<void> _saveCurrent() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final granted = await Gal.requestAccess();
      if (!mounted) return;
      if (!granted) {
        AppToast.show(context, '请在系统设置中允许访问相册');
        return;
      }

      final item = widget.items[_index];
      final bytes = await _resolveBytes(item);
      if (!mounted) return;
      if (bytes == null || bytes.isEmpty) {
        AppToast.show(context, '图片保存失败');
        return;
      }

      // 去掉原图 EXIF 拍摄时间再入库，否则会插在「当初发送那张」附近。
      // iOS 原生：creationRequestForAsset(from: UIImage) 创建时间 = 现在。
      final albumBytes = await _bytesForAlbumSave(bytes);
      await Gal.putImageBytes(
        albumBytes,
        name: 'chat_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      // iOS：TUIKitPictureSavedSuccess
      AppToast.show(context, '图片保存成功');
    } on GalException catch (_) {
      if (mounted) AppToast.show(context, '图片保存失败');
    } catch (_) {
      if (mounted) AppToast.show(context, '图片保存失败');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 解码再编码为 PNG，剥离拍摄时间等元数据，让相册按「保存时刻」排序。
  static Future<Uint8List> _bytesForAlbumSave(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) return bytes;
        return data.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } catch (_) {
      return bytes;
    }
  }

  Future<Uint8List?> _resolveBytes(ChatImagePreviewItem item) async {
    String? source;
    final msg = item.message;
    if (msg != null &&
        msg.msgId.isNotEmpty &&
        !msg.msgId.startsWith('local_img_')) {
      try {
        source = await ref
            .read(imServiceProvider)
            .resolveImagePreviewSource(msg);
      } catch (_) {}
    }
    source ??= _pickImmediate(
      path: item.placeholderPath,
      url: item.placeholderUrl,
      message: item.message,
    );
    if (source == null || source.isEmpty) return null;
    return _bytesOf(source);
  }

  static Future<Uint8List?> _bytesOf(String source) async {
    if (source.startsWith('assets/')) {
      final data = await rootBundle.load(source);
      return data.buffer.asUint8List();
    }
    if (source.startsWith('http://') || source.startsWith('https://')) {
      final resp = await Dio().get<List<int>>(
        source,
        options: Options(responseType: ResponseType.bytes),
      );
      final data = resp.data;
      if (data == null || data.isEmpty) return null;
      return Uint8List.fromList(data);
    }
    final file = File(source);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  static String? _pickImmediate({
    String? path,
    String? url,
    ImMessage? message,
  }) {
    final p = path?.trim() ?? message?.imagePath?.trim();
    if (p != null && p.isNotEmpty) {
      if (p.startsWith('assets/')) return p;
      if (p.startsWith('http://') || p.startsWith('https://')) return p;
      if (File(p).existsSync()) return p;
    }
    final u = url?.trim() ?? message?.imageUrl?.trim();
    if (u != null && u.isNotEmpty) return u;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: const ColoredBox(color: Colors.black),
          ),
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            physics: _pageLocked
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            onPageChanged: (i) => setState(() {
              _index = i;
              _pageLocked = false;
            }),
            itemBuilder: (context, i) {
              return _ChatImageZoomPage(
                key: ValueKey(widget.items[i].message?.msgId ?? 'img_$i'),
                item: widget.items[i],
                isActive: i == _index,
                onZoomChanged: _onZoomChanged,
                onDismiss: () => Navigator.of(context).maybePop(),
              );
            },
          ),
          if (widget.items.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              child: IgnorePointer(
                child: Text(
                  '${_index + 1} / ${widget.items.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          // iOS：downloadBtn 31×31，right 16，bottom 48
          Positioned(
            right: 16,
            bottom: 48,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _saving ? null : () => unawaited(_saveCurrent()),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _saving
                    ? const SizedBox(
                        width: 31,
                        height: 31,
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        ),
                      )
                    : const LoadImage(
                        AppAssets.chatImageDownload,
                        width: 31,
                        height: 31,
                        errorWidget: Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 28,
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

/// 单页：缩略图垫底 + 高清叠上；双指缩放；放大时锁定外层 PageView。
class _ChatImageZoomPage extends ConsumerStatefulWidget {
  const _ChatImageZoomPage({
    super.key,
    required this.item,
    required this.isActive,
    required this.onZoomChanged,
    required this.onDismiss,
  });

  final ChatImagePreviewItem item;
  final bool isActive;
  final ValueChanged<bool> onZoomChanged;
  final VoidCallback onDismiss;

  @override
  ConsumerState<_ChatImageZoomPage> createState() => _ChatImageZoomPageState();
}

class _ChatImageZoomPageState extends ConsumerState<_ChatImageZoomPage> {
  late final TransformationController _transform;
  late final String? _placeholder;
  String? _highRes;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform = TransformationController();
    _transform.addListener(_onTransform);
    _placeholder = _pickImmediate(
      path: widget.item.placeholderPath,
      url: widget.item.placeholderUrl,
      message: widget.item.message,
    );
    final msg = widget.item.message;
    final placeholder = _placeholder;
    // 本地原图已够清晰时直接作为高清层，避免再干等网络
    if (placeholder != null &&
        msg != null &&
        msg.isSelf &&
        !placeholder.startsWith('http') &&
        File(placeholder).existsSync()) {
      try {
        if (File(placeholder).lengthSync() >= 150 * 1024) {
          _highRes = placeholder;
        }
      } catch (_) {}
    }
    if (msg != null &&
        msg.msgId.isNotEmpty &&
        !msg.msgId.startsWith('local_img_')) {
      // 立刻拉大图；有地址就上屏，由 Image 解码（不再等整图 precache）
      unawaited(_loadHighRes(msg));
    }
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ChatImageZoomPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 滑走后复位缩放，避免再滑回来仍锁住翻页
    if (oldWidget.isActive && !widget.isActive) {
      _transform.value = Matrix4.identity();
      if (_zoomed) {
        setState(() => _zoomed = false);
      }
      widget.onZoomChanged(false);
    }
  }

  void _onTransform() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (_zoomed != zoomed) {
      setState(() => _zoomed = zoomed);
    }
    widget.onZoomChanged(zoomed);
  }

  Future<void> _loadHighRes(ImMessage message) async {
    try {
      final hi = await ref
          .read(imServiceProvider)
          .resolveImagePreviewSource(message);
      if (!mounted) return;
      if (hi == null || hi.isEmpty) return;
      if (hi == _highRes) return;
      // 已有本地大图时，勿被同质/更糊的源替换
      if (_highRes != null &&
          !_highRes!.startsWith('http') &&
          hi.startsWith('http') &&
          File(_highRes!).existsSync()) {
        try {
          if (File(_highRes!).lengthSync() >= 150 * 1024) return;
        } catch (_) {}
      }
      // 不等 precache：一有地址就叠上，缩略图垫底直到首帧出来（对齐 iOS 观察 largeImage）
      setState(() => _highRes = hi);
    } catch (_) {
      // 保持缩略图即可
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    // 按屏宽 * dpr * 最大缩放预解码，避免原图像素全量解码过慢
    final cacheWidth = (size.width * dpr * 2).round().clamp(720, 4096);
    final placeholder = _placeholder;
    final highRes = _highRes;
    return InteractiveViewer(
      transformationController: _transform,
      // 未放大时不抢横向拖动手势，交给外层 PageView 左右切图
      panEnabled: _zoomed,
      minScale: 1,
      maxScale: 4,
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              if (placeholder != null)
                _buildImage(placeholder, cacheWidth: cacheWidth),
              if (highRes != null && highRes != placeholder)
                _buildImage(highRes, cacheWidth: cacheWidth),
              if (placeholder == null && highRes == null)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String source, {required int cacheWidth}) {
    final provider = ResizeImage(ImageUtils.getImageProvider(source), width: cacheWidth);
    return Image(
      image: provider,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      // 高清层首帧未到时透明，继续露出下方缩略图
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return const SizedBox.shrink();
      },
      errorBuilder: (_, __, ___) => _error(),
    );
  }

  static String? _pickImmediate({
    String? path,
    String? url,
    ImMessage? message,
  }) {
    final p = path?.trim() ?? message?.imagePath?.trim();
    if (p != null && p.isNotEmpty) {
      if (p.startsWith('assets/')) return p;
      if (p.startsWith('http://') || p.startsWith('https://')) return p;
      if (File(p).existsSync()) return p;
    }
    final u = url?.trim() ?? message?.imageUrl?.trim();
    if (u != null && u.isNotEmpty) return u;
    return null;
  }

  Widget _error() {
    return const Center(
      child: Icon(
        Icons.broken_image_outlined,
        size: 64,
        color: AppColors.textTertiary,
      ),
    );
  }
}
