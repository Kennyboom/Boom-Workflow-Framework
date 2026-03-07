// src/app/products/page.tsx
// Next.js 16 - Cache Components with 'use cache' directive
// Demonstrates mixing cached + dynamic content on the same page via PPR
'use cache';

import { Suspense } from 'react';
import { cacheLife, cacheTag } from 'next/cache';
import { UserGreeting } from '@/components/feature/user-greeting';

// This entire page is cached with 'use cache' at the top
// But dynamic components inside <Suspense> will stream in

export default async function ProductsPage() {
    cacheLife('hours'); // Cache for hours
    cacheTag('products-page');

    const products = await getProducts();

    return (
        <main className="container mx-auto py-8">
            {/* Dynamic: Streams in after static shell renders */}
            <Suspense fallback={<div className="animate-pulse h-8 w-48 bg-muted rounded" />}>
                <UserGreeting />
            </Suspense>

            {/* Static: Cached product grid */}
            <h1 className="text-3xl font-bold mt-8 mb-6">Products</h1>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                {products.map((product) => (
                    <ProductCard key={product.id} product={product} />
                ))}
            </div>

            {/* Dynamic: Real-time trending, wrapped in Suspense */}
            <Suspense fallback={<TrendingSkeleton />}>
                <TrendingProducts />
            </Suspense>
        </main>
    );
}

// Cached function - fetches once and caches
async function getProducts() {
    'use cache';
    cacheLife('hours');
    cacheTag('products-list');

    const res = await fetch('https://api.example.com/products');
    return res.json() as Promise<Product[]>;
}

// This component is NOT cached - runs fresh each request
async function TrendingProducts() {
    // No 'use cache' = always dynamic
    const trending = await fetch('https://api.example.com/trending', {
        cache: 'no-store',
    });
    const data = await trending.json();

    return (
        <section className="mt-12">
            <h2 className="text-2xl font-semibold mb-4">Trending Now</h2>
            <div className="flex gap-4 overflow-x-auto">
                {data.map((item: Product) => (
                    <ProductCard key={item.id} product={item} />
                ))}
            </div>
        </section>
    );
}

// --- Types ---
interface Product {
    id: string;
    name: string;
    price: number;
    image: string;
}

function ProductCard({ product }: { product: Product }) {
    return (
        <div className="rounded-xl border p-4 hover:shadow-lg transition-shadow">
            <div className="aspect-square bg-muted rounded-lg mb-3" />
            <h3 className="font-medium">{product.name}</h3>
            <p className="text-muted-foreground">${product.price}</p>
        </div>
    );
}

function TrendingSkeleton() {
    return (
        <section className="mt-12">
            <div className="h-8 w-48 bg-muted rounded animate-pulse mb-4" />
            <div className="flex gap-4">
                {[1, 2, 3].map((i) => (
                    <div key={i} className="w-64 h-72 bg-muted rounded-xl animate-pulse" />
                ))}
            </div>
        </section>
    );
}
