import assert from "node:assert/strict";
import test from "node:test";
import React, { type ComponentProps } from "react";
import { renderToStaticMarkup } from "react-dom/server";

import { Navbar } from "./components/Navbar";
import { INITIAL_CONSULTANT } from "./data/mockData";

test("home header omits the AI quote action and keeps neighboring actions", () => {
  const legacyCompatibleProps = {
    consultant: INITIAL_CONSULTANT,
    onToggleListening: () => undefined,
    onOpenLiveSession: () => undefined,
    onOpenNotifications: () => undefined,
    onOpenAiQuoteModal: () => undefined,
  } as ComponentProps<typeof Navbar>;

  const markup = renderToStaticMarkup(
    React.createElement(Navbar, legacyCompatibleProps),
  );

  assert.doesNotMatch(markup, /生成 AI 金句海报/);
  assert.match(markup, /接单中/);
  assert.match(markup, /消息通知/);
});
