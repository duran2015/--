import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

/// 注释：基于 Hive 的统一本地缓存管理工具类
/// 时间：2026/8/4
/// 作者：郭翰林
class LyCache {
  static const String _defaultBoxName = 'LyCacheBox';
  static Box? _box;
  static Future<void>? _initFuture;

  /// 注释：初始化 Hive 存储（全局只需调用一次，防重入与并发锁）
  /// 时间：2026/8/4
  /// 作者：郭翰林
  static Future<void> init({String boxName = _defaultBoxName}) {
    if (_box != null && _box!.isOpen) return Future.value();
    _initFuture ??= _doInit(boxName);
    return _initFuture!;
  }

  static Future<void> _doInit(String boxName) async {
    try {
      if (kIsWeb) {
        _box = await Hive.openBox(boxName);
        return;
      }
      String path;
      try {
        final dir = await getApplicationDocumentsDirectory();
        path = dir.path;
      } catch (_) {
        final temp = Directory.systemTemp.createTempSync('hive_ly_cache_');
        path = temp.path;
      }
      Hive.init(path);
      _box = await Hive.openBox(boxName);
    } catch (e) {
      debugPrint('LyCache init error: $e');
    }
  }

  /// 内部保证 Box 已准备就绪（如果没初始化自动懒加载）
  static Future<Box?> _ensureBox() async {
    if (_box != null && _box!.isOpen) return _box;
    await init();
    return _box;
  }

  /// 注释：存储键值对
  /// 时间：2026/8/4
  /// 作者：郭翰林
  static Future<bool> put({required String? key, required dynamic value}) async {
    if (key == null || value == null) return false;
    try {
      final box = await _ensureBox();
      if (box == null) return false;
      await box.put(key, value);
      return true;
    } catch (e) {
      debugPrint('LyCache put error: $e');
      return false;
    }
  }

  /// 注释：获取存储值（异步，支持自动懒加载 Box）
  /// 时间：2026/8/4
  /// 作者：郭翰林
  static Future<T?> get<T>({required String? key, T? defaultValue}) async {
    if (key == null) return defaultValue;
    final box = await _ensureBox();
    if (box == null) return defaultValue;
    return _parseValue<T>(box, key, defaultValue);
  }

  /// 注释：获取存储值（同步，如果 Box 未准备好返回 defaultValue）
  /// 时间：2026/8/4
  /// 作者：郭翰林
  static T? getSync<T>({required String? key, T? defaultValue}) {
    if (key == null || _box == null || !_box!.isOpen) return defaultValue;
    return _parseValue<T>(_box!, key, defaultValue);
  }

  static T? _parseValue<T>(Box box, String key, T? defaultValue) {
    try {
      if (!box.containsKey(key)) return defaultValue;
      dynamic result = box.get(key, defaultValue: defaultValue);
      if (result == null) return defaultValue;
      if (T == Object || T == dynamic) return result as T;
      if (T == String) return "$result" as T;
      if (T == double) return (double.tryParse("$result") ?? defaultValue) as T?;
      if (T == int) return (int.tryParse("$result") ?? defaultValue) as T?;
      if (T == num) return (num.tryParse("$result") ?? defaultValue) as T?;
      if (T == bool) {
        if (result is bool) return result as T;
        if (result is String) {
          return (result.toLowerCase() == "true" || int.tryParse(result) == 1) as T;
        }
        if (result is int) return (result == 1) as T;
        return result as T?;
      }
      if (T == List) {
        if (result is List) return result as T;
        if (result is String) {
          dynamic jsonResult = json.decode(result);
          if (jsonResult is List) return jsonResult as T;
        }
        return result as T?;
      }
      if (T == Map) {
        if (result is Map) return Map<String, dynamic>.from(result) as T;
        if (result is String) {
          dynamic jsonResult = json.decode(result);
          if (jsonResult is Map) return Map<String, dynamic>.from(jsonResult) as T;
        }
        return result as T?;
      }
      return result as T?;
    } catch (e) {
      debugPrint('LyCache parse error: $e');
      return defaultValue;
    }
  }

  /// 注释：删除某个值
  /// 时间：2026/8/4
  /// 作者：郭翰林
  static Future<bool> remove({required String? key}) async {
    if (key == null) return false;
    try {
      final box = await _ensureBox();
      if (box == null) return false;
      if (box.containsKey(key)) {
        await box.delete(key);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('LyCache remove error: $e');
      return false;
    }
  }

  /// 注释：判断是否存在 Key
  /// 时间：2026/8/4
  /// 作者：郭翰林
  static bool containsKey({required String? key}) {
    if (key == null || _box == null || !_box!.isOpen) return false;
    return _box!.containsKey(key);
  }

  /// 注释：清空所有数据
  /// 时间：2026/8/4
  /// 作者：郭翰林
  static Future<bool> removeAll() async {
    try {
      final box = await _ensureBox();
      if (box == null) return false;
      await box.clear();
      return true;
    } catch (e) {
      debugPrint('LyCache removeAll error: $e');
      return false;
    }
  }
}
