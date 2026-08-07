import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 小鹿 AI 页首次进入「AI 服务数据说明」免责声明弹窗。
///
/// 视觉参照登录页 AgreementDialog（#F7F8FC 外卡 + 白色可滚动正文卡 +
/// 渐变主按钮 + 白底次按钮）；文案与业务逻辑对齐 iOS
/// `XYAIConsultViewController.presentAISharingConsentIfNeeded`。
///
/// 遮罩不可点击关闭（barrierDismissible: false），用户必须二选一：
/// 「同意并继续」→ pop(true)；「不同意」→ pop(false)。
class AiSharingConsentDialog extends StatelessWidget {
  const AiSharingConsentDialog({super.key});

  /// 弹出弹窗，返回 true=同意 / false=不同意。
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AiSharingConsentDialog(),
    );
  }

  /// 标题（iOS 原文）
  static const String _title = 'AI 服务数据说明';

  /// 正文（iOS 原文，三段以 \n\n 分段）
  static const String _body =
      '为向您提供 AI 心理陪伴服务，您在对话中输入的文字、语音、图片及上传的文件内容将被发送至第三方 AI 服务提供方【阿里云·通义千问】进行处理并生成回复。\n\n'
      '我们不会主动发送您的手机号、身份信息等其他个人资料。该等数据仅用于 AI 对话服务，第三方将提供与我们同等的数据保护。\n\n'
      '是否同意将上述对话内容用于 AI 服务？';

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
            _buildHeader(),
            12.verticalSpace,
            _buildContentCard(),
            16.verticalSpace,
            _buildPrimaryButton(context),
            10.verticalSpace,
            _buildSecondaryButton(context),
          ],
        ),
      ),
    );
  }

  /// 标题（居中，18sp w600 #222；不加关闭按钮——遮罩不可关，必须二选一，
  /// 对齐 iOS XYCenterAlertView.showConfirm）。
  Widget _buildHeader() {
    return SizedBox(
      width: double.infinity,
      height: 28.h,
      child: Center(
        child: Text(
          _title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF222222),
            fontFamily: 'PingFang SC',
          ),
        ),
      ),
    );
  }

  /// 白色正文卡（圆角 12，固定高度可滚动，防文案加长溢出）。
  Widget _buildContentCard() {
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
          child: Text(
            _body,
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.5,
              color: const Color(0xFF666666),
              fontFamily: 'PingFang SC',
            ),
          ),
        ),
      ),
    );
  }

  /// 主按钮「同意并继续」（渐变 #00D8E0→#00AFBE），pop(true)。
  Widget _buildPrimaryButton(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
            ),
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

  /// 次按钮「不同意」（白底 #999），pop(false)。
  Widget _buildSecondaryButton(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(false),
      child: Container(
        height: 45.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26.5.r),
        ),
        child: Center(
          child: Text(
            '不同意',
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
}
