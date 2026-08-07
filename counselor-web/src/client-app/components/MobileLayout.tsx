import React from "react";
import { PrivacyPopup } from "./PrivacyPopup";

export function MobileLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="client-root flex h-[100dvh] w-full justify-center overflow-hidden">
      <div className="app-shell client-shell relative flex h-[100dvh] w-full max-w-[520px] flex-col overflow-hidden bg-[#f8f7f2]">
        {children}
        <PrivacyPopup />
      </div>
    </div>
  );
}
