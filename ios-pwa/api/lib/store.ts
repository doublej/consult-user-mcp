// Simple in-memory store
// Questions are also embedded in push notifications for serverless compatibility

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

// In-memory stores (work within same instance)
const questions = new Map<string, Question>();
const subscriptions = new Map<string, Subscription>();
const pendingRequests = new Map<string, PendingRequest>();

export const store = {
  // Questions
  async createQuestion(question: Omit<Question, 'createdAt' | 'expiresAt' | 'status'>): Promise<Question> {
    const now = Date.now();
    const q: Question = {
      ...question,
      createdAt: now,
      expiresAt: now + 5 * 60 * 1000,
      status: 'pending',
    };
    questions.set(q.id, q);
    return q;
  },

  async getQuestion(id: string): Promise<Question | undefined> {
    return questions.get(id);
  },

  async getPendingQuestion(sessionId: string): Promise<Question | undefined> {
    for (const q of questions.values()) {
      if (q.sessionId === sessionId && q.status === 'pending') {
        return q;
      }
    }
    return undefined;
  },

  async answerQuestion(id: string, response: unknown): Promise<boolean> {
    const q = questions.get(id);
    if (!q || q.status !== 'pending') return false;

    q.status = 'answered';
    q.response = response;

    const pending = pendingRequests.get(id);
    if (pending) {
      clearTimeout(pending.timeoutId);
      pending.resolve(response);
      pendingRequests.delete(id);
    }

    return true;
  },

  async snoozeQuestion(id: string, minutes: number): Promise<boolean> {
    const q = questions.get(id);
    if (!q) return false;

    q.status = 'snoozed';
    q.expiresAt = Date.now() + minutes * 60 * 1000;

    const pending = pendingRequests.get(id);
    if (pending) {
      clearTimeout(pending.timeoutId);
      pending.resolve({ type: 'snooze', minutes });
      pendingRequests.delete(id);
    }

    return true;
  },

  // Subscriptions
  async setSubscription(sessionId: string, subscription: PushSubscription): Promise<void> {
    subscriptions.set(sessionId, {
      sessionId,
      subscription,
      createdAt: Date.now(),
    });
  },

  async getSubscription(sessionId: string): Promise<Subscription | undefined> {
    return subscriptions.get(sessionId);
  },

  // Pending requests
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

  isPersistent(): boolean {
    return false;
  },
};

export type { Question, Subscription };
