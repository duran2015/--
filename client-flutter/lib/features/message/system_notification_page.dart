import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../utils/ly_cache.dart';

/// 推送后台可配置的通知频道。正式接入时由 GET /notification/channels 返回，
/// Flutter 只消费字段，不在页面内判断具体业务类型。
class NotificationChannelConfig {
  const NotificationChannelConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.messages,
    this.unreadCount = 0,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<NotificationMockMessage> messages;
  final int unreadCount;

  NotificationMockMessage get latest => messages.last;
}

/// 后台推送消息结构 Mock。actionLabel/actionRoute 代表运营后台配置的落地动作。
class NotificationMockMessage {
  const NotificationMockMessage({
    required this.title,
    required this.content,
    required this.time,
    this.actionLabel,
    this.actionRoute,
  });

  final String title;
  final String content;
  final String time;
  final String? actionLabel;
  final String? actionRoute;
}

const _mockNotificationChannels = <NotificationChannelConfig>[
  NotificationChannelConfig(
    id: 'appointment',
    name: '预约服务',
    description: '支付、确认、资料、咨询室与回顾进度',
    icon: Icons.event_available_rounded,
    color: Color(0xFF28A978),
    unreadCount: 2,
    messages: [
      NotificationMockMessage(
        title: '预约已确认',
        content: '苏晚晴咨询师已确认 08月11日 11:46 的文字咨询。',
        time: '昨天 18:20',
        actionLabel: '查看订单',
        actionRoute: '/orders',
      ),
      NotificationMockMessage(
        title: '咨询即将开始',
        content: '你与韩青梧咨询师的语音咨询将在 10 分钟后开始。',
        time: '今天 15:23',
        actionLabel: '进入咨询',
        actionRoute: '/orders',
      ),
    ],
  ),
  NotificationChannelConfig(
    id: 'benefit',
    name: '优惠福利',
    description: '优惠券、会员权益与限时折扣',
    icon: Icons.local_activity_rounded,
    color: Color(0xFFFF7657),
    unreadCount: 1,
    messages: [
      NotificationMockMessage(
        title: '新人咨询券到账',
        content: '一张 ¥30 真人咨询优惠券已放入你的账户，7 天内有效。',
        time: '今天 10:10',
        actionLabel: '立即查看',
        actionRoute: '/home',
      ),
    ],
  ),
  NotificationChannelConfig(
    id: 'activity',
    name: '平台活动',
    description: '主题活动、直播与公益计划',
    icon: Icons.campaign_rounded,
    color: Color(0xFFFFA726),
    messages: [
      NotificationMockMessage(
        title: '世界睡眠日主题活动',
        content: '本周六晚 20:00，和专业咨询师一起学习改善睡眠。',
        time: '08月06日',
        actionLabel: '查看活动',
        actionRoute: '/home',
      ),
    ],
  ),
  NotificationChannelConfig(
    id: 'content',
    name: '精选内容',
    description: '测评、课程与个性化心理内容',
    icon: Icons.auto_awesome_rounded,
    color: Color(0xFF7863C5),
    messages: [
      NotificationMockMessage(
        title: '为你推荐：停止反复内耗',
        content: '用 3 分钟认识“灾难化思维”，试试把担忧写下来。',
        time: '08月05日',
        actionLabel: '去阅读',
        actionRoute: '/home',
      ),
    ],
  ),
  NotificationChannelConfig(
    id: 'account',
    name: '账户与安全',
    description: '登录、隐私、协议与版本更新',
    icon: Icons.shield_rounded,
    color: Color(0xFF398FE5),
    messages: [
      NotificationMockMessage(
        title: '隐私设置已更新',
        content: '你的个性化推荐设置已于 08月04日 16:32 更新。',
        time: '08月04日',
        actionLabel: '查看设置',
        actionRoute: '/home',
      ),
    ],
  ),
];

class NotificationPreferenceState {
  const NotificationPreferenceState(this.enabled);
  final Map<String, bool> enabled;

  bool isEnabled(String id) => enabled[id] ?? true;
}

