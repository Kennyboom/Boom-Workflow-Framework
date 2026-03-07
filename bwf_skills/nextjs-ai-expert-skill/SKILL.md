---
name: nextjs-ai-expert
description: Expert guidelines for Next.js 16, React 19.2, TypeScript 5.9, Node.js 25.7, Tailwind CSS v4, Shadcn UI, and Vercel AI SDK 6.0 development.
author: Kennyboom
version: 2.1.0
tags: [nextjs16, react19, typescript5.9, nodejs25, tailwind-v4, shadcn, ai-sdk, turbopack, react-compiler]
---

# 🚀 Next.js 16 AI Expert Guidelines

Use this skill when developing applications with:
- **Framework**: Next.js 16 (App Router, Turbopack, PPR)
- **Language**: TypeScript 5.9
- **Runtime**: Node.js 25.7 (Current) / 24.x (LTS)
- **Styling**: Tailwind CSS v4 + Shadcn UI
- **AI Integration**: Vercel AI SDK 6.0 (unified API)
- **React**: React 19.2 (Compiler, View Transitions, Activity)
- **State**: React Hooks + Server Actions + `use cache`

---

## 1. Project Structure & File Naming

Follow the Next.js 16 App Router conventions:

```text
src/
├── app/
│   ├── layout.tsx           # Root layout (metadata, fonts, providers)
│   ├── page.tsx             # Home page
│   ├── loading.tsx          # Loading UI (Suspense boundary)
│   ├── error.tsx            # Error boundary
│   ├── not-found.tsx        # 404 page
│   ├── [slug]/              # Dynamic routes
│   │   ├── page.tsx
│   │   └── default.tsx      # ⚠️ REQUIRED for parallel routes in v16
│   ├── @modal/              # Parallel routes (intercepting)
│   │   └── default.tsx
│   ├── api/                 # Route Handlers (GET/POST endpoints)
│   │   └── chat/
│   │       └── route.ts
│   └── actions.ts           # Server Actions (form submissions, mutations)
├── components/
│   ├── ui/                  # Shadcn primitive components (button, input, etc.)
│   └── feature/             # Feature-specific components
├── lib/
│   ├── utils.ts             # Utility functions (cn, formatters)
│   └── db.ts                # Database client (Prisma/Drizzle)
├── hooks/                   # Custom React hooks
└── proxy.ts                 # ⚠️ NEW: Replaces middleware.ts
```

- Use **`kebab-case`** for directories and files (except components: `PascalCase.tsx`).
- Colocate styles/types if specific to a component, otherwise put in `lib/` or `types/`.
- **Every parallel route slot MUST have a `default.tsx`** (Next.js 16 breaking change).

---

## 2. Next.js 16 Configuration

### next.config.ts (Recommended Config)

```typescript
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  // React Compiler - stable in Next.js 16, auto-memoizes components
  reactCompiler: true,

  // Cache Components - enables 'use cache' directive
  cacheComponents: true,

  // Partial Pre-Rendering - mix static + dynamic on same page
  ppr: true,

  // Turbopack is now DEFAULT bundler - no config needed
  // To opt-out (not recommended): bundler: 'webpack'

  images: {
    // v16 defaults: minimumCacheTTL=14400 (4h), maximumRedirects=3
    remotePatterns: [
      { protocol: 'https', hostname: '**.example.com' },
    ],
  },
};

export default nextConfig;
```

### tsconfig.json Essentials (TypeScript 5.9)

```json
{
  "compilerOptions": {
    "strict": true,
    "target": "esnext",
    "module": "nodenext",
    "lib": ["dom", "dom.iterable", "esnext"],
    "moduleResolution": "bundler",
    "paths": { "@/*": ["./src/*"] }
  }
}
```

---

## 3. Core Development Rules

### Server Components vs. Client Components
- **Default to Server Components**. Only add `'use client'` when necessary:
    - Interactive event listeners (`onClick`, `onChange`).
    - Using React Hooks (`useState`, `useEffect`).
    - Using browser-only APIs (`window`, `localStorage`).
- **Pass Data Down**: Fetch data in Server Components and pass as props to Client Components.

### Data Fetching & Caching (NEW in v16)
- Use **`'use cache'`** directive for explicit caching control:

