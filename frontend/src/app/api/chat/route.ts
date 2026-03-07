import { createAmazonBedrock } from '@ai-sdk/amazon-bedrock';
import { streamText, tool } from 'ai';
import { z } from 'zod';
import axios from 'axios';

// Allow streaming responses up to 30 seconds
export const maxDuration = 30;

export async function POST(req: Request) {
    try {
        const { messages } = await req.json();

        const systemPrompt = "You are a helpful and friendly shop assistant for an e-commerce platform called AmazonLike. " +
            "You help users find products, recommend gifts, and answer questions about the catalog.";

        const bedrock = createAmazonBedrock({
            bedrockOptions: {
                region: process.env.AWS_REGION || 'us-east-1',
            }
        });

        const result = await streamText({
            // @ts-ignore: AWS SDK provider version mismatch with legacy ai@3
            model: bedrock('anthropic.claude-3-haiku-20240307-v1:0'),
            system: systemPrompt,
            messages,
            temperature: 0.7,
            tools: {
                searchProducts: tool({
                    description: 'Search for products in the AmazonLike catalog by name, category, or keyword to check their current selling prices and details.',
                    parameters: z.object({
                        query: z.string().describe('The search term or product name to look up'),
                    }),
                    execute: async ({ query }) => {
                        try {
                            const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api';
                            const response = await axios.get(`${apiUrl}/products`);

                            const products = response.data;
                            const results = products.filter((p: any) =>
                                p.name.toLowerCase().includes(query.toLowerCase()) ||
                                p.category.toLowerCase().includes(query.toLowerCase()) ||
                                p.description.toLowerCase().includes(query.toLowerCase())
                            );

                            if (results.length === 0) {
                                return `No products found matching "${query}".`;
                            }
                            return results.map((p: any) => `${p.name} - $${p.price} (${p.category})`).join("\n");
                        } catch (error) {
                            console.error("Tool execution failed:", error);
                            return "Error: Could not retrieve live product data right now.";
                        }
                    },
                }),
            },
        });

        return result.toAIStreamResponse();
    } catch (error) {
        console.error('Bedrock APi Error:', error);
        return new Response(JSON.stringify({ error: 'Failed to connect to Bedrock' }), { status: 500 });
    }
}
