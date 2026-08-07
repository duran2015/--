# Builder 后端与数据补全参考

## 1. 文档用途

当前仓库以界面和交互演示为主，大部分业务数据来自 TypeScript Mock、Zustand 内存状态、组件局部数组和 `localStorage`。本文供 Builder 在后续接入真实数据时参考，目标是说明：

- 前端目前展示了哪些业务对象；
- Mock 数据分别位于哪里；
- 推荐如何规范化为后端资源和库表；
- 页面动作需要哪些接口、权限和实时通道；
- 应按什么顺序替换 Mock，避免一次性重写整个前端。

本文是实现参考，不代表这些后端能力已经存在。当前真实服务端仅包含健康检查和两个 AI 辅助接口。

## 2. 当前真实接口

| 方法 | 路径 | 状态 | 说明 |
| --- | --- | --- | --- |
| `GET` | `/api/health` | 已实现 | 服务健康检查 |
| `POST` | `/api/ai/session-summary` | 已实现 | 生成咨询小结；无 Gemini 密钥时返回演示数据 |
| `POST` | `/api/ai/generate-quote` | 已实现 | 生成咨询师传播文案；无 Gemini 密钥时返回演示数据 |

两个 AI 接口目前共享单进程限流：每个来源 IP 在固定 60 秒窗口内最多 10 次；JSON 请求体最大 32 KB。该限流只适合单机演示，将来多实例部署时应改为 Redis 或网关限流。

## 3. Mock 数据来源清单

| 来源 | 当前内容 | 后端替换目标 |
| --- | --- | --- |
| `src/types.ts` | B/C 两端主要业务类型 | API DTO 与数据库模型的参考，不应直接当数据库 Schema |
| `src/client-app/store.ts` | 登录态、角色、用户、订单、评估、通话、AI 设置 | 服务端会话与各领域 API；仅页面导航状态继续留在前端 |
| `src/client-app/data.ts` | 用户、量表记录、订单、咨询师、咨询记录、通知 | 用户、评估、订单、咨询师、会话、消息、通知接口 |
| `src/data/mockData.ts` | 来访者档案、咨询师、订单、商品、结算、优惠券、银行卡、提现、账单 | 咨询师工作台和财务领域接口 |
| `src/client-app/pages/Main/AITab.tsx` | AI 对话、危机关键词、练习和建议的本地规则 | AI 会话、消息、风险评估、工具推荐接口 |
| `src/client-app/pages/Counseling/TextChat.tsx` | 会话消息、系统卡片、模拟自动回复 | 会话线程、消息、已读状态、系统事件和实时推送 |
| `src/client-app/pages/Main/HomeTab.tsx` | 情绪、日历趋势和推荐任务 | 每日状态记录、趋势聚合、任务推荐接口 |
| `src/components/Growth/*` | 选题、内容、发布计划、私域线索 | 内容资产、发布计划、线索、转化统计接口 |
| `src/components/Schedule/ScheduleTab.tsx` | 日历和档期交互状态 | 可用时间规则、时段、预约接口 |
| `src/components/Profile/IncomeView.tsx` | 银行卡、账单、提现 | 财务台账、结算、收款账户、提现接口 |
| `src/consultationWorkflow.ts` | 预约到评价的演示状态机、待办、IM 卡片、总结提交和结算门禁 | 后端领域服务与事务规则的直接参考 |
| `src/consultationWorkflowMock.ts` | 实时转录、咨询师随手记、AI 洞察和 AI 总结草稿 | 音视频转录、笔记、洞察和总结生成服务 |
| `src/components/SessionReview/SessionReviewWorkspace.tsx` | 咨询师复盘工作台，区分内部记录和用户可见回顾 | 复盘查询、草稿保存、提交归档和消息推送接口 |

组件内部的展开/关闭、当前 Tab、输入框内容、动画阶段等纯 UI 状态无需进入数据库。

## 4. 统一业务状态

当前 Mock 中存在多套订单状态：`pending_confirm`、`scheduled`、`in_progress`、`paid`、`pending`、`active`、`failed` 等。后端落库前应统一为下列状态机，前端可临时用映射函数兼容旧值。

```text
draft
  -> pending_payment
  -> paid
  -> pending_confirm
  -> scheduled
  -> in_progress
  -> completed

任何可取消阶段 -> cancelled
已付款订单 -> refund_pending -> refunded
支付失败 -> payment_failed
```

