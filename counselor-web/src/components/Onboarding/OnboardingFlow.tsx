import React, { useState } from 'react';
import {
  ArrowLeft, Building2, Camera, CheckCircle2, ChevronRight, Clock3,
  FileCheck2, FileText, GraduationCap, PenLine, ShieldCheck,
} from 'lucide-react';
import { SignatureCapturePage } from './SignatureCapturePage';
import type { CounselorOnboardingProfileSeed } from '../../counselorProfileModel';

interface OnboardingFlowProps { onComplete: (seed: CounselorOnboardingProfileSeed) => void; }
type OnboardingStep = 0 | 1 | 2 | 3 | 4 | 5 | 6;
const progressLabels = ['实名认证', '入驻申请', '资质材料', '平台审核', '签署协议'];

export const OnboardingFlow: React.FC<OnboardingFlowProps> = ({ onComplete }) => {
  const [step, setStep] = useState<OnboardingStep>(0);
  const [realName, setRealName] = useState('');
  const [idNumber, setIdNumber] = useState('');
  const [portraitFileName, setPortraitFileName] = useState('');
  const [idVerified, setIdVerified] = useState(false);
  const [professionalTitle, setProfessionalTitle] = useState('心理咨询师');
  const [orientation, setOrientation] = useState('心理动力学');
  const [experienceYears, setExperienceYears] = useState(3);
  const [totalHours, setTotalHours] = useState(500);
  const [shortBio, setShortBio] = useState('持续接受专业训练与督导，关注成人情绪、关系与个人成长议题。');
  const [uploadedMaterials, setUploadedMaterials] = useState<string[]>([]);
  const [agreed, setAgreed] = useState(false);
  const [signatureOpen, setSignatureOpen] = useState(false);
  const [signatureImage, setSignatureImage] = useState<string | null>(null);
  const handleNext = () => setStep((current) => Math.min(current + 1, 6) as OnboardingStep);
  const handleBack = () => setStep((current) => Math.max(current - 1, 0) as OnboardingStep);
  const progressStep = Math.min(Math.max(step, 1), 5);
  const toggleMaterial = (id: string) => setUploadedMaterials((current) =>
    current.includes(id) ? current.filter((item) => item !== id) : [...current, id]
  );
  const onboardingSeed = (): CounselorOnboardingProfileSeed => ({
    name: realName.trim() || '待完善',
    title: professionalTitle,
    experienceYears,
    totalHours,
    orientations: [orientation],
    bio: shortBio,
    qualificationsList: uploadedMaterials.includes('qualification') ? [`${professionalTitle}资格材料（已通过入驻审核）`] : [],
    educationList: uploadedMaterials.includes('education') ? ['最高学历材料（已通过入驻审核）'] : [],
    trainingExperiences: uploadedMaterials.includes('supplement') ? ['补充培训、督导或咨询时数材料（已通过入驻审核）'] : [],
  });

  return (
    <div className="fixed inset-0 z-[100] mx-auto flex h-full w-full max-w-md flex-col overflow-y-auto bg-[#FAF8F5] shadow-2xl">
      {step > 0 && step < 6 && (
        <header className="sticky top-0 z-20 border-b border-[#ECE6DC] bg-[#FAF8F5]/95 px-4 pb-3 pt-4 backdrop-blur">
          <div className="flex items-center justify-between">
            <button type="button" onClick={handleBack} disabled={step === 4} className="-ml-2 grid h-10 w-10 place-items-center rounded-full hover:bg-[#EAE5DB] disabled:invisible"><ArrowLeft className="h-6 w-6" /></button>
            <div className="text-[14px] font-bold">咨询师入驻</div>
            <div className="w-10 text-right text-[11px] font-semibold text-[#6750A4]">{progressStep}/5</div>
          </div>
          <div className="mt-3 grid grid-cols-5 gap-1">
            {progressLabels.map((label, index) => {
              const position = index + 1;
              const active = position === progressStep;
              return <div key={label} className="min-w-0 text-center"><div className={`h-1 rounded-full ${position <= progressStep ? 'bg-[#6750A4]' : 'bg-[#E4DED5]'}`} /><span className={`mt-1 block truncate text-[9px] ${active ? 'font-bold text-[#6750A4]' : 'text-[#938F86]'}`}>{label}</span></div>;
            })}
          </div>
        </header>
      )}

      {step === 0 && (
        <div className="relative flex flex-1 flex-col">
          <div className="absolute inset-x-0 top-0 h-64 bg-gradient-to-b from-[#EADDFF] to-[#FAF8F5]" />
          <div className="relative z-10 flex flex-1 flex-col p-6 pt-20">
            <div className="mb-6 grid h-16 w-16 place-items-center rounded-[20px] bg-[#6750A4] text-white shadow-lg"><Building2 className="h-8 w-8" /></div>
            <h1 className="mb-3 text-3xl font-extrabold">成为入驻咨询师</h1>
            <p className="mb-8 text-[16px] leading-7 text-[#49463D]">完成身份与专业能力审核后，再签署正式合作协议并上线服务。</p>
            <div className="mb-auto rounded-[24px] border border-[#ECE6DC] bg-white p-5">
              <InfoRow icon={ShieldCheck} title="先审核，后签约" body="提交实名与资质材料，平台审核通过后进入正式签约。" />
            </div>
            <button onClick={handleNext} className="mt-8 flex h-14 items-center justify-center gap-2 rounded-full bg-[#6750A4] text-[16px] font-bold text-white shadow-md">开始申请 <ChevronRight className="h-5 w-5" /></button>
          </div>
        </div>
      )}

      {step === 1 && (
        <section className="flex flex-1 flex-col p-6">
          <PageTitle title="实名认证" subtitle="通过姓名、身份证号和本人照片完成三要素核验；认证结果将用于后续签约。" />
          <div className="mb-auto space-y-4">
            <FieldCard label="真实姓名"><input value={realName} onChange={(event) => { setRealName(event.target.value); setIdVerified(false); }} placeholder="请输入身份证上的姓名" className="w-full rounded-xl bg-[#FAF8F5] px-4 py-3 text-[15px] outline-none focus:ring-2 focus:ring-[#EADDFF]" /></FieldCard>
            <FieldCard label="身份证号"><input value={idNumber} onChange={(event) => { setIdNumber(event.target.value.toUpperCase()); setIdVerified(false); }} maxLength={18} placeholder="请输入18位身份证号" className="w-full rounded-xl bg-[#FAF8F5] px-4 py-3 text-[15px] outline-none focus:ring-2 focus:ring-[#EADDFF]" /></FieldCard>
            <FieldCard label="本人照片">
              <label className="flex cursor-pointer flex-col items-center gap-2 rounded-xl border-2 border-dashed border-[#C9C3BA] px-4 py-5 text-center transition hover:border-[#6750A4]">
                <Camera className="h-7 w-7 text-[#6750A4]" />
                <span className="text-[14px] font-bold text-[#49463D]">{portraitFileName || '上传本人清晰正面照片'}</span>
                <span className="text-[11px] leading-5 text-[#7A756C]">面部无遮挡、光线均匀，支持 JPG、PNG，建议不超过 5MB</span>
                <input type="file" accept="image/jpeg,image/png" className="hidden" onChange={(event) => { const file = event.target.files?.[0]; if (file) { setPortraitFileName(file.name); setIdVerified(false); } }} />
              </label>
              {idVerified ? (
                <div className="mt-3 flex items-center gap-3 rounded-xl border border-[#C4EED0] bg-[#C4EED0]/30 p-4 text-[#003912]"><CheckCircle2 className="h-5 w-5" /><div><div className="text-[14px] font-bold">三要素核验通过</div><div className="mt-0.5 text-[11px]">姓名、身份证号与本人照片匹配</div></div></div>
              ) : (
                <button type="button" onClick={() => setIdVerified(true)} disabled={realName.trim().length < 2 || !/^\d{17}[\dX]$/.test(idNumber.trim()) || !portraitFileName} className="mt-3 h-12 w-full rounded-full bg-[#6750A4] text-[14px] font-bold text-white disabled:cursor-not-allowed disabled:bg-[#D0CBC2]">开始三要素核验（Mock）</button>
              )}
              <div className="mt-3 flex items-start gap-2 rounded-xl bg-[#FAF8F5] p-3 text-[11px] leading-5 text-[#7A756C]"><ShieldCheck className="mt-0.5 h-4 w-4 shrink-0 text-[#6750A4]" /><span>信息仅用于第三方实名一致性核验和平台签约，不使用活体检测，不对外展示身份证信息及原始照片。</span></div>
            </FieldCard>
          </div>
          <PrimaryButton disabled={!idVerified} onClick={handleNext}>认证完成，继续</PrimaryButton>
        </section>
      )}

      {step === 2 && (
        <section className="flex flex-1 flex-col p-6">
          <PageTitle title="填写入驻申请" subtitle="先填写审核必需信息；通过后会自动带入个人主页与档案，可继续完善。" />
          <div className="mb-auto space-y-4">
            <FieldCard label="专业身份"><select value={professionalTitle} onChange={(event) => setProfessionalTitle(event.target.value)} className="w-full rounded-xl bg-[#FAF8F5] px-4 py-3 text-[15px] outline-none"><option>心理咨询师</option><option>注册系统心理师</option><option>精神科医师</option></select></FieldCard>
            <FieldCard label="主要专业取向"><select value={orientation} onChange={(event) => setOrientation(event.target.value)} className="w-full rounded-xl bg-[#FAF8F5] px-4 py-3 text-[15px] outline-none"><option>心理动力学</option><option>认知行为（CBT）</option><option>人本主义</option><option>家庭治疗</option><option>整合取向</option></select></FieldCard>
            <div className="grid grid-cols-2 gap-3"><FieldCard label="从业年限"><input type="number" min="0" max="50" value={experienceYears} onChange={(event) => setExperienceYears(Number(event.target.value))} className="w-full rounded-xl bg-[#FAF8F5] px-3 py-3 text-[14px] outline-none" /></FieldCard><FieldCard label="累计咨询时数"><input type="number" min="0" value={totalHours} onChange={(event) => setTotalHours(Number(event.target.value))} className="w-full rounded-xl bg-[#FAF8F5] px-3 py-3 text-[14px] outline-none" /></FieldCard></div>
            <FieldCard label="个人简介（可稍后完善）"><textarea value={shortBio} onChange={(event) => setShortBio(event.target.value)} className="min-h-24 w-full resize-none rounded-xl bg-[#FAF8F5] px-4 py-3 text-[14px] leading-6 outline-none" /></FieldCard>
            <p className="rounded-xl bg-[#F3EDFF] px-4 py-3 text-[11px] leading-5 text-[#625B71]">以上内容将直接成为“个人主页与档案”的初始资料，无需重复填写。</p>
          </div>
          <PrimaryButton onClick={handleNext}>保存并提交资质</PrimaryButton>
        </section>
      )}

      {step === 3 && (
        <section className="flex flex-1 flex-col p-6">
          <PageTitle title="提交专业资质" subtitle="入驻阶段仅要求专业资格和学历材料；其他经历可选填，并可在档案中继续补充。" />
          <div className="mb-auto space-y-3">
            {[
              ['qualification', '专业资格证明', '证书、注册信息及有效期', FileCheck2, '必填'],
              ['education', '最高学历证明', '毕业证或学位证', GraduationCap, '必填'],
              ['supplement', '补充专业材料', '培训、督导或咨询时数证明', FileText, '选填'],
            ].map(([id, title, subtitle, Icon, required]) => <button key={String(id)} type="button" onClick={() => toggleMaterial(String(id))} className="flex w-full items-center gap-4 rounded-[20px] border border-[#ECE6DC] bg-white p-4 text-left"><div className="grid h-11 w-11 shrink-0 place-items-center rounded-[14px] bg-[#F3EDFF] text-[#6750A4]"><Icon className="h-5 w-5" /></div><div className="min-w-0 flex-1"><div className="flex items-center gap-2"><strong className="block text-[14px]">{String(title)}</strong><span className="rounded-full bg-[#FAF8F5] px-2 py-0.5 text-[9px] font-bold text-[#7A756C]">{String(required)}</span></div><span className="mt-1 block text-[12px] text-[#7A756C]">{String(subtitle)}</span></div>{uploadedMaterials.includes(String(id)) ? <CheckCircle2 className="h-5 w-5 text-emerald-600" /> : <span className="text-[11px] font-bold text-[#6750A4]">上传</span>}</button>)}
            <p className="px-2 text-[11px] leading-5 text-[#938F86]">已审核材料会同步进入“个人主页与档案”的对应栏目。</p>
          </div>
          <PrimaryButton disabled={!uploadedMaterials.includes('qualification') || !uploadedMaterials.includes('education')} onClick={handleNext}>提交平台审核</PrimaryButton>
        </section>
      )}

      {step === 4 && (
        <section className="flex flex-1 flex-col items-center justify-center p-6 text-center">
          <div className="grid h-24 w-24 place-items-center rounded-full bg-[#FFF3D6] text-[#8A4B08]"><Clock3 className="h-11 w-11" /></div>
          <span className="mt-6 rounded-full bg-[#FFF3D6] px-3 py-1 text-[11px] font-bold text-[#8A4B08]">平台审核中</span>
          <h2 className="mt-3 text-2xl font-bold">申请材料已提交</h2>
          <p className="mt-3 max-w-[310px] text-[14px] leading-6 text-[#7A756C]">平台将核验实名信息与专业材料，必要时邀请您参加线上合作面谈。审核通过后才会开放正式协议签署。</p>
          <div className="mt-8 w-full rounded-[22px] border border-[#ECE6DC] bg-white p-5 text-left"><ReviewLine label="实名信息" status="已核验" done /><ReviewLine label="资质材料" status="审核中" /><ReviewLine label="合作面谈" status="按需安排" last /></div>
          <button type="button" onClick={handleNext} className="mt-8 h-13 w-full rounded-full bg-[#6750A4] text-[15px] font-bold text-white shadow-md">模拟审核通过</button>
        </section>
      )}

      {step === 5 && (
        <section className="flex flex-1 flex-col p-6">
          <span className="mb-3 w-fit rounded-full bg-emerald-50 px-3 py-1 text-[11px] font-bold text-emerald-700">审核通过 · 待签约</span>
          <PageTitle title="签署正式入驻协议" subtitle="平台已确认您的合作资格。请阅读协议并由本人完成电子签名。" />
          <div className="mb-4 rounded-[20px] border border-[#D8E8DD] bg-emerald-50/60 p-4"><div className="flex items-center gap-3"><ShieldCheck className="h-5 w-5 text-emerald-700" /><div><span className="block text-[11px] text-[#65806D]">已认证签署人</span><strong className="text-[15px] text-[#193C25]">{realName || '林木青'}</strong></div></div></div>
          <div className="mb-5 flex-1 overflow-y-auto rounded-[24px] border border-[#ECE6DC] bg-white p-5"><h3 className="mb-3 text-[15px] font-bold">心理咨询师平台服务协议</h3><div className="space-y-4 text-[13px] leading-6 text-[#49463D]"><p>1. 咨询师应遵守职业伦理，对来访者信息严格保密。</p><p>2. 咨询师承诺已提交的身份与专业材料真实、准确、持续有效。</p><p>3. 平台依据预约履约结果进行服务结算，并提供争议处理支持。</p><p>4. 本协议为 Mock 文本，正式内容由平台运营与法务提供。</p></div></div>
          <label className="mb-5 flex cursor-pointer items-start gap-3 text-[12px] leading-5 text-[#625F58]"><input type="checkbox" checked={agreed} onChange={(event) => setAgreed(event.target.checked)} className="mt-1 h-4 w-4 accent-[#6750A4]" /><span>本人已完整阅读并同意《心理咨询师平台服务协议》，确认由本人完成电子签署。</span></label>
          <PrimaryButton disabled={!agreed} onClick={() => setSignatureOpen(true)}><PenLine className="mr-2 inline h-4 w-4" />横屏手写签名</PrimaryButton>
        </section>
      )}

      {step === 6 && (
        <section className="flex flex-1 flex-col items-center justify-center p-6 text-center">
          <div className="grid h-24 w-24 place-items-center rounded-full bg-[#D8F3DF] text-emerald-700"><CheckCircle2 className="h-12 w-12" /></div><h2 className="mt-6 text-2xl font-bold">签约完成</h2><p className="mt-3 max-w-[300px] text-[14px] leading-6 text-[#7A756C]">正式上线前，请继续完善个人主页、服务商品和可预约排班。</p>
          <div className="mt-8 w-full rounded-[22px] border border-[#ECE6DC] bg-white p-5 text-left"><ReviewLine label="个人主页" status="待完善" /><ReviewLine label="服务商品" status="待配置" /><ReviewLine label="可服务排班" status="待配置" last /></div>
          {signatureImage && <div className="mt-4 flex items-center gap-2 text-[12px] font-semibold text-emerald-700"><CheckCircle2 className="h-4 w-4" />电子签名已保存</div>}
          <button type="button" onClick={() => onComplete(onboardingSeed())} className="mt-8 h-14 w-full rounded-full bg-[#6750A4] text-[16px] font-bold text-white shadow-md">进入工作台继续配置</button>
        </section>
      )}

      {signatureOpen && <SignatureCapturePage documentTitle="心理咨询师平台服务协议" signerName={realName || '林木青'} onCancel={() => setSignatureOpen(false)} onConfirm={(dataUrl) => { setSignatureImage(dataUrl); setSignatureOpen(false); setStep(6); }} />}
    </div>
  );
};

