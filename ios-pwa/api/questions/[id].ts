import type { VercelRequest, VercelResponse } from '@vercel/node';
import { store } from '../lib/store';
import { validateQuestionId } from '../lib/validate';

export default function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const id = req.query.id as string;

  const idErr = validateQuestionId(id);
  if (idErr) return res.status(400).json({ error: idErr.message });

  const question = store.getQuestion(id);

  if (!question) {
    return res.status(404).json({ error: 'Question not found' });
  }

  return res.status(200).json(question);
}