状态变更必须由动作接口完成，不允许客户端直接提交任意 `status`。每次变更写入 `order_status_events`，保存操作者、原状态、新状态、原因和时间。

金额统一以最小货币单位整数存储，例如人民币分；时间统一存 UTC 时间戳，API 返回 ISO 8601；日期和时段额外保存业务时区 `Asia/Shanghai`。

## 5. 建议领域与库表

推荐使用 PostgreSQL。主键建议使用 UUID/ULID；公开订单号、账单号和提现号作为独立唯一业务编号，不直接暴露自增主键。

### 5.1 身份、账号与角色

`users`

- `id`, `phone_country_code`, `phone`, `phone_verified_at`
- `display_name`, `avatar_url`, `account_status`
- `created_at`, `updated_at`, `deleted_at`

`user_roles`

- `user_id`, `role`
- `role`: `client`, `counselor`, `operator`, `finance`, `admin`
- 同一个账号可以同时拥有用户和咨询师身份，对应当前“双角色切换”界面。

`auth_identities`

- `user_id`, `provider`, `provider_subject`
- `provider`: `phone`, `wechat`, `apple`
- 供应商令牌只保存在服务端安全存储，不返回前端。

`user_settings`

- `user_id`, `ai_avatar`, `font_size`, `theme`, `voice`, `auto_play_voice`
- 对应 `AppState.aiSettings`。

`consent_records`

- `id`, `user_id`, `document_type`, `document_version`, `accepted_at`, `ip`, `user_agent`
- 对应隐私弹窗和协议入口；不能只保存一个布尔值。

### 5.2 用户心理档案

`client_profiles`

- `user_id`, `gender`, `birth_date`, `occupation`, `city`
- `status_score`, `status_trend`, `status_summary`
- `risk_level`, `primary_counselor_id`, `intake_at`

`emergency_contacts`

- `id`, `client_id`, `name`, `relation`, `phone_encrypted`

`profile_tags`

- `id`, `name`, `category`

`client_profile_tags`

- `client_id`, `tag_id`, `weight`, `source`, `created_at`
- `source`: `assessment`, `ai`, `counselor`, `self_report`

心理档案、紧急联系人、风险信息和咨询记录属于高敏感数据，建议字段级加密、严格角色授权、访问审计和导出水印。

### 5.3 咨询师、资质与服务商品

`counselor_profiles`

- `user_id`, `title`, `license_no_encrypted`, `experience_years`
- `total_hours`, `total_clients`, `rating`, `verified_status`
- `bio`, `counseling_style`, `is_listening_active`, `work_status`

`counselor_credentials`

- `id`, `counselor_id`, `credential_type`, `title`, `issuer`
- `certificate_no_encrypted`, `issued_at`, `expires_at`, `verification_status`

`counselor_specialties`

- `counselor_id`, `category`, `value`, `sort_order`
- 可承载流派、擅长领域、目标人群、服务类型、工作语言和咨询风格。

`service_products`

- `id`, `counselor_id`, `name`, `service_type`, `duration_minutes`
- `price_minor`, `description`, `published`, `sales_count`
- `service_type`: `video`, `audio`, `text`, `listening`

前端 `ConsultantProfile.earnings`、`referralStats` 和累计数据建议由聚合查询返回，不在咨询师主表重复维护可推导金额。

### 5.4 可用时间与预约

`availability_rules`

- `id`, `counselor_id`, `weekday`, `start_time`, `end_time`
- `slot_minutes`, `effective_from`, `effective_to`, `status`

`availability_exceptions`

- `id`, `counselor_id`, `starts_at`, `ends_at`, `reason`, `status`
- 表示休息、请假、临时加班和封锁时段。

`appointment_slots`

- `id`, `counselor_id`, `service_product_id`, `starts_at`, `ends_at`
- `status`: `available`, `held`, `booked`, `blocked`
- `hold_expires_at`, `version`

下单时必须通过数据库事务或带版本号的条件更新占用时段，避免两个用户同时购买同一档期。

### 5.5 订单、支付与退款

`orders`

