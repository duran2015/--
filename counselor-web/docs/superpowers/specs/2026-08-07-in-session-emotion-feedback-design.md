# 咨询室持续情绪反馈设计

## 1. 背景与现状

咨询室当前已有咨询师侧的“AI 咨询助手”，其中“实时情绪洞察”只展示一段固定 Mock 文案，没有时间趋势、识别来源、置信度和显著变化提醒。语音通话已有独立主舞台，视频通话仍使用参与者卡片；两种模式都缺少可持续、低干扰的情绪反馈。

本设计为前端原型和 Builder 提供统一方案：语音通话接入语音情绪识别结果，视频通话接入多模态情绪识别结果，但在产品层统一呈现为“情绪动态”。

## 2. 目标与边界

- 让咨询师在不中断谈话的情况下感知来访者的当前情绪和变化趋势。
- 普通变化静默更新；只有连续多个窗口确认的显著变化才给轻提示。
- 详细证据、趋势和模型状态集中在现有 AI 侧栏。
- 会后把关键情绪片段作为可追溯证据带入“确认总结”。
- 情绪识别仅对咨询师可见，不向来访者展示模型标签。
- 情绪模型是辅助观察，不输出诊断，不单独触发危机告警或自动上报。

暂不接真实识别服务、真实音视频流和后端持久化；先完成可演示的 Mock 状态流转及接口/库表说明。

## 3. 设计原则

1. **低干扰**：主舞台只显示一句当前趋势，不常驻大卡片，不遮挡人脸或头像。
2. **趋势优先**：不根据单个窗口直接改变结论，默认使用最近 3 个有效窗口进行平滑。
3. **表达不确定性**：使用“系统观察到”“可能呈现”等辅助性措辞；低置信度显示“信号不足”，不强行分类。
4. **统一心智**：语音和视频共用交互结构，只在详情中区分识别来源。
5. **风险解耦**：情绪恶化可以建议咨询师关注，但危机风险仍由现有“危机风险上报”独立处理。
6. **可追溯**：每个趋势和关键事件保存时间范围、来源、置信度和模型版本。

## 4. 方案 A：双层反馈

### 4.1 第一层：主舞台状态 Chip

在顶部会议计时器下方增加一个 Material 3 状态 Chip，仅咨询师端显示：

- 默认：`情绪动态 · 平稳`
- 趋势变化：`情绪动态 · 紧张上升`
- 改善趋势：`情绪动态 · 逐渐放松`
- 信号不足：`情绪动态 · 分析中` 或 `情绪动态 · 信号不足`
- 服务异常：`情绪动态 · 暂不可用`

交互规则：

- 点击 Chip 打开 AI 侧栏，并滚动到“情绪动态”卡片。
- 状态更新使用 200–300ms 的淡入/内容切换，不使用闪烁、抖动或强烈色彩跳变。
- 颜色只用于辅助，必须始终配合文字和图标；普通变化不使用错误红色。
- 视频场景不在人脸上画识别框、表情标签或置信度浮层。

### 4.2 语音通话主舞台

- 保留头像、姓名和“正在语音咨询中”的现有结构。
- 可在头像外增加低对比度的情绪趋势环，仅表现趋势变化，不对应临床风险等级。
- 趋势环动画速度缓慢，且在系统“减少动态效果”开启时停止动画。
- 识别来源在主舞台不展开，详情中显示“语音语调”。

### 4.3 视频通话主舞台

- 视频画面保持干净，状态 Chip 仍位于计时器下方。
- 不在视频画面叠加人脸检测框、情绪 Emoji 或连续数值。
- 摄像头关闭后自动降级为语音来源，并在详情中标注“视频信号中断，当前使用语音分析”。
- 识别来源在详情中显示“语音 + 表情 + 姿态”；某一模态不可用时显示实际有效来源。

### 4.4 第二层：AI 侧栏“情绪动态”卡片

将当前“实时情绪洞察”卡片升级为侧栏第一张卡片：

1. 当前状态：如“紧张，近 2 分钟缓慢上升”。
2. 趋势图：展示最近 10 分钟的低密度时间轴，不展示伪精确百分比曲线。
3. 关键节点：如“14:32 紧张持续上升”“14:36 逐渐缓和”。
4. 识别来源：语音模式为“语音语调”；视频模式为当前有效的多模态组合。
5. 可信度：只展示“较高 / 中等 / 信号不足”，不在主界面展示小数。
6. 说明：固定文案“AI 结果仅用于辅助观察，请结合对话内容和专业判断”。

