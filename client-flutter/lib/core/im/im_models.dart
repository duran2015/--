import 'dart:convert';

/// IM 层最小模型：页面不直接依赖具体 SDK 类型（底层在 ImService 内转成本层模型）。
/// iOS 参照：XYConversationSummary.swift / XYConversation.swift。

/// 会话类型（1=C2C、2=GROUP）。
enum ImConversationType {
  /// 单聊
  c2c,

  /// 群聊（本项目暂不使用）
  group,
}

/// 消息元素类型（对齐底层 IM SDK 消息类型，取 UI 相关子集）。
enum ImMessageKind {
  text,
  image,
  sound,
  file,
  video,
  custom,
  other,
}

/// 本端发送态（乐观上屏：图片先本地插入，成功后切 sent）。
enum ImMessageSendStatus {
  /// 发送中（展示 loading）
  sending,

  /// 已发送/历史/对端消息
  sent,

  /// 发送失败
  failed,
}

/// 会话摘要（消息列表展示用）。
/// iOS 参照：XYConversationSummary（userID/title/avatarURL/
/// lastMessagePreview/timeText/unreadCount）。
class ImConversation {
  const ImConversation({
    required this.conversationId,
    required this.type,
    required this.userId,
    required this.showName,
    this.faceUrl,
    required this.lastMessagePreview,
    required this.unreadCount,
    this.timestamp,
    this.lastMessageIsSelfMiddle = false,
    this.consultantId,
    this.orderId,
    this.consultantIntro,
    this.bookedSku,
  });

  /// 会话 ID（C2C：`c2c_<userId>`）
  final String conversationId;

  /// 会话类型
  final ImConversationType type;

  /// 对方 IM 用户 ID
  final String userId;

  /// 展示标题（通常为对方昵称，缺失时回退 userId）
  final String showName;

  /// 对方头像 URL（可选，无值时用默认头像）
  final String? faceUrl;

  /// 最后一条消息预览文案（已由服务层按规则计算，见 im_preview.dart）
  final String lastMessagePreview;

  /// 未读数
  final int unreadCount;

  /// 最后一条消息时间（排序/展示用）
  final DateTime? timestamp;

  /// 最后一条是否为「本端发出的 *_middle 居中卡」。
  /// 后台常伪装成咨询师账号下发，SDK 对 isSelf 不计未读，咨询师端需本地补偿。
  final bool lastMessageIsSelfMiddle;
  final int? consultantId;
  final String? orderId;
  final String? consultantIntro;
  final String? bookedSku;

  ImConversation copyWith({int? unreadCount, bool? lastMessageIsSelfMiddle}) {
    return ImConversation(
      conversationId: conversationId,
      type: type,
      userId: userId,
      showName: showName,
      faceUrl: faceUrl,
      lastMessagePreview: lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
      timestamp: timestamp,
      lastMessageIsSelfMiddle:
          lastMessageIsSelfMiddle ?? this.lastMessageIsSelfMiddle,
      consultantId: consultantId,
      orderId: orderId,
      consultantIntro: consultantIntro,
      bookedSku: bookedSku,
    );
  }
}

/// IM 消息（阶段 5A 仅用于系统通知历史解析；阶段 5B 聊天页复用）。
class ImMessage {
  const ImMessage({
    required this.msgId,
    this.senderId,
    required this.kind,
    this.text,
    this.customJson,
    this.timestamp,
    this.isSelf = false,
    this.peerId,
    this.imagePath,
    this.imageUrl,
    this.imageUuid,
    this.imageWidth,
    this.imageHeight,
    this.soundPath,
    this.soundUuid,
    this.soundUrl,
    this.soundDuration,
    this.filePath,
    this.fileName,
    this.fileSize,
    this.fileUrl,
    this.sendStatus = ImMessageSendStatus.sent,
  });

  /// 消息 ID
  final String msgId;

  /// 发送者 IM user ID
  final String? senderId;

  /// 元素类型
  final ImMessageKind kind;

  /// 文本内容（kind == text 时有值）
  final String? text;

  /// 自定义消息 customElem.data 解码后的 JSON 字符串（kind == custom 时有值）。
  /// 注：底层 IM SDK 的自定义消息 data 已是 String（native 字节由 SDK 插件层解码）。
  final String? customJson;

  /// 消息时间
  final DateTime? timestamp;

  /// 是否本人发送，决定气泡方向与卡片方向性。
  final bool isSelf;

  /// C2C 对端 userId（收/发均为会话对端），
  /// 聊天页据此过滤 newMessageStream 归属会话。
  final String? peerId;

  /// 图片本地路径（发送方有值；mock 支持 `assets/` 前缀走 Image.asset 回显）。
  final String? imagePath;

  /// 图片远端 URL（接收方有值，V2TimImageElem originalImage.url）
  final String? imageUrl;

  /// 图片 UUID（用于识别失败重发合并 / 清理历史孤儿失败条）
  final String? imageUuid;

  /// 图片像素宽（优先缩略图；气泡尺寸用，对齐 iOS TUIImageItem.size）
  final int? imageWidth;

