import type { VercelRequest, VercelResponse } from '@vercel/node';
import { store } from './lib/store';
import { validateSessionId, validateSubscription, isObject } from './lib/validate';

export default function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  if (!isObject(req.body)) {
    return res.status(400).json({ error: 'Invalid request body' });
  }

  const { sessionId, subscription } = req.body;

  const sidErr = validateSessionId(sessionId);
  if (sidErr) return res.status(400).json({ error: sidErr.message });

  const subErr = validateSubscription(subscription);
  if (subErr) return res.status(400).json({ error: subErr.message });

  store.setSubscription(sessionId, subscription);

  console.log(`[Subscribe] Session ${sessionId} subscribed to push notifications`);

  return res.status(200).json({ success: true });
}