关键节点可点击，定位到同期实时转录片段；会后则定位到“确认总结”的 AI 证据区。

### 4.5 显著变化 Snackbar

只有满足以下条件才显示低干扰 Snackbar：

- 最近 3 个有效窗口方向一致；
- 持续时间达到 60–120 秒；
- 聚合置信度达到服务端配置阈值；
- 同类提醒未处于冷却期。

示例：`系统观察到紧张状态已持续约 2 分钟`，操作按钮为`查看动态`。

Snackbar 不阻塞通话，6 秒后自动消失；同类提醒默认 5 分钟内不重复。情绪模型不得直接弹出危机上报对话框。

## 5. 情绪状态模型

前端展示使用有限、非诊断性的词汇：

```ts
type EmotionLabel =
  | "calm"
  | "tense"
  | "sad"
  | "angry"
  | "fearful"
  | "mixed"
  | "uncertain";

type EmotionTrend =
  | "stable"
  | "rising"
  | "easing"
  | "fluctuating"
  | "insufficient_signal";

type EmotionSignalSource =
  | "voice"
  | "facial_expression"
  | "body_posture";
```

展示文案由 `label + trend` 映射生成，例如：

| 状态 | 主舞台文案 | 侧栏补充 |
| --- | --- | --- |
| `calm + stable` | 情绪平稳 | 当前表达较稳定 |
| `tense + rising` | 紧张上升 | 紧张迹象近 2 分钟持续增强 |
| `sad + stable` | 低落持续 | 低落迹象保持稳定，建议结合谈话判断 |
| `mixed + fluctuating` | 情绪波动 | 多种情绪信号交替出现 |
| `uncertain` | 信号不足 | 环境噪音、遮挡或有效样本不足 |

不得显示“抑郁”“焦虑症”“高危患者”等诊断或身份标签。

## 6. 前端 Mock 演示流

进入正式通话后启动一组可重复的 Mock 窗口：

| 通话时间 | 状态 | 主界面行为 |
| --- | --- | --- |
| 0–20 秒 | 收集中 | Chip 显示“分析中” |
| 20–80 秒 | 平稳 | Chip 静默更新为“情绪平稳” |
| 80–160 秒 | 紧张上升 | 趋势连续更新，不立即提醒 |
| 160 秒 | 紧张持续 | 显示一次 Snackbar，可打开侧栏 |
| 160–240 秒 | 逐渐放松 | Chip 更新，侧栏记录关键节点 |
| 模拟断流 | 信号不足 | 保留上一有效状态并标记过期，随后显示“信号不足” |

语音和视频使用相同时间线，但 `sources` 不同。视频关闭摄像头时，Mock 应演示多模态到语音分析的降级。

## 7. 数据结构

```ts
interface EmotionObservationWindow {
  id: string;
  sessionId: string;
  startsAtSeconds: number;
  endsAtSeconds: number;
  label: EmotionLabel;
  trend: EmotionTrend;
  confidence: number;
  sources: EmotionSignalSource[];
  sourceConfidence: Partial<Record<EmotionSignalSource, number>>;
  modelVersion: string;
  isValid: boolean;
  invalidReason?: "noise" | "occlusion" | "no_face" | "stream_lost";
}

interface EmotionTrendSnapshot {
  sessionId: string;
  currentLabel: EmotionLabel;
  currentTrend: EmotionTrend;
  confidenceBand: "high" | "medium" | "insufficient";
  sources: EmotionSignalSource[];
  sustainedSeconds: number;
  latestWindowAt: string;
  isStale: boolean;
}

interface EmotionSignificantEvent {
  id: string;
  sessionId: string;
  label: EmotionLabel;
  trend: EmotionTrend;
  startsAtSeconds: number;
  endsAtSeconds?: number;
  confidenceBand: "high" | "medium";
  sourceWindowIds: string[];
  notificationShownAt?: string;
}
```

`SessionInsight.sourceType` 后续增加 `emotion_event`，`sourceIds` 引用 `EmotionSignificantEvent.id`，使会中趋势能够进入会后总结证据链。

## 8. Builder 接口建议

### 8.1 实时订阅

