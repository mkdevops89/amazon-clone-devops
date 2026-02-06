import { register, collectDefaultMetrics } from 'prom-client';

// Initialize default metrics (CPU, Memory, Event Loop)
// We check if metrics are already registered to avoid duplicates in hot-reload/dev environments
if (register.getMetricsAsJSON().length === 0) {
    collectDefaultMetrics({ prefix: 'frontend_' });
}

export async function GET() {
    try {
        const metrics = await register.metrics();
        return new Response(metrics, {
            headers: { 'Content-Type': register.contentType }
        });
    } catch (err) {
        return new Response('Internal Server Error', { status: 500 });
    }
}
