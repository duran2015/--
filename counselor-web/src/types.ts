export type OrderStatus = 
  | 'pending_confirm' // 待确认 (待接单)
  | 'pending_reschedule_confirm' // 待确认改期
  | 'pending_cancel_confirm' // 待确认取消
  | 'scheduled'       // 待咨询
  | 'in_progress'     // 服务中
  | 'completed'       // 已完成
  | 'refunded'        // 退款/售后
  | 'cancelled';      // 已取消

export type OrderServiceType = 
  | '50min_video'     // 50分钟视频咨询
  | '50min_audio'     // 50分钟语音咨询
  | '15min_listening'; // 15分钟极简倾听

export interface PreQuestionnaire {
  mainTopic: string;
  duration: string;
  event: string;
  expectation: string;
  hasCounselingHistory: boolean | null;
  hasSelfHarmThoughts: boolean | null;
}

export interface ClientProfile {
  id: string;
  name: string;
  avatar: string;
  gender: string;
  age: number;
  occupation: string;
  city: string;
  phone: string;
  emergencyContact: {
    name: string;
    relation: string;
    phone: string;
  };
  intakeDate: string;
  riskLevel: 'low' | 'moderate' | 'attention' | 'high';
  tags: string[];
  phq9Score?: { score: number; level: string; date?: string }; // 抑郁测评
  gad7Score?: { score: number; level: string; date?: string }; // 焦虑测评
  historySummary: {
    totalSessions: number;
    attendanceRate: string;
    primaryGoals: string[];
    counselorWorkingNotes: string;
  };
  sessionLogs: Array<{
    sessionNo: number;
    date: string;
    topic: string;
    preMoodScore?: number;
    keyBreakthrough: string;
    homeworkStatus?: 'completed' | 'partial' | 'pending';
  }>;
  preSessionCheckIns: Array<{
    date: string;
    moodScore: number;
    sleepHours: number;
    distressTrigger: string;
  }>;
  crisisInterventions?: Array<{
    id: string;
    date: string;
    type: 'suicide_risk' | 'self_harm' | 'violence' | 'other';
    description: string;
    actionTaken: string;
    status: 'resolved' | 'monitoring' | 'transferred';
  }>;
}

export interface Order {
  id: string;
  orderNo: string;
  clientId?: string;
  clientName: string;
  clientAvatar: string;
  serviceType: OrderServiceType;
  serviceTypeName: string;
  bookingDate: string; // YYYY-MM-DD
  bookingTimeSlot: string; // e.g. "14:00 - 14:50"
  price: number;
  originalPrice?: number;
  status: OrderStatus;
  paymentMethod?: string;
  consultationFormat?: 'video' | 'audio' | 'chat';
  preMoodScore?: number; // 1-10
  complaintTopic: string;
  note?: string;
  hasSummary?: boolean;
  createdAt: string;
  intakeForm?: {
    primaryIssueDetail: string;
    expectations: string;
    riskAssessmentPassed: boolean;
    hasCounselingHistory: boolean;
    previousCounselingType?: string;
  };
  preQuestionnaire?: PreQuestionnaire;
}

export interface ConsultantProfile {
  id: string;
  name: string;
  avatar: string;
  title: string; // e.g. 国家二级心理咨询师 / 注册系统心理师
  licenseNo: string;
  experienceYears: number;
  totalHours: number;
  totalClients: number;
  rating: number;
  verifiedStatus: 'verified' | 'under_review';
  isListeningActive: boolean; // 是否开启即时倾听通道
  orientations: string[]; // 疗法流派: 人本主义, CBT, 精神分析等
  targetGroups: string[]; // 擅长人群
  bio: string;

  // 资质与受训
  qualificationsList?: string[]; // 执业资质 (CPS注册心理师、国家二级等)
  educationList?: string[]; // 学历背景 (华东师范大学硕士等)
  trainingExperiences?: string[]; // 长短程受训经历
  supervisionHours?: number; // 督导时长 (小时)
  personalTherapyHours?: number; // 个人体验时长 (小时)

  // 咨询师擅长
  specialties?: string[]; // 擅长领域
  targetAudience?: string[]; // 适合人群
  proficientServices?: string[]; // 擅长服务
  workingLanguages?: string[]; // 工作语言
  counselingStyle?: string; // 咨询风格描述

  earnings: {
    withdrawable: number;
    monthlySettled: number;
    totalEarned: number;
    commissionRate: number; // e.g. 15%
  };
  referralStats: {
    totalReferrals: number;
    convertedClients: number;
    viralRevenue: number;
    activeVouchersCount: number;
  };
}

