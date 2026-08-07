import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xinyu_flutter/features/profile/support_profile_state.dart';

void main() {
  test('新用户只显示渐进式偏好提示，不强制完成支持档案', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(supportProfileProvider);
    expect(state.preferenceNeedsAttention, isTrue);
    expect(state.authorizedForBooking, isFalse);
    expect(state.supportIsStale, isTrue);
  });

  test('保存咨询偏好后完成匹配资料并关闭首页提示', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(supportProfileProvider.notifier).savePreference(
      concerns: const ['工作压力', '睡眠问题'],
      modes: const ['语音咨询'],
      style: '温和倾听',
      availableTime: '工作日晚间',
    );

    final state = container.read(supportProfileProvider);
    expect(state.preferenceCompletion, 100);
    expect(state.preferenceNeedsAttention, isFalse);
    expect(state.homePromptDismissed, isTrue);
  });

  test('支持档案只有用户主动授权后才可形成预约资料快照', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(supportProfileProvider.notifier).saveSupport(
          goal: '改善工作压力带来的失眠',
          counselingHistory: '曾接受短程咨询',
          currentSupport: '家人支持',
          authorized: true,
        );

    final state = container.read(supportProfileProvider);
    expect(state.authorizedForBooking, isTrue);
    expect(state.supportCompletion, 100);
    expect(state.supportIsStale, isFalse);
  });
}
