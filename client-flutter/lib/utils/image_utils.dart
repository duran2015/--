import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as paths;
import 'package:xinyu_flutter/utils/ly_utils.dart';

import 'load_image.dart';
import 'text_utils.dart';

/// 注释：图片工具类
/// 时间：2024/4/29 0029 16:20
/// 作者：郭翰林
class ImageUtils {
  static ImageProvider getAssetImage(
    String name, {
    ImageFormat format = ImageFormat.png,
  }) {
    return AssetImage(getImgPath(name, format: format));
  }

  static String getImgPath(
    String name, {
    ImageFormat format = ImageFormat.png,
  }) {
    if (name.startsWith('assets/')) {
      return name;
    }
    if (name.contains('.')) {
      return 'assets/images/$name';
    }
    return 'assets/images/$name.${format.value}';
  }

  static ImageProvider getImageProvider(
    String imageUrl, {
    String holderImg = 'ic_launcher',
  }) {
    final resolvedUrl = resolveImageDisplayUrl(imageUrl);
    if (TextUtils.isEmpty(resolvedUrl) || resolvedUrl == 'null') {
      return getAssetImage(holderImg);
    }
    if (resolvedUrl!.startsWith('http')) {
      return CachedNetworkImageProvider(resolvedUrl);
    } else if (resolvedUrl.startsWith('assets/')) {
      return AssetImage(resolvedUrl);
    } else if (!kIsWeb && File(resolvedUrl).existsSync()) {
      return FileImage(File(resolvedUrl));
    }
    return getAssetImage(resolvedUrl);
  }

  /// 注释：获取文件后缀
  /// 作者：郭翰林
  static String getFileSuffix(File file) {
    return paths.extension(file.path);
  }

  /// 注释：HEIC、Tiff格式图片转换PNG
  /// 时间：2024/4/29 0029 16:23
  /// 作者：郭翰林
  static Future<String> convertSuffixToPng(
    String filePath,
    String suffix,
  ) async {
    final fileFile = File(filePath);
    final result = await FlutterImageCompress.compressAndGetFile(
      fileFile.path,
      fileFile.path.replaceAll('.$suffix', '.png'),
      format: CompressFormat.png,
    );
    return result?.path ?? filePath;
  }

  /// 注释：压缩图片
  /// 时间：2024/10/18 0018 14:02
  /// 作者：郭翰林
  static Future<File> compressImage(File file, {double maxSizeMB = 1.0}) async {
    int maxSizeBytes = (maxSizeMB * 1024 * 1024).toInt();
    
    if (file.lengthSync() <= maxSizeBytes) {
      return file;
    }

    String fileName = paths.basenameWithoutExtension(file.path);
    String extension = paths.extension(file.path);
    
    int quality = 90;
    File? lastResult;
    
    while (quality >= 10) {
      final cachePath = await LyUtils.createTempFile(
        dir: 'flutter',
        name: "${fileName}_$quality$extension",
      );
      
      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        cachePath,
        quality: quality,
      );
      
      if (result != null && TextUtils.isNotEmpty(result.path)) {
        final currentResult = File(result.path);
        
        if (lastResult != null && lastResult.existsSync()) {
          lastResult.deleteSync();
        }
        
        lastResult = currentResult;
        
        if (currentResult.lengthSync() <= maxSizeBytes) {
          return currentResult;
        }
      } else {
        break;
      }
      
      quality -= 10;
    }
    
    if (lastResult != null) {
      return lastResult;
    }
    
    return file;
  }
}

enum ImageFormat { png, jpg, gif, webp }

extension ImageFormatExtension on ImageFormat {
  String get value => ['png', 'jpg', 'gif', 'webp'][index];
}
