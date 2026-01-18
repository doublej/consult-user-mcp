import type { VercelRequest, VercelResponse } from '@vercel/node';
import { store } from '../lib/store';
import { sendPushNotification, isConfigured } from '../lib/push';
import { validateSessionId, validateString, validateOptionalString, isObject, MAX_TITLE_LENGTH, MAX_MESSAGE_LENGTH } from '../lib/validate';

// Send a notification without requiring a response

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  if (!isObject(req.body)) {
    return res.status(400).json({ error: 'Invalid request body' });
  }

  const { sessionId, title, message } = req.body;

  const sidErr = validateSessionId(sessionId);
  if (sidErr) return res.status(400).json({ error: sidErr.message });

  const msgErr = validateString(message, 'message', MAX_MESSAGE_LENGTH);
  if (msgErr) return res.status(400).json({ error: msgErr.message });

  const titleErr = validateOptionalString(title, 'title', MAX_TITLE_LENGTH);
  if (titleErr) return res.status(400).json({ error: titleErr.message });

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
