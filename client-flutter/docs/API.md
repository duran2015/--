# 项目接口清单（Flutter）

> 维护说明：本清单由 Flutter 网络层 `ApiClient`（`lib/core/network/api_client.dart`）的四个请求方法 + 各模块 `lib/features/*/<module>_api.dart` 整理而来。新增/修改接口后请同步更新本文档。
>
> 对应 iOS 原生清单的历史视角（`XYNetworkManager` 的 `postJSON` / `postJSONPaged` / `postJSONMessage`）已整体迁移为 Flutter 视角。

## 通用约定

| 项 | 说明 |
|---|---|
| **baseURL** | `ApiEnv.baseUrl`（`api_env.dart`），线上默认 `https://api.currantmind.cn`；本地真机联调用 `flutter run --dart-define=API_BASE_URL=http://<lan-ip>:18080` 覆盖；mock 模式不发真实请求 |
| **完整 URL** | baseUrl + path，例：`https://api.currantmind.cn/app/auth/loginByPhone` |
| **请求方式** | 全部 `POST`，请求体 JSON（dio，统一经 `ApiClient`） |
| **鉴权** | 拦截器从 `authTokenProvider` 读 token 注入 `Authorization: Bearer`；由 `requireAuth`（默认 `true`）控制。免鉴权白名单 `_authFreePaths`：`loginByPhone` / `wechatLogin` / `appleLogin` / `bindPhoneLogin` / `agreement/latest` |
| **响应外壳** | RuoYi 约定：普通 `code/msg/data`，分页 `code/msg/total/rows`；网络层统一判 `code == 200` 为成功 |
| **会话过期** | HTTP 401 或业务 `code == 401` → 触发 `ApiClient.onSessionExpired`（由 `AuthController` 注册 → 统一登出回登录页） |
| **封装方法** | `postData`（取 `data`，code≠200 抛 `ApiException`）/ `postPaged`（取 `rows`+`total`）/ `postMessage`（只取 `msg` 文案）/ `post`（返回完整响应壳，调用方自判） |
| **服务器时间** | 响应头 `Date` 自动校准，用 `ApiClient.serverNow()`（支付倒计时等场景，对齐 iOS `XYServerTimeMonitor`） |
| **mock** | `flutter run --dart-define=API_ENV=mock` → `registerDevMocks()`（`dev_mock.dart`），仅 debug 生效，release 恒 live |

---

## 1. 登录与认证（`AuthApi` · `auth_api.dart`）

| 功能 | 接口 | 参数 | 封装 | 鉴权 |
|---|---|---|---|---|
| 手机号验证码登录 | `/app/auth/loginByPhone` | `phone`、`smsCode` | postData | 否 |
| 发送短信验证码 | `/app/auth/sendSmsCode` | `phone`；注销场景带 `scene`（`deactivate_user` / `deactivate_consultant`） | postMessage | `scene` 非空→是；空→否 |
| 微信授权登录 | `/app/auth/wechatLogin` | `code`（微信回调）、`platform`（"app"） | postData | 否 |
| Apple 授权登录 | `/app/auth/appleLogin` | `identityToken`（Apple JWT）、`nickName`（仅首次授权可空） | postData | 否 |
| 微信/Apple 绑定手机号 | `/app/auth/bindPhoneLogin` | `preAuthToken`、`phone`、`smsCode` | postData | 否 |
| 选择/切换登录身份 | `/app/auth/selectIdentity` | `identity`（"user"/"consultant"） | postData | 是 |
| 退出登录 | `/app/auth/logout` | 无 `{}` | postMessage | 是 |

> `sendSmsCode` 不在免鉴权白名单：登录场景（无 `scene`）`requireAuth=false`，注销场景（带 `scene`）`requireAuth=true`，由调用方按场景传参。微信/Apple 登录响应形态一致，`needBindPhone=true` 时返回 `preAuthToken/nickName/avatar`，否则同节点平铺登录态。

## 2. 协议与隐私（`AuthApi` · `auth_api.dart`）

| 功能 | 接口 | 参数 | 封装 | 鉴权 |
|---|---|---|---|---|
| 获取最新协议地址 | `/app/agreement/latest` | 无 `{}` | postData | 否 |
| 提交协议勾选同意 | `/app/agreement/consent` | `items`（`[{agreementType:1, version:服务协议版本}, {agreementType:2, version:隐私政策版本}]`）、`channel`、`deviceId`、`phone`、`userId` | postMessage | 是 |

