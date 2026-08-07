# 咨询业务闭环与会后复盘工作台设计

## 1. 背景

当前咨询师端在会议结束后通过 `open-ai-summary` 自定义事件关闭会议并回到首页，再打开 `AISummaryModal`。这条链路存在四个断点：

1. 会中的实时转录、AI 洞察和咨询师笔记只是 `VoiceCall` 内部的静态展示，没有成为总结输入。
2. `AISummaryModal` 使用固定速记文案生成总结，保存时只将订单标记为 `hasSummary`，没有保存总结正文和版本。
3. 工作台虽能根据 `completed && !hasSummary` 生成“待写小结”，但 IM 没有与它共享的总结卡片和任务状态。
4. 财务页仍按“服务结束后 T+1”描述结算，没有表达“总结正式提交后才进入 T+1 结算”的门槛。

本设计先完成前端可演示的完整业务闭环、Mock 状态流转和 Builder 所需的数据/接口说明，不接真实后端、真实转录或音视频供应商。

## 2. 目标

- 将用户预约、咨询师确认、可选前序材料、会中记录、会后总结与分享、双方评价组织成一条可追踪的业务状态流。
- 会议结束后立即打开独立的“咨询复盘”页面，不再返回首页后弹出临时 Modal。
- 支持“保存草稿并返回”，并能从工作台待办、咨询师 IM 卡片、订单详情和收入明细恢复同一份草稿。
- 咨询师正式提交总结后，统一完成待办、更新 IM 卡片、归档咨询记录、向用户发送可见版回顾并解锁 T+1 结算。
- 明确内部临床内容和用户可见内容的权限边界。
- 为 Builder 提供可直接实现的状态、类型、库表、接口、幂等和权限参考。

## 3. 非目标

- 不接入真实语音识别、说话人分离或流式 AI 服务。
- 不实现真实消息推送、支付清分、定时结算任务或数据库持久化。
- 不实现督导审批、多咨询师协作或争议仲裁。
- 不将咨询师私密笔记、完整转录、风险判断或临床总结发送给普通用户。

## 4. 产品原则

### 4.1 单一事实源

工作台待办、IM 卡片、订单详情和收入锁定提示不各自保存总结状态。它们只引用同一个 `sessionId`、`draftId` 和 workflow task。所有入口打开同一份 `SessionReviewDraft`。

### 4.2 草稿不阻塞离开，正式提交控制结算

会议结束后，咨询师可以保存草稿并返回。此时待办和 IM 卡片继续显示“待确认”，结算状态保持 `blocked_by_summary`。只有正式提交总结后，结算才转为 `eligible_t1`。

### 4.3 双层内容权限

- 内部层：转录证据、AI 洞察、风险复核、咨询师笔记和临床总结，仅咨询师本人及明确授权督导可见，用户永不可见。
- 用户层：经咨询师确认的咨询回顾、行动建议和下次计划，通过用户 IM 卡片发送。

### 4.4 AI 只生成可追溯草稿

每个 AI 重点必须带来源类型和来源 ID。无转录时明确降级为前序材料、会中笔记和历史记录，不伪造引用。AI 输出必须经咨询师审核后才能成为正式记录。

## 5. 完整业务流

| 阶段 | 用户待办 | 咨询师待办 | 系统动作 | 是否阻塞结算 |
| --- | --- | --- | --- | --- |
| 预约申请 | 提交预约 | 确认/调整/拒绝 | 创建预约 IM 卡片和咨询师待办 | 不适用 |
| 预约确认 | 等待确认结果 | 锁定服务与时段 | 更新双方日程和 IM 状态 | 不适用 |
| 前序材料 | 填写或跳过 | 材料提交后查阅 | 创建可跳过任务；逾期不阻塞进入咨询 | 否 |
| 咨询准备 | 到时进入咨询室 | 查阅材料并进入咨询室 | 双方提醒、创建会话 | 否 |
| 咨询进行中 | 参与会谈 | 记录笔记、查看 Mock 转录/AI 重点、上报风险 | 保存会中草稿 | 否 |
| 会话结束 | 等待咨询回顾 | 审核并提交咨询总结 | 创建唯一的总结待办和 IM 卡片；结算锁定 | 是 |
| 总结分享 | 查看回顾和行动建议 | 确认用户可见版 | 归档正式总结、推送用户卡片、进入 T+1 | 否 |
| 用户评价 | 评价咨询师 | 查看评价结果 | 归档用户评价；不反向阻塞结算 | 否 |

前序材料和用户评价属于业务待办但不是结算门槛。资料未填写时，咨询师的“查阅资料”阶段应标为跳过，并继续开放“开始咨询”。当前 MVP 仅以咨询师提交咨询总结作为结算门槛。

## 6. 状态模型

