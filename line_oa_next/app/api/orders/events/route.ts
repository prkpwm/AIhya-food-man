import { NextRequest } from 'next/server';
import { ensureInit } from '@/lib/init';
import { subscribe } from '@/lib/services/order_events';

ensureInit();

export const dynamic = 'force-dynamic';

export function GET(_req: NextRequest) {
  const encoder = new TextEncoder();

  const stream = new ReadableStream({
    start(controller) {
      // send initial ping so client knows connection is alive
      controller.enqueue(encoder.encode(': ping\n\n'));

      const unsub = subscribe((data) => {
        controller.enqueue(encoder.encode(`event: new-order\ndata: ${data}\n\n`));
      });

      // keep-alive ping every 25s to prevent proxy timeouts
      const interval = setInterval(() => {
        try {
          controller.enqueue(encoder.encode(': ping\n\n'));
        } catch {
          clearInterval(interval);
        }
      }, 25_000);

      // clean up when client disconnects
      _req.signal.addEventListener('abort', () => {
        unsub();
        clearInterval(interval);
        controller.close();
      });
    },
  });

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache, no-transform',
      Connection: 'keep-alive',
      'X-Accel-Buffering': 'no',
    },
  });
}
