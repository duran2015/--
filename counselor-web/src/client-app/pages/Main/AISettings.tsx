import { motion } from "motion/react";
import { ChevronRight, ChevronLeft, Palette, Type, Mic, User, Check, UploadCloud } from "lucide-react";
import { useAppStore } from "../../store";
import { useState } from "react";

export function AISettings() {
  const { popView, aiSettings, updateAISettings } = useAppStore();
  const [activeSection, setActiveSection] = useState<string | null>(null);

  const toggleSection = (section: string) => {
    setActiveSection(activeSection === section ? null : section);
  };

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      transition={{ type: "spring", damping: 25, stiffness: 200 }}
      className={`absolute inset-0 z-[60] flex flex-col ${aiSettings.theme === 'dark' ? 'bg-[#121212]' : 'bg-[#f8f9fa]'}`}
    >
      {/* Header */}
      <div className={`pt-12 pb-4 px-4 sticky top-0 z-20 flex items-center shadow-sm ${aiSettings.theme === 'dark' ? 'bg-[#1A1A1A] border-b border-gray-800' : 'bg-white'}`}>
        <button
          onClick={() => popView()}
          className={`p-2 rounded-full transition-colors absolute left-4 ${aiSettings.theme === 'dark' ? 'text-gray-300 active:bg-gray-800' : 'text-gray-500 active:bg-gray-100'}`}
        >
          <ChevronLeft size={24} />
        </button>
        <h1 className={`text-[17px] font-bold mx-auto ${aiSettings.theme === 'dark' ? 'text-white' : 'text-gray-900'}`}>小鹿偏好设置</h1>
      </div>

      <div className="flex-1 overflow-y-auto pb-8">
        <div className="px-4 py-6 space-y-6">
          {/* Display Section */}
          <div className={`rounded-2xl overflow-hidden shadow-sm border ${aiSettings.theme === 'dark' ? 'bg-[#1C1C1E] border-gray-800' : 'bg-white border-gray-100'}`}>
            <h2 className={`text-[13px] font-bold uppercase tracking-wider px-4 pt-4 pb-2 ${aiSettings.theme === 'dark' ? 'text-gray-500' : 'text-gray-400'}`}>
              聊天显示
            </h2>
            <div className={`divide-y ${aiSettings.theme === 'dark' ? 'divide-gray-800' : 'divide-gray-50'}`}>
              {/* Font Size */}
              <div>
                <button 
                  onClick={() => toggleSection('fontSize')}
                  className={`w-full flex items-center justify-between p-4 transition-colors ${aiSettings.theme === 'dark' ? 'active:bg-gray-800' : 'active:bg-gray-50'}`}
                >
                  <div className="flex items-center">
                    <div className={`w-10 h-10 rounded-xl flex items-center justify-center mr-3 ${aiSettings.theme === 'dark' ? 'bg-orange-900/30 text-orange-400' : 'bg-orange-50 text-orange-500'}`}>
                      <Type size={20} />
                    </div>
                    <div className="text-left">
                      <h3 className={`font-bold text-[15px] ${aiSettings.theme === 'dark' ? 'text-white' : 'text-gray-900'}`}>字号大小</h3>
                      <p className={`text-[12px] mt-0.5 ${aiSettings.theme === 'dark' ? 'text-gray-400' : 'text-gray-500'}`}>
                        {aiSettings.fontSize === 'small' ? '小号' : aiSettings.fontSize === 'large' ? '大号' : '中号 (标准)'}
                      </p>
                    </div>
                  </div>
                  <ChevronRight size={20} className={`transition-transform ${activeSection === 'fontSize' ? 'rotate-90' : ''} ${aiSettings.theme === 'dark' ? 'text-gray-600' : 'text-gray-400'}`} />
                </button>
                {activeSection === 'fontSize' && (
                  <div className="px-4 pb-4">
                    <div className="flex bg-gray-100/50 p-1 rounded-lg mt-2">
                      {[
                        { id: 'small', label: '小号' },
                        { id: 'medium', label: '标准' },
                        { id: 'large', label: '大号' }
                      ].map(opt => (
                        <button
                          key={opt.id}
                          onClick={() => updateAISettings({ fontSize: opt.id as 'small' | 'medium' | 'large' })}
                          className={`flex-1 py-1.5 text-[13px] font-medium rounded-md transition-all ${
                            aiSettings.fontSize === opt.id 
                              ? 'bg-white text-gray-900 shadow-sm' 
                              : 'text-gray-500 hover:text-gray-700'
                          }`}
                        >
                          {opt.label}
                        </button>
                      ))}
                    </div>
                  </div>
                )}
              </div>
              
              {/* Theme */}
              <div>
                <button 
                  onClick={() => toggleSection('theme')}
                  className={`w-full flex items-center justify-between p-4 transition-colors ${aiSettings.theme === 'dark' ? 'active:bg-gray-800' : 'active:bg-gray-50'}`}
                >
                  <div className="flex items-center">
                    <div className={`w-10 h-10 rounded-xl flex items-center justify-center mr-3 ${aiSettings.theme === 'dark' ? 'bg-purple-900/30 text-purple-400' : 'bg-purple-50 text-purple-500'}`}>
                      <Palette size={20} />
                    </div>
                    <div className="text-left">
                      <h3 className={`font-bold text-[15px] ${aiSettings.theme === 'dark' ? 'text-white' : 'text-gray-900'}`}>聊天背景</h3>
                      <p className={`text-[12px] mt-0.5 ${aiSettings.theme === 'dark' ? 'text-gray-400' : 'text-gray-500'}`}>
                        {aiSettings.theme === 'dark' ? '深色模式' : '浅色模式'}
                      </p>
                    </div>
                  </div>
                  <ChevronRight size={20} className={`transition-transform ${activeSection === 'theme' ? 'rotate-90' : ''} ${aiSettings.theme === 'dark' ? 'text-gray-600' : 'text-gray-400'}`} />
                </button>
                {activeSection === 'theme' && (
                  <div className={`px-4 pb-4 border-t ${aiSettings.theme === 'dark' ? 'border-gray-800' : 'border-gray-50'}`}>
                    <div className="pt-2 space-y-1">
                      {[
                        { id: 'light', label: '浅色模式 (治愈浅蓝)' },
                        { id: 'dark', label: '深色模式 (暗夜沉浸)' }
                      ].map(opt => (
                        <button
                          key={opt.id}
                          onClick={() => updateAISettings({ theme: opt.id as 'light' | 'dark' })}
                          className={`w-full flex items-center justify-between py-3 px-2 rounded-lg transition-colors ${aiSettings.theme === opt.id ? (aiSettings.theme === 'dark' ? 'bg-gray-800/50' : 'bg-blue-50/50') : ''}`}
                        >
                          <span className={`text-[14px] font-medium ${aiSettings.theme === 'dark' ? 'text-gray-200' : 'text-gray-700'}`}>{opt.label}</span>
                          {aiSettings.theme === opt.id && <Check size={16} className="text-blue-500" />}
                        </button>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Voice Section */}
          <div className={`rounded-2xl overflow-hidden shadow-sm border ${aiSettings.theme === 'dark' ? 'bg-[#1C1C1E] border-gray-800' : 'bg-white border-gray-100'}`}>
            <h2 className={`text-[13px] font-bold uppercase tracking-wider px-4 pt-4 pb-2 ${aiSettings.theme === 'dark' ? 'text-gray-500' : 'text-gray-400'}`}>
              语音与语调 (咨询师类型)
            </h2>
            <button 
              onClick={() => toggleSection('voice')}
              className={`w-full flex items-center justify-between p-4 transition-colors ${aiSettings.theme === 'dark' ? 'active:bg-gray-800' : 'active:bg-gray-50'}`}
            >
              <div className="flex items-center">
                <div className={`w-10 h-10 rounded-xl flex items-center justify-center mr-3 ${aiSettings.theme === 'dark' ? 'bg-green-900/30 text-green-400' : 'bg-green-50 text-green-500'}`}>
                  <Mic size={20} />
                </div>
                <div className="text-left">
                  <h3 className={`font-bold text-[15px] ${aiSettings.theme === 'dark' ? 'text-white' : 'text-gray-900'}`}>小鹿语音设置</h3>
                  <p className={`text-[12px] mt-0.5 ${aiSettings.theme === 'dark' ? 'text-gray-400' : 'text-gray-500'}`}>
                    {aiSettings.voice === 'gentle' ? '温柔知性' : aiSettings.voice === 'sexy' ? '性感细腻' : '中性建议'}
                  </p>
                </div>
              </div>
              <ChevronRight size={20} className={`transition-transform ${activeSection === 'voice' ? 'rotate-90' : ''} ${aiSettings.theme === 'dark' ? 'text-gray-600' : 'text-gray-400'}`} />
            </button>
            {activeSection === 'voice' && (
              <div className={`px-4 pb-4 border-t ${aiSettings.theme === 'dark' ? 'border-gray-800' : 'border-gray-50'}`}>
                <div className="pt-2 space-y-1">
                  {[
                    { id: 'gentle', label: '温柔知性' },
                    { id: 'sexy', label: '性感细腻' },
                    { id: 'neutral', label: '中性建议' }
                  ].map(opt => (
                    <button
                      key={opt.id}
                      onClick={() => updateAISettings({ voice: opt.id as 'gentle' | 'sexy' | 'neutral' })}
                      className={`w-full flex items-center justify-between py-3 px-2 rounded-lg transition-colors ${aiSettings.voice === opt.id ? (aiSettings.theme === 'dark' ? 'bg-gray-800/50' : 'bg-blue-50/50') : ''}`}
                    >
                      <span className={`text-[14px] font-medium ${aiSettings.theme === 'dark' ? 'text-gray-200' : 'text-gray-700'}`}>{opt.label}</span>
                      {aiSettings.voice === opt.id && <Check size={16} className="text-blue-500" />}
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </motion.div>
  );
}
