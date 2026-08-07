import 'package:flutter/material.dart';

import '../../utils/image_utils.dart';

/// 全局统一人物头像：真实图片优先，失败时使用稳定的姓名首字渐变头像。
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.name,
    required this.seed,
    required this.size,
    this.imageUrl,
    this.showOnline = false,
  });

  final String name;
  final String seed;
  final double size;
  final String? imageUrl;
  final bool showOnline;

  static const _palettes = <List<Color>>[
    [Color(0xFFEADDFF), Color(0xFFD0BCFF)],
    [Color(0xFFB2EBF2), Color(0xFF80CBC4)],
    [Color(0xFFFFDCC2), Color(0xFFFFB59B)],
    [Color(0xFFD8E2FF), Color(0xFFB7C5E8)],
    [Color(0xFFD9E7CB), Color(0xFFB8C9A8)],
  ];

  @override
  Widget build(BuildContext context) {
    final fallback = _fallback();
    final url = imageUrl;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: ClipOval(
            child: url == null || url.isEmpty
                ? fallback
                : Image(
                    image: ImageUtils.getImageProvider(url),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => fallback,
                  ),
          ),
        ),
        if (showOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: const Color(0xFF16A66A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fallback() {
    final colors = _palettes[seed.hashCode.abs() % _palettes.length];
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '咨' : trimmed.substring(0, 1);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: const Color(0xFF33245D),
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