不继续把所有语义塞入现有 `Order.status`。订单保留预约/服务层状态，并增加独立的会话、总结、任务和结算状态。

### 6.1 会话状态

```ts
type ConsultationSessionStatus =
  | "scheduled"
  | "waiting"
  | "in_progress"
  | "ended";
```

### 6.2 总结状态

```ts
type SessionReviewStatus =
  | "not_started"
  | "ai_generating"
  | "draft"
  | "submitted";
```

### 6.3 结算状态

```ts
type SessionSettlementStatus =
  | "not_applicable"
  | "blocked_by_summary"
  | "eligible_t1"
  | "settled";
```

### 6.4 任务状态

```ts
type WorkflowTaskStatus = "pending" | "in_progress" | "completed" | "skipped";

type WorkflowTaskType =
  | "confirm_booking"
  | "complete_intake"
  | "review_intake"
  | "enter_session"
  | "complete_session_review"
  | "read_session_recap"
  | "review_counselor";
```

状态迁移由纯函数执行，组件不能直接分别修改订单、待办、IM 和结算状态。

### 6.5 咨询师工作台旅程投影

Builder 为每个 `orderId`（会谈结束后关联同一 `sessionId`）返回固定四阶段，而不是把同时存在的底层待办直接暴露给客户端：

| `phase_order` | `task_type` | 标签 |
| --- | --- | --- |
| 1 | `confirm_booking` | 确认预约 |
| 2 | `review_intake` | 查阅资料 |
| 3 | `enter_session` | 开始咨询 |
| 4 | `complete_session_review` | 确认总结 |

每个阶段包含 `phase_order`、`task_id`（跳过时可为 `null`）和 `status: completed | skipped | current | locked`；旅程还返回唯一的 `current_task_id`。未完成旅程必须恰有一个 `current` 节点，之前的节点只能是 `completed` 或 `skipped`，之后的节点必须为 `locked`。未填写前序资料时第二阶段为 `skipped`，第三阶段仍可成为唯一 `current`。全部完成后 `current_task_id` 为 `null`。当前 Mock 可由前端纯函数从订单和 `WorkflowTask[]` 投影；真实后端/Builder 则必须返回该确定性旅程，客户端只渲染状态和唯一当前操作，`workflow_tasks` 仅作为服务端关联明细。

## 7. Mock 数据模型

### 7.1 转录片段

```ts
interface SessionTranscriptSegment {
  id: string;
  sessionId: string;
  speakerRole: "client" | "counselor";
  speakerName: string;
  text: string;
  startsAtSeconds: number;
  endsAtSeconds: number;
  confidence: number;
  highlightTerms: string[];
}
```

### 7.2 AI 重点及来源

```ts
interface SessionInsight {
  id: string;
  sessionId: string;
  category: "topic" | "emotion" | "intervention" | "risk" | "plan";
  title: string;
  detail: string;
  sourceType: "transcript" | "intake" | "note" | "history";
  sourceIds: string[];
  confidence: number;
}
```

### 7.3 复盘草稿

```ts
interface SessionReviewDraft {
  id: string;
  sessionId: string;
  orderId: string;
  clientId: string;
  counselorId: string;
  status: SessionReviewStatus;
  version: number;
  sourceSnapshot: {
    transcriptSegmentIds: string[];
    insightIds: string[];
    intakeAvailable: boolean;
    priorRecordIds: string[];
  };
  clinicalSummary: {
    mainConcern: string;
    clientState: string;
    interventions: string[];
    observations: string;
    riskReview: string;
    nextPlan: string;
  };
  clientSummary: {
    recap: string;
    actionItems: string[];
    nextPlan: string;
  };
  updatedAt: string;
  submittedAt?: string;
}
```

专业自评是未来督导/咨询师成长功能的扩展字段。当前 MVP 即使为旧草稿兼容而保留该字段，也不在页面展示、不参与校验、不生成待办、不随总结提交，也不影响结算；未来应以独立、受督导授权的资源/API 建模，而非回填为当前总结的必填字段。

### 7.4 业务待办

```ts
interface WorkflowTask {
  id: string;
  actorRole: "client" | "counselor";
  actorId: string;
  taskType: WorkflowTaskType;
  status: WorkflowTaskStatus;
  blockingSettlement: boolean;
  orderId: string;
  sessionId?: string;
  draftId?: string;
  dueAt?: string;
  createdAt: string;
}
```

### 7.5 IM 系统卡片

```ts
interface SummaryMessageCard {
  messageType: "summary_card";
  audience: "counselor" | "client";
  sessionId: string;
  draftId: string;
  status: "pending_review" | "submitted" | "shared";
  title: string;
  description: string;
  actionLabel: string;
}
```

