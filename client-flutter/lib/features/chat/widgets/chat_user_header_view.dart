import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/widgets/person_avatar.dart';

/// 真人咨询聊天头部：咨询师资料 + 当前订单 SKU 的轻量摘要。
class ChatUserHeaderView extends StatelessWidget {
  const ChatUserHeaderView({
    super.key,
    this.userName,
    this.avatar,
    this.avatarSeed,
    this.tags,
    this.consultantIntro,
    this.bookedSku,
    this.orderStatus,
    this.actionText,
    this.onAvatarTap,
    this.onOrderTap,
    this.onActionTap,
  });

  final String? userName;
  final String? avatar;
  final String? avatarSeed;
  final List<String>? tags;
  final String? consultantIntro;
  final String? bookedSku;
  final String? orderStatus;
  final String? actionText;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onOrderTap;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final displayName =
        (userName != null && userName!.isNotEmpty) ? userName! : '咨询师';
    final intro = (consultantIntro ?? '').trim();
    final sku = (bookedSku ?? '').trim();
    final status = (orderStatus ?? '').trim();
    final action = (actionText ?? '').trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOrderTap,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: 76.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00FFFFFF), Color(0xCBFFFFFF)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16.r),
              bottomRight: Radius.circular(16.r),
            ),
          ),
          padding: EdgeInsets.fromLTRB(15.w, 8.h, 15.w, 10.h),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onAvatarTap,
                child: PersonAvatar(
                  name: displayName,
                  seed: avatarSeed ?? displayName,
                  imageUrl: avatar,
                  size: 48.w,
                  showOnline: true,
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (intro.isNotEmpty) ...[
                      Text(
                        intro,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF666B69),
                        ),
                      ),
                    ],
                    if (sku.isNotEmpty) ...[
                      5.verticalSpace,
                      Text(
                        sku,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF006A67),
                        ),
                      ),
                    ],
                    if (status.isNotEmpty) ...[
                      5.verticalSpace,
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5F3),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF006A67),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (action.isNotEmpty) ...[
                8.horizontalSpace,
                FilledButton(
                  onPressed: onActionTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF006A67),
                    foregroundColor: Colors.white,
                    minimumSize: Size(0, 28.h),
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(action),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
