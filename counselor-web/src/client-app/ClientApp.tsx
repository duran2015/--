import { useAppStore } from "./store";
import { MobileLayout } from "./components/MobileLayout";
import { motion, AnimatePresence } from "motion/react";
import "../index.css";

// Pages
import { Login } from "./pages/Onboarding/Login";
import { Assessment } from "./pages/Onboarding/Assessment";
import { AIInterview } from "./pages/Onboarding/AIInterview";
import { ProfileGeneration } from "./pages/Onboarding/ProfileGeneration";
import { MainLayout } from "./components/MainLayout";
import { AITab } from "./pages/Main/AITab";
import { Payment } from "./pages/Counseling/Payment";
import { UserEvaluation } from "./pages/Counseling/UserEvaluation";
import { Booking } from "./pages/Counseling/Booking";
import { BookingConfirm } from "./pages/Counseling/BookingConfirm";
import { PreCounselingQuestionnaire } from "./pages/Counseling/PreCounselingQuestionnaire";
import { VoiceCall } from "./pages/Counseling/VoiceCall";
import { CallSummary } from "./pages/Counseling/CallSummary";
import { OrdersList } from "./pages/Counseling/OrdersList";
import { ProfileReport } from "./pages/Profile/ProfileReport";
import { AssessmentRecords } from "./pages/Profile/AssessmentRecords";
import { AIChatRecords } from "./pages/Profile/AIChatRecords";
import { TextChat } from "./pages/Counseling/TextChat";
import { NotificationsList } from "./pages/Main/NotificationsList";
import { NotificationDetail } from "./pages/Main/NotificationDetail";
import { ConsultationRecords } from "./pages/Profile/ConsultationRecords";
import { ConsultationDetail } from "./pages/Profile/ConsultationDetail";
import { AISettings } from "./pages/Main/AISettings";

import { TreeHole } from "./pages/Main/TreeHole";
import { MiniAssessmentHome } from "./pages/Onboarding/MiniAssessmentHome";
import { MiniAssessmentTest } from "./pages/Onboarding/MiniAssessmentTest";
import { MiniAssessmentResult } from "./pages/Onboarding/MiniAssessmentResult";
import { 
  BreathingTool, 
  WhiteNoiseTool, 
  MuyuTool, 
  MeditationTool, 
  SleepGuideTool, 
  BubbleWrapTool 
} from "./pages/Main/ReliefTools";

import { UserOrderDetail } from "./pages/Counseling/UserOrderDetail";
import { AssessmentReportDetail } from "./pages/Profile/AssessmentReportDetail";
import { CounselingSummaryList } from "./pages/Profile/CounselingSummaryList";
import { CounselingSummaryDetail } from "./pages/Profile/CounselingSummaryDetail";
import { ProfileEdit } from "./pages/Profile/ProfileEdit";
import { AccountSecurity } from "./pages/Profile/AccountSecurity";
import { AboutUs } from "./pages/Profile/AboutUs";
import { LegalDocument } from "./pages/Profile/LegalDocument";
import { DeleteAccount } from "./pages/Profile/DeleteAccount";
import { AIRecommendation } from "./pages/Counseling/AIRecommendation";
import { AISummarySync } from "./pages/Counseling/AISummarySync";
import { CounselingEntrance } from "./pages/Counseling/CounselingEntrance";
import { WorkBuddyTest } from "./pages/Main/WorkBuddyTest";