- `id`, `order_no`, `client_id`, `counselor_id`, `service_product_id`, `slot_id`
- `status`, `price_minor`, `discount_minor`, `payable_minor`, `currency`
- `complaint_topic`, `client_note`, `consultation_format`
- `created_at`, `confirmed_at`, `started_at`, `completed_at`, `cancelled_at`
- `version` 用于乐观锁。

`order_status_events`

- `id`, `order_id`, `from_status`, `to_status`, `actor_id`, `reason`, `created_at`

`payments`

- `id`, `order_id`, `provider`, `provider_trade_no`, `amount_minor`
- `status`, `paid_at`, `callback_payload_encrypted`
- 支付回调必须验签，并以 `provider_trade_no` 保证幂等。

`refunds`

- `id`, `order_id`, `payment_id`, `amount_minor`, `reason`
- `status`, `provider_refund_no`, `requested_at`, `completed_at`

### 5.6 咨询会话、通话与消息

`consultation_sessions`

- `id`, `order_id`, `session_number`, `session_type`
- `room_id`, `starts_at`, `ends_at`, `duration_seconds`, `status`
- 音视频供应商的房间密钥和临时令牌不落前端 Mock。

`conversation_threads`

- `id`, `order_id`, `client_id`, `counselor_id`, `status`, `last_message_at`

`messages`

- `id`, `thread_id`, `sender_id`, `sender_role`, `message_type`
- `content_encrypted`, `metadata_json`, `client_message_id`, `created_at`
- `message_type`: `text`, `image`, `file`, `system_event`, `summary_card`, `risk_alert`
- `client_message_id` 用于客户端重试幂等。

`message_receipts`

- `message_id`, `user_id`, `delivered_at`, `read_at`

`session_transcripts`

- `id`, `session_id`, `speaker_role`, `content_encrypted`, `starts_at`, `ends_at`

`session_notes`

- `id`, `session_id`, `counselor_id`, `content_encrypted`, `updated_at`, `version`
- 仅咨询师本人和获授权督导可见，不能同步给普通用户。

`session_summaries`

- `id`, `session_id`, `client_visible_content`, `clinical_content_encrypted`
- `ai_draft_json`, `approved_by`, `approved_at`, `created_at`
- AI 输出先作为草稿，由咨询师确认后才进入正式记录。

#### 5.6.1 咨询业务闭环与复盘版本

当前前端已按下面的业务链路做 Mock 状态联动，Builder 应保留相同语义：

```text
用户预约
  -> 咨询师确认
  -> 咨询师查阅前序资料（用户未填写时跳过）
  -> 咨询师开始咨询
  -> 会谈结束并固化转录/笔记/AI 洞察快照
  -> 咨询师确认临床总结和用户回顾
  -> 提交归档并向用户推送回顾卡片
  -> 用户阅读回顾并评价咨询师
  -> 咨询师总结提交后订单进入 T+1 可结算
```

咨询师工作台不可按底层待办的创建顺序自行推断可操作项。Builder 应按每个 `order_id`（会谈结束后同时带上 `session_id`）返回固定的序列化旅程，`phase_order` 永远为：

1. `confirm_booking`（确认预约）
2. `review_intake`（查阅资料）
3. `enter_session`（开始咨询）
4. `complete_session_review`（确认总结）

每个 phase 返回 `phase_order`、`task_type`、`task_id`（跳过时可为 `null`）和投影状态 `completed`、`skipped`、`current` 或 `locked`。未完成旅程必须有且只有一个 `current_task_id`；其前的节点只能是 `completed` 或 `skipped`，其后的节点必须为 `locked`。用户没有填写前序资料时，第二阶段固定投影为 `skipped`，不阻塞第三阶段。全部阶段完成时 `current_task_id` 为 `null`。这是服务端的确定性投影契约，客户端只渲染它，不重新解锁或排序。

`workflow_tasks`

- `id`, `task_type`, `actor_role`, `actor_id`, `order_id`, `session_id`, `review_draft_id`
- `status`: `pending`, `in_progress`, `completed`, `skipped`
- `blocking_settlement`, `due_at`, `completed_at`, `created_at`, `version`
- `task_type`: `confirm_booking`, `complete_intake`, `review_intake`, `enter_session`, `complete_session_review`, `read_session_recap`, `review_counselor`
- 对 `(task_type, actor_id, order_id)` 建唯一索引，事件重放不得制造重复待办。

