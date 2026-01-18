import type { VercelRequest, VercelResponse } from '@vercel/node';
import { store } from './lib/store';
import { validateQuestionId, validateSessionId, validateString, isObject, MAX_STRING_LENGTH } from './lib/validate';

export default function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  if (!isObject(req.body)) {
    return res.status(400).json({ error: 'Invalid request body' });
  }

  const { questionId, sessionId, response } = req.body;

  const qidErr = validateQuestionId(questionId);
  if (qidErr) return res.status(400).json({ error: qidErr.message });

  if (sessionId !== undefined) {
    const sidErr = validateSessionId(sessionId);
    if (sidErr) return res.status(400).json({ error: sidErr.message });
  }

  if (response === undefined || response === null) {
    return res.status(400).json({ error: 'Missing response' });
  }

  // Validate response is string or object with reasonable size
  const responseStr = typeof response === 'string' ? response : JSON.stringify(response);
  if (responseStr.length > MAX_STRING_LENGTH) {
    return res.status(400).json({ error: 'Response exceeds maximum length' });
  }

  const question = store.getQuestion(questionId);

  if (!question) {
    return res.status(404).json({ error: 'Question not found' });
  }

  if (sessionId && question.sessionId !== sessionId) {
    return res.status(403).json({ error: 'Session mismatch' });
  }

  const success = store.answerQuestion(questionId, response);

  if (!success) {
    return res.status(400).json({ error: 'Question already answered or expired' });
  }

  console.log(`[Answer] Question ${questionId} answered:`, response);

  return res.status(200).json({ success: true });
}
