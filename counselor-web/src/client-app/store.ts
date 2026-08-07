import { create } from "zustand";
import { AppView, AppTab, UserProfile, BlackboardState } from "./types";
import { mockUser, mockOrders, mockAssessmentRecords } from "./data";

import { INITIAL_ORDERS } from "../data/mockData";
import {
  completeIntakeReviewWorkflow,
  confirmBookingWorkflow,
  endSessionWorkflow,
  normalizeConsultationWorkflow,
  saveReviewDraft as saveWorkflowReviewDraft,
  seedWorkflowFromOrders,
  submitReviewDraft as submitWorkflowReviewDraft,
} from "../consultationWorkflow";
import { buildMockReviewPatch, buildMockSessionSnapshot } from "../consultationWorkflowMock";
import type {
  ConsultationWorkflowState,
  Order,
  SessionReviewDraft,
  SessionSnapshot,
} from "../types";

const workflowTimestamp = () => new Date().toISOString();
const WORKFLOW_STORAGE_KEY = "kelu-consultation-workflow-v1";

const buildInitialWorkflow = () => {
  const timestamp = workflowTimestamp();
  const seeded = seedWorkflowFromOrders(INITIAL_ORDERS, timestamp, buildMockSessionSnapshot);
  return seeded.reviewDrafts.reduce(
    (state, draft) =>
      saveWorkflowReviewDraft(
        state,
        draft.id,
        buildMockReviewPatch(INITIAL_ORDERS.find((order) => order.id === draft.orderId)!),
        timestamp,
      ),
    seeded,
  );
};

const loadInitialWorkflow = (): ConsultationWorkflowState => {
  try {
    const stored = localStorage.getItem(WORKFLOW_STORAGE_KEY);
    if (!stored) return buildInitialWorkflow();
    const parsed = JSON.parse(stored) as ConsultationWorkflowState;
    if (!Array.isArray(parsed.reviewDrafts) || !Array.isArray(parsed.tasks) || !Array.isArray(parsed.messages)) {
      return buildInitialWorkflow();
    }
    return normalizeConsultationWorkflow(parsed);
  } catch {
    return buildInitialWorkflow();
  }
};

const persistWorkflow = (workflow: ConsultationWorkflowState) => {
  localStorage.setItem(WORKFLOW_STORAGE_KEY, JSON.stringify(workflow));
};

const defaultUser: UserProfile = {
  ...mockUser,
  name: "未登录用户",
  role: "guest",
  isNewUser: true,
};

const defaultBlackboard: BlackboardState = {
  clinical: null,
  domain: null,
  phase: 1,
  recommendation: {
    serviceLevel: "L1",
    firstTool: "呼吸引导",
    persona: "温暖陪伴",
  },
};

const defaultAssessmentState = {
  step: 0,
  answers: { stage: "", domain: "" },
  phq2Scores: [-1, -1],
  phq2Step: 0,
};

const defaultAISettings = {
  avatar: "cat" as const,
  fontSize: "medium" as const,
  theme: "light" as const,
  voice: "gentle" as const,
  autoPlayVoice: false,
};

const buildLoggedOutState = () => ({
  viewStack: ["login"] as AppView[],
  currentTab: "home" as AppTab,
  appMode: "user" as const,
  user: defaultUser,
  blackboard: defaultBlackboard,
  selectedCounselorId: "c1",
  selectedNotificationId: "n1",
  selectedConsultationId: "",
  selectedCounselorOrder: null,
  bookingOrder: null,
  bookingSummary: null,
  orders: INITIAL_ORDERS as any[],
  assessmentRecords: mockAssessmentRecords,
  activeCallSession: null,
  isCallMinimized: false,
  assessmentState: defaultAssessmentState,
  aiSettings: defaultAISettings,
  isSessionCounselorDetail: false,
  counselorStatus: "active" as const,
  activeOrderTab: "all" as const,
  consultationWorkflow: loadInitialWorkflow(),
});

const clearAuthStorage = () => {
  localStorage.removeItem("isLoggedIn");
  localStorage.removeItem("appMode");
};

