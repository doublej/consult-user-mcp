import type { VercelRequest, VercelResponse } from '@vercel/node';
import { store } from './lib/store';

export default function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { questionId, minutes = 5 } = req.body;

  if (!questionId) {
    return res.status(400).json({ error: 'Missing questionId' });
  }

  const snoozeMinutes = Math.min(Math.max(1, minutes), 60); // Clamp between 1-60 minutes

  const success = store.snoozeQuestion(questionId, snoozeMinutes);

  if (!success) {
    return res.status(404).json({ error: 'Question not found' });
  }

  console.log(`[Snooze] Question ${questionId} snoozed for ${snoozeMinutes} minutes`);

  return res.status(200).json({ success: true, snoozeMinutes });
}
