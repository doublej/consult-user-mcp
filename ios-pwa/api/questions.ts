import type { VercelRequest, VercelResponse } from '@vercel/node';
import { store } from './lib/store';

export default function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const sessionId = req.query.sessionId as string;

  if (!sessionId) {
    return res.status(400).json({ error: 'Missing sessionId' });
  }

  const question = store.getPendingQuestion(sessionId);

  if (question) {
    return res.status(200).json({ question });
  }

  return res.status(200).json({ question: null });
}
