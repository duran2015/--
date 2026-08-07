export type ClientPrimaryTabId = "home" | "ai" | "counselors" | "messages" | "profile";

export function getClientPrimaryTabs(): Array<{ id: ClientPrimaryTabId; label: string }> {
  return [
    { id: "home", label: "首页" },
    { id: "ai", label: "小鹿助手" },
    { id: "counselors", label: "真人咨询" },
    { id: "messages", label: "消息" },
    { id: "profile", label: "我的" },
  ];
}