> 登录前调 `latest` 拿服务协议 / 隐私政策跳转 URL 与版本号；登录成功后用返回版本号调 `consent` 上报勾选记录。
> ⚠️ `channel`：iOS 实传 `2`；**Flutter 取 `agreementChannel = 1`（Android/Flutter 值，待后端确认）**。`userId` 可转 Int 时按数字上传。

## 3. 用户端 · 咨询师与预约（`ConsultantApi` · `consultant_api.dart` / `OrderApi` · `order_api.dart`）

| 功能 | 接口 | 参数 | 封装 | 鉴权 |
|---|---|---|---|---|
| 咨询师列表（分页） | `/app/consultant/list` | `pageNum`、`pageSize` | postPaged | 是 |
| 咨询师详情 | `/app/consultant/detail` | `imUserId`（优先）或 `consultantId` | postData | 是 |
| 咨询师评价列表（分页） | `/app/consultant/review-list` | `consultantId`、`pageNum`、`pageSize` | postPaged | 是 |
| 预约下单 | `/app/consultant/book` | `consultantId`、`capabilityId`、`availabilityId`、`supportMode`（"1/2/3"）、`appointmentTime`（yyyy-MM-dd HH:mm:ss） | postData | 是 |
| 我的预约订单（分页） | `/app/consultant/order/my-list` | `pageNum`、`pageSize` | postPaged | 是 |
| 取消预约 | `/app/consultant/order/cancel` | `orderId` | postData | 是 |

> `detail` 优先按 `imUserId` 查询（聊天页点头像进详情），否则按 `consultantId`。`book` 的 body 由 `BookingViewModel.buildBookBody()` 组装，返回 `orderId` 为空视为失败。无独立订单详情接口，`OrderApi.findOrderById` 按 `orderId` 在 `my-list` 分页里翻找回填。

## 4. 用户端 · 评价（`EvaluateApi` · `evaluate_api.dart`）

| 功能 | 接口 | 参数 | 封装 | 鉴权 |
|---|---|---|---|---|
| 评价可选标签 | `/app/consultant/review/tags` | 无 `{}` | postData | 是 |
| 提交评价 | `/app/consultant/review/add` | `consultantId`、`orderId`、`rating`、`content`、`tagIds`、`currentUserId`（body 由 `EvaluateSubmission.buildBody` 组装） | postData | 是 |

## 5. 用户端 · 测评 / 量表（`HomeApi` · `home_api.dart` / `MineApi` · `mine_api.dart`）

| 功能 | 接口 | 参数 | 封装 | 鉴权 |
|---|---|---|---|---|
| 测评问卷列表（首页） | `/app/assessment/list` | `category`（"clinical"） | postData | 是 |
| 量表测试记录（按状态，我的页） | `/app/assessment/list-by-status` | `status`（"1"，data 为数组非分页） | postData | 是 |
| 测评报告详情 | `/app/assessment/detail` | `assessmentId`（= 列表返回的 `userAssessId`） | postData | 是 |

> 详情 `data` 含 `sourceUrl`（内容出处外链，有值时报告页展示「内容出处」入口）。

## 6. 用户端 · 支付（`PaymentApi` · `payment_api.dart`，实现 `PaymentGateway`）

| 功能 | 接口 | 参数 | 封装 | 鉴权 |
|---|---|---|---|---|
| 创建支付 | `/app/pay/create` | `orderId`（可转 Int 时按数字）、`payType`（"wechat"/"alipay"） | postData | 是 |
| 模拟支付成功 | `/app/pay/mock-success` | `outTradeNo` | postData | 是 |
| 同步确认支付成功 | `/app/pay/confirm` | `outTradeNo`、`transactionId`（可空） | postData | 是 |

> 金额由服务端按订单价格为准（不信任客户端金额）。`create` 返回 `outTradeNo` + `orderInfo`（支付宝已签名参数串，可空）+ `wxPayParams`（微信 App 支付调起参数，可空）；客户端据 `payType` 分别唤起支付宝/微信收银台。
> `confirm`：本地联调兜底——支付宝客户端 `resultStatus=9000` 后调用，弥补异步通知内网不可达；生产仍以支付宝异步通知为准。`mock-success` 为模拟回调，上线以真实支付为准。

## 7. 用户端 · 咨询小结（`SummaryApi` · `summary_api.dart` / `MineApi` · `mine_api.dart`）

