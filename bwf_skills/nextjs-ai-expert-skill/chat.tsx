// src/components/feature/chat.tsx
// Next.js 16 + Vercel AI SDK 5.0+ Client Chat Component
'use client';

import { useState } from 'react';
import { useChat } from 'ai/react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { cn } from '@/lib/utils';

export default function Chat() {
    // AI SDK 5.0+: useChat no longer manages input state internally
    const [input, setInput] = useState('');
    const { messages, append, isLoading, error, reload, stop } = useChat();

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        if (!input.trim() || isLoading) return;
        append({ role: 'user', content: input });
        setInput('');
    };

    return (
        <div className="flex flex-col h-[600px] max-w-2xl mx-auto">
            {/* Messages Area */}
            <div className="flex-1 overflow-y-auto p-4 space-y-4">
                {messages.length === 0 && (
                    <div className="text-center text-muted-foreground py-12">
                        <p className="text-lg font-medium">Start a conversation</p>
                        <p className="text-sm">Ask me anything...</p>
                    </div>
                )}

                {messages.map((m) => (
                    <div
                        key={m.id}
                        className={cn(
                            'flex',
                            m.role === 'user' ? 'justify-end' : 'justify-start'
                        )}
                    >
                        <div
                            className={cn(
                                'max-w-[80%] rounded-2xl px-4 py-2.5 text-sm',
                                m.role === 'user'
                                    ? 'bg-primary text-primary-foreground'
                                    : 'bg-muted'
                            )}
                        >
                            {m.content}

                            {/* Render tool invocations */}
                            {m.toolInvocations?.map((tool) => (
                                <div
                                    key={tool.toolCallId}
                                    className="mt-2 p-2 rounded bg-background/50 text-xs"
                                >
                                    <span className="font-mono font-bold">{tool.toolName}</span>
                                    {'result' in tool && (
                                        <pre className="mt-1 whitespace-pre-wrap">
                                            {JSON.stringify(tool.result, null, 2)}
                                        </pre>
                                    )}
                                </div>
                            ))}
                        </div>
                    </div>
                ))}

                {isLoading && (
                    <div className="flex justify-start">
                        <div className="bg-muted rounded-2xl px-4 py-2.5 animate-pulse">
                            Thinking...
                        </div>
                    </div>
                )}

                {error && (
                    <div className="flex items-center gap-2 text-destructive text-sm">
                        <span>Error: {error.message}</span>
                        <Button variant="outline" size="sm" onClick={() => reload()}>
                            Retry
                        </Button>
                    </div>
                )}
            </div>

            {/* Input Area */}
            <form onSubmit={handleSubmit} className="p-4 border-t flex gap-2">
                <Input
                    value={input}
                    onChange={(e) => setInput(e.target.value)}
                    placeholder="Type a message..."
                    disabled={isLoading}
                    className="flex-1"
                />
                {isLoading ? (
                    <Button type="button" variant="outline" onClick={() => stop()}>
                        Stop
                    </Button>
                ) : (
                    <Button type="submit" disabled={!input.trim()}>
                        Send
                    </Button>
                )}
            </form>
        </div>
    );
}
