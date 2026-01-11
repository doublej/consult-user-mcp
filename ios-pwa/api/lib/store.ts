// Store implementation with Upstash Redis support
// Falls back to in-memory for local development

import { Redis } from '@upstash/redis';

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

// Redis client (if configured)
let redis: Redis | null = null;
if (process.env.UPSTASH_REDIS_REST_URL && process.env.UPSTASH_REDIS_REST_TOKEN) {
  redis = new Redis({
    url: process.env.UPSTASH_REDIS_REST_URL,
    token: process.env.UPSTASH_REDIS_REST_TOKEN,
  });
  console.log('[Store] Using Upstash Redis');
} else if (process.env.KV_REST_API_URL && process.env.KV_REST_API_TOKEN) {
  redis = new Redis({
    url: process.env.KV_REST_API_URL,
    token: process.env.KV_REST_API_TOKEN,
  });
  console.log('[Store] Using Vercel KV');
} else {
  console.warn('[Store] No Redis configured - using in-memory store (won\'t work across serverless instances!)');
}

// In-memory fallback (only for local dev)
const localQuestions = new Map<string, Question>();
const localSubscriptions = new Map<string, Subscription>();
const pendingRequests = new Map<string, PendingRequest>();

// Key prefixes for Redis
const QUESTION_PREFIX = 'q:';
const SUBSCRIPTION_PREFIX = 's:';
const SESSION_QUESTION_PREFIX = 'sq:';

export const store = {
  // Questions
  async createQuestion(question: Omit<Question, 'createdAt' | 'expiresAt' | 'status'>): Promise<Question> {
    const now = Date.now();
    const q: Question = {
      ...question,
      createdAt: now,
      expiresAt: now + 5 * 60 * 1000, // 5 minute expiry
      status: 'pending',
    };

    if (redis) {
      const ttl = 300; // 5 minutes
      await redis.set(`${QUESTION_PREFIX}${q.id}`, JSON.stringify(q), { ex: ttl });
      await redis.set(`${SESSION_QUESTION_PREFIX}${q.sessionId}`, q.id, { ex: ttl });
    } else {
      localQuestions.set(q.id, q);
    }

    return q;
  },

  async getQuestion(id: string): Promise<Question | undefined> {
    if (redis) {
      const data = await redis.get(`${QUESTION_PREFIX}${id}`);
      return data ? (typeof data === 'string' ? JSON.parse(data) : data as Question) : undefined;
    }
    return localQuestions.get(id);
  },

  async getPendingQuestion(sessionId: string): Promise<Question | undefined> {
    if (redis) {
      const questionId = await redis.get(`${SESSION_QUESTION_PREFIX}${sessionId}`);
      if (questionId) {
        return this.getQuestion(questionId as string);
      }
      return undefined;
    }

    for (const q of localQuestions.values()) {
      if (q.sessionId === sessionId && q.status === 'pending') {
        return q;
      }
    }
    return undefined;
  },

  async answerQuestion(id: string, response: unknown): Promise<boolean> {
    const q = await this.getQuestion(id);
    if (!q || q.status !== 'pending') return false;

    q.status = 'answered';
    q.response = response;

    if (redis) {
      await redis.set(`${QUESTION_PREFIX}${id}`, JSON.stringify(q), { ex: 60 }); // Keep for 1 min after answer
      await redis.del(`${SESSION_QUESTION_PREFIX}${q.sessionId}`);
    } else {
      localQuestions.set(id, q);
    }

    // Resolve pending request (in-memory, same instance only)
    const pending = pendingRequests.get(id);
    if (pending) {
      clearTimeout(pending.timeoutId);
      pending.resolve(response);
      pendingRequests.delete(id);
    }

    return true;
  },

  async snoozeQuestion(id: string, minutes: number): Promise<boolean> {
    const q = await this.getQuestion(id);
    if (!q) return false;

    q.status = 'snoozed';
    q.expiresAt = Date.now() + minutes * 60 * 1000;

    if (redis) {
      await redis.set(`${QUESTION_PREFIX}${id}`, JSON.stringify(q), { ex: minutes * 60 });
    } else {
      localQuestions.set(id, q);
    }

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
  async setSubscription(sessionId: string, subscription: PushSubscription): Promise<void> {
    const sub: Subscription = {
      sessionId,
      subscription,
      createdAt: Date.now(),
    };

    if (redis) {
      await redis.set(`${SUBSCRIPTION_PREFIX}${sessionId}`, JSON.stringify(sub));
    } else {
      localSubscriptions.set(sessionId, sub);
    }
  },

  async getSubscription(sessionId: string): Promise<Subscription | undefined> {
    if (redis) {
      const data = await redis.get(`${SUBSCRIPTION_PREFIX}${sessionId}`);
      return data ? (typeof data === 'string' ? JSON.parse(data) : data as Subscription) : undefined;
    }
    return localSubscriptions.get(sessionId);
  },

  // Pending requests (always in-memory - same instance only)
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

  // Check if using persistent storage
  isPersistent(): boolean {
    return redis !== null;
  },
};

export type { Question, Subscription };