`complete_intake` 是用户侧资料填写任务，不是咨询师四阶段中的节点；`review_intake` 可在资料缺失时没有实际待办，由旅程投影输出 `skipped`。会谈结束只创建 `complete_session_review` 这一项咨询师待办。

`session_review_drafts`

- `id`, `session_id`, `order_id`, `client_id`, `counselor_id`, `status`, `version`
- `clinical_summary_encrypted`, `client_summary_json`
- `source_snapshot_json`, `created_at`, `updated_at`, `submitted_at`
- `status`: `ai_generating`, `draft`, `submitted`
- `source_snapshot_json` 只保存冻结后的来源 ID 和生成版本；原始转录、笔记、洞察仍使用独立表。

`session_insights`

- `id`, `session_id`, `category`, `title`, `detail_encrypted`, `source_type`
- `source_ids`, `confidence`, `model`, `prompt_version`, `created_at`
- 每条 AI 洞察必须指向转录片段、笔记、前序资料或历史记录，前端才能展示“查看来源”。

`session_summary_versions`

- `id`, `review_draft_id`, `version`, `clinical_summary_encrypted`, `client_summary_json`
- `created_by`, `created_at`, `change_reason`
- 正式提交后不可覆盖旧版本；更正应创建新版本并记录原因。

`settlement_holds`

- `id`, `order_id`, `hold_type`, `status`, `released_at`, `released_by_event_id`, `created_at`
- `hold_type`: `session_review_required`, `risk_review_required`, `refund_pending`
- 会谈结束创建 `session_review_required`；咨询师总结提交事务成功后释放。
- 用户评价不是咨询师结算前置条件，不能因用户未评价长期冻结咨询师收入。

`session_review_drafts` 的两个 MVP 内容字段必须严格分权：

- `clinical_summary_encrypted`：仅咨询师本人及明确授权督导可见；用户、财务、运营永不可见。
- `client_summary_json`：提交后可通过用户 IM 和回顾页展示。

专业自评不是当前 MVP 的草稿字段、待办或提交条件。若为兼容历史草稿暂存了同名数据，MVP API 不读取、不校验、不写入也不展示；未来督导/咨询师成长功能可用独立、仅咨询师本人及明确授权督导可见的扩展资源保存，且绝不进入用户消息、总结提交事务或结算门槛。

### 5.7 评估、风险与危机处理

`assessment_definitions`

- `id`, `code`, `name`, `version`, `questions_json`, `scoring_rule_json`

`assessment_submissions`

- `id`, `definition_id`, `client_id`, `answers_encrypted`, `score`
- `result_level`, `generated_tags_json`, `submitted_at`

`mood_checkins`

- `id`, `client_id`, `mood_score`, `sleep_hours`, `trigger_text_encrypted`, `created_at`

`risk_events`

- `id`, `client_id`, `session_id`, `level`, `event_type`
- `source`, `description_encrypted`, `detected_at`, `status`
- `source`: `assessment`, `ai_keyword`, `counselor`, `user_report`

`risk_actions`

- `id`, `risk_event_id`, `actor_id`, `action_type`, `notes_encrypted`, `created_at`
- 记录联系紧急联系人、转介、报警、持续观察等动作。

最高风险不能仅依赖前端关键词数组。后端应执行规则/模型评估并通知具备权限的人工处理者；所有查看和修改都写审计日志。

### 5.8 AI 会话与推荐

`ai_conversations`

- `id`, `client_id`, `purpose`, `status`, `started_at`, `ended_at`

`ai_messages`

- `id`, `conversation_id`, `role`, `content_encrypted`, `model`, `created_at`

`ai_state_snapshots`

- `id`, `conversation_id`, `clinical_json`, `domain_json`, `phase`, `recommendation_json`
- 对应 `BlackboardState`，用于可追溯的阶段性推荐，不覆盖原始消息。

`recommended_tasks`

- `id`, `client_id`, `task_type`, `title`, `reason`, `status`, `scheduled_for`

AI 请求应记录模型版本、提示词模板版本、调用耗时、Token/费用和安全拦截结果，但日志中不得保存明文敏感对话。

### 5.9 通知、评价与增长

`notifications`

- `id`, `user_id`, `type`, `title`, `preview`, `content`, `read_at`, `created_at`

`reviews`