const PageTitle: React.FC<{ title: string; subtitle: string }> = ({ title, subtitle }) => <><h2 className="text-2xl font-bold">{title}</h2><p className="mb-6 mt-2 text-[14px] leading-6 text-[#7A756C]">{subtitle}</p></>;
const FieldCard: React.FC<{ label: string; children: React.ReactNode }> = ({ label, children }) => <div className="rounded-[24px] border border-[#ECE6DC] bg-white p-5"><label className="mb-2 block text-[13px] font-bold text-[#49463D]">{label}</label>{children}</div>;
const PrimaryButton: React.FC<{ disabled?: boolean; onClick: () => void; children: React.ReactNode }> = ({ disabled, onClick, children }) => <button type="button" disabled={disabled} onClick={onClick} className="mt-8 h-14 w-full rounded-full bg-[#6750A4] text-[16px] font-bold text-white shadow-md active:scale-95 disabled:cursor-not-allowed disabled:bg-[#D0CBC2] disabled:shadow-none">{children}</button>;
const InfoRow: React.FC<{ icon: React.ElementType; title: string; body: string; blue?: boolean }> = ({ icon: Icon, title, body, blue }) => <div className="flex gap-4"><div className={`grid h-10 w-10 shrink-0 place-items-center rounded-full ${blue ? 'bg-[#D3E3FD] text-[#0842A0]' : 'bg-[#EADDFF] text-[#4F378B]'}`}><Icon className="h-5 w-5" /></div><div><h3 className="font-bold">{title}</h3><p className="mt-1 text-[13px] leading-5 text-[#7A756C]">{body}</p></div></div>;
const ReviewLine: React.FC<{ label: string; status: string; done?: boolean; last?: boolean }> = ({ label, status, done, last }) => <div className={`flex items-center justify-between py-3 ${last ? '' : 'border-b border-[#ECE6DC]'}`}><span className="text-[13px] font-semibold text-[#49463D]">{label}</span><span className={`text-[12px] font-bold ${done ? 'text-emerald-700' : 'text-[#6750A4]'}`}>{status}</span></div>;