```text
WS /v1/consultation-sessions/{sessionId}/emotion-stream
```

事件：

- `emotion.window.created`：原始识别窗口，仅供服务端聚合或调试权限使用。
- `emotion.trend.updated`：前端主舞台和侧栏的主要数据源。
- `emotion.event.created`：满足持续时间和置信度后的关键节点。
- `emotion.stream.status`：`collecting | active | degraded | unavailable`。

前端正常模式只需消费聚合趋势、关键事件和流状态，不依赖高频原始窗口。

### 8.2 查询历史

```text
GET /v1/consultation-sessions/{sessionId}/emotion-trends?from=0&to=600
GET /v1/consultation-sessions/{sessionId}/emotion-events
```

用于断线重连、侧栏时间轴和会后总结证据区。

### 8.3 权限与幂等

- 只有当前会话咨询师、明确授权督导和后端服务账号可读情绪数据。
- 用户端 API 不返回模型标签、趋势或置信度。
- 事件以 `sessionId + providerEventId` 幂等写入。
- 客户端重连后使用最后事件游标补齐，避免重复 Snackbar。

## 9. Builder 库表建议

### `session_emotion_windows`

- `id`, `session_id`, `provider_event_id`
- `starts_at_ms`, `ends_at_ms`
- `label`, `trend`, `confidence`
- `sources_json`, `source_confidence_json`
- `model_version`, `is_valid`, `invalid_reason`
- `created_at`

### `session_emotion_events`

- `id`, `session_id`
- `label`, `trend`, `confidence_band`
- `starts_at_ms`, `ends_at_ms`, `sustained_ms`
- `source_window_ids_json`
- `created_at`

### `session_emotion_streams`

- `session_id`, `mode: voice | multimodal`
- `status: collecting | active | degraded | unavailable | stopped`
- `active_sources_json`
- `last_event_at`, `provider_name`, `model_version`
- `started_at`, `stopped_at`

原始音频、视频帧不写入以上业务表。若供应商要求临时缓存，应由独立的安全与留存策略约束。

## 10. 异常与降级

- 识别启动前：显示“分析中”，不显示虚构结论。
- 网络中断：短时间保留上一状态并标记过期；超过阈值显示“信号不足”。
- 摄像头关闭或遮挡：视频降级到语音，不中断咨询。
- 麦克风静音或长时间无声：显示信号不足，不把沉默推断为某种情绪。
- 服务异常：Chip 显示“暂不可用”，通话功能不受影响，可在侧栏手动重试。
- 数据乱序：按服务端事件时间和游标合并，旧事件不得覆盖新趋势。

## 11. Material 3 与可访问性

- 主状态使用 Assist/Status Chip 形态；详情使用 Filled Tonal Card；显著变化使用 Snackbar。
- 普通状态采用中性色或品牌紫色容器；只有人工风险流程使用错误红色。
- 触控目标不小于 48dp，支持键盘焦点和屏幕阅读器。
- 状态变化通过 `aria-live="polite"` 通知，不频繁朗读每个识别窗口。
- 不仅依赖颜色表达状态，趋势必须有文字和方向图标。
- 尊重 `prefers-reduced-motion`，关闭趋势环和非必要过渡。

## 12. 与会后总结衔接

结束咨询后：

1. 将显著情绪事件转换为 `SessionInsight(category="emotion")`。
2. “确认总结”的 AI 证据区新增“情绪动态”分组。
3. 咨询师可查看事件时间、趋势、来源和同期转录，但不能把模型结论未经确认直接分享给用户。
4. 用户可见总结只保留咨询师主动确认、重新表述后的内容。
5. 情绪事件不影响总结提交和结算状态；服务异常也不阻塞业务闭环。

## 13. 验收标准

- 语音咨询中，咨询师可看到持续变化的情绪 Chip、侧栏趋势和一次符合规则的显著变化提醒。
- 视频咨询中使用相同交互，详情能够显示多模态来源，并可演示关闭摄像头后降级到语音。
- 用户视角不显示任何情绪识别结果。
- 单个低置信度窗口不会触发状态突变或 Snackbar。
- 情绪识别异常不会中断音视频通话、记录、结束会议或总结流程。
- 显著事件可在会后“确认总结”中追溯到时间点和同期转录。
- 页面不在人脸上叠加识别框，不使用诊断性标签，不由模型自动打开危机上报。

