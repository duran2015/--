import React, { useState } from 'react';
import { ArrowLeft, UserCheck, CreditCard, HeartHandshake, Phone, Award, ShieldCheck, PlusSquare, Info, X } from 'lucide-react';

export type CertStatus = 'unauthenticated' | 'editing' | 'pending' | 'approved' | 'rejected';

export interface Certification {
  id: string;
  title: string;
  subtitle: string;
  status: CertStatus;
  type: 'realname' | 'bankcard' | 'upload' | 'unsupported';
}

const MOCK_CERTIFICATIONS: Certification[] = [
  { id: 'realname', title: '实名认证', subtitle: '身份认证、活体认证', status: 'approved', type: 'realname' },
  { id: 'counselor', title: '心理咨询师认证', subtitle: '证书等职业资格', status: 'approved', type: 'upload' },
  { id: 'supervisor', title: '督导师认证', subtitle: '证书等职业资格', status: 'unauthenticated', type: 'upload' },
  { id: 'psychiatrist', title: '精神科医师认证', subtitle: '证书等职业资格', status: 'unauthenticated', type: 'upload' },
];

interface CertificationsViewProps {
  onBack: () => void;
}

export const CertificationsView: React.FC<CertificationsViewProps> = ({ onBack }) => {
  const [certs, setCerts] = useState<Certification[]>(MOCK_CERTIFICATIONS);
  const [selectedCert, setSelectedCert] = useState<Certification | null>(null);

  const handleAuth = (cert: Certification) => {
    if (cert.type === 'unsupported') {
      alert('如需要开通对应的服务权限，请联系客服小灵申请。');
      return;
    }
    if (cert.type === 'realname') {
      alert('调用腾讯/阿里三要素+人脸认证接口...');
      setTimeout(() => {
        setCerts(certs.map(c => c.id === cert.id ? { ...c, status: 'approved' } : c));
        alert('实名认证成功！');
      }, 1000);
      return;
    }
    if (cert.type === 'bankcard') {
      alert('请在“收入明细与提现”模块中绑定收款账户。');
      return;
    }
    if (cert.type === 'upload') {
      setSelectedCert(cert);
    }
  };

  const handleUploadSubmit = () => {
    if (selectedCert) {
      setCerts(certs.map(c => c.id === selectedCert.id ? { ...c, status: 'pending' } : c));
      setSelectedCert(null);
      alert('资质照片已提交，等待运营审核。');
    }
  };

  const renderStatus = (status: CertStatus, cert: Certification) => {
    if (status === 'approved') return <span className="text-[#6750A4] bg-[#EADDFF] px-3 py-1.5 rounded-full text-[11px] font-bold">已认证</span>;
    if (status === 'pending') return <span className="text-[#A23F1E] bg-[#FCEEEA] px-3 py-1.5 rounded-full text-[11px] font-bold">待审核</span>;
    if (status === 'editing') return <span className="text-[#7A756C] bg-[#ECE6DC] px-3 py-1.5 rounded-full text-[11px] font-bold">编辑中</span>;
    if (status === 'rejected') return (
      <button onClick={() => handleAuth(cert)} className="text-white bg-[#A23F1E] px-3 py-1.5 rounded-full text-[11px] font-bold shadow-xs active:scale-95 transition">重新提交</button>
    );
    return (
      <button 
        onClick={() => handleAuth(cert)}
        className="text-white bg-[#0066FF] hover:bg-[#0055CC] px-4 py-1.5 rounded-full text-[12px] font-bold shadow-xs active:scale-95 transition"
      >
        去认证
      </button>
    );
  };

  const getIcon = (id: string) => {
    switch (id) {
      case 'realname': return <UserCheck className="w-5 h-5" />;
      case 'bankcard': return <CreditCard className="w-5 h-5" />;
      case 'welfare': return <HeartHandshake className="w-5 h-5" />;
      case 'listener': return <Phone className="w-5 h-5" />;
      case 'counselor': return <Award className="w-5 h-5" />;
      case 'supervisor': return <ShieldCheck className="w-5 h-5" />;
      case 'psychiatrist': return <PlusSquare className="w-5 h-5" />;
      default: return <Award className="w-5 h-5" />;
    }
  };

  if (selectedCert) {
    return (
      <div className="space-y-4 animate-in fade-in duration-200">
        <div className="flex items-center gap-2">
          <button
            onClick={() => setSelectedCert(null)}
            className="p-1.5 -ml-1.5 rounded-full text-[#6750A4] hover:bg-[#E8E2D5] transition active:scale-95 flex items-center gap-1 font-semibold text-xs"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>返回列表</span>
          </button>
          <span className="text-[#ECE6DC]">/</span>
          <span className="text-xs font-bold text-[#1D1B16]">提交{selectedCert.title}资料</span>
        </div>

        <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-6 shadow-2xs min-h-[60vh] space-y-6">
          <div>
            <h3 className="font-bold text-[18px] text-[#1D1B16] mb-1">上传资质照片</h3>
            <p className="text-xs text-[#7A756C]">请上传清晰的证件原件照片，确保证书编号及姓名清晰可见。</p>
          </div>
          
          <div className="bg-[#FAF8F5] border border-dashed border-[#ECE6DC] rounded-[20px] h-48 flex flex-col items-center justify-center text-[#7A756C] hover:bg-[#EADDFF]/20 hover:border-[#6750A4] transition cursor-pointer">
            <PlusSquare className="w-8 h-8 mb-3 text-[#6750A4]" />
            <span className="text-sm font-bold text-[#1D1B16]">点击上传资质照片</span>
            <span className="text-xs mt-1.5">支持 JPG, PNG，最大 5MB</span>
          </div>
          
          <div className="bg-[#FAF8F5] rounded-[16px] p-4 text-xs text-[#7A756C] leading-relaxed">
            温馨提示：提交后运营人员将在 1-3 个工作日内完成审核。审核期间不影响您的现有接单权限。提交后状态将变更为“待审核”。
          </div>
          
          <button 
            onClick={handleUploadSubmit}
            className="w-full py-4 rounded-full bg-[#6750A4] text-white font-bold shadow-xs active:scale-95 transition text-[15px]"
          >
            确认提交审核
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4 animate-in fade-in duration-200">
      <div className="flex items-center gap-2">
        <button
          onClick={onBack}
          className="p-1.5 -ml-1.5 rounded-full text-[#6750A4] hover:bg-[#E8E2D5] transition active:scale-95 flex items-center gap-1 font-semibold text-xs"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>返回</span>
        </button>
        <span className="text-[#ECE6DC]">/</span>
        <span className="text-xs font-bold text-[#1D1B16]">资质档案</span>
      </div>

      <div className="bg-[#F4F8FF] border border-[#B3D4FF] rounded-[16px] p-3.5 flex items-start gap-2.5 text-[#0055CC]">
        <Info className="w-4 h-4 shrink-0 mt-0.5 text-[#0066FF]" />
        <p className="text-xs leading-relaxed text-[#0055CC]">
          以下认证状态仅代表您的资质符合要求(<a href="#" className="underline font-medium hover:text-[#0044AA]">查看入驻标准</a>)，如需要开通对应的服务权限，请联系<a href="#" className="underline font-medium hover:text-[#0044AA]">客服小灵</a>申请
        </p>
      </div>

      <div className="bg-white border border-[#E6E0D6] rounded-[24px] overflow-hidden shadow-2xs">
        <div className="divide-y divide-[#ECE6DC]">
          {certs.map(cert => (
            <div key={cert.id} className="p-4 flex items-center justify-between hover:bg-[#FAF8F5] transition">
              <div className="flex items-center gap-3.5">
                <div className="w-10 h-10 rounded-[12px] bg-[#FAF8F5] border border-[#ECE6DC] flex items-center justify-center text-[#49463D]">
                  {getIcon(cert.id)}
                </div>
                <div>
                  <div className="font-bold text-[14px] text-[#1D1B16]">{cert.title}</div>
                  <div className="text-[11px] text-[#7A756C] mt-0.5">{cert.subtitle}</div>
                </div>
              </div>
              <div className="shrink-0">
                {renderStatus(cert.status, cert)}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
