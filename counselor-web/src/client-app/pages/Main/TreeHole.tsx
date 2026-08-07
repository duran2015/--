import { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { ChevronLeft, Plus, Send, X, Heart } from "lucide-react";
import { useAppStore } from "../../store";

export function TreeHole() {
  const { popView } = useAppStore();
  const [showPost, setShowPost] = useState(false);
  const [postText, setPostText] = useState("");

  const [posts, setPosts] = useState([
    {
      id: 1,
      text: "感觉最近好累，无论是身体还是心里。没有人可以诉说，只能在这里写下来。",
      time: "10分钟前",
      likes: 12,
      liked: false,
      color: "bg-blue-50/50",
    },
    {
      id: 2,
      text: "今天天气很好，阳光洒在桌子上，突然觉得之前的那些烦恼好像也没那么重要了。",
      time: "1小时前",
      likes: 45,
      liked: true,
      color: "bg-orange-50/50",
    },
    {
      id: 3,
      text: "为什么我总是做不好事情？一次次地搞砸，觉得自己像个废物。",
      time: "3小时前",
      likes: 8,
      liked: false,
      color: "bg-gray-50",
    },
    {
      id: 4,
      text: "明天就要去新的城市了，有些害怕，但也带点期待。希望一切都会好起来吧。",
      time: "5小时前",
      likes: 21,
      liked: false,
      color: "bg-green-50/50",
    },
  ]);

  const handleLike = (id: number) => {
    setPosts((prev) =>
      prev.map((p) => {
        if (p.id === id) {
          return {
            ...p,
            liked: !p.liked,
            likes: p.liked ? p.likes - 1 : p.likes + 1,
          };
        }
        return p;
      }),
    );
  };

  const handleSend = () => {
    if (!postText.trim()) return;
    const newPost = {
      id: Date.now(),
      text: postText,
      time: "刚刚",
      likes: 0,
      liked: false,
      color: "bg-indigo-50/50",
    };
    setPosts([newPost, ...posts]);
    setPostText("");
    setShowPost(false);
  };

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      className="flex flex-col h-full bg-[#FAFAFA] absolute inset-0 z-[100] overflow-hidden"
    >
      {/* Header */}
      <div className="pt-14 pb-3 px-4 bg-white/80 backdrop-blur sticky top-0 z-20 flex items-center justify-between border-b border-gray-100 shadow-sm">
        <button
          onClick={popView}
          className="w-10 h-10 -ml-2 flex items-center justify-center text-gray-900 active:bg-gray-50 rounded-full transition-colors"
        >
          <ChevronLeft size={24} />
        </button>
        <h1 className="text-[17px] font-bold text-gray-900 absolute left-1/2 -translate-x-1/2">
          匿名树洞
        </h1>
        <button
          onClick={() => setShowPost(true)}
          className="w-8 h-8 rounded-full bg-primary text-white flex items-center justify-center active:scale-95 transition-transform"
        >
          <Plus size={18} />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        <div className="text-center py-4">
          <p className="text-[12px] text-gray-400">
            在这里，你的声音会被倾听。无评论，无压力。
          </p>
        </div>

        {posts.map((post) => (
          <div
            key={post.id}
            className={`p-5 rounded-2xl border border-gray-100 shadow-sm ${post.color}`}
          >
            <p className="text-[14px] text-gray-800 leading-relaxed mb-4">
              {post.text}
            </p>
            <div className="flex items-center justify-between">
              <span className="text-[11px] text-gray-400">{post.time}</span>
              <button
                onClick={() => handleLike(post.id)}
                className={`flex items-center space-x-1 ${post.liked ? "text-rose-500" : "text-gray-400"}`}
              >
                <Heart size={14} fill={post.liked ? "currentColor" : "none"} />
                <span className="text-[12px] font-medium">{post.likes}</span>
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Post Modal */}
      <AnimatePresence>
        {showPost && (
          <motion.div
            initial={{ y: "100%" }}
            animate={{ y: 0 }}
            exit={{ y: "100%" }}
            className="absolute inset-0 bg-white z-[110] flex flex-col"
          >
            <div className="pt-14 pb-3 px-4 flex justify-between items-center border-b border-gray-100">
              <button
                onClick={() => setShowPost(false)}
                className="text-gray-500 font-medium text-[15px]"
              >
                取消
              </button>
              <h2 className="font-bold text-[16px]">写下心事</h2>
              <button
                onClick={handleSend}
                disabled={!postText.trim()}
                className={`w-16 py-1.5 rounded-full text-[13px] font-bold transition-colors ${postText.trim() ? "bg-primary text-white" : "bg-gray-100 text-gray-400"}`}
              >
                发送
              </button>
            </div>
            <div className="p-4 flex-1">
              <textarea
                value={postText}
                onChange={(e) => setPostText(e.target.value)}
                className="w-full h-full resize-none outline-none text-[16px] leading-relaxed placeholder-gray-400"
                placeholder="在这里，没人知道你是谁。想说什么都可以..."
                autoFocus
              />
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}
