import React, { useState } from 'react';
import { 
  UserCheck, ShieldCheck, Clock, Award, Wallet, Calendar, Package, Briefcase,
  ChevronRight, ArrowLeft, ArrowUpRight, Plus, Edit3, CheckCircle2, DollarSign, 
  ToggleLeft, ToggleRight, X, Sparkles, Building, FileCheck, ArrowRight,
  Sun, SunMedium, Moon, Copy, Check, Grid, Sliders, CalendarDays, FileText,
  CreditCard, Building2, AlertCircle, Info, Receipt, History, User, Phone,
  XCircle, ExternalLink, BookOpen, Globe, GraduationCap, Save, HeartHandshake, Compass,
  ShoppingBag, TrendingUp, Users, Share2, LogOut, UserRoundCog, MessageSquareText,
  CircleHelp, LockKeyhole, Repeat2, Trash2, Send
} from 'lucide-react';
import { ConsultantProfile, ServiceProduct, SettlementRecord, Order, ConsultantBookingRule } from '../../types';

import { ScheduleSettingsView, MOCK_RULE } from './ScheduleSettingsView';
import { HistoryOrdersView } from './HistoryOrdersView';
import { CertificationsView } from './CertificationsView';

const MOCK_PLATFORM_RULES = [
  {
    id: 'rule-1',
    title: '心理咨询师入驻协议',
    date: '2026-08-01',
    version: 'KL-C-2026.08',
    isAgreement: true,
    content: '欢迎入驻可鹿心理咨询服务平台。本协议由平台运营统一发布，咨询师完成电子签署后生效。\n\n一、合作主体\n咨询师以独立专业服务者身份入驻平台，依法、依规向来访者提供心理咨询服务。双方不因本协议建立劳动关系。\n\n二、资质与信息真实性\n咨询师应提交真实、完整且处于有效期内的身份、学历、专业资质、培训与督导材料；信息发生变化时应及时更新。\n\n三、专业伦理与服务边界\n咨询师应遵守心理咨询职业伦理、知情同意和保密原则，不得与来访者建立双重关系，不得引导私下交易，不得作出医疗诊断或疗效承诺。\n\n四、预约与履约\n咨询师应按平台排班准时履约。确需取消或改期时，应遵循平台公示的预约取消规则，并通过平台完成操作与通知。\n\n五、记录与隐私保护\n咨询记录仅用于专业服务与连续性支持。未经授权，不得下载、传播或向第三方披露可识别来访者身份的信息。\n\n六、费用与结算\n服务费用、退款和结算以订单及平台规则为准。平台为咨询师私域订单提供统一管理时，不额外抽取平台佣金；第三方支付通道费用按实际发生额处理。\n\n七、风险与危机处理\n发现自伤、自杀、伤人或其他重大风险时，咨询师应按照平台危机干预流程及时升级处理并留存必要记录。\n\n八、违约与退出\n资质造假、严重伦理违规、泄露隐私或绕开平台交易的，平台可暂停服务、终止合作并依法追究责任。\n\n本 Mock 协议仅用于前端流程演示，正式文本、版本号与生效日期由平台运营后台配置。'
  },
  {
    id: 'rule-2',
    title: '咨询服务费用结算规则',
    date: '2023-11-15',
    version: 'FIN-2023.11',
    isAgreement: false,
    content: '为保障咨询师的合法权益，平台制定以下费用结算规则：\n\n1. 结算周期：订单完成且提交咨询小结后，费用将于 T+1 工作日结算至您的平台钱包。\n2. 提现申请：您可随时对钱包中的可用余额发起提现申请。\n3. 提现审核：平台将在 1-3 个工作日内对提现申请进行审核。\n4. 财务打款：审核通过后，财务将在 3-7 个工作日内将款项打入您绑定的收款账户中。\n5. 手续费：提现过程中产生的银行或第三方支付渠道手续费，按实际发生额扣除。'
  },
  {
    id: 'rule-3',
    title: '平台隐私保护政策',
    date: '2024-01-05',
    version: 'PRIVACY-2024.01',
    isAgreement: false,
    content: '本平台高度重视咨询师与来访者的隐私保护：\n\n1. 数据加密：所有音视频咨询过程及文字消息均采用端到端加密技术，平台不留存任何原始咨询录音或录像。\n2. 匿名化处理：来访者的个人信息在展示给咨询师时，系统将进行必要的脱敏处理。\n3. 档案安全：咨询师记录的咨询档案和 AI 生成的小结，仅对当前咨询师及来访者本人可见，未经授权绝不向第三方提供。\n4. 账号安全：请妥善保管您的登录凭证，若发现账号异常请立即联系平台客服。'
  }
];

interface ProfileTabProps {
  consultant: ConsultantProfile;
  products: ServiceProduct[];
  settlements: SettlementRecord[];
  initialSection?: 'menu' | 'schedule_settings';
  isMockEmpty?: boolean;
  onToggleProductPublish: (productId: string) => void;
  onUpdateConsultant?: (updated: ConsultantProfile) => void;
  onSubPageChange?: (isSubPage: boolean) => void;
  onProcessOrder: (order: Order, viewMode?: 'order_detail' | 'client_profile') => void;
  onOpenOrderInfo: (order: Order) => void;
  onOpenIncomeView: () => void;
  onScheduleConfigured?: () => void;
  onSwitchToUser?: () => void;
  onLogout?: () => void;
}

