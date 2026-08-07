/// 注释：文本工具类
/// 时间：2026/5/1 10:45
/// 作者：郭翰林
class TextUtils {
  /// 注释：判断字符串是否为空
  /// 时间：2026/5/1 10:45
  /// 作者：郭翰林
  static bool isEmpty(String? str) {
    return str == null || str.trim().isEmpty;
  }

  /// 注释：判断字符串是否不为空
  /// 时间：2026/5/1 10:45
  /// 作者：郭翰林
  static bool isNotEmpty(String? str) {
    return str != null && str.trim().isNotEmpty;
  }

  /// 注释：截取字符串
  /// 时间：2026/5/1 10:45
  /// 作者：郭翰林
  static String substring(String str, int maxLength) {
    if (str.length <= maxLength) return str;
    return '${str.substring(0, maxLength)}...';
  }

  /// 注释：移除HTML标签
  /// 时间：2026/5/1 10:45
  /// 作者：郭翰林
  static String removeHtmlTags(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '');
  }
}
