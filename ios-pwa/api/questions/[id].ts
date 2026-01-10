import type { VercelRequest, VercelResponse } from '@vercel/node';
import { store } from '../lib/store';

export default function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const id = req.query.id as string;

  if (!id) {
    return res.status(400).json({ error: 'Missing question id' });
  }

  const question = store.getQuestion(id);

  if (!question) {
    return res.status(404).json({ error: 'Question not found' });
  }

  return res.status(200).json(question);
}
