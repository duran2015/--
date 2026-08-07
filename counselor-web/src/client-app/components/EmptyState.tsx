import type { ComponentType } from "react";

type IconProps = { size?: number; className?: string; strokeWidth?: number };

interface EmptyStateProps {
  icon: ComponentType<IconProps>;
  title: string;
  description: string;
  actionLabel?: string;
  onAction?: () => void;
  compact?: boolean;
}

export function EmptyState({
  icon: Icon,
  title,
  description,
  actionLabel,
  onAction,
  compact = false,
}: EmptyStateProps) {
  return (
    <div className={`flex min-h-full flex-col items-center justify-center px-8 text-center ${compact ? "py-10" : "py-16"}`}>
      <div className="relative mb-5 flex h-20 w-20 items-center justify-center rounded-[26px] border border-white bg-gradient-to-br from-primary-light to-[#fff4e4] shadow-[0_14px_34px_rgba(33,53,46,0.08)]">
        <div className="absolute -right-1 -top-1 h-4 w-4 rounded-full border-[3px] border-[#f8f7f2] bg-[#e6ad68]" />
        <Icon size={32} strokeWidth={1.7} className="text-primary" />
      </div>
      <h2 className="mb-2 text-[17px] font-black text-gray-900">{title}</h2>
      <p className="max-w-[260px] text-[13px] leading-6 text-gray-500">{description}</p>
      {actionLabel && onAction && (
        <button
          onClick={onAction}
          className="mt-6 rounded-[16px] bg-primary px-6 py-3 text-[13px] font-bold text-white shadow-[0_10px_24px_rgba(50,116,92,0.2)]"
        >
          {actionLabel}
        </button>
      )}
    </div>
  );
}

export function MissingDataPage({
  icon,
  title,
  description,
  onBack,
  actionLabel = "返回上一页",
}: Omit<EmptyStateProps, "compact" | "onAction" | "actionLabel"> & {
  onBack: () => void;
  actionLabel?: string;
}) {
  return (
    <div className="absolute inset-0 z-[80] flex flex-col bg-[#f8f7f2]">
      <EmptyState icon={icon} title={title} description={description} actionLabel={actionLabel} onAction={onBack} />
    </div>
  );
}
