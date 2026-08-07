import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'image_utils.dart';
import 'text_utils.dart';

/// 注释：将图片字段解析为可展示 URL（支持 key/完整链接/相对路径）
/// 时间：2026/5/5 17:30
/// 作者：郭翰林
String? resolveImageDisplayUrl(String? rawValue) {
  if (rawValue == null) return null;

  final value = rawValue.trim();
  if (value.isEmpty) return null;

  // 完整URL直接返回
  if (value.startsWith('http://') ||
      value.startsWith('https://') ||
      value.startsWith('blob:') ||
      value.startsWith('data:')) {
    return value;
  }

  // 本地文件路径直接返回，用于选图后的即时回显
  if (!kIsWeb && (value.startsWith('file://') || File(value).isAbsolute)) {
    return value.replaceFirst('file://', '');
  }

  // 本地资源图片（不包含点号，说明是资源名而非文件路径）
  if (!value.contains('.')) {
    return value;
  }

  return value;
}

/// 图片加载（支持本地与网络图片）
class LoadImage extends StatelessWidget {
  const LoadImage(this.image,
      {Key? key,
      this.width,
      this.height,
      this.fit = BoxFit.cover,
      this.format = ImageFormat.png,
      this.needHolderImg = true,
      this.holderFormat,
      this.holderImg = 'ic_launcher',
      this.memCacheWidth,
      this.memCacheHeight,
      this.maxWidthDiskCache,
      this.compress = true,
      this.maxHeightDiskCache,
      this.color,
      this.colorBlendMode,
      this.alignment = Alignment.center,
      this.repeat = ImageRepeat.noRepeat,
      this.errorWidget})
      : super(key: key);

  final String? image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageFormat format;
  final ImageFormat? holderFormat;
  final String holderImg;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int? maxWidthDiskCache;
  final int? maxHeightDiskCache;
  final bool compress; //是否压缩内存
  final bool needHolderImg; //是否需要中间态图片
  final Widget? errorWidget;
  final Color? color;
  final BlendMode? colorBlendMode;
  final Alignment alignment;
  final ImageRepeat repeat;

  @override
  Widget build(BuildContext context) {
    // 解析图片URL，处理相对路径的情况
    final resolvedUrl = resolveImageDisplayUrl(image);

    if (TextUtils.isEmpty(resolvedUrl) || resolvedUrl == 'null') {
      ///加载默认图片
      return LoadAssetImage(holderImg,
          height: height,
          width: width,
          fit: fit,
          color: color,
          colorBlendMode: colorBlendMode,
          alignment: alignment,
          repeat: repeat,
          format: holderFormat ?? format);
    } else {
      if (resolvedUrl!.startsWith('http')) {
        ///加载网络图片
        int? maxWidth;
        int? maxHeight;
        if (compress) {
          if (width != null && width != double.infinity) {
            maxWidth = (width! * 2).toInt();
          }
          if (height != null && height != double.infinity) {
            maxHeight = (height! * 2).toInt();
          }
        }
        return CachedNetworkImage(
          memCacheWidth: memCacheWidth ?? maxWidth,
          memCacheHeight: memCacheHeight ?? maxHeight,
          maxWidthDiskCache: maxWidthDiskCache ?? maxWidth,
          maxHeightDiskCache: maxHeightDiskCache ?? maxHeight,
          imageUrl: resolvedUrl!,
          cacheManager: DefaultCacheManager(),
          color: color,
          colorBlendMode: colorBlendMode,
          alignment: alignment,
          repeat: repeat,
          placeholder: (_, __) {
            if (needHolderImg) {
              return LoadAssetImage(holderImg,
                  height: height,
                  width: width,
                  fit: fit,
                  color: color,
                  colorBlendMode: colorBlendMode,
                  alignment: alignment,
                  repeat: repeat,
                  format: holderFormat ?? format);
            }
            return const SizedBox.shrink();
          },
          errorWidget: (_, __, dynamic error) =>
              errorWidget ??
              LoadAssetImage(holderImg,
                  height: height,
                  width: width,
                  fit: fit,
                  color: color,
                  colorBlendMode: colorBlendMode,
                  alignment: alignment,
                  repeat: repeat,
                  format: holderFormat ?? format),
          width: width,
          height: height,
          fit: fit,
        );
      } else if (resolvedUrl.startsWith('assets/')) {
        ///加载Assets里的图片
        return LoadAssetImage(resolvedUrl,
            height: height,
            width: width,
            fit: fit,
            color: color,
            colorBlendMode: colorBlendMode,
            alignment: alignment,
            repeat: repeat,
            holderImg: holderImg,
            format: holderFormat ?? format);
      } else if (resolvedUrl.contains("/")) {
        ///根据路径回显
        File file = File(resolvedUrl);
        if (file.existsSync()) {
          return Image.file(file,
              width: width,
              height: height,
              fit: fit,
              color: color,
              colorBlendMode: colorBlendMode,
              alignment: alignment,
              repeat: repeat,
              errorBuilder: (_, __, ___) =>
                  errorWidget ??
                  LoadAssetImage(holderImg,
                      height: height,
                      width: width,
                      fit: fit,
                      color: color,
                      colorBlendMode: colorBlendMode,
                      alignment: alignment,
                      repeat: repeat,
                      format: holderFormat ?? format));
        } else {
          return LoadAssetImage(holderImg,
              height: height,
              width: width,
              fit: fit,
              color: color,
              colorBlendMode: colorBlendMode,
              alignment: alignment,
              repeat: repeat,
              format: holderFormat ?? format);
        }
      } else {
        ///加载Assets里的图片
        return LoadAssetImage(resolvedUrl,
            height: height,
            width: width,
            fit: fit,
            color: color,
            colorBlendMode: colorBlendMode,
            alignment: alignment,
            repeat: repeat,
            holderImg: holderImg,
            format: holderFormat ?? format);
      }
    }
  }
}

/// 加载本地资源图片
class LoadAssetImage extends StatelessWidget {
  const LoadAssetImage(this.image,
      {Key? key,
      this.width,
      this.height,
      this.cacheWidth,
      this.cacheHeight,
      this.fit = BoxFit.contain,
      this.format = ImageFormat.png,
      this.color,
      this.colorBlendMode,
      this.alignment = Alignment.center,
      this.repeat = ImageRepeat.noRepeat,
      this.holderFormat,
      this.holderImg = "img_empty",
      this.needHolderImg = true})
      : super(key: key);

  final String image;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final int? cacheHeight;
  final BoxFit fit;
  final ImageFormat format;
  final Color? color;
  final BlendMode? colorBlendMode;
  final Alignment alignment;
  final ImageRepeat repeat;
  final ImageFormat? holderFormat;
  final String holderImg;
  final bool needHolderImg; //是否需要中间态图片

  @override
  Widget build(BuildContext context) {
    return Image.asset(ImageUtils.getImgPath(image, format: format),
        height: height,
        width: width,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        fit: fit,
        color: color,
        colorBlendMode: colorBlendMode,
        alignment: alignment,
        repeat: repeat,
        excludeFromSemantics: true, errorBuilder: (_, __, ___) {
      if (image == holderImg) {
        return SizedBox(width: width, height: height);
      }
      return LoadAssetImage(
        holderImg,
        width: width,
        height: height,
        cacheHeight: cacheHeight,
        cacheWidth: cacheWidth,
        fit: fit,
        color: color,
        colorBlendMode: colorBlendMode,
        alignment: alignment,
        repeat: repeat,
      );
    });
  }
}