export interface AppState {
  viewStack: AppView[];
  currentTab: AppTab;
  appMode: "user" | "counselor";
  user: UserProfile;
  blackboard: BlackboardState;
  selectedCounselorId: string;
  selectedNotificationId: string;
  selectedConsultationId: string;
  selectedCounselorOrder: any;
  bookingOrder: any;
  orders: any[];
  assessmentRecords: any[];
  activeCallSession: any | null;
  isCallMinimized: boolean;
  assessmentState: {
    step: number;
    answers: { stage: string; domain: string };
    phq2Scores: number[];
    phq2Step: number;
  };
  aiSettings: {
    avatar: "elephant" | "cat";
    fontSize: "small" | "medium" | "large";
    theme: "light" | "dark";
    voice: "gentle" | "sexy" | "neutral";
    autoPlayVoice: boolean;
  };
  setAssessmentState: (state: any) => void;
  updateAISettings: (settings: Partial<AppState["aiSettings"]>) => void;
  pushView: (view: AppView) => void;
  popView: () => void;
  resetToView: (view: AppView) => void;
  setTab: (tab: AppTab) => void;
  setAppMode: (mode: "user" | "counselor") => void;
  enterAppMode: (mode: "user" | "counselor") => void;
  updateUser: (data: Partial<UserProfile>) => void;
  updateBlackboard: (data: Partial<BlackboardState>) => void;
  setSelectedCounselorId: (id: string) => void;
  setSelectedNotificationId: (id: string) => void;
  setSelectedConsultationId: (id: string) => void;
  setSelectedCounselorOrder: (order: any) => void;
  setBookingOrder: (order: any) => void;
  setOrders: (orders: any[]) => void;
  addOrder: (order: any) => void;
  updateOrder: (orderId: string, data: any) => void;
  setAssessmentRecords: (records: any[]) => void;
  setActiveCallSession: (session: any | null) => void;
  setIsCallMinimized: (minimized: boolean) => void;
  isSessionCounselorDetail: boolean;
  setIsSessionCounselorDetail: (isSession: boolean) => void;
  counselorStatus: "active" | "paused";
  setCounselorStatus: (status: "active" | "paused") => void;
  activeOrderTab: "all" | "pending" | "completed" | "cancelled" | "settlement";
  setActiveOrderTab: (tab: "all" | "pending" | "completed" | "cancelled" | "settlement") => void;
  bookingSummary: any | null;
  setBookingSummary: (summary: any | null) => void;
  consultationWorkflow: ConsultationWorkflowState;
  ensureSessionReview: (order: Order, snapshot?: SessionSnapshot) => string;
  endConsultationSession: (order: Order, snapshot?: SessionSnapshot) => string;
  saveSessionReview: (draftId: string, patch: Partial<SessionReviewDraft>) => void;
  submitSessionReview: (draftId: string, patch?: Partial<SessionReviewDraft>) => { ok: boolean; errors: string[] };
  completeWorkflowTask: (taskId: string) => void;
  completeIntakeReview: (orderId: string) => void;
  confirmConsultationBooking: (orderId: string) => void;
  hasAgreedPrivacy: boolean;
  agreePrivacy: () => void;
  logout: () => void;
  deleteAccount: () => void;
}

