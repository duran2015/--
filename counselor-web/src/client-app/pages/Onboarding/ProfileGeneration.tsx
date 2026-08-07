import { useEffect } from "react";
import { motion } from "motion/react";
import { useAppStore } from "../../store";

export function ProfileGeneration() {
  const { resetToView, updateUser } = useAppStore();

  useEffect(() => {
    const timer = setTimeout(() => {
      updateUser({ isNewUser: false });
      resetToView("main");
    }, 4000);
    return () => clearTimeout(timer);
  }, [resetToView, updateUser]);

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="flex flex-col items-center justify-center h-full bg-primary-light"
    >
      <motion.div
        animate={{
          scale: [1, 1.2, 1],
          opacity: [0.5, 1, 0.5],
        }}
        transition={{
          duration: 2,
          repeat: Infinity,
          ease: "easeInOut",
        }}
        className="w-32 h-32 bg-white rounded-full flex items-center justify-center shadow-lg shadow-primary/20 mb-8"
      >
        <svg
          fill="none"
          viewBox="0 0 24 24"
          strokeWidth="1.5"
          stroke="currentColor"
          className="w-12 h-12 text-primary"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z"
          />
        </svg>
      </motion.div>
      <h2 className="text-2xl font-bold text-gray-900 mb-2">
        生成专属心灵画像
      </h2>
      <p className="text-gray-500 animate-pulse text-sm">
        正在深度分析你的状态...
      </p>
    </motion.div>
  );
}