- `id`, `order_id`, `client_id`, `counselor_id`, `rating`, `tags_json`, `content`, `created_at`
- 每个完成订单最多一条有效评价。

`vouchers`

- `id`, `owner_counselor_id`, `code`, `discount_type`, `discount_value`
- `valid_from`, `valid_to`, `claim_limit`, `enabled`

`voucher_claims`

- `id`, `voucher_id`, `user_id`, `status`, `claimed_at`, `used_order_id`

`referrals`

- `id`, `referrer_id`, `referred_user_id`, `channel`, `converted_order_id`, `created_at`

`content_assets`

- `id`, `counselor_id`, `content_type`, `title`, `body`, `status`, `published_at`

`publish_plans`

- `id`, `content_asset_id`, `channel`, `scheduled_at`, `status`, `external_post_id`

### 5.10 财务、结算与提现

`ledger_entries`

- `id`, `account_owner_id`, `order_id`, `entry_type`, `amount_minor`, `created_at`
- 使用不可变台账记录收入、平台佣金、税费、退款、冻结、解冻和提现。

`settlements`

- `id`, `counselor_id`, `period_start`, `period_end`
- `gross_minor`, `platform_fee_minor`, `tax_minor`, `net_minor`, `status`, `paid_at`

`payout_accounts`

- `id`, `user_id`, `account_type`, `bank_name`
- `account_number_encrypted`, `account_number_masked`, `holder_name_encrypted`, `is_default`

`withdrawals`

- `id`, `withdraw_no`, `counselor_id`, `payout_account_id`, `amount_minor`
- `status`, `requested_at`, `processed_at`, `reject_reason`, `finance_note`

余额必须从台账聚合或受控余额表计算，不能接受前端传入“可提现余额”。

### 5.11 审计与运营

`audit_logs`

- `id`, `actor_id`, `actor_role`, `action`, `resource_type`, `resource_id`
- `ip`, `user_agent`, `metadata_json`, `created_at`
- 重点记录心理档案、会谈记录、风险事件、资质、退款和提现的访问/修改。

`outbox_events`

- `id`, `event_type`, `aggregate_type`, `aggregate_id`, `payload_json`, `published_at`
- 支付成功、预约确认、会话结束等事务内写入，再异步发送通知，避免业务成功但通知丢失。

## 6. 建议 API 清单

统一前缀建议为 `/api/v1`。列表接口使用游标分页；创建/支付/退款/发消息使用 `Idempotency-Key`；更新接口使用 `If-Match` 或请求体版本号。

### 身份与账号

- `POST /auth/phone/send-code`
- `POST /auth/phone/verify`
- `POST /auth/oauth/:provider/callback`
- `POST /auth/logout`
- `GET /me`
- `PATCH /me/profile`
- `GET /me/settings`
- `PATCH /me/settings`
- `POST /me/consents`
- `DELETE /me/account`

### 咨询师与服务

- `GET /counselors`
- `GET /counselors/:id`
- `GET /counselors/:id/services`
- `GET /counselors/:id/availability?from=&to=`
- `GET /counselors/recommendations`
- `PATCH /counselor/profile`
- `POST /counselor/credentials`
- `PATCH /counselor/services/:id`
- `PUT /counselor/availability-rules`
- `POST /counselor/availability-exceptions`

### 订单与支付

- `POST /orders/holds`：短暂锁定时段并返回过期时间。
- `POST /orders`：基于 hold 创建订单。
- `GET /orders`、`GET /orders/:id`
- `POST /orders/:id/confirm`
- `POST /orders/:id/cancel`
- `POST /orders/:id/refunds`
- `POST /payments`
- `POST /payments/:provider/webhook`：公开回调但必须验签。

### 咨询与消息

