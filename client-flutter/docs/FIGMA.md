# Figma 高保真 UI 实现规范

本文件从 `AGENTS.md` 拆出，仅在涉及 Figma / 高保真 UI 实现时按需读取，避免每次会话全量加载。

> 本项目（心愈 / Xinyu，Flutter）的设计 token 与资源命名由 iOS 原生工程 `HeartHealing` 迁移而来，故 `lib/core/theme/` 代码注释常带 iOS 出处（`XYHomeStyle`、`UIFont`、`SnapKit` 等）。**实现时一律以 Flutter token 为准，不照搬 iOS 写法。**

## 设计 token（先查 token，再谈 ÷2）

颜色 / 尺寸 / 字号 / 资源路径已沉淀在 `lib/core/theme/`，**且其中数值已经做过 ÷2**：

| 文件 | 类 | 用途 |
|---|---|---|
| `app_colors.dart` | `AppColors` | 颜色：`textPrimary`/`textSecondary`/`textTertiary`、`brandTeal`(#00A6A1)、`accentTeal`(#00BBC8)、`indigo`、`priceRed`、`cardBackground`、`divider`、`consultVoice`/`consultVideo` … |
| `app_dimens.dart` | `AppDimens` | 尺寸/间距/圆角：`screenPadding`/`sectionGap`/`cardPadding`/`cardRadius`/`cardRadiusLarge`、`gap4..gap20`、`buttonHeight`/`buttonRadiusCapsule`、`radiusTag`/`radiusConsultTag`/`radiusMedium` … |
| `app_text_styles.dart` | `AppTextStyles` | 文字：`displayLarge`/`title`/`titleMedium`/`titleLarge`/`body`/`bodyLarge`/`caption`/`label`/`price`/`codeDigit`…（系统字体；字重惯例：semibold 标题、regular 正文、bold 价格） |
| `app_assets.dart` | `AppAssets` | 图片路径常量（由 `xinyu/scripts/migrate_ios_assets.py` 从 iOS xcassets 生成） |

- **能用 token 就直接用，不要再 ÷2**：`AppDimens.cardRadius`(=12) 已是 Figma 24÷2，直接写 `AppDimens.cardRadius`，**禁止** `AppDimens.cardRadius / 2`。
- **颜色禁止硬编码 hex**：一律走 `AppColors`；设计稿出现新颜色时，先加进 `app_colors.dart` 再引用。
- **图片路径禁止散落字面量**：一律走 `AppAssets.xxx`（项目无 `lib/common/assets.dart`，不要新建）。

## 核心规则

- 所有尺寸（字体、间距、圆角、图标宽高、frame）= **Figma 标注值 ÷ 2**。设计稿按 @2x 标注，Flutter 逻辑像素（`double`）即 Figma px ÷ 2。**例外**：取自 `AppDimens`/`AppTextStyles` 的值已 ÷2。
- 布局用 Flutter（`Row`/`Column`/`Stack` + `EdgeInsets`/`SizedBox`/`Expanded`/`FractionallySizedBox`/`AspectRatio`），取值优先 `AppColors`/`AppDimens`/`AppTextStyles`，不硬编码。
- 项目**无通用卡片/按钮/间距组件库**：每个 feature 用 token 自行组合，不要假设存在 `CommonCard`/`Spacing` 之类组件。
- 图标/图片从 Figma MCP 返回的 asset URL 下载（见下），不引入新图标库、不引入新字体。
- Figma 值无对应 token 时，手动 ÷2 并注释来源，如 `radius: 9, // Figma 18 → 9`。

## Figma MCP 限流（每会话每 node 1 次）

计数键：`fileKey + nodeId`。`get_figma_data`、`download_figma_images` 等读工具共享计数。

- **同一 `fileKey + nodeId`，本会话内 `get_figma_data` 只调 1 次**；返回的设计树/截图/asset URL 视为缓存，写代码、改 UI、验收、修 bug 均复用。
- node-id 未变时（追问尺寸/颜色/对齐、重复粘贴链接、改代码失败）**不重拉**，先读代码常量、`AppAssets`、已有 context。
- 仅当 node-id 变化或首轮失败（429 读 `Retry-After` 等待后重试 1 次）才可再调。
- 整页过大时先按子节点拆分，再对每个不同子 node 各调 1 次。
- 调用顺序：`get_figma_data（逐块）→ 一次性 download_figma_images → 写代码 → 用已存截图验收`。
- 禁止并行批量调用 Figma MCP 读工具。

## 图标与图片资源

- **PNG 优先，禁止 SVG 切图**：项目**未引入 `flutter_svg`**；`assets/images/` 下现存 `.svg` 均用 PNG 兜底 / 内置图标近似（见 `chat_input_bar.dart` 的 `.svg` 分支、`counselor_widgets.dart` 注释，视觉差异已记录）。新切图一律从 Figma 导出 PNG。
- **只下载 @2x 一份图**：设计稿本身按 @2x 标注，`download_figma_images` 用 **pngScale:1**（= Figma 原生像素，即 @2x），导出单张 PNG 放入 `assets/images/`（基础目录），**不建 `2.0x/`/`3.0x/`、不提供 1x/3x**；显示时按 ÷2 逻辑尺寸渲染（如 116px 图 → 58pt）。`pubspec.yaml` 只声明 `assets/images/` 目录，新增文件无需改 pubspec。
- `assets/images/` 已有同名/同语义资源 → 复用，不重复下载。
- 新图标且无现成资源 → 必须下载；**优先用 `download_figma_images` 直接导出 PNG 切图**（Figma 默认导出即 PNG），禁止先把切图当 SVG 再栅格化。
- 仅当 `download_figma_images` 不可用或明确需矢量时才考虑 SVG，用 macOS Quick Look 栅格化为 PNG：`qlmanage -t -s 160 -o <outdir> icon.svg`；SVG 含 CSS 变量（`var(--fill-0, …)`）渲染失败时替换为固定色值再处理，**不得以无法渲染为由跳过下载**。
- 新增资源后**必须更新 `lib/core/theme/app_assets.dart`**：重跑 `migrate_ios_assets.py`（覆盖生成区），或在文件末尾「手工补充」区块追加（脚本不覆盖手工区块，如 TUIKit / 举报图标）。
- MCP 未返回 URL 或下载失败 → 允许 Material Icon 占位并注释「待补图」，但提交前必须替换为真实 PNG。
- **禁止**在 Figma 实现中用 Material Icon / emoji 长期占位而不下载真实切图。

### iOS 原生层资源（与 Flutter 资源分开）
- AppIcon、LaunchScreen.storyboard 等原生层资源归 `ios/Runner/Assets.xcassets/`，不进 Flutter `assets/images/`。
- Flutter 侧启动图 `launchBg` / `launchContent` 已在 `AppAssets`（PNG）。

## 尺寸与间距（易错点）

- **所有尺寸必须严格按 Figma 标注值 ÷ 2 实现**（字体、行高、图标、间距、圆角、按钮高、卡片内边距）；取自 `AppDimens`/`AppTextStyles` 的除外（已 ÷2）。
- 禁止凭经验估算或目测取值；标题+副标题行高按 Figma 卡片总高 ÷ 行数计算，不得自行压缩。
- 非平凡尺寸用常量或注释标明来源，如 `// Figma 140 → 70`。