export interface TimeSlot {
  id: string;
  dayOfWeek: number; // 1-7
  time: string; // e.g. "10:00"
  status: 'available' | 'booked' | 'blocked';
  clientName?: string;
}

export interface ServiceProduct {
  id: string;
  name: string;
  type: OrderServiceType;
  durationMinutes: number;
  price: number;
  salesCount: number;
  isPublished: boolean;
  description: string;
}

export interface SettlementRecord {
  id: string;
  period: string; // e.g., "2026年07月（下半月）"
  totalAmount: number;
  platformFee: number;
  taxAmount: number;
  netAmount: number;
  payoutStatus: 'paid' | 'processing';
  payoutDate: string;
}

export interface BankAccount {
  id: string;
  accountType: 'bank_card' | 'wechat' | 'alipay';
  bankName: string;
  cardNumber: string;
  accountHolder: string;
  phone: string;
  isDefault: boolean;
}

export type WithdrawalStatus = 'applied' | 'reviewing' | 'paying' | 'success' | 'failed';

export interface WithdrawalRecord {
  id: string;
  withdrawNo: string;
  amount: number;
  bankAccount: {
    bankName: string;
    cardNumber: string;
    accountHolder: string;
  };
  status: WithdrawalStatus;
  applyTime: string;
  completedTime?: string;
  rejectReason?: string;
  financeNote?: string;
}

export type BillRecordStatus = 'pending_settlement' | 'settled' | 'refunded';

export interface BillRecord {
  id: string;
  billNo: string;
  orderId?: string;
  orderNo?: string;
  clientName: string;
  clientAvatar?: string;
  serviceTypeName: string;
  bookingDate: string;
  bookingTimeSlot?: string;
  grossAmount: number;
  platformFee: number;
  netAmount: number;
  status: BillRecordStatus;
  createdAt: string;
  settledAt?: string;
}

export interface SessionSummary {
  id: string;
  orderId: string;
  clientName: string;
  date: string;
  sessionNumber: number;
  clientMood: string;
  mainComplaint: string;
  interventions: string[];
  insights: string;
  homework: string;
  nextPlan: string;
  createdAt: string;
}

export type ConsultationSessionStatus = "scheduled" | "waiting" | "in_progress" | "ended";
export type SessionReviewStatus = "not_started" | "ai_generating" | "draft" | "submitted";
export type SessionSettlementStatus = "not_applicable" | "blocked_by_summary" | "eligible_t1" | "settled";
export type WorkflowTaskStatus = "pending" | "in_progress" | "completed" | "skipped";
export type WorkflowTaskType =
  | "confirm_booking"
  | "handle_reschedule"
  | "handle_cancel_request"
  | "complete_intake"
  | "review_intake"
  | "enter_session"
  | "complete_session_review"
  | "read_session_recap"
  | "review_counselor";

export interface SessionTranscriptSegment {
  id: string;
  sessionId: string;
  speakerRole: "client" | "counselor";
  speakerName: string;
  text: string;
  startsAtSeconds: number;
  endsAtSeconds: number;
  confidence: number;
  highlightTerms: string[];
}

export interface SessionInsight {
  id: string;
  sessionId: string;
  category: "topic" | "emotion" | "intervention" | "risk" | "plan";
  title: string;
  detail: string;
  sourceType: "transcript" | "intake" | "note" | "history" | "emotion_event";
  sourceIds: string[];
  confidence: number;
}

export interface SessionNoteSnapshot {
  id: string;
  text: string;
}

export interface SessionSnapshot {
  durationSeconds: number;
  transcript: SessionTranscriptSegment[];
  notes: SessionNoteSnapshot[];
  insights: SessionInsight[];
}

export interface SessionReviewDraft {
  id: string;
  sessionId: string;
  orderId: string;
  clientId: string;
  counselorId: string;
  status: SessionReviewStatus;
  version: number;
  sourceSnapshot: {
    transcriptSegmentIds: string[];
    insightIds: string[];
    noteIds: string[];
    intakeAvailable: boolean;
    priorRecordIds: string[];
  };
  clinicalSummary: {
    mainConcern: string;
    clientState: string;
    interventions: string[];
    observations: string;
    riskReview: string;
    nextPlan: string;
  };
  clientSummary: {
    recap: string;
    actionItems: string[];
    nextPlan: string;
  };
  counselorReflection?: {
    allianceQuality: "needs_attention" | "stable" | "strong" | null;
    goalProgress: "limited" | "partial" | "clear" | null;
    reflection: string;
  };
  updatedAt: string;
  submittedAt?: string;
}

