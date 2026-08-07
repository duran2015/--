import React, { useState, useRef } from "react";
import { motion } from "motion/react";
import { useAppStore } from "../../store";
import { ChevronLeft, Camera, Check } from "lucide-react";

export function ProfileEdit() {
  const { user, updateUser, popView } = useAppStore();
  const [name, setName] = useState(user.name);
  const [avatar, setAvatar] = useState(user.avatar);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleAvatarClick = () => {
    fileInputRef.current?.click();
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setAvatar(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSave = () => {
    if (!name.trim()) {
      alert("昵称不能为空");
      return;
    }
    updateUser({ name, avatar });
    popView();
  };

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      transition={{ type: "spring", damping: 25, stiffness: 200 }}
      className="flex flex-col h-full bg-[#f8f9fa] absolute inset-0 z-50 overflow-hidden"
    >
      <div className="pt-14 pb-4 px-4 bg-white sticky top-0 z-20 flex items-center justify-between shadow-sm">
        <button
          onClick={popView}
          className="w-10 h-10 -ml-2 flex items-center justify-center text-gray-900 border border-transparent active:bg-gray-50 rounded-full transition-colors"
        >
          <ChevronLeft size={24} />
        </button>
        <h1 className="text-[17px] font-bold text-gray-900">
          编辑个人资料
        </h1>
        <button
          onClick={handleSave}
          className="w-10 h-10 -mr-2 flex items-center justify-center text-primary font-bold active:bg-gray-50 rounded-full transition-colors"
        >
          <Check size={22} />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto p-5">
        <div className="flex flex-col items-center mt-6 mb-10">
          <div className="relative cursor-pointer group" onClick={handleAvatarClick}>
            <img
              src={avatar}
              alt="avatar"
              className="w-24 h-24 rounded-full border-4 border-white shadow-md object-cover transition-opacity group-active:opacity-80"
            />
            <div className="absolute bottom-0 right-0 w-8 h-8 bg-gray-900 text-white rounded-full flex items-center justify-center border-2 border-white shadow-sm">
              <Camera size={14} />
            </div>
          </div>
          <p className="text-[12px] text-gray-500 mt-3">点击更换头像</p>
          <input 
            type="file" 
            ref={fileInputRef} 
            onChange={handleFileChange} 
            accept="image/*" 
            className="hidden" 
          />
        </div>

        <div className="bg-white rounded-2xl p-4 shadow-sm border border-gray-100">
          <div className="mb-2">
            <label className="text-[13px] font-bold text-gray-700 block mb-2 px-1">
              用户昵称
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="请输入您的昵称"
              maxLength={20}
              className="w-full bg-gray-50 border border-transparent focus:border-primary/30 focus:bg-white rounded-xl p-3.5 text-[15px] font-medium text-gray-900 focus:outline-none transition-all"
            />
            <p className="text-[11px] text-gray-400 mt-2 px-1 text-right">
              {name.length}/20
            </p>
          </div>
        </div>
      </div>
    </motion.div>
  );
}