IM 卡片只保存引用和展示摘要，不复制完整临床内容。

## 8. 复盘工作台设计

### 8.1 入口

1. 会议结束后的主入口：结束会话后立即打开。
2. 工作台“待确认咨询总结”待办。
3. 咨询师 IM 的系统总结卡片。
4. 订单详情中的“撰写/继续/查看总结”。
5. 收入明细中 `blocked_by_summary` 行旁的“去完成总结”。

本地 Demo 使用 `App` 内的 `activeSessionReviewId` 打开全屏页面。Builder 实现时对应逻辑路由 `/counselor/sessions/:sessionId/review`，支持刷新和深链接恢复。

### 8.2 页面结构

- Material 3 顶部应用栏：返回、标题、来访者/次数、草稿状态。
- 结算状态横幅：解释当前为何锁定以及提交后的 T+1 规则。
- 三个内容区：AI 证据、临床总结、用户分享。
- AI 证据区：数据来源状态、重点标签、带时间戳的转录引用、会中笔记和历史连续性。
- 临床总结区：核心议题、身心状态、干预方式、观察、风险复核、下次计划。
- 用户分享区：仅用户可见的回顾、行动建议、下次计划及发送预览。
- Material 3 底部操作栏：`保存草稿并返回`、`正式提交总结`。

移动端采用单列和横向滚动分段按钮；宽屏采用左侧证据、右侧编辑的双栏布局。所有编辑自动写入 Mock store，页面退出前再执行一次显式保存。

### 8.3 提交流程

正式提交前校验：

- 核心议题、干预方式、咨询师观察、风险复核和下次计划完整。
- 用户可见回顾、至少一条行动建议和下次计划完整。
- 咨询师确认用户可见内容不包含私密笔记、诊断性标签或风险内部判断。

确认对话框展示两项结果：“用户可见版将发送”和“提交后进入 T+1 结算”。提交后仍可查看；未来 Builder 需要通过新版本修订而不是覆盖历史版本。

## 9. 入口与后续联动

### 9.1 会议结束

`VoiceCall` 不再关闭后派发全局 `open-ai-summary` 事件。它通过显式的 `onSessionEnded(order, sessionSnapshot)` 回调交给 `App`：

1. 将会话置为 `ended`。
2. 将结算置为 `blocked_by_summary`。
3. 创建或复用一份复盘草稿。
4. 创建咨询师复盘待办和 IM 卡片。
5. 打开 `SessionReviewWorkspace`。

### 9.2 保存草稿

- 保存草稿、完成度和来源快照。
- 返回工作台。
- 待办和 IM 卡片保持 `pending_review`。
- 结算保持锁定。

### 9.3 正式提交

必须通过一个原子状态迁移完成：

1. 草稿转为 `submitted` 并生成正式版本。
2. 唯一的 `complete_session_review` 咨询师任务转为完成。
3. 咨询师 IM 卡片原位更新为“总结已提交”。
4. 用户 IM 新增仅包含 `clientSummary` 的回顾卡片。
5. 来访者档案和咨询记录新增正式记录。
6. 结算从 `blocked_by_summary` 转为 `eligible_t1`。
7. 创建用户评价咨询师待办和用户查看回顾待办。

用户是否阅读或评价不影响结算。

## 10. IM 与待办设计

### 10.1 咨询师 IM

- 会话结束：推送“本次咨询总结待确认”，显示草稿完成度、结算锁定和“打开复盘”。
- 保存草稿：同一卡片更新完成度，不新增重复消息。
- 正式提交：同一卡片更新为“总结已提交 · T+1 结算中”，动作变为“查看已归档总结”。

### 10.2 用户 IM

- 正式提交后推送“本次咨询回顾”，包含回顾、行动建议和下次计划。
- 卡片提供“查看完整回顾”和“评价咨询师”。
- 不展示临床总结、完整转录、私密笔记、风险判断或任何未来督导成长扩展内容。

### 10.3 工作台待办

当前 Mock 可由前端纯函数从 `WorkflowTask[]` 投影工作台，不再仅靠 `completed && !hasSummary` 临时计算。真实后端/Builder 必须将固定 `phase_order`、唯一 `current_task_id` 和阶段状态作为工作台唯一数据源返回；客户端只渲染该 journey，`WorkflowTask` 仅作为服务端关联明细。复盘任务显示来访者、会话时间、草稿完成度、结算锁定状态和继续填写入口。

## 11. Mock 状态管理

在 Zustand store 增加：

- `consultationSessions`
- `sessionTranscripts`
- `sessionInsights`
- `sessionReviewDrafts`
- `workflowTasks`
- `conversationMessages`
- `sessionSettlementStates`

核心 action：

