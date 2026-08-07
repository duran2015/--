import 'package:flutter_test/flutter_test.dart';
import 'package:xinyu_flutter/core/im/im_models.dart';
import 'package:xinyu_flutter/core/im/middle_card_unread.dart';
import 'package:xinyu_flutter/features/chat/cards/chat_card_logic.dart';

void main() {
  group('isMiddleCardBusinessId', () {
    test('*_middle 为 true', () {
      expect(isMiddleCardBusinessId('begin_chat_middle'), isTrue);
      expect(isMiddleCardBusinessId('for_evaluate_middle'), isTrue);
      expect(isMiddleCardBusinessId('for_summary_middle'), isTrue);
      expect(isMiddleCardBusinessId('remind_window_middle'), isTrue);
    });

    test('非 middle / 空 为 false', () {
      expect(isMiddleCardBusinessId('question_assistant'), isFalse);
      expect(isMiddleCardBusinessId('summary_advise'), isFalse);
      expect(isMiddleCardBusinessId(null), isFalse);
      expect(isMiddleCardBusinessId(''), isFalse);
    });
  });

  group('isSelfMiddleCardMessage', () {
    ImMessage msg({
      required bool isSelf,
      required String businessID,
      String peerId = 'xy_1',
    }) {
      return ImMessage(
        msgId: 'm1',
        kind: ImMessageKind.custom,
        customJson: '{"businessID":"$businessID","title":"t"}',
        isSelf: isSelf,
        peerId: peerId,
        timestamp: DateTime(2026, 8, 5),
      );
    }

    test('本端 *_middle → true', () {
      expect(
        isSelfMiddleCardMessage(msg(isSelf: true, businessID: 'begin_chat_middle')),
        isTrue,
      );
    });

    test('对端 *_middle → false（SDK 已计未读，无需补偿）', () {
      expect(
        isSelfMiddleCardMessage(msg(isSelf: false, businessID: 'for_evaluate_middle')),
        isFalse,
      );
    });

    test('本端非 middle 自定义卡 → false', () {
      expect(
        isSelfMiddleCardMessage(msg(isSelf: true, businessID: 'question_assistant')),
        isFalse,
      );
    });
  });
}
