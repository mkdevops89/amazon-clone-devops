import { register, collectDefaultMetrics } from 'prom-client';

// Initialize default metrics (CPU, Memory, Event Loop)
// We check if metrics are already registered to avoid duplicates in hot-reload/dev environments
if (!(global as any)._prometheus_default_metrics_initialized) {
    collectDefaultMetrics({ prefix: 'frontend_' });
    (global as any)._prometheus_default_metrics_initialized = true;
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