```typescript
// Cache an entire page
'use cache';

export default async function ProductsPage() {
  const products = await db.product.findMany();
  return <ProductList products={products} />;
}
```

```typescript
// Cache a specific function
import { cacheLife, cacheTag } from 'next/cache';

export async function getProduct(id: string) {
  'use cache';
  cacheLife('hours'); // Cache profile: 'seconds' | 'minutes' | 'hours' | 'days' | 'weeks' | 'max'
  cacheTag(`product-${id}`);

  return db.product.findUnique({ where: { id } });
}
```

```typescript
// Cache a component
async function PricingWidget() {
  'use cache';
  cacheLife('minutes');

  const prices = await fetchPrices();
  return <PriceTable data={prices} />;
}
```

### Revalidation (Updated APIs)

```typescript
'use server';

import { revalidateTag, updateTag } from 'next/cache';

export async function updateProduct(id: string, data: ProductData) {
  await db.product.update({ where: { id }, data });

  // updateTag - read-your-writes semantics (immediate refresh in same request)
  updateTag(`product-${id}`);

  // revalidateTag - now requires cacheLife profile
  revalidateTag(`product-${id}`, 'hours');
}
```

### Server Actions for Mutations
- Use **Server Actions** for all POST/PUT/DELETE operations.
- Avoid `useEffect` for initial data fetching; fetch on the server instead.

---

## 4. proxy.ts — Replaces middleware.ts

Next.js 16 replaces `middleware.ts` with `proxy.ts` to clarify its network boundary role.

```typescript
// src/proxy.ts (or root proxy.ts)
import { NextRequest, NextResponse } from 'next/server';

export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Auth redirect
  if (pathname.startsWith('/dashboard') && !request.cookies.get('session')) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  // A/B testing via rewrite
  if (pathname === '/pricing') {
    const variant = Math.random() > 0.5 ? '/pricing-a' : '/pricing-b';
    return NextResponse.rewrite(new URL(variant, request.url));
  }

  // Add custom headers
  const response = NextResponse.next();
  response.headers.set('x-request-id', crypto.randomUUID());
  return response;
}

export const config = {
  matcher: [
    // Match all except static files and _next
    '/((?!_next/static|_next/image|favicon.ico).*)',
  ],
};
```

**Rules for proxy.ts:**
- ✅ Redirects, rewrites, header manipulation, A/B testing
- ❌ NO database calls, NO heavy processing, NO full auth logic
- Only one `proxy.ts` per project (root or `src/`)

---

## 5. React 19.2 Features

### React Compiler (Stable)
The React Compiler is now stable and enabled via `reactCompiler: true` in next.config.ts.
- **Automatically memoizes** components, hooks, and expressions.
- **Remove manual optimizations**: No more `useMemo`, `useCallback`, `React.memo` needed.
- The compiler handles it automatically — just write clean code.

### View Transitions

```typescript
'use client';

import { useViewTransition } from 'react';

export function AnimatedNav() {
  const { startTransition } = useViewTransition();

  const handleNavigate = () => {
    startTransition(() => {
      // Navigation or state change with smooth animated transition
      router.push('/new-page');
    });
  };

  return <button onClick={handleNavigate}>Navigate</button>;
}
```

### useEffectEvent (Isolate non-reactive logic)

```typescript
'use client';

import { useEffectEvent, useEffect } from 'react';

export function ChatRoom({ roomId }: { roomId: string }) {
  // Non-reactive: won't re-trigger the effect when theme changes
  const onMessage = useEffectEvent((msg: Message) => {
    showNotification(msg, theme);
  });

  useEffect(() => {
    const conn = createConnection(roomId);
    conn.on('message', onMessage);
    return () => conn.disconnect();
  }, [roomId]); // No need to include onMessage in deps
}
```

### Activity Component (Background UI States)

```typescript
import { Activity } from 'react';

export function TabPanel({ activeTab }: { activeTab: string }) {
  return (
    <div>
      <Activity mode={activeTab === 'home' ? 'visible' : 'hidden'}>
        <HomeTab />
      </Activity>
      <Activity mode={activeTab === 'settings' ? 'visible' : 'hidden'}>
        <SettingsTab />
      </Activity>
    </div>
  );
}
```

---

## 6. Vercel AI SDK 6.0 Patterns

### Unified streamText (replaces streamObject)

