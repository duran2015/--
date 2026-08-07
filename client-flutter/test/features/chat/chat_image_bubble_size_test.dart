import 'package:flutter_test/flutter_test.dart';
import 'package:xinyu_flutter/features/chat/chat_image_bubble_size.dart';

void main() {
  test('mobile image bubble follows the reference width', () {
    final size = chatImageBubbleSize(
      screenWidth: 390,
      imageWidth: 100,
      imageHeight: 100,
    );

    expect(size.width, 180);
    expect(size.height, 180);
  });

  test('wide web layouts cap the image bubble at 240 pixels', () {
    final size = chatImageBubbleSize(
      screenWidth: 1280,
      imageWidth: 100,
      imageHeight: 100,
    );

    expect(size.width, 240);
    expect(size.height, 240);
  });

  test('portrait images preserve their ratio under the cap', () {
    final size = chatImageBubbleSize(
      screenWidth: 1280,
      imageWidth: 100,
      imageHeight: 200,
    );

    expect(size.width, 120);
    expect(size.height, 240);
  });
}