  /// 图片像素高
  final int? imageHeight;

  /// 语音本地路径（发送方 path / 已下载 localUrl）
  final String? soundPath;

  /// 语音文件 UUID（V2TimSoundElem.UUID，下载用）
  final String? soundUuid;

  /// 语音在线 URL（getMessageOnlineUrl 后有值；部分环境下 soundElem.url 直出）
  final String? soundUrl;

  /// 语音时长（秒，V2TimSoundElem.duration）
  final int? soundDuration;

  /// 文件本地路径
  final String? filePath;

  /// 文件名
  final String? fileName;

  /// 文件大小（字节数）
  final int? fileSize;

  /// 文件在线/下载 URL
  final String? fileUrl;

  /// 本端发送状态（默认 sent；乐观图片为 sending）
  final ImMessageSendStatus sendStatus;

  ImMessage copyWith({
    String? msgId,
    String? senderId,
    ImMessageKind? kind,
    String? text,
    String? customJson,
    DateTime? timestamp,
    bool? isSelf,
    String? peerId,
    String? imagePath,
    String? imageUrl,
    String? imageUuid,
    int? imageWidth,
    int? imageHeight,
    String? soundPath,
    String? soundUuid,
    String? soundUrl,
    int? soundDuration,
    String? filePath,
    String? fileName,
    int? fileSize,
    String? fileUrl,
    ImMessageSendStatus? sendStatus,
  }) {
    return ImMessage(
      msgId: msgId ?? this.msgId,
      senderId: senderId ?? this.senderId,
      kind: kind ?? this.kind,
      text: text ?? this.text,
      customJson: customJson ?? this.customJson,
      timestamp: timestamp ?? this.timestamp,
      isSelf: isSelf ?? this.isSelf,
      peerId: peerId ?? this.peerId,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUuid: imageUuid ?? this.imageUuid,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      soundPath: soundPath ?? this.soundPath,
      soundUuid: soundUuid ?? this.soundUuid,
      soundUrl: soundUrl ?? this.soundUrl,
      soundDuration: soundDuration ?? this.soundDuration,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileUrl: fileUrl ?? this.fileUrl,
      sendStatus: sendStatus ?? this.sendStatus,
    );
  }
}

/// 自定义消息卡（契约 im_custom_message_contract.md §3：customElem.data
/// UTF-8 JSON，顶层字段白名单 businessID/title/desc/label/type/date/
/// buttonText/logoPic/link）。
class ImCustomCard {
  const ImCustomCard({
    this.businessID,
    this.title,
    this.desc,
    this.label,
    this.type,
    this.date,
    this.buttonText,
    this.logoPic,
    this.link,
    this.audience,
    this.status,
    this.orderId,
    this.sessionId,
    this.draftId,
    this.messageType,
  });

  final String? businessID;
  final String? title;
  final String? desc;
  final String? label;

  /// 卡片子类型（语义随 businessID，见契约 §4）
  final int? type;
  final String? date;
  final String? buttonText;
  final String? logoPic;
  final String? link;

  /// 与咨询师端 workflow message 一致的受众与业务状态。
  /// 旧消息不含 audience 时保持兼容，由原有 businessID 规则决定展示。
  final String? audience;
  final String? status;
  final String? orderId;
  final String? sessionId;
  final String? draftId;
  final String? messageType;

  /// 解析 customElem.data JSON；非 JSON / 非对象 → null（调用方走兜底）。
  static ImCustomCard? tryParse(String? json) {
    if (json == null || json.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map) return null;
      String? str(String key) {
        final v = decoded[key];
        if (v == null) return null;
        final s = v.toString();
        return s.isEmpty ? null : s;
      }

      // 实测（2026-07-24 live）：后端 begin_chat_middle 卡片下发 "type":""
      // （空字符串），严格 as num 会抛异常导致整卡解析失败，故宽松解析。
      int? typeOrNull() {
        final v = decoded['type'];
        if (v is num) return v.toInt();
        return int.tryParse('$v');
      }

      return ImCustomCard(
        businessID: str('businessID'),
        title: str('title'),
        desc: str('description') ?? str('desc'),
        label: str('label'),
        type: typeOrNull(),
        date: str('date'),
        buttonText: str('actionLabel') ?? str('buttonText'),
        logoPic: str('logoPic'),
        link: str('link'),
        audience: str('audience'),
        status: str('status'),
        orderId: str('orderId'),
        sessionId: str('sessionId'),
        draftId: str('draftId'),
        messageType: str('messageType'),
      );
    } catch (_) {
      return null;
    }
  }
}

/// IM 黑名单用户摘要（黑名单管理页展示用）。
class ImBlockedUser {
  const ImBlockedUser({
    required this.userId,
    this.nickName,
    this.faceUrl,
  });

  final String userId;
  final String? nickName;
  final String? faceUrl;

  /// 展示名：昵称优先，否则回落 userId。
  String get displayName {
    final n = nickName?.trim();
    if (n != null && n.isNotEmpty) return n;
    return userId;
  }
}