| 功能 | 接口 | 参数 | 封装 | 鉴权 |
|---|---|---|---|---|
| 我的小结列表（分页） | `/app/mine/summaries` | `pageNum`、`pageSize` | postPaged | 是 |
| 小结详情 | `/app/mine/summary/detail` | `orderId` | postData | 是 |

## 8. 用户端 · 账号（`MineApi` · `mine_api.dart`）

| 功能 | 接口 | 参数 | 封装 | 鉴权 |
|---|---|---|---|---|
| 注销账号 | `/app/mine/deactivate` | `phone`、`smsCode` | postMessage | 是 |
| 提交意见反馈 | `/app/mine/feedback/submit` | `content` | postMessage | 是 |

> 注销前先调 `/app/auth/sendSmsCode` 取验证码，并带 `scene`（用户端 `deactivate_user`、咨询师端 `deactivate_consultant`）。注销成功后客户端清本地登录态并登出 IM。

## 9. 数字心理画像（`CounselorApi.fetchPersonality` · `counselor_api.dart`）

| 功能 | 接口 | 参数 | 封装 | 鉴权 |
|---|---|---|---|---|
| 用户自身画像 | `/app/mine/profile` | 无 `{}`（`fetchPersonality` 的 `userId` 为空时走此） | postData | 是 |
| 咨询师查看用户画像 | `/consultant/home/userProfile` | `userId` | postData | 是 |

> `fetchPersonality(userId)` 按 `userId` 分发：空 → `/app/mine/profile`（自身）；非空 → `/consultant/home/userProfile`。返回 AI 生成的心理画像（当前风险、人格特质、综合分析、韧性/风险依据等）。注：原生用户端「我的·心灵档案·心理画像」入口已下线（dev_mock 标注），接口保留供咨询师端复用。

## 10. 用户端 · 心情 / 情绪（首页，`HomeApi` · `home_api.dart`）

| 功能 | 接口 | 参数 | 封装 | 鉴权 |
|---|---|---|---|---|
| 提交今天的心情 | `/app/user/mood` | `recordDate`、`moodScore`、`note` | postMessage | 是 |
| 情绪月历（按月） | `/app/user/mood/calendar` | `year`、`month` | postData | 是 |
| 最近情绪趋势 | `/app/user/mood/trend` | `days`（当前传 7） | postData | 是 |

> `mood` 走 `postMessage`（只取返回 `msg` 文案 Toast）；`calendar`/`trend` 走 `postData`（`data` 为数组）。

## 11. 咨询室（进房 / 时段校验，按角色）

| 功能 | 接口 | 参数 | 封装 | 鉴权 | 归属 |
|---|---|---|---|---|---|
| 用户端进房时段校验 | `/app/consultant/room/join` | `orderId` | postMessage | 是 | `OrderApi` |
| 用户端 NERTC 进房 Token | `/app/consultant/room/token` | `orderId` | postData | 是 | `OrderApi` |
| 咨询师端开始咨询 | `/consultant/order/start` | `orderId` | postMessage | 是 | `CounselorApi` |

> 进房流程：先 `room/join`（用户）/ `order/start`（咨询师）做时段校验（code==200 视为通过），再 `room/token` 取 NERTC 安全模式进房凭证（返回 `{token, uid, channelName, expireAt}`，客户端须用服务端推导的 `uid` 调 `joinChannel`，不得本地另算）。

## 12. 咨询师端 · 工作台 / 小结（`CounselorApi` · `counselor_api.dart`）

| 功能 | 接口 | 参数 | 封装 | 鉴权 |
|---|---|---|---|---|
| 工作台首页 | `/consultant/home/index` | 无 `{}` | postData | 是 |
| 预约单列表（分页） | `/consultant/home/pendingList` | `pageNum`、`pageSize` | postPaged | 是 |
| 已咨询列表（分页） | `/consultant/home/completedList` | `pageNum`、`pageSize` | postPaged | 是 |
| 预约订单详情 | `/consultant/home/orderDetail` | `orderId` | postData | 是 |
| 过往接待记录（分页） | `/consultant/home/pastConsultations` | `orderId`、`pageNum`、`pageSize` | postPaged | 是 |
| 保存咨询小结与建议 | `/consultant/summary/save` | `orderId`、`content`（咨询师小结）、`advice`（行动建议 String 数组） | postMessage | 是 |
| 咨询小结详情 | `/consultant/summary/detail` | `orderId` | postData | 是 |

