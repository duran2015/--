import express from "express";
import path from "path";
import { createServer as createViteServer } from "vite";
import { GoogleGenAI } from "@google/genai";
import dotenv from "dotenv";
import {
  FixedWindowRateLimiter,
  validateQuoteBody,
  validateSessionSummaryBody,
} from "./server/aiGuard";

dotenv.config();

const app = express();
const PORT = Number(process.env.PORT || 4311);

app.use(express.json({ limit: "32kb" }));

app.use(((error, _req, res, next) => {
  const requestError = error as Error & { status?: number; type?: string };
  if (requestError.type === "entity.too.large") {
    return res.status(413).json({ error: "Request body too large" });
  }
  if (requestError instanceof SyntaxError && requestError.status === 400) {
    return res.status(400).json({ error: "Malformed JSON" });
  }
  return next(error);
}) as express.ErrorRequestHandler);

const aiRateLimiter = new FixedWindowRateLimiter(10, 60_000);
app.use("/api/ai", (req, res, next) => {
  const result = aiRateLimiter.check(req.ip || req.socket.remoteAddress || "unknown");
  if (!result.allowed) {
    res.setHeader("Retry-After", String(result.retryAfterSeconds));
    return res.status(429).json({ error: "Too many AI requests" });
  }
  return next();
});

// Lazy Gemini client helper
let aiClient: GoogleGenAI | null = null;
function getGeminiClient(): GoogleGenAI | null {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || apiKey === "MY_GEMINI_API_KEY") {
    return null;
  }
  if (!aiClient) {
    aiClient = new GoogleGenAI({ apiKey });
  }
  return aiClient;
}

// API: Health check
app.get("/api/health", (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// API: AI Session Summary Assistant
app.post("/api/ai/session-summary", async (req, res) => {
  try {
    const validation = validateSessionSummaryBody(req.body);
    if (validation.ok === false) {
      return res.status(400).json({ error: "Invalid request", details: validation.errors });
    }

    const { clientName, rawNotes, sessionTopic, sessionNumber } = validation.value;
    const ai = getGeminiClient();

    if (ai) {
      const response = await ai.models.generateContent({
        model: "gemini-2.5-flash",
        contents: `你是一位专业且温暖的心理咨询师助手。请根据咨询师在第 ${sessionNumber || 1} 次咨询中记录的草稿信息，整理一份结构严谨、富有共情力的【咨询结案小结】。

来访者：${clientName || "来访者"}
咨询主题：${sessionTopic || "情绪疏导"}
咨询师随手记录：${rawNotes || "聊到了工作压力、失眠情况、与上司沟通障碍。情绪有所释放。"}

请输出 JSON 格式（严格遵守 JSON 语法）：
{
  "clientMood": "情绪状态简述（例如：初段焦虑伴抑郁，中后段呼吸放缓、情绪渐趋平稳）",
  "mainComplaint": "主诉与核心议题概括（2-3句）",
  "interventions": ["使用的技术/干预策略1", "干预策略2", "干预策略3"],
  "insights": "来访者觉察与突破",
  "homework": "课后觉察练习/家庭作业建议",
  "nextPlan": "下一次咨询方向建议"
}`
      });

      const text = response.text || "";
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return res.json({ success: true, summary: JSON.parse(jsonMatch[0]) });
      }
    }

    // Fallback template response if Gemini isn't configured or returns plain text
    res.json({
      success: true,
      summary: {
        clientMood: "会谈前半段伴有明显躯体化紧绷（肩颈发紧），伴随对答节奏加快；后半段通过呼吸练习，情绪降温至 4/10 稳定水平。",
        mainComplaint: `来访者 ${clientName || "来访者"} 主要围绕【${sessionTopic || "职场焦虑与人际沟通"}】展开，表达了近期在工作决策中的不确定感与对负面评价的过度担忧。`,
        interventions: [
          "应用人本主义共情技术，无条件积极关注并确认其情绪合理性",
          "引导做 4-7-8 腹式呼吸躯体放松，观察躯体紧绷部位",
          "采用 CBT 认知重建，识别“非黑即白”的灾难化认知思维"
        ],
        insights: "来访者首次意识到“必须完美”的要求源于童年期对认可的渴望，学会建立心理边界。",
        homework: "每日记录 1 次【情绪触发事件点与身体感受】，下次带回讨论。",
        nextPlan: "巩固自我关怀习惯，深入探索亲密关系/职场中的边界建立。"
      }
    });
  } catch (error: any) {
    console.error("Error generating session summary:", error);
    res.status(500).json({ error: "Failed to generate summary" });
  }
});

// API: AI Social Viral Quote Generator
app.post("/api/ai/generate-quote", async (req, res) => {
  try {
    const validation = validateQuoteBody(req.body);
    if (validation.ok === false) {
      return res.status(400).json({ error: "Invalid request", details: validation.errors });
    }

    const { topic, consultantName } = validation.value;
    const ai = getGeminiClient();

    if (ai) {
      const response = await ai.models.generateContent({
        model: "gemini-2.5-flash",
        contents: `请为心理咨询师 ${consultantName || "咨询师"} 生成 3 句温暖、治愈、具有社交裂变传播力的【朋友圈心理学金句】。
主题方向：${topic || "允许自己不完美/缓解焦虑/亲密关系边界/自我关怀"}

输出 JSON 格式：
{
  "quotes": [
    { "title": "短标题1", "quote": "温暖金句内容1", "tag": "主题标签1" },
    { "title": "短标题2", "quote": "温暖金句内容2", "tag": "主题标签2" },
    { "title": "短标题3", "quote": "温暖金句内容3", "tag": "主题标签3" }
  ]
}`
      });

      const text = response.text || "";
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return res.json({ success: true, data: JSON.parse(jsonMatch[0]) });
      }
    }

    // Fallback response
    res.json({
      success: true,
      data: {
        quotes: [
          {
            title: "允许情绪如云飘过",
            quote: "情绪不是需要被解决的敌人，而是内心理所当然的信使。允许自己悲伤，就像允许阴雨自然落下。",
            tag: "情绪接纳"
          },
          {
            title: "收回向外索求的目光",
            quote: "最深沉的关怀，往往来自你第一次对自己说：即使今天什么都没做好，我也值得被温柔对待。",
            tag: "自我关怀"
          },
          {
            title: "温柔而坚定的边界",
            quote: "拒绝别人并不意味着你冷漠，而是你在为自己的心理能量筑起一座温暖的花园。",
            tag: "边界探索"
          }
        ]
      }
    });
  } catch (error: any) {
    console.error("Error generating quote:", error);
    res.status(500).json({ error: "Failed to generate quote" });
  }
});

// Vite middleware for development vs. production static build
async function startServer() {
  // The production deliverable contains the real Flutter client under /client/.
  // Keep this route ahead of Vite's SPA fallback so /client never renders the
  // retired React client prototype.
  const flutterClientPath = path.join(
    process.cwd(),
    process.env.NODE_ENV === "production" ? "dist/client" : "public/client",
  );
  app.get(/^\/client$/, (_req, res) => res.redirect(302, "/client/"));
  app.use("/client", express.static(flutterClientPath));
  app.get("/client/*", (_req, res) => {
    res.sendFile(path.join(flutterClientPath, "index.html"));
  });

  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: {
        middlewareMode: true,
        hmr: process.env.DISABLE_HMR === "true" ? false : undefined,
      },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), "dist");
    app.use(express.static(distPath));
    app.get("*", (req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on http://0.0.0.0:${PORT}`);
  });
}

startServer();
