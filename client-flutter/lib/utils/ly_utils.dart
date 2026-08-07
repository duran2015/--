import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xinyu_flutter/utils/app_global.dart';
import 'package:xinyu_flutter/utils/load_image.dart';

/// 注释：通用工具类
/// 时间：2026/5/1 10:45
/// 作者：郭翰林
class LyUtils {
  /// 全局Toast
  static FToast? toast;

  /// 注释：获取App版本号
  /// 时间：2026/5/1 10:45
  /// 作者：郭翰林
  static Future<String> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// 注释：判断字符串是否为空
  /// 时间：2026/5/1 10:45
  /// 作者：郭翰林
  static bool isEmpty(String? str) {
    return str == null || str.isEmpty;
  }

  /// 注释：判断字符串是否不为空
  /// 时间：2026/5/1 10:45
  /// 作者：郭翰林
  static bool isNotEmpty(String? str) {
    return str != null && str.isNotEmpty;
  }

  /// 注释：获取Android系统版本号
  /// 时间：2025/12/14 14:47
  /// 作者：郭翰林
  static Future<int> getAndroidVersion() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return int.parse(androidInfo.version.release); // 例如: "12", "11", "10"
  }

  /// 注释：获取版本构建号
  /// 时间：2025/12/4 13:03
  /// 作者：郭翰林
  static Future<String> getAppBuildNumber() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber; // 返回构建号
  }

  /// 注释：比较版本号,true 需要更新
  /// 时间：2025/12/4 13:06
  /// 作者：郭翰林
  static bool compareVersions(String? version1, String? version2) {
    String cleanV1 = version1?.split('+').first ?? '0.0.0';
    String cleanV2 = version2?.split('+').first ?? '0.0.0';
    List<String> v1Parts = cleanV1.split('.');
    List<String> v2Parts = cleanV2.split('.');
    for (int i = 0; i < 3; i++) {
      int v1Num = v1Parts.length > i ? int.tryParse(v1Parts[i]) ?? 0 : 0;
      int v2Num = v2Parts.length > i ? int.tryParse(v2Parts[i]) ?? 0 : 0;
      if (v1Num > v2Num) return true;
      if (v1Num < v2Num) return false;
    }
    return false; // 相等
  }

  /// 注释：判断是否需要更新
  /// 时间：2026/6/26
  /// 作者：郭翰林
  static bool isNeedUpdate(String currentVersion, String latestVersion) {
    return compareVersions(latestVersion, currentVersion);
  }

  /// 注释：格式化数字（如：1000 -> 1k）
  /// 时间：2026/5/1 10:45
  /// 作者：郭翰林
  static String formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  /// 注释：格式化字节大小
  /// 作者：AI
  static String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "G", "T", "P", "E", "Z", "Y"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) +
        ' ' +
        suffixes[i];
  }

  /// 注释：创建临时文件
  /// 时间：2024/3/8 0008 14:38
  /// 作者：郭翰林
  static Future<String> createTempFile({
    required String dir,
    required String name,
  }) async {
    final storage = Platform.isAndroid
        ? await getTemporaryDirectory()
        : await getApplicationDocumentsDirectory();
    Directory directory = Directory('${storage.path}/$dir');
    if (!(await directory.exists())) {
      directory.create(recursive: true);
    }
    File file = File('${directory.path}/$name');
    if (!(await file.exists())) {
      file.create();
    }
    return file.path;
  }

  /// 注释：获取临时文件路径
  /// 时间：2024/3/8 0008 14:38
  /// 作者：郭翰林
  static Future<String> getTempFilePath({
    required String dir,
    required String name,
  }) async {
    final storage = Platform.isAndroid
        ? await getTemporaryDirectory()
        : await getApplicationDocumentsDirectory();
    Directory directory = Directory('${storage.path}/$dir');
    if (!(await directory.exists())) {
      directory.create(recursive: true);
    }
    return "${directory.path}/$name";
  }

  /// 注释：隐藏软键盘
  /// 时间：2026/2/6 17:51
  /// 作者：郭翰林
  static void hideKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  /// 注释：全局 Toast
  /// 时间：2026/1/30 17:03
  /// 作者：郭翰林
  static void showToast(String msg, {String? icon}) {
    if (toast == null) {
      BuildContext context = appNavigatorKey.currentState!.overlay!.context;
      toast = FToast();
      toast!.init(context);
    }
    toast!.showToast(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Color(0xB3000000),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                LoadAssetImage(icon ?? 'ic_info', width: 16.w, height: 16.w),
                8.horizontalSpace,
                Container(
                  constraints: BoxConstraints(maxWidth: 250.w),
                  child: Text(
                    msg,
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      gravity: ToastGravity.TOP,
      toastDuration: Duration(seconds: 2),
    );
  }

  /// 注释：拷贝文本
  /// 时间：2024/1/26 0026 13:54
  /// 作者：郭翰林
  static void copyText(String? text) {
    Clipboard.setData(ClipboardData(text: text ?? ""));
  }
}