- `endConsultationSession(sessionId, snapshot)`
- `ensureSessionReviewDraft(sessionId)`
- `saveSessionReviewDraft(draftId, patch)`
- `submitSessionReview(draftId)`
- `getWorkflowTasks(actorRole, actorId)`
- `getConversationMessages(orderId, audience)`

状态迁移逻辑放在独立纯函数模块中，由单元测试覆盖。React 组件只触发 action 和渲染派生状态。

## 12. 异常与降级

- 无转录：显示“本次无可用转录”，AI 证据改用前序材料、会中笔记和历史记录；允许手写总结。
- AI 生成失败：保留所有输入，显示可重试状态；手写路径始终可用。
- 草稿保存失败（Builder 阶段）：保留本地未提交更改并重试，不能静默返回首页。
- 提交校验失败：定位到缺失分区，保留当前内容，不改变待办或结算状态。
- 重复提交：Mock 纯函数和 Builder API 都按 `draftId + version` 幂等，不重复创建消息、任务或账单事件。
- 并发编辑（Builder 阶段）：使用版本号做乐观锁，冲突时提示刷新，不覆盖其他版本。

## 13. 隐私与权限

- 咨询师只能访问与自己存在有效服务关系的会话。
- 转录、私密笔记、临床总结和风险复核只能由咨询师本人及明确授权督导读取，用户永不可见。
- 用户只读取自己会话的 `clientSummary`。
- AI 草稿和正式提交都保留来源、编辑人、提交人和版本审计。
- IM `summary_card` 根据 `audience` 生成内容，不能由前端隐藏字段来替代后端字段级授权。

## 14. Builder 后端参考增量

在现有 `docs/builder-backend-reference.md` 基础上补充：

### 14.1 新增或细化表

- `workflow_tasks`：actor、task_type、status、blocking_settlement、entity refs、due_at；会谈结束仅创建 `complete_session_review` 这一项咨询师任务。
- 咨询师旅程投影：每笔 order/session 返回固定四阶段 `phase_order`、节点的 `completed`/`skipped`/`current`/`locked` 状态，以及唯一 `current_task_id`。
- `session_review_drafts`：session、status、version、source_snapshot_json、临床总结和用户回顾两个 MVP 内容分区、updated_at、submitted_at。
- `session_summary_versions`：正式版本、提交人、用户可见内容、内部加密内容、审计信息。
- `settlement_holds`：order、reason=`summary_required`、status、released_at、release_event_id。
- `messages.metadata_json`：summary card 的 sessionId、draftId、audience、status、action。

### 14.2 新增或细化接口

- `POST /sessions/:id/end`
- `GET /sessions/:id/review`
- `PUT /sessions/:id/review/draft`
- `POST /sessions/:id/review/submit`
- `GET /workflow/tasks?actor=me&status=pending`
- `GET /counselor/journeys?status=`
- `POST /workflow/tasks/:id/complete`
- `GET /threads/:id/messages`
- `POST /orders/:id/reviews`
- `GET /orders/:id/settlement-status`

提交接口在同一事务中写正式总结、完成任务、更新/创建 IM 卡片、归档记录并释放结算锁。使用 `Idempotency-Key` 防止重复提交。

## 15. 测试与验收

### 15.1 单元测试

- 会话结束创建草稿、咨询师待办、IM 卡片和结算锁。
- 保存草稿不完成任务、不发送用户卡片、不解锁结算。
- 正式提交一次性完成所有下游联动。
- 缺少临床总结或用户回顾必填字段时拒绝提交并保持原状态。
- 重复提交不重复创建消息、任务或结算事件。
- 咨询师视图能读取内部内容，用户视图只能读取 `clientSummary`。

### 15.2 浏览器验收

1. 从会议室结束咨询，直接进入复盘工作台。
2. 查看 Mock 转录、AI 重点、会中笔记和前序材料来源。
3. 保存草稿返回首页，工作台和咨询师 IM 均存在待确认入口。
4. 从两个入口分别恢复，内容和完成度一致。
5. 正式提交后，待办消失、咨询师 IM 卡片更新、咨询记录新增、收入状态进入 T+1。
6. 切换用户端，用户 IM 只出现可见版回顾，并生成评价待办。
7. 完成用户评价，并确认其不改变已由总结提交解锁的结算状态。
8. 浏览器控制台无 React、DOM、类型或运行时错误。

## 16. 实施边界

本轮实现前端 Mock 的可演示主链路，并更新 Builder 文档。优先复用现有 `VoiceCall`、工作台、订单详情、`ChatDrawer`、用户 `TextChat` 和收入页；用新的 `SessionReviewWorkspace` 替代当前首页 `AISummaryModal` 流程。现有 AI `/api/ai/session-summary` 可用于生成草稿，但数据来源在 Mock 阶段由前端固定转录、笔记和前序材料组装。
