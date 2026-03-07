// src/app/api/chat/route.ts
// Next.js 16 + Vercel AI SDK 6.0 - Unified Streaming API
import { google } from '@ai-sdk/google';
import { streamText } from 'ai';
import { z } from 'zod';

export const maxDuration = 60;

export async function POST(req: Request) {
  const { messages } = await req.json();

  const result = streamText({
    model: google('gemini-2.0-flash'),
    system: 'You are a helpful AI assistant.',
    messages,

    // AI SDK 6.0: Unified API handles text, objects, and tools
    tools: {
      getWeather: {
        description: 'Get current weather for a location',
        parameters: z.object({
          city: z.string().describe('City name'),
          unit: z.enum(['celsius', 'fahrenheit']).optional().default('celsius'),
        }),
        execute: async ({ city, unit }) => {
          // Replace with real weather API call
          return {
            city,
            temperature: unit === 'celsius' ? 22 : 72,
            condition: 'sunny',
            unit,
          };
        },
      },
      searchProducts: {
        description: 'Search for products in our catalog',
        parameters: z.object({
          query: z.string().describe('Search query'),
          maxResults: z.number().optional().default(5),
        }),
        execute: async ({ query, maxResults }) => {
          // Replace with real DB/API call
          return {
            results: [
              { id: '1', name: `${query} Pro`, price: 99 },
              { id: '2', name: `${query} Basic`, price: 49 },
            ].slice(0, maxResults),
          };
        },
      },
    },
  });

  return result.toDataStreamResponse();
}
