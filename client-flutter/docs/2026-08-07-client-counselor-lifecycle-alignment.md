# 用户端与咨询师端业务闭环对齐

## 用户可见状态链

`待支付 → 待咨询师确认 → 填写/跳过咨询前资料 → 进入咨询 → 等待咨询师确认回顾 → 查看回顾 → 评价 → 已归档`

订单列表、订单详情、IM 卡片和咨询室结束回跳必须消费同一份服务端状态投影，不允许页面自行根据文案猜测状态。

## 前端 Mock 字段

| 字段 | 用途 |
| --- | --- |
| `orderId` | 订单、支付、资料、评价的业务主键 |
| `sessionId` | 咨询室、转录、情绪流与会后回顾的会话主键 |
| `draftId` | 咨询师待确认总结草稿主键 |
| `confirmationStatus` | `not_requested / pending / confirmed / rejected` |
| `intakeStatus` | `locked / pending / submitted / skipped` |
| `sessionStatus` | `locked / ready / in_progress / completed` |
| `summaryStatus` | `none / pending / shared` |
| `recapRead` | 用户是否已查看咨询回顾 |
| `hasReview` | 用户是否已完成评价 |

IM 卡片与咨询师端统一额外携带 `audience`、`status`、`orderId`、`sessionId`、`draftId`。客户端必须先按 `audience` 做身份过滤，再按 `businessID` 渲染；旧消息缺少 `audience` 时才回退原协议兼容规则。

双端共用字段以咨询师端 `WorkflowMessage` 为准：`messageType`、`audience`、`status`、`title`、`description`、`actionLabel`、`orderId`、`sessionId`、`draftId`。Flutter 只为兼容旧 IM 协议保留 `businessID / desc / buttonText` 别名，不允许为两端分别维护不同业务文案。

## 用户端操作门禁

- 未支付只能支付或取消。
- 支付成功后等待咨询师确认，不能提前进入咨询室。
- 咨询前资料为选填；提交或明确跳过后进入 `ready`。
- 文字咨询进入对应 IM；语音和视频咨询进入订单绑定的 `roomId`。
- 用户结束会议后仅将 `sessionStatus` 更新为 `completed`、`summaryStatus` 更新为 `pending`。
- 咨询师正式提交总结后，后端原子更新 `summaryStatus=shared` 并创建用户 `summary_card` IM 消息。
- `recapRead=true` 后才开放评价；评价不能影响咨询师结算状态。

## IM 事件卡片

| 业务节点 | 卡片 | 路由参数 |
| --- | --- | --- |
| 预约确认 | `begin_chat_middle` | `orderId` |
| 咨询室开放 | `remind_window_middle` | `orderId, sessionId, roomId, supportMode` |
| 回顾已分享 | `summary_advise` | `orderId, sessionId, draftId` |
| 回顾已读、待评价 | `for_evaluate_middle` | `orderId, counselorId` |

咨询师专用 `for_summary_middle` 不得下发或展示给用户。

## 七节点演示数据

订单页和消息页使用同一组七位咨询师，方便 Builder 逐项核对状态、操作和 IM 卡片：

| 当前节点 | 咨询师 | 订单 | IM 卡片/提示 |
| --- | --- | --- | --- |
| 支付 | 林小满 | `mock_order_1001` | 预约申请已创建、待支付 |
| 咨询师确认 | 陈安之 | `2003` | 等待咨询师确认 |
| 前序资料 | 苏晚晴 | `2004` | 预约已确认、资料待填写 |
| 咨询室 | 韩青梧 | `2006` | 咨询室已开放、进入咨询室 |
| 等待回顾 | 沈知遥 | `2007` | 咨询已结束、等待咨询师整理 |
| 查看回顾 | 顾一帆 | `2008` | 本次咨询回顾、查看详情 |
| 评价 | 白鹭洲 | `2009` | 回顾已查看、评价本次咨询 |

## Builder 接口建议

- `GET /client/orders`：返回列表及确定性的 `currentNode`。
- `GET /client/orders/:orderId`：返回订单、SKU、排期、会话与当前操作。
- `POST /orders/:orderId/intake`、`POST /orders/:orderId/intake/skip`。
- `POST /sessions/:sessionId/join`、`POST /sessions/:sessionId/leave`。
- `GET /sessions/:sessionId/recap`：只返回用户可见回顾，不得返回完整转录、咨询师私密笔记或临床总结。
- `PUT /sessions/:sessionId/recap/read`。
- `POST /orders/:orderId/review`：按订单幂等。

所有状态迁移应在服务端事务内同时更新任务、订单投影和 IM outbox；客户端 Mock 仅用于 Builder 前的演示。
