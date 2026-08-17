import React, { useState } from 'react';
import { CheckCircle2, FileText, ShieldCheck, Camera, ArrowLeft, Building2, User, ChevronRight } from 'lucide-react';
import { SignatureCapturePage } from './SignatureCapturePage';

interface OnboardingFlowProps {
  onComplete: () => void;
}

export const OnboardingFlow: React.FC<OnboardingFlowProps> = ({ onComplete }) => {
  const [step, setStep] = useState<0 | 1 | 2 | 3 | 4>(0);
  const [agreed, setAgreed] = useState(false);
  const [idVerified, setIdVerified] = useState(false);
  const [signatureOpen, setSignatureOpen] = useState(false);
  const [signatureImage, setSignatureImage] = useState<string | null>(null);
  
  const handleNext = () => setStep((s) => Math.min(s + 1, 4) as any);
  const handleBack = () => setStep((s) => Math.max(s - 1, 0) as any);

  return (
    <div className="fixed inset-0 z-[100] bg-[#FAF8F5] overflow-y-auto max-w-md mx-auto w-full h-full flex flex-col shadow-2xl">
      {/* Header for Steps > 0 */}
      {step > 0 && step < 4 && (
        <div className="sticky top-0 z-10 flex items-center justify-between p-4 bg-[#FAF8F5]">
          <button onClick={handleBack} className="p-2 -ml-2 rounded-full hover:bg-[#EAE5DB] transition">
            <ArrowLeft className="w-6 h-6 text-[#1D1B16]" />
          </button>
          <div className="text-[14px] font-bold text-[#1D1B16]">
            入驻申请 ({step}/3)
          </div>
          <div className="w-10" />
        </div>
      )}

      {/* STEP 0: Welcome Landing */}
      {step === 0 && (
        <div className="flex-1 flex flex-col relative">
          <div className="absolute top-0 inset-x-0 h-64 bg-gradient-to-b from-[#EADDFF] to-[#FAF8F5]" />
          <div className="relative z-10 flex-1 flex flex-col pt-20 p-6">
            <div className="w-16 h-16 rounded-[20px] bg-[#6750A4] text-white flex items-center justify-center mb-6 shadow-lg">
              <Building2 className="w-8 h-8" />
            </div>
            <h1 className="text-3xl font-extrabold text-[#1D1B16] mb-3">
              成为入驻咨询师
            </h1>
            <p className="text-[16px] text-[#49463D] mb-12">
              连接海量来访者需求，打造个人专业品牌。平台提供全方位合规保障与智能化工具。
            </p>
            
            <div className="space-y-4 mb-auto">
              <div className="flex items-start gap-4 p-4 rounded-[20px] bg-white border border-[#ECE6DC]">
                <div className="w-10 h-10 rounded-full bg-[#EADDFF] text-[#4F378B] flex items-center justify-center shrink-0">
                  <User className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-bold text-[#1D1B16] mb-1">专业个人主页</h3>
                  <p className="text-[13px] text-[#7A756C]">展示受训背景与擅长领域，快速建立信任</p>
                </div>
              </div>
              <div className="flex items-start gap-4 p-4 rounded-[20px] bg-white border border-[#ECE6DC]">
                <div className="w-10 h-10 rounded-full bg-[#D3E3FD] text-[#0842A0] flex items-center justify-center shrink-0">
                  <ShieldCheck className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-bold text-[#1D1B16] mb-1">合规交易保障</h3>
                  <p className="text-[13px] text-[#7A756C]">透明的 T+1 结算机制，专业财务法务支持</p>
                </div>
              </div>
            </div>
            
            <div className="pt-8">
              <button 
                onClick={handleNext}
                className="w-full h-14 rounded-full bg-[#6750A4] text-white font-bold text-[16px] flex items-center justify-center gap-2 shadow-md hover:bg-[#594294] transition active:scale-95"
              >
                开始入驻流程 <ChevronRight className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* STEP 1: Agreement */}
      {step === 1 && (
        <div className="flex-1 flex flex-col p-6 animate-in fade-in slide-in-from-right-8 duration-300">
          <h2 className="text-2xl font-bold text-[#1D1B16] mb-2">阅读并同意协议</h2>
          <p className="text-[14px] text-[#7A756C] mb-6">入驻前请仔细阅读平台的规范与协议条款</p>
          
          <div className="flex-1 bg-white border border-[#ECE6DC] rounded-[24px] p-5 overflow-y-auto mb-6">
            <h3 className="font-bold text-[15px] mb-3 text-[#1D1B16]">心理咨询师入驻协议</h3>
            <div className="text-[13px] text-[#49463D] space-y-4 leading-relaxed">
              <p>1. 服务规范：咨询师应遵守职业伦理，对来访者信息严格保密。</p>
              <p>2. 资质要求：咨询师需提供真实有效的执业资格证书、学历证明及受训背景资料。</p>
              <p>3. 结算规则：平台采用 T+1 结算模式，订单完成后资金自动进入账户。</p>
              <p>4. 违约责任：如发现资质造假或严重违反伦理，平台有权终止合作并追究责任。</p>
              <p>（以上为模拟条款内容，完整版请参照平台正式发布文档）</p>
            </div>
          </div>

          <label className="flex items-start gap-3 mb-8 cursor-pointer group">
            <div className="mt-0.5">
              <div className={`w-5 h-5 rounded flex items-center justify-center border transition ${agreed ? 'bg-[#6750A4] border-[#6750A4]' : 'border-[#7A756C] group-hover:border-[#6750A4]'}`}>
                {agreed && <CheckCircle2 className="w-4 h-4 text-white" />}
              </div>
              <input type="checkbox" className="hidden" checked={agreed} onChange={(e) => setAgreed(e.target.checked)} />
            </div>
            <span className="text-[13px] text-[#49463D] leading-snug">
              我已阅读并同意 <span className="text-[#6750A4] font-medium">《心理咨询师入驻协议》</span> 与 <span className="text-[#6750A4] font-medium">《隐私保护政策》</span>
            </span>
          </label>

          {signatureImage && (
            <div className="mb-4 flex items-center gap-2 rounded-[14px] bg-emerald-50 px-4 py-3 text-[12px] font-semibold text-emerald-800">
              <CheckCircle2 className="h-4 w-4" />手写签名已采集
            </div>
          )}

          <button 
            disabled={!agreed}
            onClick={() => setSignatureOpen(true)}
            className={`w-full h-14 rounded-full font-bold text-[16px] transition shadow-md active:scale-95 ${
              agreed ? 'bg-[#6750A4] text-white hover:bg-[#594294]' : 'bg-[#EAE5DB] text-[#7A756C] cursor-not-allowed shadow-none'
            }`}
          >
            {signatureImage ? '重新签名并继续' : '签名并继续'}
          </button>
        </div>
      )}

      {/* STEP 2: Identity Verification */}
      {step === 2 && (
        <div className="flex-1 flex flex-col p-6 animate-in fade-in slide-in-from-right-8 duration-300">
          <h2 className="text-2xl font-bold text-[#1D1B16] mb-2">实名与身份认证</h2>
          <p className="text-[14px] text-[#7A756C] mb-6">为保障平台交易合规，请完成实名认证</p>
          
          <div className="space-y-4 mb-auto">
            <div className="bg-white rounded-[24px] p-5 border border-[#ECE6DC]">
              <label className="block text-[13px] font-bold text-[#49463D] mb-2">真实姓名</label>
              <input type="text" placeholder="请输入身份证上的姓名" className="w-full bg-[#FAF8F5] rounded-xl px-4 py-3 text-[15px] outline-none focus:ring-2 focus:ring-[#EADDFF]" />
            </div>
            <div className="bg-white rounded-[24px] p-5 border border-[#ECE6DC]">
              <label className="block text-[13px] font-bold text-[#49463D] mb-2">身份证号</label>
              <input type="text" placeholder="请输入18位身份证号" className="w-full bg-[#FAF8F5] rounded-xl px-4 py-3 text-[15px] outline-none focus:ring-2 focus:ring-[#EADDFF]" />
            </div>
            
            <div className="bg-white rounded-[24px] p-5 border border-[#ECE6DC] mt-4">
              <label className="block text-[13px] font-bold text-[#49463D] mb-4">人脸活体检测</label>
              {idVerified ? (
                <div className="flex items-center gap-3 bg-[#C4EED0]/30 text-[#003912] p-4 rounded-xl border border-[#C4EED0]">
                  <CheckCircle2 className="w-5 h-5" />
                  <span className="font-bold text-[14px]">认证已通过</span>
                </div>
              ) : (
                <button 
                  onClick={() => setIdVerified(true)}
                  className="w-full py-4 rounded-xl border-2 border-dashed border-[#6750A4] text-[#6750A4] font-bold text-[14px] flex flex-col items-center gap-2 hover:bg-[#EADDFF]/20 transition"
                >
                  <Camera className="w-6 h-6" />
                  点击进行人脸识别 (模拟)
                </button>
              )}
            </div>
          </div>

          <button 
            disabled={!idVerified}
            onClick={handleNext}
            className={`w-full h-14 mt-8 rounded-full font-bold text-[16px] transition shadow-md active:scale-95 ${
              idVerified ? 'bg-[#6750A4] text-white hover:bg-[#594294]' : 'bg-[#EAE5DB] text-[#7A756C] cursor-not-allowed shadow-none'
            }`}
          >
            下一步
          </button>
        </div>
      )}

      {/* STEP 3: Professional Qualifications */}
      {step === 3 && (
        <div className="flex-1 flex flex-col p-6 animate-in fade-in slide-in-from-right-8 duration-300">
          <h2 className="text-2xl font-bold text-[#1D1B16] mb-2">专业资质提交</h2>
          <p className="text-[14px] text-[#7A756C] mb-6">请上传您的执业证书，平台审核通过后方可接单</p>
          
          <div className="space-y-4 mb-auto">
            <div className="bg-white rounded-[24px] p-5 border border-[#ECE6DC]">
              <label className="block text-[13px] font-bold text-[#49463D] mb-2">资质类型</label>
              <select className="w-full bg-[#FAF8F5] rounded-xl px-4 py-3 text-[15px] outline-none focus:ring-2 focus:ring-[#EADDFF]">
                <option>心理咨询师</option>
                <option>心理督导师</option>
                <option>精神科医师</option>
              </select>
            </div>
            
            <div className="bg-white rounded-[24px] p-5 border border-[#ECE6DC]">
              <label className="block text-[13px] font-bold text-[#49463D] mb-4">证书照片上传</label>
              <button className="w-full py-8 rounded-xl border-2 border-dashed border-[#ECE6DC] text-[#7A756C] font-bold text-[14px] flex flex-col items-center gap-3 hover:bg-[#FAF8F5] transition">
                <div className="w-12 h-12 rounded-full bg-[#F5F5F5] flex items-center justify-center">
                  <FileText className="w-6 h-6 text-[#49463D]" />
                </div>
                <span>点击或拖拽上传证书图片</span>
                <span className="text-[11px] font-normal">支持 JPG/PNG，最大 5MB</span>
              </button>
            </div>
          </div>

          <button 
            onClick={handleNext}
            className="w-full h-14 mt-8 rounded-full font-bold text-[16px] bg-[#6750A4] text-white hover:bg-[#594294] transition shadow-md active:scale-95"
          >
            提交审核
          </button>
        </div>
      )}

      {/* STEP 4: Success / Under Review */}
      {step === 4 && (
        <div className="flex-1 flex flex-col items-center justify-center p-6 animate-in zoom-in-95 duration-500">
          <div className="w-24 h-24 rounded-full bg-[#EADDFF] flex items-center justify-center mb-6">
            <CheckCircle2 className="w-12 h-12 text-[#4F378B]" />
          </div>
          <h2 className="text-2xl font-bold text-[#1D1B16] mb-3">申请提交成功</h2>
          <p className="text-[15px] text-[#7A756C] text-center mb-12 max-w-[280px]">
            平台将在 1-3 个工作日内完成资质审核。审核通过后，您即可开启专属的咨询师工作台。
          </p>
          
          <button 
            onClick={onComplete}
            className="w-full h-14 rounded-full font-bold text-[16px] bg-[#6750A4] text-white hover:bg-[#594294] transition shadow-md active:scale-95"
          >
            进入工作台 (模拟审核通过)
          </button>
        </div>
      )}

      {signatureOpen && (
        <SignatureCapturePage
          documentTitle="心理咨询师入驻协议"
          onCancel={() => setSignatureOpen(false)}
          onConfirm={(dataUrl) => {
            setSignatureImage(dataUrl);
            setSignatureOpen(false);
            handleNext();
          }}
        />
      )}
    </div>
  );
};
