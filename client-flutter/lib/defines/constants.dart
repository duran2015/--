

/// 注释：缓存Key常量
/// 时间：2026/5/1 10:45
/// 作者：郭翰林
class LyCacheKey {
  static String agreedPrivacy = "agreed_privacy";
}

/// 注释：应用配置常量
/// 时间：2026/5/1 10:45
/// 作者：郭翰林
class LyConfig {
  /// 用户协议 H5 链接
  static const String userAgreement =
      'https://admin.currantmind.cn/agreement/kelu-user-agreement.html';

  /// 隐私政策 H5 链接
  static const String privacyPolicy =
      'https://admin.currantmind.cn/agreement/kelu-privacy-policy.html';
}

/// 注释：文件类型后缀
/// 时间：2026/5/1 10:45
/// 作者：郭翰林
class FileTypeSuffix {
  static List<String> docSuffix = ["pdf", "doc", "docx", "txt", "ppt", "pptx"];
  static List<String> imgSuffix = ["jpg", "png", "jpeg", "gif", "bmp", "webp"];
  static List<String> videoSuffix = ["mp4", "avi", "mov", "wmv", "mkv"];
}