- `POST /orders/:id/session-token`：校验参与者和时间窗后签发短期房间令牌。
- `POST /sessions/:id/start`
- `POST /sessions/:id/end`
- `GET /threads`
- `GET /threads/:id/messages?cursor=`
- `POST /threads/:id/messages`
- `POST /threads/:id/read`
- `PUT /sessions/:id/notes`
- `POST /sessions/:id/summaries/ai-draft`
- `PUT /sessions/:id/summaries/:summaryId/approve`
- `GET /workflow/tasks?actor=me&status=pending`：返回用户或咨询师当前业务待办。
- `GET /counselor/journeys?status=`：按订单/会谈返回固定四阶段 `phase_order`、节点状态和唯一 `current_task_id` 的服务端投影；客户端不可自行改变顺序或解锁节点。
- `GET /sessions/:id/review`：一次返回草稿、来源快照、权限裁剪后的字段和结算门禁。
- `PUT /sessions/:id/review/draft`：保存临床总结和用户回顾；使用 `If-Match` 处理版本冲突。
- `POST /sessions/:id/review/submit`：正式提交并归档，必须携带 `Idempotency-Key`。
- `GET /sessions/:id/recap`：用户读取已分享的 `client_summary_json`，绝不返回临床记录。
- `POST /workflow/tasks/:id/complete`：只允许完成属于当前操作者且符合前置状态的任务。

### 评估、档案与风险

- `GET /assessments/definitions`
- `POST /assessments/:code/submissions`
- `GET /me/assessments`
- `POST /me/mood-checkins`
- `GET /clients/:id/profile`：咨询师仅能访问与自己存在有效服务关系的来访者。
- `POST /clients/:id/risk-events`
- `POST /risk-events/:id/actions`

### 通知、评价、增长与财务

- `GET /notifications`、`POST /notifications/:id/read`
- `POST /orders/:id/review`
- `GET /counselor/vouchers`、`POST /counselor/vouchers`
- `GET /counselor/content`、`POST /counselor/content`
- `GET /counselor/finance/summary`
- `GET /counselor/finance/ledger`
- `GET /counselor/settlements`
- `GET /counselor/payout-accounts`
- `POST /counselor/payout-accounts`
- `POST /counselor/withdrawals`

### 复盘提交事务边界

`POST /sessions/:id/review/submit` 不能拆成多个由前端串行调用的接口。服务端应在同一数据库事务中：

1. 校验调用者是本次会谈咨询师，草稿版本与 `If-Match` 一致，临床总结和用户回顾两个必填分区完整。
2. 把草稿标记为 `submitted`，写入不可变 `session_summary_versions`。
3. 完成唯一的 `complete_session_review` 咨询师待办。
4. 将咨询师 IM 中“待确认总结”卡片更新为“已归档”。
5. 创建用户 `summary_card` 消息，以及 `read_session_recap`、`review_counselor` 待办。
6. 释放 `session_review_required` 结算冻结，写入 `ledger_entries` 或 T+1 结算候选。
7. 写入 `outbox_events`，事务提交后再异步推送 WebSocket/通知。

相同 `Idempotency-Key` 重试必须返回第一次提交结果，不能重复创建用户消息、待办、归档版本或财务记录。

## 7. 实时通信建议

使用 WebSocket 或托管实时服务，鉴权后按用户订阅，不允许客户端任意指定他人频道。

| 频道 | 事件示例 |
| --- | --- |
| `user:{userId}` | `notification.created`, `order.updated` |
| `thread:{threadId}` | `message.created`, `message.read`, `typing.changed` |
| `session:{sessionId}` | `participant.joined`, `session.started`, `session.ended`, `risk.alerted` |
| `counselor:{counselorId}` | `booking.created`, `booking.cancelled`, `payout.updated` |
| `workflow:{userId}` | `task.created`, `task.completed`, `review.submitted`, `settlement.unblocked` |

每个事件包含 `eventId`、`type`、`occurredAt`、`resourceId`、`version`，客户端按 `eventId` 去重并在断线后通过 REST 补拉。

## 8. 统一响应与错误

建议成功响应：

```json
{
  "data": {},
  "meta": { "requestId": "req_xxx" }
}
```

建议错误响应：

```json
{
  "error": {
    "code": "ORDER_SLOT_CONFLICT",
    "message": "该时段已被占用",
    "fields": []
  },
  "meta": { "requestId": "req_xxx" }
}
```

前端可展示 `message`，日志和客服使用稳定的 `code` 与 `requestId`。服务端日志保留内部错误，不能把堆栈、模型原始错误或支付密钥返回客户端。

## 9. 权限边界