> `home/index` 含 `tabCounts.unreadMessageCount`（小鹿/系统通知未读）。`pastConsultations` / `summary/detail` 在 iOS 清单曾标注「待后端确认」，Flutter 已按 Android 契约实现并配 mock。

## 13. 举报 / 拉黑（`ReportApi` · `report_api.dart`）

| 功能 | 接口 | 参数 | 封装 | 鉴权 |
|---|---|---|---|---|
| 举报类型列表 | `/app/report/reasons` | 无 `{}`（data 为数组） | postData | 是 |
| 提交举报 | `/app/report/submit` | `targetType`（chat_msg/review/consultant/user）、`targetId`、`reasonCode`、`reasonDetail`（可空） | postMessage | 是 |
| 拉黑上报留档 | `/app/block/add` | 用户端拉黑咨询师：`consultantId`；咨询师端拉黑用户：`blockedUserId`（二选一） | postMessage | 是 |
| 黑名单列表（分页） | `/app/block/list` | `pageNum`、`pageSize` | postPaged | 是 |
| 解除黑名单 | `/app/block/cancel` | `blockedUserId`（取自 `/app/block/list` 返回） | postMessage | 是 |

> 拉黑/解除均先走 IM 黑名单（网易云信单向屏蔽），IM 生效后再静默调 `/app/block/add` / `/app/block/cancel` 通知后端（失败不阻断）。举报 `targetType` 与 `targetId` 对应：`chat_msg`→对方 imUserId、`review`→reviewId、`consultant`→咨询师 userId、`user`→用户 userId。

## 14. 用户端 · 小鹿 AI（`AiApi` · `ai_api.dart`）

| 功能 | 接口 | 参数 | 封装 | 鉴权 |
|---|---|---|---|---|
| 首次进入 AI 聊天页引导 | `/app/chat/guidance` | 无 `{}` | postMessage | 是 |

> 首次进入小鹿 AI 聊天页、且**用户已同意「AI 服务数据说明」**后调用，通知后端驱动 AI 主动发起开场消息（消息经 IM 下发到机器人会话）。前端按 `userID` 维度本地标记「已触发」（`ai_guidance_triggered_{userId}`），仅成功（code==200）才标记、失败下次重试；每个用户仅触发一次。

## 15. 咨询完成状态（`ConsultStatusApi` · `chat/consult_status_api.dart`）

| 功能 | 接口 | 参数 | 封装 | 鉴权 |
|---|---|---|---|---|
| 订单咨询完成状态 | `/app/mine/order/consult-status` | `orderId` | postData | 是 |

> 返回 `{reviewDone, summaryDone}`（是否已评价 / 是否已发布小结）。卡片「已完成」态按 app 自有数据渲染（ADR-0005），不再依赖 IM 消息原地编辑；失败回退未完成，不阻断渲染。

---

## 备注

- **合计 49 个业务接口**（iOS 原清单 44 + Flutter 新增 5：`pay/confirm`、`room/token`、`block/list`、`block/cancel`、`mine/order/consult-status`）。
- **命名规律**：用户端走 `/app/...`，咨询师端走 `/consultant/...`（不带 `/app`）；两端进房 / 订单接口成对存在。
- **封装映射**：`postData` ↔ iOS `postJSON`（取 data）；`postPaged` ↔ `postJSONPaged`（解析 rows/total）；`postMessage` ↔ `postJSONMessage`（只取 msg）。分页列表统一走 `postPaged`；`/app/user/mood`、各 `*/submit`、`block/*`、`logout`、`guidance` 等取文案/无返回体的走 `postMessage`。
- **`/app/pay/mock-success`** 为模拟支付回调；生产已接真实微信（`wxPayParams`）/ 支付宝（`orderInfo`）+ `pay/confirm` 同步确认。
- **IM 凭证**：Flutter 无独立 `/api/im/usersig` 接口，`imUserId` / `imUserSig` 由 `loginByPhone` / `wechatLogin` / `appleLogin` / `bindPhoneLogin` / `selectIdentity` 登录态直接下发。
- **账号密码登录**（iOS `/login/password`）：Flutter 未实现（仅验证码 + 微信 + Apple 三条登录链路）。
- **mock 数据**：`dev_mock.dart` 覆盖全部接口，含特殊手机号 `13800000002`（双身份）、特殊微信/Apple code（已绑定/未绑定分支），供断网开发与单测。
