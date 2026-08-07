import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import 'im_models.dart';
import 'mock_im_service.dart';
import 'netease_im_service.dart';

/// IM 服务异常。
class ImException implements Exception {
  const ImException({
    required this.code,
    required this.desc,
    this.failedMessage,
  });

  final int code;
  final String desc;

  /// 发送失败时 SDK 已落库的消息（含真实 msgId，供同条重发合并）。
  final ImMessage? failedMessage;

  @override
  String toString() => 'ImException($code, $desc)';
}

/// IM 抽象层：登录/登出/会话/未读/历史消息。
/// iOS 参照：XYIMManager.swift（登录闭环）+ XYChatService 会话摘要能力。
///
/// 实现：
/// - [NeteaseImService]：网易云信 nim_core_v2 V2 SDK；
/// - [MockImService]：内存假数据，供无后端/无厂商环境演示（dev mock）。
abstract class ImService {
  /// 初始化 SDK（登录前调用一次即可，重复调用应幂等）。
  Future<void> initSDK(int sdkAppId);

  /// 登录 IM。成功应触发 [onLoginSuccess] 并刷新会话流。
  /// iOS 参照：XYIMManager.login(sdkAppID:userID:imUserSig:)。
  Future<void> login({required String imUserId, required String imUserSig});

  /// 登出 IM。注意 iOS 已知竞态：logout succ 先于 unInitSDK 触发，
  /// 下一次 login 必须延迟一轮（实现内处理，见 NeteaseImService.logout）。
  Future<void> logout();

  /// 是否已登录
  bool get isLoggedIn;

  /// 当前登录的 IM 用户 ID（未登录为 null）
  String? get currentUserId;

  /// 会话列表推送流（onNewConversation / onConversationChanged / 已读变化后推新值）
  Stream<List<ImConversation>> get conversationStream;

  /// 拉取一次会话列表
  Future<List<ImConversation>> fetchConversations();

  /// SDK 总未读数流（含机器人与系统通知）。
  /// ⚠ 消息 Tab 角标不使用本流：Tab 角标 = 普通对话 unreadCount 之和
  /// （不含机器人与系统通知），由消息页 ViewModel 派生
  /// （iOS 参照：XYMessageViewModel.conversationUnreadTotal →
  /// XYUnreadMessageTotalChanged 通知）。
  Stream<int> get unreadTotalStream;

  /// 标记会话已读（conversationId 形如 `c2c_<userId>`）。
  /// Android 参照：SystemNotificationActivity cleanConversationUnreadMessageCount。
  Future<void> markConversationRead(String conversationId);

  /// 拉取 C2C 历史消息（旧→新，与 IM SDK 返回顺序一致）。
  /// 阶段 5A 用于系统通知页（userId=sysNotification, count=50）；
  /// 阶段 5B 聊天页复用（count=20，lastMsgId 分页）。
  Future<List<ImMessage>> historyMessages({
    required String userId,
    int count = 20,
    String? lastMsgId,
  });

  /// 新消息推送流（SDK onRecvNewMessage；阶段 5B 聊天页追加用）。
  /// 按 senderId 过滤归属会话。
  /// Android 参照：RobotChatFragment V2TIMManager.addAdvancedMsgListener。
  Stream<ImMessage> get newMessageStream;

  /// 发送 C2C 文本消息，返回本地回显消息（isSelf=true）。
  /// iOS 参照：XYChatContainerViewController.chatInputBar(didSendText:)。
  Future<ImMessage> sendTextMessage({
    required String userId,
    required String text,
  });

  /// 发送 C2C 图片消息（imagePath 为本地文件路径）。
  /// iOS 参照：XYChatContainerViewController.chatInputBar(didSendImage:)。
  Future<ImMessage> sendImageMessage({
    required String userId,
    required String imagePath,
  });

  /// 发送 C2C 文件消息（filePath 本地文件路径）。
  Future<ImMessage> sendFileMessage({
    required String userId,
    required String filePath,
    String? fileName,
    int? fileSize,
  });

