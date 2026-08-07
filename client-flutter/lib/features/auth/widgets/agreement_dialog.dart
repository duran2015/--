import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:xinyu_flutter/defines/constants.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../utils/load_image.dart';

/// 注释：协议文案与默认链接常量
/// 时间：2026/8/4
/// 作者：郭翰林
class AgreementTexts {
  AgreementTexts._();

  static const String serviceAgreementTitle = '《服务协议》';
  static const String privacyPolicyTitle = '《隐私政策》';
  static const String userAgreementTitle = '《用户协议》';
  static const String defaultServiceAgreementUrl = LyConfig.userAgreement;
  static const String defaultPrivacyPolicyUrl = LyConfig.privacyPolicy;
}

/// 注释：用户服务协议与隐私政策弹窗组件（使用 flutter_screenutil 进行全屏幕响应式适配）
/// 时间：2026/8/4
/// 作者：郭翰林
class AgreementDialog extends StatelessWidget {
  const AgreementDialog({super.key, this.serviceUrl, this.privacyUrl});

  final String? serviceUrl;
  final String? privacyUrl;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        width: 315.w,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(16.r),
        ),
        padding: EdgeInsets.all(12.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            renderHeader(context),
            12.verticalSpace,
            renderContentCard(context),
            16.verticalSpace,
            renderPrimaryButton(context),
            10.verticalSpace,
            renderSecondaryButton(context),
          ],
        ),
      ),
    );
  }

  /// 注释：绘制弹窗头部（标题与关闭按钮）
  /// 时间：2026/8/4
  /// 作者：郭翰林
  Widget renderHeader(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 28.h,
          child: Center(
            child: Text(
              '服务协议与隐私政策',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF222222),
                fontFamily: 'PingFang SC',
              ),
            ),
          ),
        ),
        Positioned(
          right: 4.w,
          top: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(false),
            child: Container(
              width: 24.w,
              height: 24.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x10000000),
              ),
              child: Icon(
                Icons.close,
                size: 16.r,
                color: const Color(0xFF999999),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 注释：绘制白色协议内容卡片视图
  /// 时间：2026/8/4
  /// 作者：郭翰林
  Widget renderContentCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      padding: EdgeInsets.all(14.w),
      child: SizedBox(
        height: 235.h,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: renderRichTextContent(context),
        ),
      ),
    );
  }

  /// 注释：绘制卡片内协议富文本内容
  /// 时间：2026/8/4
  /// 作者：郭翰林
  Widget renderRichTextContent(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: 13.sp,
      height: 1.5,
      color: const Color(0xFF666666),
      fontFamily: 'PingFang SC',
    );
    final linkStyle = TextStyle(
      fontSize: 13.sp,
      height: 1.5,
      color: const Color(0xFF00AFBE),
      fontWeight: FontWeight.w600,
      fontFamily: 'PingFang SC',
    );

    return Text.rich(
      TextSpan(
        style: textStyle,
        children: [
          const TextSpan(
            text: '欢迎使用「可鹿心理」。为了保障你的个人信息与使用权益，请在继续前阅读并理解',
          ),
          TextSpan(
            text: AgreementTexts.userAgreementTitle,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _openUrl(
                    context,
                    serviceUrl ?? AgreementTexts.defaultServiceAgreementUrl,
                  ),
          ),
          const TextSpan(text: '和'),
          TextSpan(
            text: AgreementTexts.privacyPolicyTitle,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _openUrl(
                    context,
                    privacyUrl ?? AgreementTexts.defaultPrivacyPolicyUrl,
                  ),
          ),
          const TextSpan(
            text: '。\n在你使用AI倾诉、心理测评、情绪记录和咨询预约等服务时，我们会收集必要的设备信息、网络信息，以及你主动提供的情绪和服务资料，并按照相关法律法规进行保护。\n未经你的明确同意，我们不会将AI沟通内容直接展示给咨询师;仅在你授权时同步结构化摘要用于咨询前准备。',
          ),
        ],
      ),
    );
  }

  /// 注释：绘制同意并继续主按钮视图
  /// 时间：2026/8/4
  /// 作者：郭翰林
  Widget renderPrimaryButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(true),
      child: Container(
        height: 45.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00D8E0), Color(0xFF00AFBE)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(26.5.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0x2000AFBE),
              offset: Offset(0, 4.h),
              blurRadius: 8.r,
            )
          ],
        ),
        child: Center(
          child: Text(
            '同意并继续',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'PingFang SC',
            ),
          ),
        ),
      ),
    );
  }

  /// 注释：绘制暂不同意次要按钮视图
  /// 时间：2026/8/4
  /// 作者：郭翰林
  Widget renderSecondaryButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(false),
      child: Container(
        height: 45.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26.5.r),
        ),
        child: Center(
          child: Text(
            '暂不同意',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF999999),
              fontFamily: 'PingFang SC',
            ),
          ),
        ),
      ),
    );
  }

  void _openUrl(BuildContext context, String url) {
    context.push('${RoutePaths.webview}?url=${Uri.encodeComponent(url)}');
  }
}

