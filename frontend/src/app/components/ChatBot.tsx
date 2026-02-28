"use client";

import { useChat } from 'ai/react';
import { useState } from 'react';
import { MessageSquare, X, Send } from 'lucide-react';

export default function ChatBot() {
    const [isOpen, setIsOpen] = useState(false);

    // Vercel AI SDK hook that automatically manages the streaming state and history
    const { messages, input, handleInputChange, handleSubmit, isLoading } = useChat({
        api: process.env.NEXT_PUBLIC_API_URL + '/chat',
    });

    return (
        <div className="fixed bottom-6 right-6 z-50">
            {isOpen ? (
                <div className="bg-white max-w-[360px] w-[360px] h-[500px] border border-gray-200 rounded-xl shadow-2xl flex flex-col overflow-hidden animate-in slide-in-from-bottom-5 duration-300">

                    {/* Header */}
                    <div className="bg-violet-600 p-4 flex justify-between items-center text-white">
                        <h3 className="font-semibold flex items-center gap-2">
                            <MessageSquare size={18} /> AmazonLike Assistant
                        </h3>
                        <button onClick={() => setIsOpen(false)} className="hover:text-gray-200 transition-colors rounded-md hover:bg-violet-700 p-1">
                            <X size={18} />
                        </button>
                    </div>

                    {/* Chat History */}
                    <div className="flex-1 p-4 overflow-y-auto space-y-4 bg-gray-50">
                        {messages.length === 0 && (
                            <div className="text-gray-500 text-sm text-center mt-4 bg-white p-4 rounded-lg shadow-sm border border-gray-100">
                                Hi! I'm your AI Shop Assistant powered by AWS Bedrock. Looking for a gift? Ask me!
                            </div>
                        )}
                        {messages.map(m => (
                            <div key={m.id} className={`flex ${m.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                                <div className={`rounded-xl px-4 py-2.5 max-w-[85%] text-sm shadow-sm ${m.role === 'user'
                                    ? 'bg-violet-600 text-white rounded-br-none'
                                    : 'bg-white text-gray-800 rounded-bl-none border border-gray-100'
                                    }`}>
                                    {m.content}
                                </div>
                            </div>
                        ))}
                        {isLoading && (
                            <div className="flex justify-start">
                                <div className="bg-white border border-gray-100 text-gray-500 rounded-xl rounded-bl-none px-4 py-2.5 text-sm shadow-sm flex gap-1 items-center">
                                    <span className="animate-bounce">•</span>
                                    <span className="animate-bounce delay-75">•</span>
                                    <span className="animate-bounce delay-150">•</span>
                                </div>
                            </div>
                        )}
                    </div>

                    {/* Input Box */}
                    <div className="p-3 bg-white border-t border-gray-100">
                        <form onSubmit={handleSubmit} className="flex gap-2 relative">
                            <input
                                value={input}
                                onChange={handleInputChange}
                                disabled={isLoading}
                                placeholder="Ask about our products..."
                                className="flex-1 bg-gray-50 border border-gray-200 text-gray-900 text-sm rounded-full focus:ring-violet-500 focus:border-violet-500 block w-full pl-4 pr-12 py-3 transition-colors disabled:opacity-50"
                                required
                            />
                            <button
                                type="submit"
                                disabled={isLoading || !input.trim()}
                                className="absolute right-1 top-1 bottom-1 text-white bg-violet-600 hover:bg-violet-700 font-medium rounded-full text-sm aspect-square flex items-center justify-center transition-all disabled:opacity-50 disabled:cursor-not-allowed">
                                <Send size={16} className={input.trim() ? "translate-x-[-1px]" : ""} />
                            </button>
                        </form>
                    </div>
                </div>
            ) : (
                <button
                    onClick={() => setIsOpen(true)}
                    className="bg-violet-600 hover:bg-violet-700 text-white rounded-full p-4 shadow-xl transition-all hover:scale-110 flex items-center justify-center group animate-bounce hover:animate-none"
                    aria-label="Open AI Assistant"
                >
                    <MessageSquare size={24} />
                </button>
            )}
        </div>
    );
}
