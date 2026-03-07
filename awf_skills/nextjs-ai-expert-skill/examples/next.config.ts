// next.config.ts
// Next.js 16 - Recommended Configuration
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
    // ⚡ React Compiler - stable in Next.js 16
    // Auto-memoizes components, hooks, expressions
    // Remove manual useMemo/useCallback/React.memo
    reactCompiler: true,

    // 🧠 Cache Components - enables 'use cache' directive
    cacheComponents: true,

    // 🎯 Partial Pre-Rendering - mix static + dynamic on same page
    ppr: true,

    // 🤖 DevTools MCP - AI agent debugging integration
    devtools: {
        mcp: true,
    },

    // 🖼️ Image optimization (v16 defaults)
    images: {
        // minimumCacheTTL defaults to 14400 (4 hours) in v16
        // maximumRedirects defaults to 3
        // qualities defaults to [75]
        remotePatterns: [
            {
                protocol: 'https',
                hostname: '**.example.com',
            },
            {
                protocol: 'https',
                hostname: 'images.unsplash.com',
            },
        ],
    },

    // 🔒 Security headers
    async headers() {
        return [
            {
                source: '/(.*)',
                headers: [
                    { key: 'X-Frame-Options', value: 'DENY' },
                    { key: 'X-Content-Type-Options', value: 'nosniff' },
                    { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
                ],
            },
        ];
    },

    // Note: Turbopack is the DEFAULT bundler in v16 - no config needed
    // Note: AMP support has been REMOVED in v16
    // Note: `next lint` removed - use `eslint .` or `biome check .` directly
};

export default nextConfig;