/// 注释：通用协议富文本组件（供登录页等外部视图引用）
/// 时间：2026/8/4
/// 作者：郭翰林
class AgreementRichText extends StatefulWidget {
  const AgreementRichText({
    super.key,
    required this.prefix,
    required this.middle,
    required this.suffix,
    this.serviceUrl,
    this.privacyUrl,
    this.style,
    this.textAlign = TextAlign.left,
  });

  final String prefix;
  final String middle;
  final String suffix;
  final String? serviceUrl;
  final String? privacyUrl;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  State<AgreementRichText> createState() => _AgreementRichTextState();
}

class _AgreementRichTextState extends State<AgreementRichText> {
  late TapGestureRecognizer _serviceRecognizer;
  late TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _serviceRecognizer = TapGestureRecognizer()..onTap = _openService;
    _privacyRecognizer = TapGestureRecognizer()..onTap = _openPrivacy;
  }

  @override
  void dispose() {
    _serviceRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _open(String url) {
    context.push('${RoutePaths.webview}?url=${Uri.encodeComponent(url)}');
  }

  void _openService() => _open(
        widget.serviceUrl ?? AgreementTexts.defaultServiceAgreementUrl,
      );

  void _openPrivacy() => _open(
        widget.privacyUrl ?? AgreementTexts.defaultPrivacyPolicyUrl,
      );

  @override
  Widget build(BuildContext context) {
    final body = widget.style ??
        AppTextStyles.label.copyWith(color: AppColors.textSecondary);
    final link = body.copyWith(color: AppColors.brandTeal);
    return Text.rich(
      TextSpan(
        style: body,
        children: [
          TextSpan(text: widget.prefix),
          TextSpan(
            text: AgreementTexts.serviceAgreementTitle,
            style: link,
            recognizer: _serviceRecognizer,
          ),
          TextSpan(text: widget.middle),
          TextSpan(
            text: AgreementTexts.privacyPolicyTitle,
            style: link,
            recognizer: _privacyRecognizer,
          ),
          TextSpan(text: widget.suffix),
        ],
      ),
      textAlign: widget.textAlign,
    );
  }
}

/// 注释：登录页协议勾选行组件（全屏幕 ScreenUtil 响应式规范）
/// 时间：2026/8/4
/// 作者：郭翰林
class AgreementConsentRow extends StatelessWidget {
  const AgreementConsentRow({
    super.key,
    required this.agreed,
    required this.onChanged,
    this.serviceUrl,
    this.privacyUrl,
  });

  final bool agreed;
  final ValueChanged<bool> onChanged;
  final String? serviceUrl;
  final String? privacyUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!agreed),
          child: SizedBox(
            width: AppDimens.loginCheckBoxTapSize.w,
            height: AppDimens.loginCheckBoxTapSize.h,
            child: Center(
              child: LoadImage(
                agreed
                    ? AppAssets.loginAgreementChecked
                    : AppAssets.loginAgreementUnchecked,
                width: AppDimens.loginCheckBoxSize.w,
                height: AppDimens.loginCheckBoxSize.w,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: AppDimens.gap4.h),
            child: AgreementRichText(
              prefix: '我已阅读并同意',
              middle: '与',
              suffix: '， 未注册手机号通过验证后将自动注册。',
              serviceUrl: serviceUrl,
              privacyUrl: privacyUrl,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