class NotificationPreferenceController
    extends Notifier<NotificationPreferenceState> {
  static String _key(String id) => 'notification_channel_enabled_$id';

  @override
  NotificationPreferenceState build() => NotificationPreferenceState({
        for (final channel in _mockNotificationChannels)
          channel.id: LyCache.getSync<bool>(key: _key(channel.id)) ?? true,
      });

  Future<void> setEnabled(String id, bool enabled) async {
    state = NotificationPreferenceState({...state.enabled, id: enabled});
    await LyCache.put(key: _key(id), value: enabled);
  }
}

final notificationPreferenceProvider = NotifierProvider<
    NotificationPreferenceController, NotificationPreferenceState>(
  NotificationPreferenceController.new,
);

/// 系统通知改为“通知会话”入口：每一类通知是一个由推送后台维护的会话。
class SystemNotificationPage extends ConsumerWidget {
  const SystemNotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(notificationPreferenceProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppNavBar(
                title: '消息中心',
                transparent: true,
                actions: [
                  IconButton(
                    tooltip: '通知管理',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationSettingsPage(),
                      ),
                    ),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _mockNotificationChannels.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final channel = _mockNotificationChannels[index];
                    return _NotificationConversationTile(
                      channel: channel,
                      enabled: preferences.isEnabled(channel.id),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => NotificationConversationPage(
                            channel: channel,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationConversationTile extends StatelessWidget {
  const _NotificationConversationTile({
    required this.channel,
    required this.enabled,
    required this.onTap,
  });

  final NotificationChannelConfig channel;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: enabled ? 0.96 : 0.66),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _ChannelIcon(channel: channel, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            channel.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          channel.latest.time,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            enabled ? channel.latest.content : '该类通知已关闭',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (enabled && channel.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${channel.unreadCount}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelIcon extends StatelessWidget {
  const _ChannelIcon({required this.channel, required this.size});
  final NotificationChannelConfig channel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: channel.color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(channel.icon, color: channel.color, size: size * 0.5),
    );
  }
}

/// 单类通知详情采用 IM 时间线，但没有输入栏：消息由推送后台单向下发。
class NotificationConversationPage extends ConsumerWidget {
  const NotificationConversationPage({super.key, required this.channel});
  final NotificationChannelConfig channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled =
        ref.watch(notificationPreferenceProvider).isEnabled(channel.id);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppNavBar(
                title: channel.name,
                transparent: true,
                actions: [
                  IconButton(
                    tooltip: enabled ? '关闭该类通知' : '开启该类通知',
                    onPressed: () => ref
                        .read(notificationPreferenceProvider.notifier)
                        .setEnabled(channel.id, !enabled),
                    icon: Icon(
                      enabled
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_off_outlined,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  itemCount: channel.messages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7D817F),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              enabled ? channel.description : '该类通知已关闭',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    final message = channel.messages[index - 1];
                    return _NotificationBubble(
                      channel: channel,
                      message: message,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBubble extends StatelessWidget {
  const _NotificationBubble({required this.channel, required this.message});
  final NotificationChannelConfig channel;
  final NotificationMockMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          Text(
            message.time,
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChannelIcon(channel: channel, size: 38),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 310),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(color: const Color(0xFFE8E4DE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message.content,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (message.actionLabel != null) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonal(
                            onPressed: () => context.go(message.actionRoute!),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              minimumSize: const Size(0, 36),
                            ),
                            child: Text(message.actionLabel!),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(notificationPreferenceProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              const AppNavBar(title: '消息通知管理', transparent: true),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(4, 4, 4, 12),
                      child: Text(
                        '关闭后不再接收该类站内推送，可随时重新开启。订单关键状态仍可在订单页查看。',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0;
                              i < _mockNotificationChannels.length;
                              i++) ...[
                            _NotificationSettingTile(
                              channel: _mockNotificationChannels[i],
                              value: preferences.isEnabled(
                                _mockNotificationChannels[i].id,
                              ),
                              onChanged: (value) => ref
                                  .read(notificationPreferenceProvider.notifier)
                                  .setEnabled(
                                    _mockNotificationChannels[i].id,
                                    value,
                                  ),
                            ),
                            if (i < _mockNotificationChannels.length - 1)
                              const Divider(height: 1, indent: 66),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationSettingTile extends StatelessWidget {
  const _NotificationSettingTile({
    required this.channel,
    required this.value,
    required this.onChanged,
  });
  final NotificationChannelConfig channel;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: Row(
        children: [
          _ChannelIcon(channel: channel, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  channel.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
