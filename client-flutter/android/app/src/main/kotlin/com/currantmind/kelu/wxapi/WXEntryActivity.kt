package com.currantmind.kelu.wxapi

import com.jarvan.fluwx.wxapi.FluwxWXEntryActivity

/**
 * 微信 SDK 回调入口 Activity（fluwx 版）。
 *
 * 注意：包名路径必须固定为 `${applicationId}.wxapi.WXEntryActivity`，
 * 微信 SDK 按此路径唤起；applicationId 已与微信开放平台登记一致
 * （com.currantmind.kelu）。回调分发由 fluwx 父类完成（转发给 Flutter
 * 引擎，对齐 iOS XYWechatLoginManager.onResp 回调链路），收到响应后立即 finish。
 */
class WXEntryActivity : FluwxWXEntryActivity()
