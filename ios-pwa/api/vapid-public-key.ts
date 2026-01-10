import type { VercelRequest, VercelResponse } from '@vercel/node';
import { getVapidPublicKey, isConfigured } from './lib/push';

export default function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  if (!isConfigured()) {
    return res.status(503).json({
      error: 'Push notifications not configured',
      message: 'VAPID keys not set in environment variables'
    });
  }

  return res.status(200).json({
    publicKey: getVapidPublicKey()
  });
}
