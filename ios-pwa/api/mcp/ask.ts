import type { VercelRequest, VercelResponse } from '@vercel/node';
import { store } from '../lib/store';
import { sendPushNotification, isConfigured } from '../lib/push';
import { validateSessionId, validateOptionalString, validateChoices, isObject, isString, MAX_TITLE_LENGTH, MAX_MESSAGE_LENGTH } from '../lib/validate';

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

  if (!isObject(req.body)) {
    return res.status(400).json({ error: 'Invalid request body' });
  }

  const { sessionId, type, title, message, choices, options } = req.body as AskRequest;

  const sidErr = validateSessionId(sessionId);
  if (sidErr) return res.status(400).json({ error: sidErr.message });

  if (!isString(type) || !['confirm', 'choose', 'text'].includes(type)) {
    return res.status(400).json({ error: 'Invalid or missing type (must be confirm, choose, or text)' });
  }

  const titleErr = validateOptionalString(title, 'title', MAX_TITLE_LENGTH);
  if (titleErr) return res.status(400).json({ error: titleErr.message });

  const msgErr = validateOptionalString(message, 'message', MAX_MESSAGE_LENGTH);
  if (msgErr) return res.status(400).json({ error: msgErr.message });

  if (type === 'choose' && choices) {
    const choicesErr = validateChoices(choices);
    if (choicesErr) return res.status(400).json({ error: choicesErr.message });
  }

  // Generate question ID
  const questionId = `q_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

  // Create the question
  const question = store.createQuestion({
    id: questionId,
    sessionId,
    type,
    title: title || 'Question',
    message: message || '',
    choices,
    options,
  });

  console.log(`[MCP] Created question ${questionId} for session ${sessionId}`);

  // Send push notification if configured
  const subscription = store.getSubscription(sessionId);
  if (subscription && isConfigured()) {
    await sendPushNotification(subscription.subscription as any, {
      title: title || 'Claude needs your input',
      body: message || 'Tap to respond',
      questionId,
      type,
    });
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