export const ProfileTab: React.FC<ProfileTabProps> = ({
  consultant,
  products,
  settlements,
  initialSection = 'menu',
  isMockEmpty,
  onToggleProductPublish,
  onUpdateConsultant,
  onSubPageChange,
  onProcessOrder,
  onOpenOrderInfo,
  onOpenIncomeView,
  onScheduleConfigured,
  onSwitchToUser,
  onLogout
}) => {
  // Navigation section: 'menu' is default home view; selecting an item opens a dedicated page view
  const [activeSection, setActiveSection] = useState<'menu' | 'profile_edit' | 'products' | 'qualifications' | 'schedule_settings' | 'platform_rules' | 'history_orders' | 'account_security' | 'feedback' | 'about'>(initialSection);
  const [selectedRule, setSelectedRule] = useState<(typeof MOCK_PLATFORM_RULES)[number] | null>(null);
  const [agreementStatus, setAgreementStatus] = useState<'pending' | 'signing' | 'signed'>('pending');
  const [agreementChecked, setAgreementChecked] = useState(false);
  const [signatureName, setSignatureName] = useState(consultant.name);
  const [signedAt, setSignedAt] = useState<string | null>(null);
  const [feedbackContent, setFeedbackContent] = useState('');

  // Sync initialSection changes from parent
  React.useEffect(() => {
    setActiveSection(initialSection);
  }, [initialSection]);

  // Shared booking rule state for scheduling and products filtering
  const [bookingRule, setBookingRule] = useState<ConsultantBookingRule>(MOCK_RULE);

  React.useEffect(() => {
    if (onSubPageChange) {
      onSubPageChange(activeSection !== 'menu');
    }
  }, [activeSection, onSubPageChange]);

  // Qualifications & Profile view mode: 'view' (card preview) or 'edit' (form editing)
  const [qualificationsViewMode, setQualificationsViewMode] = useState<'view' | 'edit'>('view');

  // Form states for Consultant Profile Editing
  const [formName, setFormName] = useState<string>(consultant.name);
  const [formTitle, setFormTitle] = useState<string>(consultant.title);
  const [formLicenseNo, setFormLicenseNo] = useState<string>(consultant.licenseNo);
  const [formExperienceYears, setFormExperienceYears] = useState<number>(consultant.experienceYears);
  const [formBio, setFormBio] = useState<string>(consultant.bio);
  const [avatarReviewStatus, setAvatarReviewStatus] = useState<'approved' | 'pending' | 'rejected'>('approved');
  const [pendingAvatar, setPendingAvatar] = useState<string | null>(null);
  const [avatarReviewNote, setAvatarReviewNote] = useState('');

  // Qualifications & Training arrays
  const [formQualifications, setFormQualifications] = useState<string[]>(
    consultant.qualificationsList || [
      '中国心理学会注册心理师 (CPS-R-2018-0921)',
      '国家二级心理咨询师 (证书编号: 1603000008201201)',
      '上海市心理学会临床专业委员会会员'
    ]
  );
  const [formEducation, setFormEducation] = useState<string[]>(
    consultant.educationList || [
      '华东师范大学 临床与咨询心理学硕士',
      '浙江大学 心理与行为科学系学士'
    ]
  );
  const [formTraining, setFormTraining] = useState<string[]>(
    consultant.trainingExperiences || [
      '中美心理动力学连续培训项目（3年长程系统培训）',
      '认知行为疗法（CBT）临床实操与技术演练（120学时）',
      '正念减压（MBSR）与接纳承诺疗法（ACT）短程实操工作坊',
      '危机干预与心理首救专题研修'
    ]
  );
  const [formSupervisionHours, setFormSupervisionHours] = useState<number>(
    consultant.supervisionHours || 360
  );
  const [formPersonalTherapyHours, setFormPersonalTherapyHours] = useState<number>(
    consultant.personalTherapyHours || 220
  );

  // Specialties & Style arrays
  const [formSpecialties, setFormSpecialties] = useState<string[]>(
    consultant.specialties || ['职场焦虑与倦怠', '亲密关系与沟通', '情绪过载与自我关怀', '高敏感人群适应', '个人成长与自我认同']
  );
  const [formTargetAudience, setFormTargetAudience] = useState<string[]>(
    consultant.targetAudience || ['成人 (18-50岁)', '高压职场白领/管理者', '高敏感人群', '高校学生']
  );
  const [formProficientServices, setFormProficientServices] = useState<string[]>(
    consultant.proficientServices || ['50分钟个体心理咨询 (视频/语音)', '15分钟极简舒压倾听']
  );
  const [formLanguages, setFormLanguages] = useState<string[]>(
    consultant.workingLanguages || ['普通话 (标准)', '英语 (Fluent)', '粤语 (基础)']
  );
  const [formOrientations, setFormOrientations] = useState<string[]>(
    consultant.orientations || ['人本主义', '认知行为 (CBT)', '正念与接纳承诺 (ACT)', '心理剧与躯体觉察']
  );
  const [formStyle, setFormStyle] = useState<string>(
    consultant.counselingStyle || '温暖接纳、敏锐洞察、温和而坚定。注重陪伴来访者在安全氛围中自发探索，结合逻辑梳理与躯体感知。'
  );

  // Quick inputs for adding list items in Edit mode
  const [newQualInput, setNewQualInput] = useState('');
  const [newEduInput, setNewEduInput] = useState('');
  const [newTrainInput, setNewTrainInput] = useState('');
  const [newSpecialtyInput, setNewSpecialtyInput] = useState('');
  const [newAudienceInput, setNewAudienceInput] = useState('');
  const [newServiceInput, setNewServiceInput] = useState('');
  const [newLangInput, setNewLangInput] = useState('');
  const [newOrientInput, setNewOrientInput] = useState('');

  // Default tags for suggestions
  const DEFAULT_SPECIALTIES = ['情绪管理', '人际关系', '个人成长', '职业发展', '婚姻家庭', '心理创伤', '睡眠问题', '躯体化症状'];
  const DEFAULT_AUDIENCES = ['青少年 (12-18岁)', '大学生', '职场人士', '情侣/夫妻', '孕产妇', 'LGBTQ+', '老年人'];
  const DEFAULT_SERVICES = ['50分钟个体心理咨询 (视频/语音)', '15分钟极简舒压倾听', '90分钟家庭/伴侣咨询', '心理测评及解读'];
  const DEFAULT_LANGUAGES = ['普通话', '英语', '粤语', '日语', '手语'];
  const DEFAULT_ORIENTATIONS = ['精神分析/心理动力学', '人本主义', '认知行为 (CBT)', '系统家庭治疗', '焦点解决 (SFBT)', '正念与接纳承诺 (ACT)', '表达性艺术治疗'];

  // Helper function to add items
  const handleAddItem = (
    value: string, 
    setValue: React.Dispatch<React.SetStateAction<string>>, 
    list: string[], 
    setList: React.Dispatch<React.SetStateAction<string[]>>
  ) => {
    const trimmed = value.trim();
    if (!trimmed) return;
    if (list.includes(trimmed)) {
      alert('已存在相同的项目');
      return;
    }
    setList([...list, trimmed]);
    setValue('');
  };

  const handleRemoveItem = (
    index: number, 
    list: string[], 
    setList: React.Dispatch<React.SetStateAction<string[]>>
  ) => {
    setList(list.filter((_, i) => i !== index));
  };

  const handleAddTag = (
    tag: string,
    list: string[],
    setList: React.Dispatch<React.SetStateAction<string[]>>
  ) => {
    if (!list.includes(tag)) {
      setList([...list, tag]);
    }
  };

  const handleAvatarSelected = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    event.target.value = '';
    if (!file) return;
    if (!file.type.startsWith('image/')) {
      alert('请选择图片文件');
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      alert('头像需小于 5MB');
      return;
    }
    const reader = new FileReader();
    reader.onload = () => {
      setPendingAvatar(String(reader.result));
      setAvatarReviewStatus('pending');
      setAvatarReviewNote('预计 1 个工作日内完成审核，审核前继续展示原头像。');
    };
    reader.readAsDataURL(file);
  };

  const approvePendingAvatar = () => {
    if (!pendingAvatar) return;
    onUpdateConsultant?.({ ...consultant, avatar: pendingAvatar });
    setPendingAvatar(null);
    setAvatarReviewStatus('approved');
    setAvatarReviewNote('新头像已通过平台审核并生效。');
  };

  // Save changes handler
  const handleSaveProfile = () => {
    const updated: ConsultantProfile = {
      ...consultant,
      name: formName,
      title: formTitle,
      licenseNo: formLicenseNo,
      experienceYears: formExperienceYears,
      bio: formBio,
      qualificationsList: formQualifications,
      educationList: formEducation,
      trainingExperiences: formTraining,
      supervisionHours: formSupervisionHours,
      personalTherapyHours: formPersonalTherapyHours,
      specialties: formSpecialties,
      targetAudience: formTargetAudience,
      proficientServices: formProficientServices,
      workingLanguages: formLanguages,
      orientations: formOrientations,
      counselingStyle: formStyle,
      targetGroups: formTargetAudience.length > 0 ? formTargetAudience : consultant.targetGroups,
    };

    if (onUpdateConsultant) {
      onUpdateConsultant(updated);
    }
    setQualificationsViewMode('view');
    alert('咨询师资质档案与个人介绍已成功保存更新！');
  };

  // ============================================================================
  // END OF STATE
  // ============================================================================

  return (
    <div className="space-y-4 animate-in fade-in duration-200">
      
      {/* DEFAULT MAIN MENU PAGE VIEW */}
      {activeSection === 'menu' && (
        <div className="space-y-4">
          
          {/* M3 Elevated Profile Summary Card */}
          <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-5 shadow-2xs space-y-4 relative overflow-hidden group">
            <div className="absolute top-0 right-0 w-48 h-48 bg-[#E8E2D5]/30 rounded-full blur-2xl -mr-16 -mt-16 pointer-events-none" />
            <button 
              onClick={() => {
                setQualificationsViewMode('edit');
                setActiveSection('profile_edit');
              }}
              className="absolute top-4 right-4 p-2 bg-[#FAF8F5] hover:bg-[#E8E2D5] rounded-full text-[#6750A4] transition z-20"
              title="编辑个人资料"
            >
              <Edit3 className="w-4 h-4" />
            </button>

            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 relative z-10">
              
              <div className="flex items-center gap-3.5">
                <div className="relative shrink-0">
                  <img
                    src={consultant.avatar}
                    alt={consultant.name}
                    className="w-16 h-16 rounded-full object-cover ring-2 ring-[#6750A4]/20 shadow-2xs"
                  />
                  {avatarReviewStatus === 'pending' && (
                    <span className="absolute -bottom-2 left-1/2 -translate-x-1/2 whitespace-nowrap rounded-full bg-[#FFF3D6] px-2 py-0.5 text-[9px] font-bold text-[#7A5700] border border-[#E8C86A]">头像审核中</span>
                  )}
                  <span className="absolute bottom-0 right-0 bg-[#6750A4] text-white p-1 rounded-full border-2 border-white" title="实名认证">
                    <ShieldCheck className="w-3.5 h-3.5" />
                  </span>
                </div>

                <div className="space-y-1">
                  <div className="flex items-center gap-2 flex-wrap">
                    <h2 className="text-[18px] font-bold text-[#1D1B16]">{consultant.name}</h2>
                    <span className="bg-[#EADDFF] text-[#21005D] text-[11px] px-2.5 py-0.5 rounded-full font-semibold border border-[#D0BCFF] flex items-center gap-1">
                      <Award className="w-3 h-3 text-[#21005D]" />
                      CPS 认证在籍
                    </span>
                  </div>

                  <p className="text-[13px] text-[#49463D]">{consultant.title}</p>
                  <div className="text-[12px] text-[#7A756C] font-mono">执业证书: {consultant.licenseNo}</div>
                </div>
              </div>

              {/* M3 Metric Chips Grid */}
              <div className="grid grid-cols-3 gap-2 border-t sm:border-t-0 sm:border-l border-[#ECE6DC] pt-3 sm:pt-0 sm:pl-5 w-full sm:w-auto">
                <div className="bg-[#FAF8F5] border border-[#ECE6DC] p-2.5 rounded-[18px] text-center">
                  <div className="text-[10px] text-[#7A756C]">累计服务时长</div>
                  <div className="text-base font-bold text-[#6750A4] font-mono mt-0.5">{consultant.totalHours}h</div>
                </div>
                <div className="bg-[#FAF8F5] border border-[#ECE6DC] p-2.5 rounded-[18px] text-center">
                  <div className="text-[10px] text-[#7A756C]">已服务个案</div>
                  <div className="text-base font-bold text-[#1D1B16] font-mono mt-0.5">{consultant.totalClients}人</div>
                </div>
                <div className="bg-[#FAF8F5] border border-[#ECE6DC] p-2.5 rounded-[18px] text-center">
                  <div className="text-[10px] text-[#7A756C]">咨询师评分</div>
                  <div className="text-base font-bold text-[#A23F1E] font-mono mt-0.5">{consultant.rating} ★</div>
                </div>
              </div>

            </div>
          </div>

          {/* Independent Page Hub Entry List - Orders & Income */}
          <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-2 shadow-2xs space-y-1">
            <div className="px-4 pt-2 pb-1 text-[13px] font-bold text-[#7A756C] flex items-center gap-1.5">
              <Receipt className="w-4 h-4 text-[#6750A4]" />
              <span>订单与收入</span>
            </div>
            
            {/* New: Orders Management Item */}
            <button
              onClick={() => setActiveSection('history_orders')}
              className="w-full p-4 rounded-[20px] hover:bg-[#FAF8F5] transition flex items-center justify-between group active:scale-[0.99]"
            >
              <div className="flex items-center gap-3.5">
                <div className="w-11 h-11 rounded-full bg-[#FAF8F5] text-[#49463D] flex items-center justify-center shrink-0 border border-[#ECE6DC]">
                  <ShoppingBag className="w-5 h-5 text-[#6750A4]" />
                </div>
                <div className="text-left">
                  <div className="font-bold text-sm text-[#1D1B16] flex items-center gap-2">
                    <span>历史订单管理</span>
                  </div>
                  <p className="text-xs text-[#7A756C] mt-0.5">查看所有历史订单记录、退款及售后工单</p>
                </div>
              </div>
              <ChevronRight className="w-5 h-5 text-[#7A756C] group-hover:text-[#1D1B16] group-hover:translate-x-0.5 transition shrink-0" />
            </button>

            <div className="h-px bg-[#ECE6DC] mx-4" />

            {/* 1. 收入明细 Item */}
            <button
              onClick={onOpenIncomeView}
              className="w-full p-4 rounded-[20px] hover:bg-[#FAF8F5] transition flex items-center justify-between group active:scale-[0.99]"
            >
              <div className="flex items-center gap-3.5">
                <div className="w-11 h-11 rounded-full bg-[#FAF8F5] text-[#49463D] flex items-center justify-center shrink-0 border border-[#ECE6DC]">
                  <Wallet className="w-5 h-5 text-[#6750A4]" />
                </div>
                <div className="text-left">
                  <div className="font-bold text-sm text-[#1D1B16] flex items-center gap-2">
                    <span>收入明细与提现</span>
                    <span className="text-[10px] bg-[#EADDFF] text-[#21005D] font-mono px-2 py-0.2 rounded-full font-semibold">
                      可提现: ¥{consultant.earnings.withdrawable.toFixed(2)}
                    </span>
                  </div>
                  <p className="text-xs text-[#7A756C] mt-0.5">订单账单明细、提现申请、财务打款记录与收款银行卡维护</p>
                </div>
              </div>
              <ChevronRight className="w-5 h-5 text-[#7A756C] group-hover:text-[#1D1B16] group-hover:translate-x-0.5 transition shrink-0" />
            </button>
          </div>

          {/* New Module: 业务与规则设置 */}
          <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-2 shadow-2xs space-y-1">
            <div className="px-4 pt-2 pb-1 text-[13px] font-bold text-[#7A756C] flex items-center gap-1.5">
              <Sliders className="w-4 h-4 text-[#6750A4]" />
              <span>业务与规则设置</span>
            </div>
            
            {/* 4. 资质档案 Item */}
            <button
              onClick={() => setActiveSection('qualifications')}
              className="w-full p-4 rounded-[20px] hover:bg-[#FAF8F5] transition flex items-center justify-between group active:scale-[0.99]"
            >
              <div className="flex items-center gap-3.5">
                <div className="w-11 h-11 rounded-full bg-[#FAF8F5] text-[#49463D] flex items-center justify-center shrink-0 border border-[#ECE6DC]">
                  <ShieldCheck className="w-5 h-5 text-[#6750A4]" />
                </div>
                <div className="text-left">
                  <div className="font-bold text-sm text-[#1D1B16] flex items-center gap-2">
                    <span>资质认证</span>
                    <span className="text-[10px] bg-[#EADDFF] text-[#21005D] px-2 py-0.2 rounded-full font-semibold border border-[#D0BCFF]">
                      CPS 认证在籍
                    </span>
                  </div>
                  <p className="text-xs text-[#7A756C] mt-0.5">查看及管理个人从业资质认证状态</p>
                </div>
              </div>
              <ChevronRight className="w-5 h-5 text-[#7A756C] group-hover:text-[#1D1B16] group-hover:translate-x-0.5 transition shrink-0" />
            </button>

            <div className="h-px bg-[#ECE6DC] mx-4" />
            
            {/* 1. 商品设置 Item */}
            <button
              onClick={() => setActiveSection('products')}
              className="w-full p-4 rounded-[20px] hover:bg-[#FAF8F5] transition flex items-center justify-between group active:scale-[0.99]"
            >
              <div className="flex items-center gap-3.5">
                <div className="w-11 h-11 rounded-full bg-[#FAF8F5] text-[#49463D] flex items-center justify-center shrink-0 border border-[#ECE6DC]">
                  <Briefcase className="w-5 h-5 text-[#6750A4]" />
                </div>
                <div className="text-left">
                  <div className="font-bold text-sm text-[#1D1B16] flex items-center gap-2">
                    <span>我的服务</span>
                  </div>
                  <p className="text-xs text-[#7A756C] mt-0.5">管理您的咨询服务类型、价格及上架状态</p>
                </div>
              </div>
              <ChevronRight className="w-5 h-5 text-[#7A756C] group-hover:text-[#1D1B16] group-hover:translate-x-0.5 transition shrink-0" />
            </button>

            <div className="h-px bg-[#ECE6DC] mx-4" />

            {/* 2. 排班设置 Item */}
            <button
              onClick={() => setActiveSection('schedule_settings')}
              className="w-full p-4 rounded-[20px] hover:bg-[#FAF8F5] transition flex items-center justify-between group active:scale-[0.99]"
            >
              <div className="flex items-center gap-3.5">
                <div className="w-11 h-11 rounded-full bg-[#FAF8F5] text-[#49463D] flex items-center justify-center shrink-0 border border-[#ECE6DC]">
                  <CalendarDays className="w-5 h-5 text-[#6750A4]" />
                </div>
                <div className="text-left">
                  <div className="font-bold text-sm text-[#1D1B16] flex items-center gap-2">
                    <span>排班设置</span>
                  </div>
                  <p className="text-xs text-[#7A756C] mt-0.5">配置可服务时间、我的服务与预约规则</p>
                </div>
              </div>
              <ChevronRight className="w-5 h-5 text-[#7A756C] group-hover:text-[#1D1B16] group-hover:translate-x-0.5 transition shrink-0" />
            </button>

            <div className="h-px bg-[#ECE6DC] mx-4" />

            {/* 3. 平台规则 Item */}
            <button
              onClick={() => setActiveSection('platform_rules')}
              className="w-full p-4 rounded-[20px] hover:bg-[#FAF8F5] transition flex items-center justify-between group active:scale-[0.99]"
            >
              <div className="flex items-center gap-3.5">
                <div className="w-11 h-11 rounded-full bg-[#FAF8F5] text-[#49463D] flex items-center justify-center shrink-0 border border-[#ECE6DC]">
                  <FileText className="w-5 h-5 text-[#6750A4]" />
                </div>
                <div className="text-left">
                  <div className="font-bold text-sm text-[#1D1B16] flex items-center gap-2">
                    <span>平台规则</span>
                    <span className={`text-[10px] px-2 py-0.5 rounded-full font-semibold ${
                      agreementStatus === 'signed'
                        ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                        : agreementStatus === 'signing'
                          ? 'bg-amber-50 text-amber-700 border border-amber-200'
                          : 'bg-[#FFF1F0] text-[#BA1A1A] border border-[#FFDAD6]'
                    }`}>
                      {agreementStatus === 'signed' ? '已签约' : agreementStatus === 'signing' ? '签约中' : '待签约'}
                    </span>
                  </div>
                  <p className="text-xs text-[#7A756C] mt-0.5">查看平台入驻协议、隐私政策与服务条款</p>
                </div>
              </div>
              <ChevronRight className="w-5 h-5 text-[#7A756C] group-hover:text-[#1D1B16] group-hover:translate-x-0.5 transition shrink-0" />
            </button>
          </div>

          {/* Account & support — mirrors the user-side account controls. */}
          <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-2 shadow-2xs space-y-1">
            <div className="px-4 pt-2 pb-1 text-[13px] font-bold text-[#7A756C] flex items-center gap-1.5">
              <UserRoundCog className="w-4 h-4 text-[#6750A4]" />
              <span>账号与支持</span>
            </div>

            {[
              { key: 'about' as const, title: '关于我们', desc: '平台介绍、联系方式与版本信息', icon: CircleHelp },
              { key: 'feedback' as const, title: '意见反馈', desc: '提交使用问题或产品建议', icon: MessageSquareText },
              { key: 'account_security' as const, title: '账号与安全', desc: '切换身份、退出登录与账号管理', icon: LockKeyhole },
            ].map((item, index) => {
              const Icon = item.icon;
              return (
                <React.Fragment key={item.key}>
                  {index > 0 && <div className="h-px bg-[#ECE6DC] mx-4" />}
                  <button
                    onClick={() => setActiveSection(item.key)}
                    className="w-full p-4 rounded-[20px] hover:bg-[#FAF8F5] transition flex items-center justify-between group active:scale-[0.99]"
                  >
                    <div className="flex items-center gap-3.5 min-w-0">
                      <div className="w-11 h-11 rounded-full bg-[#FAF8F5] flex items-center justify-center shrink-0 border border-[#ECE6DC]">
                        <Icon className="w-5 h-5 text-[#6750A4]" />
                      </div>
                      <div className="text-left min-w-0">
                        <div className="font-bold text-sm text-[#1D1B16]">{item.title}</div>
                        <p className="text-xs text-[#7A756C] mt-0.5 truncate">{item.desc}</p>
                      </div>
                    </div>
                    <ChevronRight className="w-5 h-5 text-[#7A756C] shrink-0" />
                  </button>
                </React.Fragment>
              );
            })}
          </div>

        </div>
      )}





      {/* DEDICATED PAGE 3: Service Products Catalog */}
      {activeSection === 'products' && (
        <div className="space-y-4 animate-in fade-in duration-200">
          <div className="flex items-center gap-2">
            <button
              onClick={() => setActiveSection('menu')}
              className="p-1.5 -ml-1.5 rounded-full text-[#6750A4] hover:bg-[#E8E2D5] transition active:scale-95 flex items-center gap-1 font-semibold text-xs"
            >
              <ArrowLeft className="w-4 h-4" />
              <span>返回列表</span>
            </button>
            <span className="text-[#ECE6DC]">/</span>
            <span className="text-xs font-bold text-[#1D1B16]">我的服务</span>
          </div>

          <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-5 shadow-2xs space-y-4">
            <div className="pb-2 border-b border-[#ECE6DC]">
              <h3 className="font-bold text-sm text-[#1D1B16]">咨询服务商品状态管理</h3>
              <p className="text-xs text-[#7A756C] mt-0.5">根据您的排班设置（最小预约时长：{bookingRule.minDuration}分钟），系统将自动为您过滤不符合规则的短时长服务。</p>
            </div>

            {products.filter(prod => prod.durationMinutes >= bookingRule.minDuration).length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                {products.filter(prod => prod.durationMinutes >= bookingRule.minDuration).map((prod) => (
                  <div key={prod.id} className="bg-[#FAF8F5] border border-[#ECE6DC] rounded-[20px] p-4 space-y-3">
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <div className="flex items-center gap-2">
                          <h4 className="font-bold text-sm text-[#1D1B16]">{prod.name}</h4>
                        </div>
                        <p className="text-xs text-[#49463D] mt-1 leading-relaxed">{prod.description}</p>
                      </div>

                      <button
                        onClick={() => onToggleProductPublish(prod.id)}
                        className="text-[#6750A4] hover:opacity-80 transition active:scale-95 shrink-0"
                        title="上架/下架开关"
                      >
                        {prod.isPublished ? (
                          <ToggleRight className="w-8 h-8 text-[#6750A4]" />
                        ) : (
                          <ToggleLeft className="w-8 h-8 text-[#7A756C]" />
                        )}
                      </button>
                    </div>

                    <div className="flex items-center justify-between pt-2 border-t border-[#ECE6DC] text-xs">
                      <div className="text-[#7A756C]">
                        服务时长: <strong className="text-[#1D1B16] font-mono">{prod.durationMinutes || 50} 分钟</strong>
                      </div>

                      <div className="flex items-center gap-2">
                        <span className="text-base font-bold font-mono text-[#6750A4]">¥{prod.price}</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-10 bg-[#FAF8F5] border border-[#ECE6DC] rounded-[20px] flex flex-col items-center">
                <div className="w-14 h-14 bg-white rounded-full flex items-center justify-center mb-3 shadow-sm border border-[#E6E0D6]">
                  <Package className="w-6 h-6 text-[#6750A4]" />
                </div>
                <h4 className="text-[15px] font-bold text-[#1D1B16] mb-1">暂无可用服务</h4>
                <p className="text-[12px] text-[#7A756C] max-w-[200px] mb-4">
                  您还没有配置任何咨询服务，或者所有服务均不符合当前的最小预约时长规则。
                </p>
                <button className="bg-[#6750A4] text-white px-5 py-2 rounded-full text-[13px] font-bold shadow-sm active:scale-95 transition hover:bg-[#594294]">
                  添加咨询服务
                </button>
              </div>
            )}
          </div>
        </div>
      )}

      {/* DEDICATED PAGE 4: Certifications */}
      {activeSection === 'qualifications' && (
        <CertificationsView onBack={() => setActiveSection('menu')} />
      )}

      {/* DEDICATED PAGE: Profile Edit (previously in qualifications) */}
      {activeSection === 'profile_edit' && (
        <div className="space-y-4 animate-in fade-in duration-200">
          
          {/* Top Header & View/Edit Switcher */}
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-2">
              <button
                onClick={() => setActiveSection('menu')}
                className="p-1.5 -ml-1.5 rounded-full text-[#6750A4] hover:bg-[#E8E2D5] transition active:scale-95 flex items-center gap-1 font-semibold text-xs"
              >
                <ArrowLeft className="w-4 h-4" />
                <span>返回主页</span>
              </button>
              <span className="text-[#ECE6DC]">/</span>
              <span className="text-xs font-bold text-[#1D1B16]">个人主页与档案</span>
            </div>

            {/* Mode Switcher Buttons */}
            <div className="flex items-center gap-1 bg-[#E8E2D5] p-1 rounded-full border border-[#DCD5C8]">
              <button
                type="button"
                onClick={() => setQualificationsViewMode('view')}
                className={`px-3 py-1 rounded-full text-[11px] font-bold transition flex items-center gap-1.5 ${
                  qualificationsViewMode === 'view'
                    ? 'bg-white text-[#6750A4] shadow-2xs'
                    : 'text-[#7A756C] hover:text-[#1D1B16]'
                }`}
              >
                <User className="w-3.5 h-3.5" />
                <span>预览名片</span>
              </button>

              <button
                type="button"
                onClick={() => setQualificationsViewMode('edit')}
                className={`px-3 py-1 rounded-full text-[11px] font-bold transition flex items-center gap-1.5 ${
                  qualificationsViewMode === 'edit'
                    ? 'bg-[#6750A4] text-white shadow-2xs'
                    : 'text-[#7A756C] hover:text-[#1D1B16]'
                }`}
              >
                <Edit3 className="w-3.5 h-3.5" />
                <span>编辑资料</span>
              </button>
            </div>
          </div>

          {/* VIEW MODE: 名片与资质介绍预览 */}
          {qualificationsViewMode === 'view' && (
            <div className="space-y-4 text-xs text-[#1D1B16]">
              
              {/* Consultant Card Header */}
              <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-4 sm:p-5 shadow-2xs relative overflow-hidden">
                <div className="absolute top-0 right-0 w-32 h-32 bg-radial from-[#6750A4]/5 to-transparent rounded-bl-full pointer-events-none" />
                
                <div className="flex items-start gap-3.5 sm:gap-4 relative z-10">
                  <img
                    src={consultant.avatar}
                    alt={consultant.name}
                    className="w-16 h-16 sm:w-20 sm:h-20 rounded-2xl object-cover ring-2 ring-[#6750A4]/20 shadow-xs shrink-0"
                  />

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <h2 className="text-base sm:text-lg font-bold text-[#1D1B16]">{formName}</h2>
                      <span className="px-2 py-0.5 rounded-full bg-[#6750A4]/10 text-[#6750A4] text-[10px] font-bold flex items-center gap-1 border border-[#6750A4]/20">
                        <ShieldCheck className="w-3 h-3 text-[#6750A4]" />
                        <span>CPS 认证在籍</span>
                      </span>
                    </div>

                    <p className="text-xs text-[#49463D] font-medium mt-1">{formTitle}</p>
                    
                    <div className="flex items-center gap-2 mt-1.5 text-[11px] text-[#7A756C] font-mono flex-wrap">
                      <span>证书: {formLicenseNo}</span>
                      <span>•</span>
                      <span>从业 {formExperienceYears} 年</span>
                    </div>

                    <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 mt-3 pt-3 border-t border-[#ECE6DC] text-center">
                      <div className="bg-[#FAF8F5] p-2 rounded-[14px] border border-[#ECE6DC]">
                        <div className="text-[10px] text-[#7A756C]">个案小时</div>
                        <div className="text-xs font-bold font-mono text-[#6750A4] mt-0.5">{consultant.totalHours}h</div>
                      </div>
                      <div className="bg-[#FAF8F5] p-2 rounded-[14px] border border-[#ECE6DC]">
                        <div className="text-[10px] text-[#7A756C]">督导时长</div>
                        <div className="text-xs font-bold font-mono text-[#6750A4] mt-0.5">{formSupervisionHours}h</div>
                      </div>
                      <div className="bg-[#FAF8F5] p-2 rounded-[14px] border border-[#ECE6DC]">
                        <div className="text-[10px] text-[#7A756C]">个人体验</div>
                        <div className="text-xs font-bold font-mono text-[#6750A4] mt-0.5">{formPersonalTherapyHours}h</div>
                      </div>
                      <div className="bg-[#FAF8F5] p-2 rounded-[14px] border border-[#ECE6DC]">
                        <div className="text-[10px] text-[#7A756C]">服务人次</div>
                        <div className="text-xs font-bold font-mono text-[#6750A4] mt-0.5">{consultant.totalClients}+</div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* CARD 1: 个人简介 (Personal Bio / Self Introduction) */}
              <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-4 sm:p-5 shadow-2xs space-y-2.5">
                <div className="flex items-center gap-2 text-[#6750A4] font-bold text-xs pb-1 border-b border-[#ECE6DC]">
                  <Sparkles className="w-4 h-4 text-[#6750A4]" />
                  <span>个人简介与咨询寄语</span>
                </div>
                <div className="bg-[#FAF8F5] p-3.5 sm:p-4 rounded-[18px] border-l-4 border-l-[#6750A4] border border-[#ECE6DC] text-[#49463D] leading-relaxed text-xs italic">
                  “{formBio}”
                </div>
              </div>

              {/* CARD 2: 资质与受训 (Qualifications & Training) */}
              <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-4 sm:p-5 shadow-2xs space-y-4">
                <div className="flex items-center gap-2 text-[#6750A4] font-bold text-xs pb-1 border-b border-[#ECE6DC]">
                  <ShieldCheck className="w-4 h-4 text-[#6750A4]" />
                  <span>资质与受训背景</span>
                </div>

                <div className="space-y-3.5">
                  {/* 执业资质 */}
                  <div>
                    <h4 className="text-[11px] font-bold text-[#7A756C] uppercase tracking-wider mb-2 flex items-center gap-1.5">
                      <Award className="w-3.5 h-3.5 text-[#6750A4]" />
                      <span>执业资质与专业认证</span>
                    </h4>
                    <div className="space-y-1.5">
                      {formQualifications.map((item, idx) => (
                        <div key={idx} className="bg-[#FAF8F5] px-3 py-2 rounded-[14px] border border-[#ECE6DC] flex items-center gap-2 text-xs text-[#1D1B16]">
                          <CheckCircle2 className="w-4 h-4 text-[#6750A4] shrink-0" />
                          <span>{item}</span>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* 学历背景 */}
                  <div>
                    <h4 className="text-[11px] font-bold text-[#7A756C] uppercase tracking-wider mb-2 flex items-center gap-1.5">
                      <GraduationCap className="w-3.5 h-3.5 text-[#6750A4]" />
                      <span>学历背景</span>
                    </h4>
                    <div className="space-y-1.5">
                      {formEducation.map((item, idx) => (
                        <div key={idx} className="bg-[#FAF8F5] px-3 py-2 rounded-[14px] border border-[#ECE6DC] flex items-center gap-2 text-xs text-[#1D1B16]">
                          <Building className="w-4 h-4 text-[#6750A4] shrink-0" />
                          <span>{item}</span>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* 长短程受训 */}
                  <div>
                    <h4 className="text-[11px] font-bold text-[#7A756C] uppercase tracking-wider mb-2 flex items-center gap-1.5">
                      <BookOpen className="w-3.5 h-3.5 text-[#6750A4]" />
                      <span>长短程培训经历</span>
                    </h4>
                    <div className="space-y-1.5">
                      {formTraining.map((item, idx) => (
                        <div key={idx} className="bg-[#FAF8F5] px-3 py-2 rounded-[14px] border border-[#ECE6DC] flex items-center gap-2 text-xs text-[#1D1B16]">
                          <div className="w-1.5 h-1.5 rounded-full bg-[#6750A4] shrink-0" />
                          <span>{item}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>

              {/* CARD 3: 咨询师擅长 (Expertise, Languages, Orientations & Style) */}
              <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-4 sm:p-5 shadow-2xs space-y-4">
                <div className="flex items-center gap-2 text-[#6750A4] font-bold text-xs pb-1 border-b border-[#ECE6DC]">
                  <Compass className="w-4 h-4 text-[#6750A4]" />
                  <span>咨询师擅长与工作流派</span>
                </div>

                <div className="space-y-3.5">
                  {/* 擅长领域 */}
                  <div>
                    <h4 className="text-[11px] font-bold text-[#7A756C] uppercase tracking-wider mb-2">擅长领域</h4>
                    <div className="flex flex-wrap gap-1.5">
                      {formSpecialties.map((item, idx) => (
                        <span key={idx} className="px-3 py-1 rounded-full bg-[#6750A4]/10 text-[#6750A4] border border-[#6750A4]/20 text-xs font-semibold">
                          {item}
                        </span>
                      ))}
                    </div>
                  </div>

                  {/* 适合人群 */}
                  <div>
                    <h4 className="text-[11px] font-bold text-[#7A756C] uppercase tracking-wider mb-2">适合人群</h4>
                    <div className="flex flex-wrap gap-1.5">
                      {formTargetAudience.map((item, idx) => (
                        <span key={idx} className="px-3 py-1 rounded-full bg-[#FAF8F5] text-[#1D1B16] border border-[#ECE6DC] text-xs font-medium">
                          {item}
                        </span>
                      ))}
                    </div>
                  </div>

                  {/* 擅长服务 */}
                  <div>
                    <h4 className="text-[11px] font-bold text-[#7A756C] uppercase tracking-wider mb-2">擅长服务</h4>
                    <div className="flex flex-wrap gap-1.5">
                      {formProficientServices.map((item, idx) => (
                        <span key={idx} className="px-3 py-1 rounded-full bg-[#FAF8F5] text-[#49463D] border border-[#ECE6DC] text-xs font-medium flex items-center gap-1">
                          <Package className="w-3 h-3 text-[#6750A4]" />
                          <span>{item}</span>
                        </span>
                      ))}
                    </div>
                  </div>

                  {/* 工作语言 & 工作流派 */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-1">
                    <div className="bg-[#FAF8F5] p-3 rounded-[16px] border border-[#ECE6DC]">
                      <div className="text-[11px] font-bold text-[#7A756C] mb-1.5 flex items-center gap-1">
                        <Globe className="w-3.5 h-3.5 text-[#6750A4]" />
                        <span>工作语言</span>
                      </div>
                      <div className="flex flex-wrap gap-1">
                        {formLanguages.map((lang, idx) => (
                          <span key={idx} className="px-2 py-0.5 rounded-md bg-white text-[#1D1B16] text-[11px] border border-[#ECE6DC]">
                            {lang}
                          </span>
                        ))}
                      </div>
                    </div>

                    <div className="bg-[#FAF8F5] p-3 rounded-[16px] border border-[#ECE6DC]">
                      <div className="text-[11px] font-bold text-[#7A756C] mb-1.5 flex items-center gap-1">
                        <BookOpen className="w-3.5 h-3.5 text-[#6750A4]" />
                        <span>工作流派</span>
                      </div>
                      <div className="flex flex-wrap gap-1">
                        {formOrientations.map((orient, idx) => (
                          <span key={idx} className="px-2 py-0.5 rounded-md bg-white text-[#1D1B16] text-[11px] border border-[#ECE6DC]">
                            {orient}
                          </span>
                        ))}
                      </div>
                    </div>
                  </div>

                  {/* 咨询风格 */}
                  <div>
                    <h4 className="text-[11px] font-bold text-[#7A756C] uppercase tracking-wider mb-1.5">咨询风格</h4>
                    <div className="bg-[#FAF8F5] p-3 rounded-[16px] border border-[#ECE6DC] text-xs text-[#49463D] leading-relaxed">
                      {formStyle}
                    </div>
                  </div>
                </div>
              </div>

              {/* CARD 4: 预约须知与服务契约 (Booking Notice & Order Rules Disclaimer) */}
              <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-4 sm:p-5 shadow-2xs space-y-3">
                <div className="flex items-center justify-between pb-1 border-b border-[#ECE6DC]">
                  <div className="flex items-center gap-2 text-[#1D1B16] font-bold text-xs">
                    <FileCheck className="w-4 h-4 text-[#6750A4]" />
                    <span>预约须知与订单服务契约</span>
                  </div>
                  <span className="text-[10px] text-[#7A756C] bg-[#FAF8F5] px-2 py-0.5 rounded-full border border-[#ECE6DC]">
                    订单通用条款
                  </span>
                </div>

                <div className="space-y-2 text-[11px] text-[#49463D]">
                  <div className="bg-[#FAF8F5] p-3 rounded-[16px] border border-[#ECE6DC] space-y-1.5">
                    <div className="font-bold text-[#1D1B16] flex items-center gap-1.5 text-xs">
                      <Clock className="w-3.5 h-3.5 text-[#6750A4]" />
                      <span>1. 咨询时长与候诊</span>
                    </div>
                    <p className="pl-5 text-[#7A756C]">个体心理咨询标准时长为 50 分钟/次；请于预约时间前 5 分钟在极简咨询室界面候诊以保证服务完整体验。</p>
                  </div>

                  <div className="bg-[#FAF8F5] p-3 rounded-[16px] border border-[#ECE6DC] space-y-1.5">
                    <div className="font-bold text-[#1D1B16] flex items-center gap-1.5 text-xs">
                      <AlertCircle className="w-3.5 h-3.5 text-[#A23F1E]" />
                      <span>2. 免费改期与退订规则</span>
                    </div>
                    <ul className="pl-5 space-y-0.5 list-disc text-[#7A756C]">
                      <li>开诊前 24 小时以上：支持无损取消退款或免费调整预约时段；</li>
                      <li>开诊前 24 小时以内：取消或改期扣除 50% 订单服务费；</li>
                      <li>开诊前 12 小时以内：取消或缺席全额扣除服务费。</li>
                    </ul>
                  </div>

                  <div className="bg-[#FAF8F5] p-3 rounded-[16px] border border-[#ECE6DC] space-y-1.5">
                    <div className="font-bold text-[#1D1B16] flex items-center gap-1.5 text-xs">
                      <ShieldCheck className="w-3.5 h-3.5 text-[#6750A4]" />
                      <span>3. 伦理与危机干预提示</span>
                    </div>
                    <p className="pl-5 text-[#7A756C]">咨询过程严格遵循《中国心理学会临床与咨询心理学工作伦理守则》。若存在极高自伤、伤害他人或法定通报情形，将按规定启动紧急保密例外干预。</p>
                  </div>
                </div>

                <div className="text-[10px] text-[#7A756C] bg-[#FAF8F5] p-2.5 rounded-[12px] border border-[#ECE6DC] text-center">
                  * 提示：以上预约须知规则在来访者下单及订单确认时自动呈现并由系统履约挂载。
                </div>
              </div>

            </div>
          )}

          {/* EDIT MODE: 资质档案与个人介绍编辑表单 */}
          {qualificationsViewMode === 'edit' && (
            <form onSubmit={(e) => { e.preventDefault(); handleSaveProfile(); }} className="space-y-4 text-xs">
              
              {/* SECTION 1: 基本资料 & 个人简介 */}
              <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-4 sm:p-5 shadow-2xs space-y-3.5">
                <div className="font-bold text-xs text-[#1D1B16] flex items-center gap-2 pb-2 border-b border-[#ECE6DC]">
                  <User className="w-4 h-4 text-[#6750A4]" />
                  <span>基本资料与个人简介编辑</span>
                </div>

                <div className="rounded-[20px] border border-[#E6E0D6] bg-[#FAF8F5] p-3.5">
                  <div className="flex items-center gap-3">
                    <div className="relative shrink-0">
                      <img src={pendingAvatar || consultant.avatar} alt="头像预览" className="h-16 w-16 rounded-full object-cover" />
                      {pendingAvatar && <span className="absolute inset-x-0 bottom-0 rounded-b-full bg-black/55 py-0.5 text-center text-[9px] font-bold text-white">待审核</span>}
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <span className="font-bold text-[#1D1B16]">个人头像</span>
                        <span className={`rounded-full px-2 py-0.5 text-[10px] font-bold ${
                          avatarReviewStatus === 'approved' ? 'bg-[#DDF3E7] text-[#175C3A]' :
                          avatarReviewStatus === 'pending' ? 'bg-[#FFF3D6] text-[#7A5700]' : 'bg-[#FDE2E0] text-[#8C1D18]'
                        }`}>
                          {avatarReviewStatus === 'approved' ? '已通过' : avatarReviewStatus === 'pending' ? '审核中' : '未通过'}
                        </span>
                      </div>
                      <p className="mt-1 text-[10px] leading-relaxed text-[#7A756C]">头像将展示给来访者，更换后需平台审核；审核前不影响当前头像。</p>
                    </div>
                    <label className="cursor-pointer rounded-full bg-[#6750A4] px-3 py-2 text-[11px] font-bold text-white active:scale-95">
                      {avatarReviewStatus === 'rejected' ? '重新上传' : '更换头像'}
                      <input type="file" accept="image/*" className="hidden" onChange={handleAvatarSelected} />
                    </label>
                  </div>
                  {avatarReviewNote && <p className="mt-2 rounded-[12px] bg-white px-3 py-2 text-[10px] text-[#7A756C]">{avatarReviewNote}</p>}
                  {avatarReviewStatus === 'pending' && (
                    <div className="mt-2 flex justify-end gap-2">
                      <button type="button" onClick={() => { setAvatarReviewStatus('rejected'); setAvatarReviewNote('审核未通过：请上传本人清晰正面照，不要包含联系方式或广告水印。'); }} className="rounded-full border border-[#D0C8BC] px-3 py-1.5 text-[10px] font-bold text-[#7A756C]">Dev：模拟驳回</button>
                      <button type="button" onClick={approvePendingAvatar} className="rounded-full bg-[#EADDFF] px-3 py-1.5 text-[10px] font-bold text-[#21005D]">Dev：模拟通过</button>
                    </div>
                  )}
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="block text-[11px] font-bold text-[#7A756C] mb-1">咨询师姓名</label>
                    <input
                      type="text"
                      required
                      value={formName}
                      onChange={(e) => setFormName(e.target.value)}
                      className="w-full bg-[#FAF8F5] border border-[#E6E0D6] rounded-[14px] px-3 py-2 text-xs text-[#1D1B16] font-medium focus:outline-none focus:ring-2 focus:ring-[#6750A4]/20"
                    />
                  </div>

                  <div>
                    <label className="block text-[11px] font-bold text-[#7A756C] mb-1">执业头衔/称谓</label>
                    <input
                      type="text"
                      required
                      value={formTitle}
                      onChange={(e) => setFormTitle(e.target.value)}
                      className="w-full bg-[#FAF8F5] border border-[#E6E0D6] rounded-[14px] px-3 py-2 text-xs text-[#1D1B16] font-medium focus:outline-none focus:ring-2 focus:ring-[#6750A4]/20"
                    />
                  </div>

                  <div>
                    <label className="block text-[11px] font-bold text-[#7A756C] mb-1">证书/注册编号</label>
                    <input
                      type="text"
                      value={formLicenseNo}
                      onChange={(e) => setFormLicenseNo(e.target.value)}
                      className="w-full bg-[#FAF8F5] border border-[#E6E0D6] rounded-[14px] px-3 py-2 text-xs font-mono text-[#1D1B16] focus:outline-none focus:ring-2 focus:ring-[#6750A4]/20"
                    />
                  </div>

                  <div>
                    <label className="block text-[11px] font-bold text-[#7A756C] mb-1">从极从业年限 (年)</label>
                    <input
                      type="number"
                      min="0"
                      max="50"
                      value={formExperienceYears}
                      onChange={(e) => setFormExperienceYears(Number(e.target.value))}
                      className="w-full bg-[#FAF8F5] border border-[#E6E0D6] rounded-[14px] px-3 py-2 text-xs font-mono text-[#1D1B16] focus:outline-none focus:ring-2 focus:ring-[#6750A4]/20"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-[11px] font-bold text-[#7A756C] mb-1">个人简介与寄语 (面向来访者)</label>
                  <textarea
                    rows={3}
                    value={formBio}
                    onChange={(e) => setFormBio(e.target.value)}
                    placeholder="输入咨询师简介、接纳寄语或个人咨询理念..."
                    className="w-full bg-[#FAF8F5] border border-[#E6E0D6] rounded-[16px] p-3 text-xs text-[#1D1B16] leading-relaxed focus:outline-none focus:ring-2 focus:ring-[#6750A4]/20"
                  />
                  <span className="text-[10px] text-[#7A756C] mt-0.5 block text-right">建议 50-200 字</span>
                </div>
              </div>

              {/* SECTION 2: 资质、学历与受训经历编辑 */}
              <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-4 sm:p-5 shadow-2xs space-y-4">
                <div className="font-bold text-xs text-[#1D1B16] flex items-center gap-2 pb-2 border-b border-[#ECE6DC]">
                  <ShieldCheck className="w-4 h-4 text-[#6750A4]" />
                  <span>资质、学历与受训经历</span>
                </div>

                {/* 1. 执业资质列表 */}
                <div>
                  <label className="block text-[11px] font-bold text-[#7A756C] mb-1.5">执业资质与专业资格</label>
                  <div className="space-y-1.5 mb-2">
                    {formQualifications.map((item, idx) => (
                      <div key={idx} className="bg-[#FAF8F5] px-3 py-1.5 rounded-[12px] border border-[#ECE6DC] flex items-center justify-between text-xs">
                        <span className="text-[#1D1B16]">{item}</span>
                        <button
                          type="button"
                          onClick={() => handleRemoveItem(idx, formQualifications, setFormQualifications)}
                          className="p-1 rounded-full text-[#7A756C] hover:text-[#A23F1E] hover:bg-[#E8E2D5] transition"
                        >
                          <X className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    ))}
                  </div>

                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={newQualInput}
                      onChange={(e) => setNewQualInput(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') {
                          e.preventDefault();
                          handleAddItem(newQualInput, setNewQualInput, formQualifications, setFormQualifications);
                        }
                      }}
                      placeholder="如：中国心理学会注册心理师 (CPS-R-xxxx-xxxx)"
                      className="flex-1 bg-[#FAF8F5] border border-[#E6E0D6] rounded-[12px] px-3 py-1.5 text-xs text-[#1D1B16] focus:outline-none focus:ring-1 focus:ring-[#6750A4]"
                    />
                    <button
                      type="button"
                      onClick={() => handleAddItem(newQualInput, setNewQualInput, formQualifications, setFormQualifications)}
                      className="px-3 py-1.5 rounded-[12px] bg-[#6750A4] text-white font-semibold text-xs hover:bg-[#594294] shrink-0"
                    >
                      添加
                    </button>
                  </div>
                </div>

                {/* 2. 学历背景列表 */}
                <div>
                  <label className="block text-[11px] font-bold text-[#7A756C] mb-1.5">学历背景</label>
                  <div className="space-y-1.5 mb-2">
                    {formEducation.map((item, idx) => (
                      <div key={idx} className="bg-[#FAF8F5] px-3 py-1.5 rounded-[12px] border border-[#ECE6DC] flex items-center justify-between text-xs">
                        <span className="text-[#1D1B16]">{item}</span>
                        <button
                          type="button"
                          onClick={() => handleRemoveItem(idx, formEducation, setFormEducation)}
                          className="p-1 rounded-full text-[#7A756C] hover:text-[#A23F1E] hover:bg-[#E8E2D5] transition"
                        >
                          <X className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    ))}
                  </div>

                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={newEduInput}
                      onChange={(e) => setNewEduInput(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') {
                          e.preventDefault();
                          handleAddItem(newEduInput, setNewEduInput, formEducation, setFormEducation);
                        }
                      }}
                      placeholder="如：华东师范大学 临床与咨询心理学硕士"
                      className="flex-1 bg-[#FAF8F5] border border-[#E6E0D6] rounded-[12px] px-3 py-1.5 text-xs text-[#1D1B16] focus:outline-none focus:ring-1 focus:ring-[#6750A4]"
                    />
                    <button
                      type="button"
                      onClick={() => handleAddItem(newEduInput, setNewEduInput, formEducation, setFormEducation)}
                      className="px-3 py-1.5 rounded-[12px] bg-[#6750A4] text-white font-semibold text-xs hover:bg-[#594294] shrink-0"
                    >
                      添加
                    </button>
                  </div>
                </div>

                {/* 3. 长短程受训经历列表 */}
                <div>
                  <label className="block text-[11px] font-bold text-[#7A756C] mb-1.5">长短程培训受训经历</label>
                  <div className="space-y-1.5 mb-2">
                    {formTraining.map((item, idx) => (
                      <div key={idx} className="bg-[#FAF8F5] px-3 py-1.5 rounded-[12px] border border-[#ECE6DC] flex items-center justify-between text-xs">
                        <span className="text-[#1D1B16]">{item}</span>
                        <button
                          type="button"
                          onClick={() => handleRemoveItem(idx, formTraining, setFormTraining)}
                          className="p-1 rounded-full text-[#7A756C] hover:text-[#A23F1E] hover:bg-[#E8E2D5] transition"
                        >
                          <X className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    ))}
                  </div>

                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={newTrainInput}
                      onChange={(e) => setNewTrainInput(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') {
                          e.preventDefault();
                          handleAddItem(newTrainInput, setNewTrainInput, formTraining, setFormTraining);
                        }
                      }}
                      placeholder="如：中美心理动力学3年连续培训项目"
                      className="flex-1 bg-[#FAF8F5] border border-[#E6E0D6] rounded-[12px] px-3 py-1.5 text-xs text-[#1D1B16] focus:outline-none focus:ring-1 focus:ring-[#6750A4]"
                    />
                    <button
                      type="button"
                      onClick={() => handleAddItem(newTrainInput, setNewTrainInput, formTraining, setFormTraining)}
                      className="px-3 py-1.5 rounded-[12px] bg-[#6750A4] text-white font-semibold text-xs hover:bg-[#594294] shrink-0"
                    >
                      添加
                    </button>
                  </div>
                </div>

                {/* 4. 督导与体验时长 */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-2 border-t border-[#ECE6DC]">
                  <div>
                    <label className="block text-[11px] font-bold text-[#7A756C] mb-1">一对一督导时长 (小时)</label>
                    <input
                      type="number"
                      min="0"
                      value={formSupervisionHours}
                      onChange={(e) => setFormSupervisionHours(Number(e.target.value))}
                      className="w-full bg-[#FAF8F5] border border-[#E6E0D6] rounded-[12px] px-3 py-1.5 font-mono text-xs text-[#1D1B16] focus:outline-none focus:ring-1 focus:ring-[#6750A4]"
                    />
                  </div>

                  <div>
                    <label className="block text-[11px] font-bold text-[#7A756C] mb-1">个人体验时长 (小时)</label>
                    <input
                      type="number"
                      min="0"
                      value={formPersonalTherapyHours}
                      onChange={(e) => setFormPersonalTherapyHours(Number(e.target.value))}
                      className="w-full bg-[#FAF8F5] border border-[#E6E0D6] rounded-[12px] px-3 py-1.5 font-mono text-xs text-[#1D1B16] focus:outline-none focus:ring-1 focus:ring-[#6750A4]"
                    />
                  </div>
                </div>
              </div>

              {/* SECTION 3: 咨询师擅长、领域、人群、服务、流派与风格 */}
              <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-4 sm:p-5 shadow-2xs space-y-4">
                <div className="font-bold text-xs text-[#1D1B16] flex items-center gap-2 pb-2 border-b border-[#ECE6DC]">
                  <Compass className="w-4 h-4 text-[#6750A4]" />
                  <span>咨询师擅长、人群、流派与风格</span>
                </div>

                {/* 1. 擅长领域 */}
                <div>
                  <label className="block text-[11px] font-bold text-[#7A756C] mb-1.5">擅长领域 (议题/主题)</label>
                  <div className="flex flex-wrap gap-1.5 mb-2">
                    {formSpecialties.map((item, idx) => (
                      <span key={idx} className="px-2.5 py-1 rounded-full bg-[#6750A4]/10 text-[#6750A4] border border-[#6750A4]/20 text-xs font-medium flex items-center gap-1">
                        <span>{item}</span>
                        <button
                          type="button"
                          onClick={() => handleRemoveItem(idx, formSpecialties, setFormSpecialties)}
                          className="hover:text-[#A23F1E]"
                        >
                          <X className="w-3 h-3" />
                        </button>
                      </span>
                    ))}
                  </div>

                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={newSpecialtyInput}
                      onChange={(e) => setNewSpecialtyInput(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') {
                          e.preventDefault();
                          handleAddItem(newSpecialtyInput, setNewSpecialtyInput, formSpecialties, setFormSpecialties);
                        }
                      }}
                      placeholder="如：职场焦虑与倦怠"
                      className="flex-1 bg-[#FAF8F5] border border-[#E6E0D6] rounded-[12px] px-3 py-1.5 text-xs text-[#1D1B16] focus:outline-none focus:ring-1 focus:ring-[#6750A4]"
                    />
                    <button
                      type="button"
                      onClick={() => handleAddItem(newSpecialtyInput, setNewSpecialtyInput, formSpecialties, setFormSpecialties)}
                      className="px-3 py-1.5 rounded-[12px] bg-[#6750A4] text-white font-semibold text-xs hover:bg-[#594294] shrink-0"
                    >
                      添加
                    </button>
                  </div>
                  <div className="flex flex-wrap gap-1.5 mt-2">
                    {DEFAULT_SPECIALTIES.filter(t => !formSpecialties.includes(t)).map(tag => (
                      <button 
                        key={tag} 
                        type="button" 
                        onClick={() => handleAddTag(tag, formSpecialties, setFormSpecialties)}
                        className="px-2 py-0.5 rounded-full bg-[#FAF8F5] text-[#7A756C] border border-[#ECE6DC] text-[10px] hover:bg-[#EADDFF] hover:text-[#6750A4] hover:border-[#6750A4]/30 transition"
                      >
                        + {tag}
                      </button>
                    ))}
                  </div>
                </div>

                {/* 2. 适合人群 */}
                <div>
                  <label className="block text-[11px] font-bold text-[#7A756C] mb-1.5">适合人群 (对象人群)</label>
                  <div className="flex flex-wrap gap-1.5 mb-2">
                    {formTargetAudience.map((item, idx) => (
                      <span key={idx} className="px-2.5 py-1 rounded-full bg-[#FAF8F5] text-[#1D1B16] border border-[#ECE6DC] text-xs font-medium flex items-center gap-1">
                        <span>{item}</span>
                        <button
                          type="button"
                          onClick={() => handleRemoveItem(idx, formTargetAudience, setFormTargetAudience)}
                          className="hover:text-[#A23F1E]"
                        >
                          <X className="w-3 h-3" />
                        </button>
                      </span>
                    ))}
                  </div>

                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={newAudienceInput}
                      onChange={(e) => setNewAudienceInput(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') {
                          e.preventDefault();
                          handleAddItem(newAudienceInput, setNewAudienceInput, formTargetAudience, setFormTargetAudience);
                        }
                      }}
                      placeholder="如：成人 (18-50岁) / 高敏人群"
                      className="flex-1 bg-[#FAF8F5] border border-[#E6E0D6] rounded-[12px] px-3 py-1.5 text-xs text-[#1D1B16] focus:outline-none focus:ring-1 focus:ring-[#6750A4]"
                    />
                    <button
                      type="button"
                      onClick={() => handleAddItem(newAudienceInput, setNewAudienceInput, formTargetAudience, setFormTargetAudience)}
                      className="px-3 py-1.5 rounded-[12px] bg-[#6750A4] text-white font-semibold text-xs hover:bg-[#594294] shrink-0"
                    >
                      添加
                    </button>
                  </div>
                  <div className="flex flex-wrap gap-1.5 mt-2">
                    {DEFAULT_AUDIENCES.filter(t => !formTargetAudience.includes(t)).map(tag => (
                      <button 
                        key={tag} 
                        type="button" 
                        onClick={() => handleAddTag(tag, formTargetAudience, setFormTargetAudience)}
                        className="px-2 py-0.5 rounded-full bg-[#FAF8F5] text-[#7A756C] border border-[#ECE6DC] text-[10px] hover:bg-[#EADDFF] hover:text-[#6750A4] hover:border-[#6750A4]/30 transition"
                      >
                        + {tag}
                      </button>
                    ))}
                  </div>
                </div>

                {/* 3. 擅长服务 */}
                <div>
                  <label className="block text-[11px] font-bold text-[#7A756C] mb-1.5">擅长服务类型</label>
                  <div className="flex flex-wrap gap-1.5 mb-2">
                    {formProficientServices.map((item, idx) => (
                      <span key={idx} className="px-2.5 py-1 rounded-full bg-[#FAF8F5] text-[#49463D] border border-[#ECE6DC] text-xs font-medium flex items-center gap-1">
                        <span>{item}</span>
                        <button
                          type="button"
                          onClick={() => handleRemoveItem(idx, formProficientServices, setFormProficientServices)}
                          className="hover:text-[#A23F1E]"
                        >
                          <X className="w-3 h-3" />
                        </button>
                      </span>
                    ))}
                  </div>

                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={newServiceInput}
                      onChange={(e) => setNewServiceInput(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') {
                          e.preventDefault();
                          handleAddItem(newServiceInput, setNewServiceInput, formProficientServices, setFormProficientServices);
                        }
                      }}
                      placeholder="如：50分钟个体心理咨询 / 15分钟倾听"
                      className="flex-1 bg-[#FAF8F5] border border-[#E6E0D6] rounded-[12px] px-3 py-1.5 text-xs text-[#1D1B16] focus:outline-none focus:ring-1 focus:ring-[#6750A4]"
                    />
                    <button
                      type="button"
                      onClick={() => handleAddItem(newServiceInput, setNewServiceInput, formProficientServices, setFormProficientServices)}
                      className="px-3 py-1.5 rounded-[12px] bg-[#6750A4] text-white font-semibold text-xs hover:bg-[#594294] shrink-0"
                    >
                      添加
                    </button>
                  </div>
                  <div className="flex flex-wrap gap-1.5 mt-2">
                    {DEFAULT_SERVICES.filter(t => !formProficientServices.includes(t)).map(tag => (
                      <button 
                        key={tag} 
                        type="button" 
                        onClick={() => handleAddTag(tag, formProficientServices, setFormProficientServices)}
                        className="px-2 py-0.5 rounded-full bg-[#FAF8F5] text-[#7A756C] border border-[#ECE6DC] text-[10px] hover:bg-[#EADDFF] hover:text-[#6750A4] hover:border-[#6750A4]/30 transition"
                      >
                        + {tag}
                      </button>
                    ))}
                  </div>
                </div>

                {/* 4. 工作语言 */}
                <div>
                  <label className="block text-[11px] font-bold text-[#7A756C] mb-1.5">工作语言</label>
                  <div className="flex flex-wrap gap-1.5 mb-2">
                    {formLanguages.map((item, idx) => (
                      <span key={idx} className="px-2.5 py-1 rounded-full bg-white text-[#1D1B16] border border-[#ECE6DC] text-xs font-medium flex items-center gap-1">
                        <span>{item}</span>
                        <button
                          type="button"
                          onClick={() => handleRemoveItem(idx, formLanguages, setFormLanguages)}
                          className="hover:text-[#A23F1E]"
                        >
                          <X className="w-3 h-3" />
                        </button>
                      </span>
                    ))}
                  </div>

                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={newLangInput}
                      onChange={(e) => setNewLangInput(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') {
                          e.preventDefault();
                          handleAddItem(newLangInput, setNewLangInput, formLanguages, setFormLanguages);
                        }
                      }}
                      placeholder="如：普通话 (标准) / 英语"
                      className="flex-1 bg-[#FAF8F5] border border-[#E6E0D6] rounded-[12px] px-3 py-1.5 text-xs text-[#1D1B16] focus:outline-none focus:ring-1 focus:ring-[#6750A4]"
                    />
                    <button
                      type="button"
                      onClick={() => handleAddItem(newLangInput, setNewLangInput, formLanguages, setFormLanguages)}
                      className="px-3 py-1.5 rounded-[12px] bg-[#6750A4] text-white font-semibold text-xs hover:bg-[#594294] shrink-0"
                    >
                      添加
                    </button>
                  </div>
                  <div className="flex flex-wrap gap-1.5 mt-2">
                    {DEFAULT_LANGUAGES.filter(t => !formLanguages.includes(t)).map(tag => (
                      <button 
                        key={tag} 
                        type="button" 
                        onClick={() => handleAddTag(tag, formLanguages, setFormLanguages)}
                        className="px-2 py-0.5 rounded-full bg-[#FAF8F5] text-[#7A756C] border border-[#ECE6DC] text-[10px] hover:bg-[#EADDFF] hover:text-[#6750A4] hover:border-[#6750A4]/30 transition"
                      >
                        + {tag}
                      </button>
                    ))}
                  </div>
                </div>

                {/* 5. 工作流派 */}
                <div>
                  <label className="block text-[11px] font-bold text-[#7A756C] mb-1.5">工作流派 (理论取向)</label>
                  <div className="flex flex-wrap gap-1.5 mb-2">
                    {formOrientations.map((item, idx) => (
                      <span key={idx} className="px-2.5 py-1 rounded-full bg-white text-[#1D1B16] border border-[#ECE6DC] text-xs font-medium flex items-center gap-1">
                        <span>{item}</span>
                        <button
                          type="button"
                          onClick={() => handleRemoveItem(idx, formOrientations, setFormOrientations)}
                          className="hover:text-[#A23F1E]"
                        >
                          <X className="w-3 h-3" />
                        </button>
                      </span>
                    ))}
                  </div>

                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={newOrientInput}
                      onChange={(e) => setNewOrientInput(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') {
                          e.preventDefault();
                          handleAddItem(newOrientInput, setNewOrientInput, formOrientations, setFormOrientations);
                        }
                      }}
                      placeholder="如：人本主义 / CBT / 精神分析"
                      className="flex-1 bg-[#FAF8F5] border border-[#E6E0D6] rounded-[12px] px-3 py-1.5 text-xs text-[#1D1B16] focus:outline-none focus:ring-1 focus:ring-[#6750A4]"
                    />
                    <button
                      type="button"
                      onClick={() => handleAddItem(newOrientInput, setNewOrientInput, formOrientations, setFormOrientations)}
                      className="px-3 py-1.5 rounded-[12px] bg-[#6750A4] text-white font-semibold text-xs hover:bg-[#594294] shrink-0"
                    >
                      添加
                    </button>
                  </div>
                  <div className="flex flex-wrap gap-1.5 mt-2">
                    {DEFAULT_ORIENTATIONS.filter(t => !formOrientations.includes(t)).map(tag => (
                      <button 
                        key={tag} 
                        type="button" 
                        onClick={() => handleAddTag(tag, formOrientations, setFormOrientations)}
                        className="px-2 py-0.5 rounded-full bg-[#FAF8F5] text-[#7A756C] border border-[#ECE6DC] text-[10px] hover:bg-[#EADDFF] hover:text-[#6750A4] hover:border-[#6750A4]/30 transition"
                      >
                        + {tag}
                      </button>
                    ))}
                  </div>
                </div>

                {/* 6. 咨询风格 */}
                <div>
                  <label className="block text-[11px] font-bold text-[#7A756C] mb-1">咨询风格描述</label>
                  <textarea
                    rows={2}
                    value={formStyle}
                    onChange={(e) => setFormStyle(e.target.value)}
                    placeholder="描述您的沟通语气、陪伴习惯与核心咨询风格..."
                    className="w-full bg-[#FAF8F5] border border-[#E6E0D6] rounded-[16px] p-3 text-xs text-[#1D1B16] leading-relaxed focus:outline-none focus:ring-2 focus:ring-[#6750A4]/20"
                  />
                </div>
              </div>

              {/* Form Bottom Save Action Bar */}
              <div className="sticky bottom-4 z-20 bg-[#FAF8F5]/90 backdrop-blur-md p-3.5 rounded-[20px] border border-[#ECE6DC] shadow-lg flex items-center justify-between gap-3">
                <button
                  type="button"
                  onClick={() => setQualificationsViewMode('view')}
                  className="px-4 py-2 rounded-full border border-[#E6E0D6] bg-white text-[#49463D] font-semibold hover:bg-[#E8E2D5] active:scale-95 transition"
                >
                  取消/放弃修改
                </button>

                <button
                  type="submit"
                  className="px-6 py-2 rounded-full bg-[#6750A4] text-white font-semibold hover:bg-[#594294] shadow-2xs active:scale-95 transition flex items-center gap-1.5"
                >
                  <Save className="w-4 h-4" />
                  <span>保存资质档案</span>
                </button>
              </div>

            </form>
          )}

        </div>
      )}


      {/* DEDICATED PAGE 5: Schedule Settings */}
      {activeSection === 'schedule_settings' && (
        <ScheduleSettingsView 
          onBack={() => setActiveSection('menu')} 
          rule={bookingRule}
          onRuleChange={setBookingRule}
          products={products}
          isMockEmpty={isMockEmpty}
          onScheduleConfigured={onScheduleConfigured}
        />
      )}

      {/* DEDICATED PAGE 6: Platform Rules */}
      {/* PLATFORM RULES SUB PAGE */}
      {activeSection === 'platform_rules' && (
        <div className="space-y-4 animate-in fade-in duration-200">
          <div className="flex items-center gap-2">
            <button
              onClick={() => {
                if (selectedRule) {
                  setSelectedRule(null);
                } else {
                  setActiveSection('menu');
                }
              }}
              className="p-1.5 -ml-1.5 rounded-full text-[#6750A4] hover:bg-[#E8E2D5] transition active:scale-95 flex items-center gap-1 font-semibold text-xs"
            >
              <ArrowLeft className="w-4 h-4" />
              <span>{selectedRule ? '返回规则列表' : '返回'}</span>
            </button>
            <span className="text-[#ECE6DC]">/</span>
            <span className="text-xs font-bold text-[#1D1B16] truncate max-w-[200px]">
              {selectedRule ? selectedRule.title : '平台规则'}
            </span>
          </div>

          {!selectedRule ? (
            <div className="bg-white border border-[#E6E0D6] rounded-[24px] overflow-hidden shadow-2xs">
              <div className="p-5 pb-3 border-b border-[#ECE6DC]">
                <h3 className="font-bold text-[15px] text-[#1D1B16] flex items-center gap-2">
                  <FileText className="w-5 h-5 text-[#6750A4]" /> 平台运营与服务条款
                </h3>
                <p className="text-xs text-[#7A756C] mt-1.5">以下规则由平台运营统一发布，点击可查看完整条款详情。</p>
              </div>
              <div className="divide-y divide-[#ECE6DC]">
                {MOCK_PLATFORM_RULES.map((rule) => (
                  <button 
                    key={rule.id}
                    onClick={() => setSelectedRule(rule)}
                    className="w-full text-left p-5 hover:bg-[#FAF8F5] transition flex items-center justify-between group"
                  >
                    <div className="min-w-0">
                      <div className="flex items-center gap-2">
                        <div className="truncate font-bold text-[14px] text-[#1D1B16] group-hover:text-[#6750A4] transition">{rule.title}</div>
                        {rule.isAgreement && (
                          <span className={`shrink-0 text-[10px] px-2 py-0.5 rounded-full font-semibold ${
                            agreementStatus === 'signed'
                              ? 'bg-emerald-50 text-emerald-700'
                              : agreementStatus === 'signing'
                                ? 'bg-amber-50 text-amber-700'
                                : 'bg-[#FFF1F0] text-[#BA1A1A]'
                          }`}>
                            {agreementStatus === 'signed' ? '已签约' : agreementStatus === 'signing' ? '签约中' : '待签约'}
                          </span>
                        )}
                      </div>
                      <div className="text-xs text-[#7A756C] mt-1">版本 {rule.version} · 发布日期 {rule.date}</div>
                    </div>
                    <ChevronRight className="w-5 h-5 text-[#7A756C] group-hover:translate-x-0.5 transition" />
                  </button>
                ))}
              </div>
            </div>
          ) : (
            <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-6 shadow-2xs min-h-[60vh]">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <h2 className="font-bold text-[18px] text-[#1D1B16] mb-2">{selectedRule.title}</h2>
                  <div className="text-xs text-[#7A756C]">协议版本: {selectedRule.version}</div>
                </div>
                {selectedRule.isAgreement && (
                  <span className={`shrink-0 text-[11px] px-2.5 py-1 rounded-full font-bold ${
                    agreementStatus === 'signed'
                      ? 'bg-emerald-50 text-emerald-700'
                      : agreementStatus === 'signing'
                        ? 'bg-amber-50 text-amber-700'
                        : 'bg-[#FFF1F0] text-[#BA1A1A]'
                  }`}>
                    {agreementStatus === 'signed' ? '已签约' : agreementStatus === 'signing' ? '签约中' : '待签约'}
                  </span>
                )}
              </div>
              <div className="text-xs text-[#7A756C] mb-6 mt-3 pb-4 border-b border-[#ECE6DC]">最后更新: {selectedRule.date} · 发布方: 可鹿平台运营中心</div>
              <div className="text-[14px] text-[#49463D] leading-loose whitespace-pre-wrap">
                {selectedRule.content}
              </div>

              {selectedRule.isAgreement && (
                <div className="mt-8 border-t border-[#ECE6DC] pt-6">
                  {agreementStatus === 'pending' && (
                    <div className="rounded-[20px] bg-[#F6F1FF] p-5">
                      <div className="flex items-start gap-3">
                        <FileCheck className="mt-0.5 h-5 w-5 shrink-0 text-[#6750A4]" />
                        <div>
                          <h3 className="font-bold text-[15px] text-[#1D1B16]">协议待签署</h3>
                          <p className="mt-1 text-[12px] leading-5 text-[#7A756C]">请核对协议版本并由咨询师本人完成电子签名。签署记录将用于平台入驻与后续协议审计。</p>
                        </div>
                      </div>
                      <button
                        onClick={() => setAgreementStatus('signing')}
                        className="mt-4 h-11 w-full rounded-full bg-[#6750A4] text-[14px] font-bold text-white shadow-sm transition active:scale-[.99]"
                      >
                        开始签约
                      </button>
                    </div>
                  )}

                  {agreementStatus === 'signing' && (
                    <div className="rounded-[20px] border border-[#E6E0D6] bg-[#FAF8F5] p-5">
                      <div className="mb-4 flex items-center gap-2">
                        <Edit3 className="h-5 w-5 text-[#6750A4]" />
                        <h3 className="font-bold text-[15px] text-[#1D1B16]">咨询师电子签名</h3>
                      </div>
                      <label className="block text-[12px] font-semibold text-[#625F58]">签署人姓名</label>
                      <input
                        value={signatureName}
                        onChange={(event) => setSignatureName(event.target.value)}
                        placeholder="请输入与实名认证一致的姓名"
                        className="mt-2 h-12 w-full rounded-[14px] border border-[#C9C5BD] bg-white px-4 text-[15px] outline-none focus:border-[#6750A4] focus:ring-2 focus:ring-[#EADDFF]"
                      />
                      <label className="mt-4 flex cursor-pointer items-start gap-3 text-[12px] leading-5 text-[#625F58]">
                        <input
                          type="checkbox"
                          checked={agreementChecked}
                          onChange={(event) => setAgreementChecked(event.target.checked)}
                          className="mt-1 h-4 w-4 accent-[#6750A4]"
                        />
                        <span>本人已完整阅读并同意《心理咨询师入驻协议》，确认使用上述姓名生成具有签约意愿的电子签名。</span>
                      </label>
                      <div className="mt-5 flex gap-3">
                        <button
                          onClick={() => setAgreementStatus('pending')}
                          className="h-11 flex-1 rounded-full border border-[#C9C5BD] bg-white text-[14px] font-bold text-[#49463D]"
                        >取消</button>
                        <button
                          disabled={!agreementChecked || !signatureName.trim()}
                          onClick={() => {
                            setSignedAt(new Date().toLocaleString('zh-CN', { hour12: false }));
                            setAgreementStatus('signed');
                          }}
                          className="h-11 flex-[1.4] rounded-full bg-[#6750A4] text-[14px] font-bold text-white disabled:cursor-not-allowed disabled:bg-[#D0CBC2]"
                        >确认签署</button>
                      </div>
                    </div>
                  )}

                  {agreementStatus === 'signed' && (
                    <div className="rounded-[20px] border border-emerald-200 bg-emerald-50/60 p-5">
                      <div className="flex items-center gap-2 text-emerald-800">
                        <CheckCircle2 className="h-5 w-5" />
                        <h3 className="font-bold text-[15px]">协议已完成签署</h3>
                      </div>
                      <div className="mt-5 grid grid-cols-2 gap-4 text-[12px] text-[#625F58]">
                        <div><span className="block text-[#938F86]">签署人</span><strong className="mt-1 block text-[14px] text-[#1D1B16]">{signatureName}</strong></div>
                        <div><span className="block text-[#938F86]">签署时间</span><strong className="mt-1 block text-[13px] text-[#1D1B16]">{signedAt || '2026/08/07 16:28:00'}</strong></div>
                        <div><span className="block text-[#938F86]">协议版本</span><strong className="mt-1 block text-[13px] text-[#1D1B16]">{selectedRule.version}</strong></div>
                        <div><span className="block text-[#938F86]">签约状态</span><strong className="mt-1 block text-[13px] text-emerald-700">有效</strong></div>
                      </div>
                      <div className="mt-5 rounded-[16px] border border-dashed border-emerald-300 bg-white/80 px-5 py-4 text-right">
                        <span className="block text-[11px] text-[#938F86]">咨询师电子签名</span>
                        <span className="mt-2 block text-[27px] font-semibold italic tracking-[0.15em] text-[#243B35]" style={{ fontFamily: 'KaiTi, STKaiti, serif' }}>{signatureName}</span>
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {/* HISTORY ORDERS VIEW */}
      {activeSection === 'history_orders' && (
        <HistoryOrdersView
          onBack={() => setActiveSection('menu')}
          onOpenOrderInfo={onOpenOrderInfo}
        />
      )}

      {activeSection === 'account_security' && (
        <div className="space-y-4 animate-in fade-in duration-200">
          <ProfileSubPageHeader title="账号与安全" onBack={() => setActiveSection('menu')} />
          <div className="rounded-[24px] border border-[#E6E0D6] bg-white p-2 shadow-2xs">
            <AccountAction
              icon={Repeat2}
              title="切换为用户端"
              description="保留当前账号，进入用户身份继续使用"
              onClick={() => {
                if (window.confirm('确认切换为用户端吗？')) onSwitchToUser?.();
              }}
            />
            <div className="h-px bg-[#ECE6DC] mx-4" />
            <AccountAction
              icon={LogOut}
              title="退出登录"
              description="退出当前账号并返回登录页"
              onClick={() => {
                if (window.confirm('确定要退出登录吗？')) onLogout?.();
              }}
            />
            <div className="h-px bg-[#ECE6DC] mx-4" />
            <AccountAction
              icon={Trash2}
              title="注销账号"
              description="提交申请后进入人工审核，数据将按规则处理"
              destructive
              onClick={() => window.alert('Mock：注销申请入口已触发。正式环境需经过身份验证、冷静期与人工审核。')}
            />
          </div>
          <div className="rounded-[20px] bg-[#F3EDF7] px-4 py-3 text-[12px] leading-5 text-[#625B71]">
            用户资料与咨询师执业资料分别保存；切换身份不会清空订单、排班或咨询记录。
          </div>
        </div>
      )}

      {activeSection === 'feedback' && (
        <div className="space-y-4 animate-in fade-in duration-200">
          <ProfileSubPageHeader title="意见反馈" onBack={() => setActiveSection('menu')} />
          <div className="rounded-[24px] border border-[#E6E0D6] bg-white p-5 shadow-2xs">
            <h3 className="text-[15px] font-bold text-[#1D1B16]">告诉我们遇到了什么</h3>
            <p className="mt-1 text-[12px] leading-5 text-[#7A756C]">请勿填写来访者姓名、联系方式或咨询记录等敏感信息。</p>
            <textarea
              value={feedbackContent}
              onChange={(event) => setFeedbackContent(event.target.value.slice(0, 500))}
              placeholder="描述问题、出现位置和期望结果…"
              className="mt-4 min-h-40 w-full resize-none rounded-[18px] border border-[#C9C5BD] bg-[#FAF8F5] p-4 text-[14px] leading-6 outline-none focus:border-[#6750A4] focus:ring-2 focus:ring-[#EADDFF]"
            />
            <div className="mt-2 text-right text-[11px] text-[#938F86]">{feedbackContent.length}/500</div>
            <button
              disabled={!feedbackContent.trim()}
              onClick={() => {
                window.alert('反馈已提交，感谢您的建议');
                setFeedbackContent('');
                setActiveSection('menu');
              }}
              className="mt-3 flex h-11 w-full items-center justify-center gap-2 rounded-full bg-[#6750A4] text-[14px] font-bold text-white disabled:bg-[#D0CBC2]"
            >
              <Send className="h-4 w-4" />提交反馈
            </button>
          </div>
        </div>
      )}

      {activeSection === 'about' && (
        <div className="space-y-4 animate-in fade-in duration-200">
          <ProfileSubPageHeader title="关于我们" onBack={() => setActiveSection('menu')} />
          <div className="rounded-[24px] border border-[#E6E0D6] bg-white p-6 text-center shadow-2xs">
            <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-[22px] bg-[#EADDFF] text-2xl font-black text-[#4F378B]">鹿</div>
            <h2 className="mt-4 text-[18px] font-bold text-[#1D1B16]">可鹿心理 · 咨询师工作台</h2>
            <p className="mt-2 text-[13px] leading-6 text-[#625F58]">连接专业咨询师与来访者，统一管理预约、咨询、回顾与服务记录。</p>
            <div className="mt-6 divide-y divide-[#ECE6DC] rounded-[18px] bg-[#FAF8F5] px-4 text-left text-[13px]">
              <div className="flex justify-between py-3"><span className="text-[#7A756C]">当前版本</span><strong>原型演示版 2.0</strong></div>
              <div className="flex justify-between py-3"><span className="text-[#7A756C]">客服邮箱</span><strong>support@kelu.example</strong></div>
              <div className="flex justify-between py-3"><span className="text-[#7A756C]">服务时间</span><strong>工作日 09:00–18:00</strong></div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

function ProfileSubPageHeader({ title, onBack }: { title: string; onBack: () => void }) {
  return (
    <div className="flex items-center gap-2">
      <button onClick={onBack} className="flex items-center gap-1 rounded-full p-1.5 text-xs font-semibold text-[#6750A4] transition hover:bg-[#E8E2D5] active:scale-95">
        <ArrowLeft className="h-4 w-4" /><span>返回</span>
      </button>
      <span className="text-[#D0CBC2]">/</span>
      <h2 className="text-xs font-bold text-[#1D1B16]">{title}</h2>
    </div>
  );
}

function AccountAction({ icon: Icon, title, description, onClick, destructive = false }: {
  icon: React.ComponentType<{ className?: string }>;
  title: string;
  description: string;
  onClick: () => void;
  destructive?: boolean;
}) {
  return (
    <button onClick={onClick} className="flex w-full items-center justify-between rounded-[18px] p-4 text-left transition hover:bg-[#FAF8F5] active:scale-[.99]">
      <div className="flex min-w-0 items-center gap-3.5">
        <div className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-full border ${destructive ? 'border-[#FFDAD6] bg-[#FFF1F0] text-[#BA1A1A]' : 'border-[#ECE6DC] bg-[#FAF8F5] text-[#6750A4]'}`}>
          <Icon className="h-5 w-5" />
        </div>
        <div className="min-w-0">
          <div className={`text-sm font-bold ${destructive ? 'text-[#BA1A1A]' : 'text-[#1D1B16]'}`}>{title}</div>
          <p className="mt-0.5 truncate text-xs text-[#7A756C]">{description}</p>
        </div>
      </div>
      <ChevronRight className="h-5 w-5 shrink-0 text-[#7A756C]" />
    </button>
  );
}

// Helper component for spinning icon
function RefreshCwSpinner({ className }: { className?: string }) {
  return (
    <svg className={className} xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 12a9 9 0 0 0-9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/>
      <path d="M3 3v5h5"/>
      <path d="M3 12a9 9 0 0 0 9 9 9.75 9.75 0 0 0 6.74-2.74L21 16"/>
      <path d="M16 16h5v5"/>
    </svg>
  );
}