  /// 对已落库的失败消息按同一 msgId 重发（合并为一条，避免历史破图+成功双条）。
  Future<ImMessage> reSendMessage({required String msgId});

  /// 发送 C2C 语音消息（soundPath 本地文件 + duration 秒）。
  /// iOS 参照：XYChatContainerViewController.chatInputBar(didSendVoice:duration:)。
  Future<ImMessage> sendSoundMessage({
    required String userId,
    required String soundPath,
    required int duration,
  });

  /// 解析语音可播放路径/URL：本地 path → 已下载 local → 在线 URL / 下载。
  /// iOS 参照：TUIVoiceMessageCellData.getVoicePath + downloadSound。
  /// 返回本地文件路径或 https URL；不可用时返回 null。
  Future<String?> resolveSoundPlayablePath(ImMessage message);

  /// 解析图片可展示路径/URL：本地 path → imageList.localUrl → url →
  /// getMessageOnlineUrl / downloadMessage。
  /// iOS 参照：TUIImageMessageCellData.getImagePath + downloadImage。
  /// 返回本地文件路径、assets 路径或 https URL；不可用时返回 null。
  Future<String?> resolveImageDisplaySource(ImMessage message);

  /// 解析全屏预览用图源（网络优先大图而非原图；本地可原图）。
  /// 同一 msgId 会合并进行中的请求并缓存结果，供气泡预取 / 预览页复用。
  Future<String?> resolveImagePreviewSource(ImMessage message);

  /// 发送 C2C 自定义消息（customJson 为 customElem.data 的 JSON 字符串，
  /// 顶层字段受契约 §3 白名单约束；咨询师工具卡 question_assistant 用）。
  /// iOS 参照：XYChatContainerViewController.chatInputBar(didSendAssistantCard:)。
  Future<ImMessage> sendCustomMessage({
    required String userId,
    required String customJson,
  });

  /// 将用户加入 IM 黑名单（单向屏蔽接收）。
  /// 参照 iOS XYBlockManager.addToBlackList（底层网易云信 UserService.addUserToBlockList；
  /// iOS 原版腾讯 IM 已弃用）。
  Future<void> addToBlackList(String imUserId);

  /// 删除与指定用户的 C2C 会话及历史（拉黑后从消息列表移除）。
  /// 失败不抛错（会话可能本就不存在）。
  /// 参照 iOS XYBlockManager.deleteC2CConversation（底层网易云信 localConversationService）。
  Future<void> deleteC2CConversation(String imUserId);

  /// 查询某用户是否在自己 IM 黑名单中；失败按未拉黑回传。
  /// 参照 iOS XYBlockManager.isUserBlocked（底层网易云信 UserService.checkBlock）。
  Future<bool> isUserBlocked(String imUserId);

  /// 拉取当前账号 IM 黑名单列表（含昵称/头像，供黑名单管理页）。
  Future<List<ImBlockedUser>> fetchBlackList();

  /// 将用户从 IM 黑名单移除。
  Future<void> removeFromBlackList(String imUserId);

  /// userSig 过期回调（实现内已做 60s 节流，iOS 参照：XYIMManager.onUserSigExpired）。
  /// 业务层语义：弹「登录已过期」并登出，不静默刷新（契约 §1）。
  void Function()? onUserSigExpired;

  /// 被踢下线回调（同账号异地登录等）。业务层语义：弹「账号已下线」并登出回登录页。
  void Function()? onKickedOffline;

  /// IM 登录成功回调（iOS 参照：XYIMLoginSuccess 通知，
  /// 消息 Tab 据此重拉会话/未读）。
  void Function()? onLoginSuccess;

  /// 释放资源（取消监听、关闭流）。
  Future<void> dispose();
}

/// 按 ApiClient.useMock 选择实现（非 Mock 时统一使用网易云信 NeteaseImService）。
final imServiceProvider = Provider<ImService>((ref) {
  final ImService service =
      ApiClient.useMock ? MockImService() : NeteaseImService();
  ref.onDispose(() => service.dispose());
  return service;
});
