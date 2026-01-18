// Input validation utilities for API endpoints

export const MAX_STRING_LENGTH = 1000;
export const MAX_TITLE_LENGTH = 200;
export const MAX_MESSAGE_LENGTH = 2000;
export const MAX_CHOICES = 20;
export const SESSION_ID_PATTERN = /^[a-zA-Z0-9_-]{1,64}$/;
export const QUESTION_ID_PATTERN = /^q_\d+_[a-z0-9]+$/;

export interface ValidationError {
  field: string;
  message: string;
}

export function isString(value: unknown): value is string {
  return typeof value === 'string';
}

export function isNumber(value: unknown): value is number {
  return typeof value === 'number' && !isNaN(value);
}

export function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

export function isArray(value: unknown): value is unknown[] {
  return Array.isArray(value);
}

export function validateSessionId(sessionId: unknown): ValidationError | null {
  if (!isString(sessionId)) {
    return { field: 'sessionId', message: 'sessionId must be a string' };
  }
  if (!SESSION_ID_PATTERN.test(sessionId)) {
    return { field: 'sessionId', message: 'sessionId contains invalid characters or is too long' };
  }
  return null;
}

export function validateQuestionId(questionId: unknown): ValidationError | null {
  if (!isString(questionId)) {
    return { field: 'questionId', message: 'questionId must be a string' };
  }
  if (!QUESTION_ID_PATTERN.test(questionId)) {
    return { field: 'questionId', message: 'Invalid questionId format' };
  }
  return null;
}

export function validateString(
  value: unknown,
  field: string,
  maxLength = MAX_STRING_LENGTH
): ValidationError | null {
  if (!isString(value)) {
    return { field, message: `${field} must be a string` };
  }
  if (value.length > maxLength) {
    return { field, message: `${field} exceeds maximum length of ${maxLength}` };
  }
  return null;
}

export function validateOptionalString(
  value: unknown,
  field: string,
  maxLength = MAX_STRING_LENGTH
): ValidationError | null {
  if (value === undefined || value === null) {
    return null;
  }
  return validateString(value, field, maxLength);
}

export function validateChoices(choices: unknown): ValidationError | null {
  if (!isArray(choices)) {
    return { field: 'choices', message: 'choices must be an array' };
  }
  if (choices.length > MAX_CHOICES) {
    return { field: 'choices', message: `choices cannot exceed ${MAX_CHOICES} items` };
  }
  for (let i = 0; i < choices.length; i++) {
    const choice = choices[i];
    if (!isObject(choice)) {
      return { field: `choices[${i}]`, message: 'choice must be an object' };
    }
    const labelErr = validateString(choice.label, `choices[${i}].label`, MAX_TITLE_LENGTH);
    if (labelErr) return labelErr;
    const valueErr = validateString(choice.value, `choices[${i}].value`, MAX_STRING_LENGTH);
    if (valueErr) return valueErr;
    if (choice.description !== undefined) {
      const descErr = validateOptionalString(choice.description, `choices[${i}].description`, MAX_MESSAGE_LENGTH);
      if (descErr) return descErr;
    }
  }
  return null;
}

export function validateSubscription(subscription: unknown): ValidationError | null {
  if (!isObject(subscription)) {
    return { field: 'subscription', message: 'subscription must be an object' };
  }
  if (!isString(subscription.endpoint)) {
    return { field: 'subscription.endpoint', message: 'endpoint must be a string' };
  }
  // Basic URL validation
  try {
    new URL(subscription.endpoint as string);
  } catch {
    return { field: 'subscription.endpoint', message: 'endpoint must be a valid URL' };
  }
  return null;
}
