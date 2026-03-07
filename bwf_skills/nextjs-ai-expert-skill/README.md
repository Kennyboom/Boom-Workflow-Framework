# Next.js 16 AI Expert Skill 🚀

> **v2.0.0** — Updated for Next.js 16, React 19.2, Vercel AI SDK 6.0, Tailwind CSS v4

A specialized "Skill" for AI Agents (Antigravity, Cursor, Windsurf, Claude Code) that enforces strict architectural constraints, best practices, and code patterns for building high-quality AI-powered Next.js 16 applications.

## 📖 What's New in v2.0

| Feature | v1.0 (Next.js 15) | v2.0 (Next.js 16) |
|---------|--------------------|--------------------|
| Bundler | Webpack / Turbopack beta | **Turbopack stable (default)** |
| React | 19.0 | **19.2** (View Transitions, Activity, useEffectEvent) |
| React Compiler | Experimental | **Stable** (auto-memoization) |
| Caching | `fetch()` cache options | **`use cache` directive** |
| Middleware | `middleware.ts` | **`proxy.ts`** |
| AI SDK | v3.x | **v6.0** (unified API) |
| Tailwind | v3 | **v4** (CSS-first config) |
| DevTools | Standard | **MCP integration** |
| PPR | Experimental | **Stable** |

## 📂 Repository Structure

```
nextjs-ai-expert-skill/
├── SKILL.md                        # The "Brain" - Instructions for the AI Agent
├── examples/
│   ├── route.ts                    # AI SDK 6.0 Unified Streaming Route Handler
│   ├── chat.tsx                    # Client Chat Component (AI SDK 5.0+ transport)
│   ├── proxy.ts                   # NEW: Replaces middleware.ts
│   ├── cache-example.tsx           # NEW: 'use cache' + PPR example
│   └── next.config.ts              # NEW: Recommended Next.js 16 config
├── README.md                       # Documentation (You are here)
└── LICENSE                         # MIT License
```

## 🛠️ Installation & Usage

### Option 1: For Antigravity / AI Agents using Skills

Copy the `SKILL.md` file to your agent's skills directory:

```bash
# Antigravity
cp SKILL.md ~/.gemini/antigravity/skills/nextjs-ai-expert/SKILL.md

# Or clone the entire skill
git clone https://github.com/Kennyboom/nextjs-ai-expert-skill.git \
  ~/.gemini/antigravity/skills/nextjs-ai-expert-skill
```

### Option 2: Manual Reference

Read `SKILL.md` as a development guidebook for building modern Next.js 16 applications.

## ✨ Key Topics Covered

### 🏗️ Architecture
- **App Router** with `layout.tsx`, `page.tsx`, `loading.tsx`, `error.tsx`
- **Parallel routes** with mandatory `default.tsx` (v16 breaking change)
- **Server Components by default**, Client Components only when needed

### ⚡ Next.js 16 Features
- **Turbopack** — Default bundler, 2-5x faster builds
- **React Compiler** — Stable auto-memoization (remove `useMemo`/`useCallback`)
- **`use cache` directive** — Explicit caching with `cacheLife` and `cacheTag`
- **`proxy.ts`** — Replaces `middleware.ts` for network boundary
- **PPR** — Partial Pre-Rendering: static shell + dynamic streaming
- **DevTools MCP** — AI agent debugging integration

### ⚛️ React 19.2
- **View Transitions** — Smooth animated UI updates
- **`useEffectEvent()`** — Isolate non-reactive logic from Effects
- **`<Activity />`** — Manage background/foreground UI states

### 🤖 Vercel AI SDK 6.0
- **Unified `streamText`** — Replaces `streamObject`, handles text + objects + tools
- **Transport Architecture** — `useChat` with external input state management
- **Tool Calling** — Zod-validated tool parameters and execution
- **Server Actions** — Non-streaming AI tasks with `generateText`

### 🎨 Styling
- **Tailwind CSS v4** — CSS-first config with `@theme` directive
- **Shadcn UI** — Accessible component primitives
- **`cn()` utility** — Conditional class merging

### 🔐 TypeScript & Validation
- **Strict mode** enabled
- **Zod schemas** for all operational boundaries
- **No `any`** — Use `unknown` or specific interfaces

## 🔄 Migration from v1.0 (Next.js 15)

1. Update Node.js to ≥ 20.9
2. Rename `middleware.ts` → `proxy.ts`
3. Add `default.tsx` to all parallel route slots
4. Enable React Compiler: `reactCompiler: true`
5. Switch to `'use cache'` directive for caching
6. Replace `next lint` with `eslint .`
7. Run `npx @next/codemod@latest upgrade`

## 🤝 Contributing

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit your changes (`git commit -m 'Add new pattern'`)
4. Push to the branch (`git push origin feature/improvement`)
5. Open a Pull Request

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.
