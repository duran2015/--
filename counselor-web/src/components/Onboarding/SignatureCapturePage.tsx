import React, { useCallback, useEffect, useRef, useState } from 'react';
import { Check, PenLine, RotateCcw, Smartphone, X } from 'lucide-react';

interface SignatureCapturePageProps {
  documentTitle: string;
  signerName?: string;
  onCancel: () => void;
  onConfirm: (signatureDataUrl: string) => void;
}

type Point = { x: number; y: number };

export const SignatureCapturePage: React.FC<SignatureCapturePageProps> = ({
  documentTitle,
  signerName,
  onCancel,
  onConfirm,
}) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const frameRef = useRef<HTMLDivElement>(null);
  const drawingRef = useRef(false);
  const lastPointRef = useRef<Point | null>(null);
  const [hasSignature, setHasSignature] = useState(false);
  const [isPortrait, setIsPortrait] = useState(false);

  const clearCanvas = useCallback(() => {
    const canvas = canvasRef.current;
    const context = canvas?.getContext('2d');
    if (!canvas || !context) return;
    context.clearRect(0, 0, canvas.width, canvas.height);
    setHasSignature(false);
    drawingRef.current = false;
    lastPointRef.current = null;
  }, []);

  const resizeCanvas = useCallback(() => {
    const canvas = canvasRef.current;
    const frame = frameRef.current;
    if (!canvas || !frame) return;

    const rect = frame.getBoundingClientRect();
    const ratio = Math.max(window.devicePixelRatio || 1, 1);
    canvas.width = Math.max(Math.floor(rect.width * ratio), 1);
    canvas.height = Math.max(Math.floor(rect.height * ratio), 1);
    canvas.style.width = `${rect.width}px`;
    canvas.style.height = `${rect.height}px`;

    const context = canvas.getContext('2d');
    if (!context) return;
    context.scale(ratio, ratio);
    context.lineCap = 'round';
    context.lineJoin = 'round';
    context.lineWidth = 4;
    context.strokeStyle = '#161616';
    setHasSignature(false);
  }, []);

  useEffect(() => {
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    const updateOrientation = () => setIsPortrait(window.innerHeight > window.innerWidth);
    updateOrientation();

    const observer = typeof ResizeObserver === 'undefined'
      ? null
      : new ResizeObserver(() => resizeCanvas());
    if (frameRef.current && observer) observer.observe(frameRef.current);
    resizeCanvas();
    window.addEventListener('resize', updateOrientation);
    return () => {
      observer?.disconnect();
      window.removeEventListener('resize', updateOrientation);
      document.body.style.overflow = previousOverflow;
    };
  }, [resizeCanvas]);

  const pointFromEvent = (event: React.PointerEvent<HTMLCanvasElement>): Point => {
    const rect = event.currentTarget.getBoundingClientRect();
    return { x: event.clientX - rect.left, y: event.clientY - rect.top };
  };

  const startDrawing = (event: React.PointerEvent<HTMLCanvasElement>) => {
    event.currentTarget.setPointerCapture(event.pointerId);
    drawingRef.current = true;
    lastPointRef.current = pointFromEvent(event);
  };

  const draw = (event: React.PointerEvent<HTMLCanvasElement>) => {
    if (!drawingRef.current || !lastPointRef.current) return;
    const context = event.currentTarget.getContext('2d');
    if (!context) return;
    const nextPoint = pointFromEvent(event);
    context.beginPath();
    context.moveTo(lastPointRef.current.x, lastPointRef.current.y);
    context.lineTo(nextPoint.x, nextPoint.y);
    context.stroke();
    lastPointRef.current = nextPoint;
    setHasSignature(true);
  };

  const stopDrawing = (event: React.PointerEvent<HTMLCanvasElement>) => {
    if (event.currentTarget.hasPointerCapture(event.pointerId)) {
      event.currentTarget.releasePointerCapture(event.pointerId);
    }
    drawingRef.current = false;
    lastPointRef.current = null;
  };

  const confirmSignature = () => {
    const canvas = canvasRef.current;
    if (!canvas || !hasSignature) return;
    onConfirm(canvas.toDataURL('image/png'));
  };

  return (
    <div className="fixed inset-0 z-[300] bg-[#F4F1EC] text-[#1D1B16]">
      <div className="flex h-full min-h-0 flex-col">
        <header className="flex h-14 shrink-0 items-center justify-between border-b border-[#E4DED5] bg-white px-4">
          <button
            type="button"
            onClick={onCancel}
            aria-label="退出签名"
            className="grid h-10 w-10 place-items-center rounded-full text-[#49454F] transition hover:bg-[#F4EFF4] active:scale-95"
          >
            <X className="h-5 w-5" />
          </button>
          <div className="min-w-0 px-3 text-center">
            <div className="truncate text-[15px] font-bold">在线签名</div>
            <div className="truncate text-[10px] text-[#79747E]">{documentTitle}</div>
          </div>
          <div className="w-10" />
        </header>

        <main className="flex min-h-0 flex-1 flex-col gap-3 p-3 sm:gap-4 sm:p-4">
          <section className="relative min-w-0 flex-1 overflow-hidden rounded-[24px] border border-[#DED8CF] bg-white shadow-sm">
            <div className="pointer-events-none absolute left-5 top-4 z-10 flex items-center gap-2 rounded-full bg-[#F7F2FF]/95 px-3 py-1.5 text-[11px] font-semibold text-[#5A438E]">
              <PenLine className="h-3.5 w-3.5" />
              <span>{signerName ? `请手写“${signerName}”` : '请手写本人姓名'}</span>
            </div>
            <div ref={frameRef} className="absolute inset-0">
              <canvas
                ref={canvasRef}
                onPointerDown={startDrawing}
                onPointerMove={draw}
                onPointerUp={stopDrawing}
                onPointerCancel={stopDrawing}
                onPointerLeave={(event) => {
                  if (drawingRef.current) stopDrawing(event);
                }}
                className="block h-full w-full cursor-crosshair touch-none"
                aria-label="手写签名区域"
              />
            </div>
            {!hasSignature && (
              <div className="pointer-events-none absolute inset-0 grid place-items-center pt-6 text-[13px] text-[#AAA39A]">
                在空白处签名
              </div>
            )}
          </section>

          <aside className="flex shrink-0 items-center gap-3 rounded-[22px] border border-[#DED8CF] bg-white px-4 py-3 sm:px-5">
            <div className="min-w-0 flex-1">
              <div className="flex items-baseline gap-2">
                <span className="shrink-0 text-[11px] font-bold text-[#79747E]">签署人</span>
                <strong className="truncate text-[14px] text-[#1D1B16]">{signerName || '本人'}</strong>
              </div>
              <p className="mt-1 truncate text-[10px] text-[#79747E]">请本人手写完整姓名，确认后将生成电子签署记录</p>
            </div>
            <div className="flex shrink-0 items-center gap-2">
              <button
                type="button"
                onClick={clearCanvas}
                disabled={!hasSignature}
                className="flex h-10 items-center justify-center gap-1.5 rounded-full border border-[#C9C3BA] px-4 text-[12px] font-bold text-[#49454F] disabled:opacity-40"
              >
                <RotateCcw className="h-4 w-4" />清空
              </button>
              <button
                type="button"
                onClick={confirmSignature}
                disabled={!hasSignature}
                className="flex h-10 items-center justify-center gap-1.5 rounded-full bg-[#6750A4] px-5 text-[12px] font-bold text-white shadow-sm transition active:scale-95 disabled:cursor-not-allowed disabled:bg-[#D0C9D6]"
              >
                <Check className="h-4 w-4" />确认签署
              </button>
            </div>
          </aside>
        </main>

        <footer className="shrink-0 px-4 pb-3 text-center text-[10px] text-[#79747E]">
          点击确认即表示本人已阅读并同意协议，签名将作为电子签署记录保存
        </footer>
      </div>

      {isPortrait && (
        <div className="absolute inset-0 z-20 flex flex-col items-center justify-center bg-[#F4F1EC]/98 px-8 text-center">
          <div className="grid h-16 w-16 place-items-center rounded-[22px] bg-[#EADDFF] text-[#4F378B]">
            <Smartphone className="h-8 w-8 rotate-90" />
          </div>
          <h2 className="mt-5 text-[20px] font-bold">请将设备横过来</h2>
          <p className="mt-2 max-w-[260px] text-[13px] leading-5 text-[#79747E]">横屏可以获得更大的签名区域，旋转后即可开始手写</p>
          <button type="button" onClick={onCancel} className="mt-7 h-11 rounded-full px-6 text-[13px] font-bold text-[#6750A4]">稍后签署</button>
        </div>
      )}
    </div>
  );
};
