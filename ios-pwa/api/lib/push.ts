// eslint-disable-next-line @typescript-eslint/no-var-requires
const webpush = require('web-push');

// VAPID keys - in production, store these in environment variables
// Generate new keys with: npx web-push generate-vapid-keys
const VAPID_PUBLIC_KEY = process.env.VAPID_PUBLIC_KEY || '';
const VAPID_PRIVATE_KEY = process.env.VAPID_PRIVATE_KEY || '';
const VAPID_SUBJECT = process.env.VAPID_SUBJECT || 'mailto:admin@example.com';

// Configure web-push
if (VAPID_PUBLIC_KEY && VAPID_PRIVATE_KEY) {
  webpush.setVapidDetails(VAPID_SUBJECT, VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY);
}

interface WebPushSubscription {
  endpoint: string;
  keys: {
    p256dh: string;
    auth: string;
  };
}

export interface PushPayload {
  title: string;
  body: string;
  questionId: string;
  type: string;
}

export async function sendPushNotification(
  subscription: WebPushSubscription,
  payload: PushPayload
): Promise<boolean> {
  if (!VAPID_PUBLIC_KEY || !VAPID_PRIVATE_KEY) {
    console.warn('[Push] VAPID keys not configured');
    return false;
  }

  try {
    await webpush.sendNotification(subscription, JSON.stringify(payload));
    console.log('[Push] Notification sent successfully');
    return true;
  } catch (error: unknown) {
    const err = error as { statusCode?: number };
    console.error('[Push] Failed to send notification:', error);

    // Handle subscription expiry
    if (err.statusCode === 410) {
      console.log('[Push] Subscription has expired or is invalid');
    }

    return false;
  }
}

export function getVapidPublicKey(): string {
  return VAPID_PUBLIC_KEY;
}

export function isConfigured(): boolean {
  return Boolean(VAPID_PUBLIC_KEY && VAPID_PRIVATE_KEY);
}