export interface WorkflowTask {
  id: string;
  actorRole: "client" | "counselor";
  actorId: string;
  taskType: WorkflowTaskType;
  status: WorkflowTaskStatus;
  blockingSettlement: boolean;
  orderId: string;
  sessionId?: string;
  draftId?: string;
  dueAt?: string;
  createdAt: string;
}

export interface WorkflowMessage {
  id: string;
  orderId: string;
  messageType: "summary_card";
  audience: "counselor" | "client";
  sessionId: string;
  draftId: string;
  status: "pending_review" | "submitted" | "shared";
  title: string;
  description: string;
  actionLabel: string;
  clientSummary?: SessionReviewDraft["clientSummary"];
  createdAt: string;
  updatedAt: string;
}

export interface ArchivedSessionReview
  extends Omit<SessionReviewDraft, "status" | "submittedAt" | "counselorReflection"> {
  status: "submitted";
  submittedAt: string;
}

export interface ConsultationWorkflowState {
  reviewDrafts: SessionReviewDraft[];
  tasks: WorkflowTask[];
  messages: WorkflowMessage[];
  settlements: Record<string, SessionSettlementStatus>;
  snapshots: Record<string, SessionSnapshot>;
  archivedReviews: ArchivedSessionReview[];
}

export interface ViralVoucher {
  id: string;
  title: string;
  code: string;
  discountType: 'free_15min' | 'amount_off' | 'percentage';
  discountValue: number; // e.g. 50 RMB off or 100% off
  originalPrice: number;
  voucherPrice: number; // e.g. 0 for gift, or 19 RMB
  claimedCount: number;
  conversionCount: number;
  isEnabled: boolean;
}

export interface TherapyQuote {
  id: string;
  title: string;
  quote: string;
  tag: string;
  authorNote?: string;
}
export type AppView =
  | "login"
  | "assessment"
  | "ai-interview"
  | "generation"
  | "main"
  | "counseling-detail"
  | "counseling-booking"
  | "booking-confirm"
  | "pre-questionnaire"
  | "counseling-booking-confirm"
  | "counseling-payment"
  | "counseling-call"
  | "voice-call"
  | "counseling-text-chat"
  | "counseling-summary"
  | "orders-list"
  | "profile-report"
  | "assessment-records"
  | "assessment-report-detail"
  | "ai-chat-records"
  | "ai-chat"
  | "tree-hole"
  | "mini-assessment-home"
  | "mini-assessment-test"
  | "mini-assessment-result"
  | "counselor-workbench"
  | "counselor-order-detail"
  | "counselor-patient-profile"
  | "counselor-earnings"
  | "user-order-detail"
  | "user-evaluation"
  | "counseling-summary-list"
  | "counseling-summary-detail"
  | "counselor-session-notes"
  | "profile-edit"
  | "account-security"
  | "counselor-boundary"
  | "counselor-onboarding"
  | "counselor-services"
  | "counselor-schedule"
  | "counselor-user-card"
  | "counselor-risk-report"
  | "counselor-evalusions"
  | "counselor-evaluations"
  | "counselor-service-chat"
  | "counselor-clients-tab"
  | "counselor-profile-tab"
  | "counselor-account-security"
  | "counselor-growth-center"
  | "notifications-list"
  | "notification-detail"
  | "consultation-records"
  | "consultation-detail"
  | "breathing"
  | "white-noise"
  | "muyu"
  | "meditation"
  | "sleep-guide"
  | "bubble-wrap"
  | "work-buddy-test"
  | "delete-account"
  | "ai-settings"
  | "ai-recommendation"
  | "ai-summary-sync"
  | "counseling-entrance"
  | "counselor-list"
  | "about-us"
  | "legal-document";

export type AppTab = "home" | "counseling" | "counselors" | "messages" | "profile" | "appointments" | "growth" | "clients" | "earnings";

export interface UserProfile {
  id: string;
  name: string;
  avatar: string;
  age?: number;
  school?: string;
  major?: string;
  grade?: string;
  statusScore: number;
  statusTrend: number;
  statusSummary: string;
  isNewUser: boolean;
  hasRisk: boolean;
  role: "guest" | "registered" | "active";
  usedTrialCount?: number;
}

export interface BookingOrder {
  id: string;
  counselorId: string;
  date: string;
  time: string;
  price: number;
  type?: "text" | "voice" | "video";
  status: OrderStatus;
  isEvaluated?: boolean;
  counselorNotesWritten?: boolean;
}

export interface CounselorSchedule {
  date: string;
  label: string;
  isFull: boolean;
  times: string[];
}