```typescript
// src/app/api/chat/route.ts
import { google } from '@ai-sdk/google';
import { streamText } from 'ai';
import { z } from 'zod';

export const maxDuration = 60;

export async function POST(req: Request) {
  const { messages } = await req.json();

  const result = streamText({
    model: google('gemini-2.0-flash'),
    messages,
    // Unified API: text, structured objects, and tools in one call
    tools: {
      getWeather: {
        description: 'Get current weather for a location',
        parameters: z.object({
          city: z.string().describe('City name'),
        }),
        execute: async ({ city }) => {
          return { temp: 22, condition: 'sunny', city };
        },
      },
    },
  });

  return result.toDataStreamResponse();
}
```

### Client-Side Chat Hook (AI SDK 5.0+ Transport Architecture)

```typescript
'use client';

import { useState } from 'react';
import { useChat } from 'ai/react';

export default function Chat() {
  // AI SDK 5.0+: useChat no longer manages input state internally
  const [input, setInput] = useState('');
  const { messages, append, isLoading, error } = useChat();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim()) return;
    append({ role: 'user', content: input });
    setInput('');
  };

  return (
    <div className="flex flex-col h-screen">
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((m) => (
          <div
            key={m.id}
            className={m.role === 'user' ? 'text-right' : 'text-left'}
          >
            <span className="inline-block px-4 py-2 rounded-lg bg-muted">
              {m.content}
            </span>
          </div>
        ))}
        {isLoading && <div className="animate-pulse">Thinking...</div>}
        {error && <div className="text-red-500">{error.message}</div>}
      </div>
      <form onSubmit={handleSubmit} className="p-4 border-t flex gap-2">
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Type a message..."
          className="flex-1 px-4 py-2 border rounded-lg"
        />
        <button type="submit" disabled={isLoading}>
          Send
        </button>
      </form>
    </div>
  );
}
```

### Server Actions for AI (Non-streaming)

```typescript
'use server';

import { generateText } from 'ai';
import { google } from '@ai-sdk/google';
import { z } from 'zod';

export async function summarizeText(text: string) {
  const { text: summary } = await generateText({
    model: google('gemini-2.0-flash'),
    prompt: `Summarize this concisely: ${text}`,
  });
  return summary;
}

// Unified API: generateText now handles structured output too (replaces generateObject)
export async function extractEntities(text: string) {
  const { object } = await generateText({
    model: google('gemini-2.0-flash'),
    prompt: `Extract entities from: ${text}`,
    output: z.object({
      people: z.array(z.string()),
      places: z.array(z.string()),
      dates: z.array(z.string()),
    }),
  });
  return object;
}
```

---

## 7. Styling (Tailwind CSS v4 + Shadcn)

- Use `cn()` utility (clsx + tailwind-merge) for conditional classes.
- Tailwind v4: CSS-first configuration, use `@theme` in CSS instead of `tailwind.config.ts`.
- Use CSS variables for theming (defined in `globals.css`).

```css
/* globals.css - Tailwind v4 */
@import "tailwindcss";

@theme {
  --color-primary: oklch(0.70 0.15 250);
  --color-secondary: oklch(0.65 0.12 300);
  --font-sans: 'Inter', sans-serif;
  --breakpoint-3xl: 120rem;
}
```

- Do NOT write custom CSS files unless absolutely necessary. Use Tailwind utility classes.

---

## 8. TypeScript 5.9 Best Practices

- **Strict Mode**: Enable `strict: true` in `tsconfig.json`.
- **No `any`**: Use `unknown` or define specific interfaces.
- **Zod Validation**: Validate all inputs (env vars, API bodies, form data) with Zod schemas.
- **`module: "nodenext"`**: Default in TS 5.9 `tsc --init`.
- **`target: "esnext"`**: Default in TS 5.9.

```typescript
import { z } from 'zod';

const UserSchema = z.object({
  email: z.string().email(),
  role: z.enum(['admin', 'user']),
});

type User = z.infer<typeof UserSchema>;
```

### Deferred Imports (TypeScript 5.9)

Lazy-load modules to improve startup performance:

```typescript
// Module is NOT evaluated until `heavyLib` properties are accessed
import defer * as heavyLib from './heavy-analytics';

export function handleClick() {
  // Module evaluation happens HERE, on first property access
  heavyLib.trackEvent('click');
}
```

### Expandable Hover Types

