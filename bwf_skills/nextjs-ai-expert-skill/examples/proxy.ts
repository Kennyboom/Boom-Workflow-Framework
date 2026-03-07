// src/proxy.ts
// Next.js 16 - Replaces middleware.ts
// Handles redirects, rewrites, headers, A/B testing
// ❌ NO database calls, NO heavy processing, NO full auth sessions
import { NextRequest, NextResponse } from 'next/server';

export function proxy(request: NextRequest) {
    const { pathname } = request.nextUrl;

    // --- Auth Guard: Redirect unauthenticated users ---
    const protectedPaths = ['/dashboard', '/settings', '/admin'];
    const isProtected = protectedPaths.some((p) => pathname.startsWith(p));

    if (isProtected && !request.cookies.get('session')) {
        const loginUrl = new URL('/login', request.url);
        loginUrl.searchParams.set('callbackUrl', pathname);
        return NextResponse.redirect(loginUrl);
    }

    // --- Admin Role Check ---
    if (pathname.startsWith('/admin')) {
        const role = request.cookies.get('role')?.value;
        if (role !== 'admin') {
            return NextResponse.redirect(new URL('/unauthorized', request.url));
        }
    }

    // --- A/B Testing via Rewrite ---
    if (pathname === '/pricing') {
        const bucket = request.cookies.get('ab-pricing')?.value;
        const variant = bucket || (Math.random() > 0.5 ? 'a' : 'b');
        const response = NextResponse.rewrite(
            new URL(`/pricing-${variant}`, request.url)
        );
        if (!bucket) {
            response.cookies.set('ab-pricing', variant, { maxAge: 60 * 60 * 24 * 7 });
        }
        return response;
    }

    // --- Geo-based Routing ---
    const country = request.geo?.country || 'US';
    if (pathname === '/' && country === 'JP') {
        return NextResponse.rewrite(new URL('/ja', request.url));
    }

    // --- Add Security & Tracking Headers ---
    const response = NextResponse.next();
    response.headers.set('x-request-id', crypto.randomUUID());
    response.headers.set('x-frame-options', 'DENY');
    response.headers.set('x-content-type-options', 'nosniff');

    return response;
}

export const config = {
    matcher: [
        /*
         * Match all request paths except:
         * - _next/static (static files)
         * - _next/image (image optimization files)
         * - favicon.ico (favicon file)
         * - public assets (images, etc.)
         */
        '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
    ],
};