function ViewManager() {
  const { viewStack, activeCallSession, appMode } = useAppStore();
  const currentView = viewStack[viewStack.length - 1];

  return (
    <>
      <AnimatePresence mode="sync">
        {currentView === "login" && <Login key="login" />}
      {currentView === "assessment" && <Assessment key="assessment" />}
      {currentView === "ai-interview" && <AIInterview key="ai-interview" />}
      {currentView === "generation" && <ProfileGeneration key="generation" />}

      {/* Main Tab Wrapper maintains continuous presence unless replaced linearly by full screen sub-views */}
      {(currentView === "main" ||
        currentView.startsWith("counseling-") ||
        currentView === "ai-chat" ||
        currentView === "orders-list" ||
        currentView === "user-order-detail" ||
        currentView === "notifications-list" ||
        currentView === "notification-detail" ||
        currentView === "consultation-records" ||
        currentView === "assessment-records" ||
        currentView === "assessment-report-detail" ||
        currentView === "ai-chat-records" ||
        currentView === "profile-report") && <MainLayout key="main" />}

      {/* Sub views stacked above Main Layout absolutely */}
      {currentView === "counseling-booking" && <Booking key="counseling_booking" />}
      {currentView === "booking-confirm" && <BookingConfirm key="booking_confirm" />}
      {currentView === "counseling-booking-confirm" && <BookingConfirm key="counseling_booking_confirm" />}
      {currentView === "pre-questionnaire" && <PreCounselingQuestionnaire key="pre_q" />}
      {currentView === "ai-chat" && (
        <div className="absolute inset-0 z-50 bg-white">
          <AITab />
        </div>
      )}
      {currentView === "counseling-payment" && <Payment key="cpayment" />}
      {currentView === "counseling-text-chat" && <TextChat key="tchat" />}
      {currentView === "voice-call" && <VoiceCall key="vcall" />}
      {currentView === "counseling-summary" && <CallSummary key="csummary" />}
      {currentView === "orders-list" && <OrdersList key="orders" />}
      {currentView === "user-order-detail" && <UserOrderDetail key="u_order_detail" />}
      {currentView === "profile-report" && <ProfileReport key="preport" />}
      {currentView === "user-evaluation" && <UserEvaluation key="ueval" />}
      {currentView === "assessment-records" && (
        <AssessmentRecords key="arecords" />
      )}
      {currentView === "assessment-report-detail" && <AssessmentReportDetail key="areport_detail" />}
      {currentView === "ai-chat-records" && <AIChatRecords key="achat_rec" />}
      {currentView === "tree-hole" && <TreeHole key="tree_hole" />}
      {currentView === "mini-assessment-home" && (
        <MiniAssessmentHome key="mini_home" />
      )}
      {currentView === "mini-assessment-test" && (
        <MiniAssessmentTest key="mini_test" />
      )}
      {currentView === "mini-assessment-result" && (
        <MiniAssessmentResult key="mini_result" />
      )}
      {currentView === "notifications-list" && <NotificationsList key="n_list" />}
      {currentView === "notification-detail" && <NotificationDetail key="n_detail" />}
      {currentView === "consultation-records" && <ConsultationRecords key="cons_records" />}
      {currentView === "consultation-detail" && <ConsultationDetail key="cons_detail" />}
      {currentView === "ai-settings" && <AISettings key="ai_settings" />}
      {currentView === "counseling-summary-list" && <CounselingSummaryList key="c_summary_list" />}
      {currentView === "counseling-summary-detail" && <CounselingSummaryDetail key="c_summary_detail" />}
      {currentView === "profile-edit" && <ProfileEdit key="p_edit" />}
      {currentView === "account-security" && <AccountSecurity key="account_security" />}
      {currentView === "delete-account" && <DeleteAccount key="delete_account" />}
      {currentView === "about-us" && <AboutUs key="about_us" />}
      {currentView === "legal-document" && <LegalDocument key="legal_document" />}
      
      {currentView === "ai-recommendation" && <AIRecommendation key="ai_rec" />}
      {currentView === "ai-summary-sync" && <AISummarySync key="ai_sync" />}
      {currentView === "counseling-entrance" && <CounselingEntrance key="c_entrance" />}
            
      {currentView === "breathing" && <BreathingTool key="tool_breathing" />}
      {currentView === "white-noise" && <WhiteNoiseTool key="tool_white_noise" />}
      {currentView === "muyu" && <MuyuTool key="tool_muyu" />}
      {currentView === "meditation" && <MeditationTool key="tool_meditation" />}
      {currentView === "sleep-guide" && <SleepGuideTool key="tool_sleep" />}
      {currentView === "bubble-wrap" && <BubbleWrapTool key="tool_bubble" />}
      {currentView === "work-buddy-test" && <WorkBuddyTest key="work_buddy_test" />}
    </AnimatePresence>
    {activeCallSession && <VoiceCall />}
    </>
  );
}

export default function ClientApp() {
  return (
    <MobileLayout>
      <ViewManager />
    </MobileLayout>
  );
}
