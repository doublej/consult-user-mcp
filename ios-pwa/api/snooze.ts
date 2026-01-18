import type { VercelRequest, VercelResponse } from '@vercel/node';
import { store } from './lib/store';
import { validateQuestionId, isObject, isNumber } from './lib/validate';

export default function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  if (!isObject(req.body)) {
    return res.status(400).json({ error: 'Invalid request body' });
  }

  const { questionId, minutes = 5 } = req.body;

  const qidErr = validateQuestionId(questionId);
  if (qidErr) return res.status(400).json({ error: qidErr.message });

  if (minutes !== undefined && !isNumber(minutes)) {
    return res.status(400).json({ error: 'minutes must be a number' });
  }

  const snoozeMinutes = Math.min(Math.max(1, Number(minutes) || 5), 60);

  const success = store.snoozeQuestion(questionId, snoozeMinutes);

  if (!success) {
    return res.status(404).json({ error: 'Question not found' });
  }

  console.log(`[Snooze] Question ${questionId} snoozed for ${snoozeMinutes} minutes`);

  return res.status(200).json({ success: true, snoozeMinutes });
}
