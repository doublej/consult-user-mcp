// In-memory store (for demo - use Vercel KV or Upstash Redis in production)
// This works for single-instance deployments; for production, use a real database

interface Question {
  id: string;
  sessionId: string;
  type: 'confirm' | 'choose' | 'text';
  title: string;
  message: string;
  choices?: Array<{ label: string; value: string; description?: string }>;
  options?: Record<string, unknown>;
  createdAt: number;
  expiresAt: number;
  status: 'pending' | 'answered' | 'snoozed' | 'expired';
  response?: unknown;
}

interface Subscription {
  sessionId: string;
  subscription: PushSubscription;
  createdAt: number;
}

interface PendingRequest {
  questionId: string;
  resolve: (value: unknown) => void;
  reject: (reason: unknown) => void;
  timeoutId: NodeJS.Timeout;
}

// In-memory stores
const questions = new Map<string, Question>();
const subscriptions = new Map<string, Subscription>();
const pendingRequests = new Map<string, PendingRequest>();

// Cleanup old entries periodically
setInterval(() => {
  const now = Date.now();
  for (const [id, q] of questions) {
    if (q.expiresAt < now) {
      questions.delete(id);
      // Reject any pending request
      const pending = pendingRequests.get(id);
      if (pending) {
        clearTimeout(pending.timeoutId);
        pending.reject(new Error('Question expired'));
        pendingRequests.delete(id);
      }
    }
  }
}, 60000); // Every minute

export const store = {
  // Questions
  createQuestion(question: Omit<Question, 'createdAt' | 'expiresAt' | 'status'>): Question {
    const now = Date.now();
    const q: Question = {
      ...question,
      createdAt: now,
      expiresAt: now + 5 * 60 * 1000, // 5 minute expiry
      status: 'pending',
    };
    questions.set(q.id, q);
    return q;
  },

  getQuestion(id: string): Question | undefined {
    return questions.get(id);
  },

  getPendingQuestion(sessionId: string): Question | undefined {
    for (const q of questions.values()) {
      if (q.sessionId === sessionId && q.status === 'pending') {
        return q;
      }
    }
    return undefined;
  },

  answerQuestion(id: string, response: unknown): boolean {
    const q = questions.get(id);
    if (!q || q.status !== 'pending') return false;

    q.status = 'answered';
    q.response = response;

    // Resolve pending request
    const pending = pendingRequests.get(id);
    if (pending) {
      clearTimeout(pending.timeoutId);
      pending.resolve(response);
      pendingRequests.delete(id);
    }

    return true;
  },

  snoozeQuestion(id: string, minutes: number): boolean {
    const q = questions.get(id);
    if (!q) return false;

    q.status = 'snoozed';
    q.expiresAt = Date.now() + minutes * 60 * 1000;

    // Resolve pending request with snooze
    const pending = pendingRequests.get(id);
    if (pending) {
      clearTimeout(pending.timeoutId);
      pending.resolve({ type: 'snooze', minutes });
      pendingRequests.delete(id);
    }

    return true;
  },

  // Subscriptions
  setSubscription(sessionId: string, subscription: PushSubscription): void {
    subscriptions.set(sessionId, {
      sessionId,
      subscription,
      createdAt: Date.now(),
    });
  },

  getSubscription(sessionId: string): Subscription | undefined {
    return subscriptions.get(sessionId);
  },

  getAllSubscriptions(): Subscription[] {
    return Array.from(subscriptions.values());
  },

  // Pending requests (for long-polling MCP responses)
  addPendingRequest(
    questionId: string,
    resolve: (value: unknown) => void,
    reject: (reason: unknown) => void,
    timeoutMs: number = 120000
  ): void {
    const timeoutId = setTimeout(() => {
      pendingRequests.delete(questionId);
      reject(new Error('Request timeout'));
    }, timeoutMs);

    pendingRequests.set(questionId, { questionId, resolve, reject, timeoutId });
  },

  removePendingRequest(questionId: string): void {
    const pending = pendingRequests.get(questionId);
    if (pending) {
      clearTimeout(pending.timeoutId);
      pendingRequests.delete(questionId);
    }
  },
};

export type { Question, Subscription };
