import type { VercelRequest, VercelResponse } from '@vercel/node';
import { store } from './lib/store';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { questionId, sessionId, response } = req.body;

  if (!questionId || !response) {
    return res.status(400).json({ error: 'Missing questionId or response' });
  }

  const question = await store.getQuestion(questionId);

  if (!question) {
    return res.status(404).json({ error: 'Question not found' });
  }

  if (sessionId && question.sessionId !== sessionId) {
    return res.status(403).json({ error: 'Session mismatch' });
  }

  const success = await store.answerQuestion(questionId, response);

  if (!success) {
    return res.status(400).json({ error: 'Question already answered or expired' });
  }

  console.log(`[Answer] Question ${questionId} answered:`, response);

  return res.status(200).json({ success: true });
}