export interface MVPCounselorSchedule {
  id: string;
  counselorId: string;
  date: string;
  shift: "morning" | "afternoon" | "evening";
  slotCount: number;
  status: "active" | "cancelled";
}

export interface Appointment {
  id: string;
  userId: string;
  counselorId: string;
  date: string;
  timeSlot: string;
  price: number;
  isTrial: boolean;
  status: OrderStatus;
  meetingUrl?: string;
  paidAt?: string;
  startedAt?: string;
  endedAt?: string;
  cancelledAt?: string;
  cancelReason?: string;
  createdAt?: string;
}

// For frontend display mapping
export interface AvailableSlot {
  time: string;
  shift: string;
  available: boolean;
}

export interface AvailabilityResponse {
  date: string;
  slots: AvailableSlot[];
  price: number;
  isTrial: boolean;
}

export interface Counselor {
  id: string;
  name: string;
  avatar: string;
  title: string;
  tags: string[]; // Keep for legacy if needed, or remove
  price: number;
  pricing?: {
    text: number;
    voice: number;
    video: number;
  };
  rating: number;
  reviewsCount: number;
  about: string;
  specialties: string[];
  schedules: CounselorSchedule[];
  type?: "pro" | "listener";
  status?: "online" | "busy" | "offline";
  styles?: string[];
  credentials?: string[];
  consultationCount?: number;
  serviceHours?: number;
}

export interface ChatMessage {
  id: string;
  role: "user" | "ai";
  content: string;
  timestamp: string;
}

export interface TodayTask {
  id: string;
  title: string;
  duration: string;
  reason: string;
  type: "breathing" | "meditation" | "cbt" | "journal";
}

// ----------------------------------------------------
// Data Architecture Systems Models
// ----------------------------------------------------

export interface ProfileTag {
  id: string;
  name: string;
  category: "emotion" | "personality" | "relationship" | "development";
  weight: number; // 0-1
}

export interface RiskProfile {
  level: "low" | "medium" | "high" | "critical";
  lastTriggers: string[];
  requiresIntervention: boolean;
  lastUpdated: string;
}

export interface AdvancedUserProfile extends UserProfile {
  userId: string;
  basicInfo: {
    age?: number;
    gender?: string;
    occupation?: string;
  };
  psychStats: {
    currentScore: number;
    trend: number;
    stressLevel: "low" | "medium" | "high";
  };
  tagsDetails: ProfileTag[];
  riskProfile: RiskProfile;
}

export interface AssessmentRecord {
  id: string;
  assessmentId: string; // e.g. 'PHQ-9'
  title: string;
  date: string;
  score: number;
  result: string;
  tagsGenerated: string[];
}

export interface ConsultationRecord {
  id: string;
  orderId: string;
  counselorId: string;
  date: string;
  duration: number; // minutes
  summary: string;
  counselorNotes: string;
  clientFeedback?: {
    rating: number;
    content: string;
  };
  actionItems: {
    text: string;
    completed: boolean;
  }[];
}

// ----------------------------------------------------
// Consultant Scheduling & Booking Engine Models
// ----------------------------------------------------

export interface ConsultantAvailability {
  id: string;
  weekday: number; // 1-7 (1=Monday)
  startTime: string; // "09:00"
  endTime: string;   // "12:00"
  status: 'active' | 'inactive';
}

export interface ConsultantService {
  id: string;
  name: string;      // e.g., "深度咨询", "情绪支持"
  type: 'video' | 'audio';
  duration: 15 | 30 | 45 | 60; // Minutes
  price: number;
  description: string;
  status: 'active' | 'inactive';
}

export interface ConsultantBookingRule {
  minDuration: 15 | 30 | 45 | 60; // Minimum bookable duration
  bufferTime: number; // Buffer time between sessions (minutes)
  advanceTime: number; // Minimum advance booking time (hours)
  cancelRule: number; // Cancellation window without penalty (hours)
  fragmentMode: 'flexible' | 'standard' | 'deep'; // Handling fragmented time slots
}

// ----------------------------------------------------
// Blackboard State Pool Models (Agent Collaboration)
// ----------------------------------------------------

export interface BlackboardState {
  clinical: {
    phq2Score: number;
    severity: "轻度" | "中度" | "重度" | "危机" | "未评估";
    crisis: boolean;
  } | null;
  domain: {
    primary: "学业" | "工作" | "情感" | "家庭" | "社交" | "自我" | "说不清" | "未分类";
    secondary?: string;
  } | null;
  phase: 1 | 2 | 3 | 4;
  recommendation: {
    serviceLevel: "L1" | "L2" | "L3" | "L4";
    firstTool?: string;
    persona?: string;
  } | null;
}
