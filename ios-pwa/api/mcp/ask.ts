import type { VercelRequest, VercelResponse } from '@vercel/node';
import { store } from '../lib/store';
import { sendPushNotification, isConfigured } from '../lib/push';

// This endpoint is called by the MCP client (Claude) to ask questions
// It creates a question, sends a push notification, and waits for the response

export const config = {
  maxDuration: 120, // Allow up to 2 minutes for user response
};

interface AskRequest {
  sessionId: string;
  type: 'confirm' | 'choose' | 'text';
  title: string;
  message: string;
  choices?: Array<{ label: string; value: string; description?: string }>;
  options?: Record<string, unknown>;
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { sessionId, type, title, message, choices, options } = req.body as AskRequest;

  if (!sessionId) {
    return res.status(400).json({ error: 'Missing sessionId' });
  }

  if (!type || !['confirm', 'choose', 'text'].includes(type)) {
    return res.status(400).json({ error: 'Invalid or missing type' });
  }

  // Generate question ID
  const questionId = `q_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

  // Create the question
  const question = await store.createQuestion({
    id: questionId,
    sessionId,
    type,
    title: title || 'Question',
    message: message || '',
    choices,
    options,
  });

  console.log(`[MCP] Created question ${questionId} for session ${sessionId}, persistent: ${store.isPersistent()}`);

  // Send push notification with full question data
  const subscription = await store.getSubscription(sessionId);
  if (subscription && isConfigured()) {
    await sendPushNotification(subscription.subscription as any, {
      title: title || 'Claude needs your input',
      body: message || 'Tap to respond',
      questionId,
      type,
      question: {
        id: questionId,
        sessionId,
        type,
        title: title || 'Question',
        message: message || '',
        choices,
        options,
      },
    });
    console.log(`[MCP] Push notification sent with full question data`);
  } else {
    console.log(`[MCP] No push subscription for session ${sessionId}, relying on polling`);
  }

  // Wait for response (long-polling style)
  // The response will come via the /api/answer endpoint
  try {
    const response = await new Promise((resolve, reject) => {
      store.addPendingRequest(questionId, resolve, reject, 115000); // 115s timeout (under Vercel's 120s limit)
    });

    console.log(`[MCP] Question ${questionId} got response:`, response);

    return res.status(200).json({
      success: true,
      questionId,
      response,
    });
  } catch (error) {
    console.log(`[MCP] Question ${questionId} timed out or failed:`, error);

    return res.status(408).json({
      error: 'Request timeout',
      questionId,
      message: 'User did not respond in time',
    });
  }
}