TS 5.9 adds deep hover previews in VSCode — nested types expand inline without navigating to definitions.

---

## 9. Performance Optimization

- **Turbopack**: Default bundler in v16. 2-5x faster builds. No config needed.
- **React Compiler**: Auto-memoization. Remove manual `useMemo`/`useCallback`.
- **PPR (Partial Pre-Rendering)**: Combine static shell + dynamic islands on same page.
- **Images**: Always use `next/image` with `width`/`height` or `fill`. v16 caches for 4h by default.
- **Fonts**: Use `next/font` (`Inter`, `Geist`) to prevent layout shift.
- **Dynamic Imports**: Use `next/dynamic` for heavy client components.
- **Metadata**: Populate `export const metadata` in `layout.tsx` and `page.tsx` for SEO.
- **Incremental Prefetching**: Next.js 16 auto-prefetches only what's not in cache.
- **Layout Deduplication**: Shared layouts downloaded once across multiple prefetched URLs.

---

## 10. Next.js DevTools MCP

Next.js 16 integrates with Model Context Protocol (MCP) for AI-powered debugging:

```typescript
// next.config.ts
const nextConfig: NextConfig = {
  devtools: {
    mcp: true, // Enable MCP for AI agent debugging
  },
};
```

This allows AI tools to understand your project's routing, caching behavior, and rendering patterns.

---

## 11. Common Pitfalls to Avoid

- ❌ Using `middleware.ts` — it's now `proxy.ts` in Next.js 16.
- ❌ Importing Server Actions directly into `useEffect` (wrap in async function or event handler).
- ❌ Putting secrets in `NEXT_PUBLIC_` environment variables.
- ❌ Using `fs` module in Client Components.
- ❌ Forgetting `key` prop in `.map()` lists.
- ❌ Forgetting `default.tsx` in parallel route slots (required in v16).
- ❌ Using `useMemo`/`useCallback` manually when React Compiler is enabled.
- ❌ Using `images.domains` (deprecated) — use `images.remotePatterns` instead.
- ❌ Using `next/legacy/image` (deprecated in v16).
- ❌ Using Node.js < 20.9 (minimum for Next.js 16). Recommend Node.js 25.7 or 24.x LTS.
- ❌ Using `next lint` (removed) — run ESLint or Biome directly.
- ❌ Using `target: "ES2022"` in tsconfig — use `"esnext"` with TypeScript 5.9.
- ❌ Using eager imports for heavy modules — use `import defer` for startup perf.

---

## 12. Node.js 25.7 Features

- **V8 Engine 14.1**: Faster JS execution, latest ECMAScript support.
- **`--allow-net` flag**: Granular network access control (Permission Model).
- **Web Storage API stable**: `localStorage`/`sessionStorage` available by default.
- **Performance improvements**: Faster startup, better memory management.
- ⚠️ Node 25.x is **Current** (not LTS). For production, use **Node.js 24.x LTS**.

---

## 13. Migration from Next.js 15

If upgrading from Next.js 15:

1. **Update Node.js** to 25.7 (or 24.x LTS minimum)
2. **Update TypeScript** to 5.9, set `target: "esnext"`, `module: "nodenext"`
3. **Rename `middleware.ts`** → `proxy.ts`, export `proxy()` instead of `default`
4. **Add `default.tsx`** to all parallel route slots
5. **Enable React Compiler**: `reactCompiler: true` in next.config.ts, remove manual `useMemo`/`useCallback`
6. **Enable PPR**: `ppr: true` for static + dynamic mixing
7. **Switch caching**: Replace `fetch` cache options with `'use cache'` directive
8. **Remove `next lint`** from scripts, use `eslint .` directly
9. **Update `images`**: Use `remotePatterns` instead of `domains`
10. **Run `npx @next/codemod@latest upgrade`** for automated migrations

---

## 14. Workflow Checklist

Before finishing a task:
1. [ ] Type check: `tsc --noEmit`
2. [ ] Lint: `eslint .` or `biome check .`
3. [ ] Build: `next build` (uses Turbopack by default)
4. [ ] Verify responsive design (Mobile/Tablet/Desktop)
5. [ ] Verify AI API keys are set in `.env.local`
6. [ ] Verify `default.tsx` exists for all parallel routes
7. [ ] Verify no manual memoization when React Compiler is on