- 用户只能读取自己的档案、订单、消息、评估和通知。
- 咨询师只能读取分配给自己且处于有效服务关系内的来访者资料。
- 咨询师工作笔记默认不对用户可见。
- 用户可见咨询小结必须与临床记录分字段保存。
- 财务人员可处理结算和提现，但不应查看咨询内容。
- 运营人员可查看脱敏聚合指标，不应直接访问会谈原文。
- 风险事件需要专门权限、二次确认和完整审计。
- 所有对象级授权在服务端校验，前端隐藏按钮不能替代权限控制。

## 10. Mock 替换顺序

### 阶段 1：身份和基础资料

1. 接入登录、`GET /me`、角色列表和协议记录。
2. `localStorage` 只保留短期会话标识或由 HttpOnly Cookie 替代。
3. 用 `/me/settings` 替换本地 AI 设置。

### 阶段 2：咨询师、商品和档期

1. 替换 `mockCounselors` 和 `INITIAL_CONSULTANT`。
2. 替换 `INITIAL_SERVICE_PRODUCTS`。
3. 用 availability API 替换咨询师 `schedules` 数组。

### 阶段 3：订单和支付

1. 用服务端 hold/订单替换 `Date.now()` 生成的临时订单号。
2. `orders/addOrder/updateOrder` 改为 API 调用后刷新缓存。
3. 支付成功只信任服务端回调后的订单状态。

### 阶段 4：咨询室和消息

1. 订单详情返回 thread/session 标识。
2. 替换 `mockConsultationRecords` 和 TextChat 的本地自动回复。
3. 接入消息历史、实时消息、已读回执和会话令牌。
4. 接入 `session_transcripts`、`session_notes`、`session_insights`，会谈结束时固化可追溯快照。

### 阶段 4.1：业务待办、复盘与结算门禁

1. 先用 `workflow_tasks` 替换 Zustand 中由订单状态推导的待办。
2. 接入会谈总结查询与版本化草稿保存，确保临床记录和用户回顾分字段授权；专业自评留待未来督导/成长扩展实现。
3. 最后接入原子提交事务，让 IM 双端卡片、用户回顾、评价待办和结算解锁由同一领域事件驱动。

### 阶段 5：评估、档案和风险

1. 替换 `mockAssessmentRecords`、`INITIAL_CLIENT_PROFILES`。
2. 量表答案和评分规则由后端版本化。
3. 把前端危机关键词升级为后端风险事件流程。

### 阶段 6：通知、增长和财务

1. 替换 `mockNotifications`。
2. 替换组件局部的选题、内容、发布计划和线索数组。
3. 最后接入不可变财务台账、结算、银行卡和提现。

## 11. Builder 完成检查表

- [ ] 为每个 API 明确调用角色和对象级授权。
- [ ] 统一订单、支付、退款、提现状态枚举。
- [ ] 金额使用整数最小货币单位，时间使用 UTC。
- [ ] 下单占位和支付回调具备事务与幂等性。
- [ ] 敏感心理数据、联系电话、证件和收款账号加密。
- [ ] 咨询师笔记与用户可见小结分离。
- [ ] 会谈结束会生成复盘草稿、咨询师待办、IM 待确认卡片和结算冻结。
- [ ] 复盘提交是幂等原子事务，同时归档、发卡片、建用户待办并释放结算。
- [ ] 每条 AI 洞察可追溯到转录、笔记、前序资料或历史记录。
- [ ] 用户回顾接口永远不返回临床总结；未来专业自评扩展也不向用户暴露。
- [ ] 咨询师工作台旅程由服务端按固定四阶段返回，含稳定 `phase_order`、唯一 `current_task_id` 和 `completed`/`skipped`/`current`/`locked` 状态。
- [ ] 风险事件、档案访问、退款和提现写审计日志。
- [ ] 列表接口支持分页、筛选和稳定排序。
- [ ] 实时事件支持鉴权、去重和断线补拉。
- [ ] 前端移除 Mock 前已有加载、空态、错误和重试状态。
- [ ] 每替换一个数据源，同时删除对应 Mock import，避免真假数据混用。
- [ ] 生产环境限流迁移到共享存储或 API 网关。
- [ ] AI 输出先进入草稿，经过人工确认后才成为正式记录。

## 12. 明确不属于当前实现的内容

本文没有在当前仓库中创建数据库、认证、支付、音视频、消息队列、对象存储或完整 REST API。Builder 可根据目标云平台选择具体实现，但应维持本文中的领域边界、权限原则、状态机和 Mock 替换顺序。
