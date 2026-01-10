import type { VercelRequest, VercelResponse } from '@vercel/node';
import { store } from './lib/store';

export default function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { sessionId, subscription } = req.body;

  if (!sessionId || !subscription) {
    return res.status(400).json({ error: 'Missing sessionId or subscription' });
  }

  store.setSubscription(sessionId, subscription);

  console.log(`[Subscribe] Session ${sessionId} subscribed to push notifications`);

  return res.status(200).json({ success: true });
}
