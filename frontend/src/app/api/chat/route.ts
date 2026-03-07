import { createAmazonBedrock } from '@ai-sdk/amazon-bedrock';
import { streamText } from 'ai';

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
        });

        return result.toAIStreamResponse();
    } catch (error) {
        console.error('Bedrock APi Error:', error);
        return new Response(JSON.stringify({ error: 'Failed to connect to Bedrock' }), { status: 500 });
    }
}
