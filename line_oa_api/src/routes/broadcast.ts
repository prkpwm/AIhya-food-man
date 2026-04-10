import { Router, Request, Response, NextFunction } from 'express';
import { messagingApi } from '@line/bot-sdk';
import { env } from '../config/env';

const router = Router();

function getClient(): messagingApi.MessagingApiClient {
  return new messagingApi.MessagingApiClient({ channelAccessToken: env.line.channelAccessToken });
}

// POST /broadcast/flex — broadcast flex message to all followers
router.post('/flex', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { flexJson } = req.body as { flexJson: string };
    if (!flexJson) {
      res.status(400).json({ code: '400', en: 'flexJson required', th: 'ข้อมูลไม่ครบ' });
      return;
    }

    const flex = JSON.parse(flexJson);
    const client = getClient();

    await client.broadcast({
      messages: [flex],
    });

    console.table({ step: 'broadcast-flex', altText: flex.altText ?? '-' });
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

export default router;