export const useAppStore = create<AppState>((set, get) => ({
  viewStack: (() => {
    const isLoggedIn = localStorage.getItem("isLoggedIn") === "true";
    if (!isLoggedIn) return ["login"];
    return ["main"];
  })(),
  currentTab: "home",
  appMode: (localStorage.getItem("appMode") as any) || "user",
  user: localStorage.getItem("isLoggedIn") === "true" ? mockUser : defaultUser,
  blackboard: defaultBlackboard,
  selectedCounselorId: "c1",
  selectedNotificationId: "n1",
  selectedConsultationId: "",
  selectedCounselorOrder: null,
  bookingOrder: null,
  bookingSummary: null,
  orders: INITIAL_ORDERS as any[],
  assessmentRecords: mockAssessmentRecords,
  activeCallSession: null,
  isCallMinimized: false,
  isSessionCounselorDetail: false,
  counselorStatus: "active",
  activeOrderTab: "all",
  assessmentState: defaultAssessmentState,
  aiSettings: defaultAISettings,
  hasAgreedPrivacy: localStorage.getItem("hasAgreedPrivacy") === "true",
  consultationWorkflow: loadInitialWorkflow(),

  agreePrivacy: () => {
    localStorage.setItem("hasAgreedPrivacy", "true");
    set({ hasAgreedPrivacy: true });
  },

  setAssessmentState: (state: any) => set({ assessmentState: state }),
  updateAISettings: (settings: Partial<AppState["aiSettings"]>) => 
    set((state) => ({ aiSettings: { ...state.aiSettings, ...settings } })),
  
  addOrder: (order: any) => set((state) => {
    const newOrders = [order, ...state.orders];
    // Sync to counselor state if possible, though React state might not auto-sync unless handled in App.tsx
    return { orders: newOrders };
  }),
  
  updateOrder: (orderId: string, data: any) => set((state) => {
    const newOrders = state.orders.map(o => o.id === orderId ? { ...o, ...data } : o);
    const newSelectedOrder = state.selectedCounselorOrder?.id === orderId ? { ...state.selectedCounselorOrder, ...data } : state.selectedCounselorOrder;
    const newBookingOrder = state.bookingOrder?.id === orderId ? { ...state.bookingOrder, ...data } : state.bookingOrder;
    return { orders: newOrders, selectedCounselorOrder: newSelectedOrder, bookingOrder: newBookingOrder };
  }),

  pushView: (view: AppView) => set((state) => ({ viewStack: [...state.viewStack, view] })),
  popView: () => set((state) => ({ viewStack: state.viewStack.length > 1 ? state.viewStack.slice(0, -1) : state.viewStack })),
  
  resetToView: (view: AppView) => {
    set({ viewStack: [view] });
    if (view === "main" || view === "counselor-workbench") {
      localStorage.setItem("isLoggedIn", "true");
    } else if (view === "login") {
      clearAuthStorage();
    }
  },

  setTab: (tab: AppTab) => set({ currentTab: tab }),
  
  setAppMode: (mode: "user" | "counselor") => {
    set({ appMode: mode });
    localStorage.setItem("appMode", mode);
  },

  enterAppMode: (mode: "user" | "counselor") => {
    set({ appMode: mode, currentTab: "home" });
    localStorage.setItem("appMode", mode);
    get().resetToView("main");
  },

  updateUser: (data: Partial<UserProfile>) => set((state) => ({ user: { ...state.user, ...data } })),
  updateBlackboard: (data: Partial<BlackboardState>) => set((state) => ({ blackboard: { ...state.blackboard, ...data } })),
  
  setSelectedCounselorId: (id: string) => set({ selectedCounselorId: id }),
  setSelectedNotificationId: (id: string) => set({ selectedNotificationId: id }),
  setSelectedConsultationId: (id: string) => set({ selectedConsultationId: id }),
  setSelectedCounselorOrder: (order: any) => set({ selectedCounselorOrder: order }),
  setBookingOrder: (order: any) => set({ bookingOrder: order }),
  setOrders: (orders: any[]) => set({ orders }),
  setAssessmentRecords: (records: any[]) => set({ assessmentRecords: records }),
  setActiveCallSession: (session: any | null) => set({ activeCallSession: session }),
  setIsCallMinimized: (minimized: boolean) => set({ isCallMinimized: minimized }),
  setIsSessionCounselorDetail: (isSession: boolean) => set({ isSessionCounselorDetail: isSession }),
  setCounselorStatus: (status: "active" | "paused") => set({ counselorStatus: status }),
  setActiveOrderTab: (tab: "all" | "pending" | "completed" | "cancelled" | "settlement") => set({ activeOrderTab: tab }),
  setBookingSummary: (summary: any | null) => set({ bookingSummary: summary }),
  ensureSessionReview: (order, snapshot) => {
    const existing = get().consultationWorkflow.reviewDrafts.find((draft) => draft.orderId === order.id);
    if (existing) return existing.id;
    const timestamp = workflowTimestamp();
    const ended = endSessionWorkflow(
      get().consultationWorkflow,
      order,
      snapshot || buildMockSessionSnapshot(order),
      timestamp,
    );
    const draftId = `draft-${order.id}`;
    const nextWorkflow = saveWorkflowReviewDraft(
      ended,
      draftId,
      buildMockReviewPatch(order),
      timestamp,
    );
    persistWorkflow(nextWorkflow);
    set({ consultationWorkflow: nextWorkflow });
    return draftId;
  },
  endConsultationSession: (order, snapshot) => {
    const draftId = get().ensureSessionReview(order, snapshot);
    get().updateOrder(order.id, { status: "completed" });
    return draftId;
  },
  saveSessionReview: (draftId, patch) => {
    const nextWorkflow = saveWorkflowReviewDraft(
      get().consultationWorkflow,
      draftId,
      patch,
      workflowTimestamp(),
    );
    persistWorkflow(nextWorkflow);
    set({ consultationWorkflow: nextWorkflow });
  },
  submitSessionReview: (draftId, patch) => {
    let workflow = get().consultationWorkflow;
    if (patch) {
      workflow = saveWorkflowReviewDraft(workflow, draftId, patch, workflowTimestamp());
    }
    const result = submitWorkflowReviewDraft(workflow, draftId, workflowTimestamp());
    persistWorkflow(result.state);
    set({ consultationWorkflow: result.state });
    if (result.ok) {
      const orderId = result.state.reviewDrafts.find((draft) => draft.id === draftId)?.orderId;
      if (orderId) get().updateOrder(orderId, { status: "completed", hasSummary: true });
    }
    return { ok: result.ok, errors: result.errors };
  },
  completeWorkflowTask: (taskId) => {
    const current = get().consultationWorkflow;
    const nextWorkflow = {
      ...current,
      tasks: current.tasks.map((task) =>
        task.id === taskId ? { ...task, status: "completed" as const } : task,
      ),
    };
    persistWorkflow(nextWorkflow);
    set({ consultationWorkflow: nextWorkflow });
  },
  completeIntakeReview: (orderId) => {
    const nextWorkflow = completeIntakeReviewWorkflow(
      get().consultationWorkflow,
      orderId,
    );
    persistWorkflow(nextWorkflow);
    set({ consultationWorkflow: nextWorkflow });
  },
  confirmConsultationBooking: (orderId) => {
    const order = get().orders.find((item) => item.id === orderId) as Order | undefined;
    if (!order) return;
    const nextWorkflow = confirmBookingWorkflow(
      get().consultationWorkflow,
      order,
      workflowTimestamp(),
    );
    persistWorkflow(nextWorkflow);
    set((state) => ({
      consultationWorkflow: nextWorkflow,
      orders: state.orders.map((item) =>
        item.id === orderId ? { ...item, status: "scheduled" } : item,
      ),
    }));
  },
  logout: () => {
    clearAuthStorage();
    set(buildLoggedOutState());
  },
  deleteAccount: () => {
    clearAuthStorage();
    set(buildLoggedOutState());
  },
}));
