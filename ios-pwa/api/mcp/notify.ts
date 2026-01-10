import type { VercelRequest, VercelResponse } from '@vercel/node';
import { store } from '../lib/store';
import { sendPushNotification, isConfigured } from '../lib/push';

// Send a notification without requiring a response

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { sessionId, title, message } = req.body;

  if (!sessionId || !message) {
    return res.status(400).json({ error: 'Missing sessionId or message' });
  }

  // Send push notification if configured
  const subscription = store.getSubscription(sessionId);
  if (subscription && isConfigured()) {
    await sendPushNotification(subscription.subscription as any, {
      title: title || 'Notification',
      body: message,
      questionId: '', // No question ID for notifications
      type: 'notify',
    });

    return res.status(200).json({ success: true, delivered: true });
  }

  console.log(`[Notify] No push subscription for session ${sessionId}`);

  return res.status(200).json({
    success: true,
    delivered: false,
    message: 'No push subscription - notification not delivered',
  });
}
