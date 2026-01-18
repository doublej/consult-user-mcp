// Consult User PWA - Main Application

// ============================================================================
// Configuration
// ============================================================================

const CONFIG = {
  apiBase: '/api',
  pollInterval: 3000, // Poll for questions every 3 seconds
  reconnectDelay: 5000,
};

// ============================================================================
// State Management
// ============================================================================

const state = {
  isInstalled: false,
  isSubscribed: false,
  subscription: null,
  sessionId: null,
  currentQuestion: null,
  pollTimer: null,
};

// ============================================================================
// DOM Elements
// ============================================================================

const elements = {
  installPrompt: document.getElementById('install-prompt'),
  mainScreen: document.getElementById('main-screen'),
  notificationPrompt: document.getElementById('notification-prompt'),
  enableNotifications: document.getElementById('enable-notifications'),
  waitingState: document.getElementById('waiting-state'),
  dialogContainer: document.getElementById('dialog-container'),
  connectionStatus: document.getElementById('connection-status'),
  sessionInfo: document.getElementById('session-info'),
};

// ============================================================================
// Initialization
// ============================================================================

async function init() {
  console.log('[App] Initializing...');

  // Check if running as installed PWA
  state.isInstalled = window.matchMedia('(display-mode: standalone)').matches
    || window.navigator.standalone === true;

  console.log('[App] Is installed:', state.isInstalled);

  if (!state.isInstalled) {
    showScreen('install');
    return;
  }

  showScreen('main');

  // Register service worker
  await registerServiceWorker();

  // Check notification permission
  await checkNotificationPermission();

  // Generate or retrieve session ID
  state.sessionId = getOrCreateSessionId();
  updateSessionInfo();

  // Check for question in URL
  const urlParams = new URLSearchParams(window.location.search);
  const questionId = urlParams.get('question');
  if (questionId) {
    await fetchAndShowQuestion(questionId);
  }

  // Start polling for questions
  startPolling();

  // Setup event listeners
  setupEventListeners();

  // Listen for messages from service worker
  navigator.serviceWorker?.addEventListener('message', handleServiceWorkerMessage);

  updateConnectionStatus('connected');
}

// ============================================================================
// Service Worker Registration
// ============================================================================

async function registerServiceWorker() {
  if (!('serviceWorker' in navigator)) {
    console.warn('[App] Service workers not supported');
    return;
  }

  try {
    const registration = await navigator.serviceWorker.register('/sw.js');
    console.log('[App] Service worker registered:', registration.scope);

    // Handle updates
    registration.addEventListener('updatefound', () => {
      const newWorker = registration.installing;
      newWorker?.addEventListener('statechange', () => {
        if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
          console.log('[App] New service worker available');
          newWorker.postMessage({ type: 'SKIP_WAITING' });
        }
      });
    });
  } catch (error) {
    console.error('[App] Service worker registration failed:', error);
  }
}

// ============================================================================
// Push Notifications
// ============================================================================

async function checkNotificationPermission() {
  if (!('Notification' in window)) {
    console.warn('[App] Notifications not supported');
    return;
  }

  if (Notification.permission === 'granted') {
    elements.notificationPrompt.classList.add('hidden');
    await subscribeToPush();
  } else if (Notification.permission === 'denied') {
    elements.notificationPrompt.classList.add('hidden');
    console.warn('[App] Notifications denied');
  } else {
    elements.notificationPrompt.classList.remove('hidden');
  }
}

async function requestNotificationPermission() {
  try {
    const permission = await Notification.requestPermission();
    console.log('[App] Notification permission:', permission);

    if (permission === 'granted') {
      elements.notificationPrompt.classList.add('hidden');
      await subscribeToPush();
    }
  } catch (error) {
    console.error('[App] Failed to request notification permission:', error);
  }
}

async function subscribeToPush() {
  try {
    const registration = await navigator.serviceWorker.ready;

    // Check for existing subscription
    let subscription = await registration.pushManager.getSubscription();

    if (!subscription) {
      // Get VAPID public key from server
      const response = await fetch(`${CONFIG.apiBase}/vapid-public-key`);
      const { publicKey } = await response.json();

      // Subscribe
      subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(publicKey)
      });

      // Send subscription to server
      await fetch(`${CONFIG.apiBase}/subscribe`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          sessionId: state.sessionId,
          subscription: subscription.toJSON()
        })
      });
    }

    state.subscription = subscription;
    state.isSubscribed = true;
    console.log('[App] Push subscription active');
  } catch (error) {
    console.error('[App] Failed to subscribe to push:', error);
  }
}

// ============================================================================
// Question Polling & Handling
// ============================================================================

function startPolling() {
  if (state.pollTimer) {
    clearInterval(state.pollTimer);
  }

  state.pollTimer = setInterval(pollForQuestions, CONFIG.pollInterval);
  pollForQuestions(); // Initial poll
}

async function pollForQuestions() {
  try {
    const response = await fetch(`${CONFIG.apiBase}/questions?sessionId=${state.sessionId}`);
    if (!response.ok) return;

    const data = await response.json();

    if (data.question && !state.currentQuestion) {
      showQuestion(data.question);
    }

    updateConnectionStatus('connected');
  } catch (error) {
    console.error('[App] Poll error:', error);
    updateConnectionStatus('disconnected');
  }
}

async function fetchAndShowQuestion(questionId) {
  try {
    const response = await fetch(`${CONFIG.apiBase}/questions/${questionId}`);
    if (!response.ok) return;

    const question = await response.json();
    showQuestion(question);
  } catch (error) {
    console.error('[App] Failed to fetch question:', error);
  }
}

function showQuestion(question) {
  state.currentQuestion = question;
  elements.waitingState.classList.add('hidden');
  elements.dialogContainer.classList.remove('hidden');

  const dialogHtml = renderDialog(question);
  elements.dialogContainer.innerHTML = dialogHtml;

  // Setup dialog event listeners
  setupDialogListeners();
}

function hideQuestion() {
  state.currentQuestion = null;
  elements.dialogContainer.classList.add('hidden');
  elements.dialogContainer.innerHTML = '';
  elements.waitingState.classList.remove('hidden');
}

// ============================================================================
// Dialog Rendering
// ============================================================================

function renderDialog(question) {
  const { type, title, message, options = {} } = question;

  switch (type) {
    case 'confirm':
      return renderConfirmDialog(question);
    case 'choose':
      return renderChooseDialog(question);
    case 'text':
      return renderTextDialog(question);
    default:
      return renderConfirmDialog(question);
  }
}

function renderConfirmDialog(question) {
  const { title, message, options = {} } = question;
  const yesText = options.yesText || 'Yes';
  const noText = options.noText || 'No';

  return `
    <div class="dialog" data-type="confirm">
      <div class="dialog-header">
        <div class="dialog-icon">
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="10"/>
            <path d="M12 16v-4M12 8h.01"/>
          </svg>
        </div>
        <h1 class="dialog-title">${escapeHtml(title || 'Confirmation')}</h1>
        <p class="dialog-message">${escapeHtml(message || 'Please confirm')}</p>
      </div>

      ${renderToolbar()}

      <div class="dialog-actions">
        <button class="btn primary" data-action="yes">${escapeHtml(yesText)}</button>
        <button class="btn secondary" data-action="no">${escapeHtml(noText)}</button>
      </div>
    </div>
  `;
}

function renderChooseDialog(question) {
  const { title, message, choices = [], options = {} } = question;
  const isMulti = options.multiple || false;

  const choicesHtml = choices.map((choice, index) => `
    <div class="choice-card ${isMulti ? 'multi' : ''}"
         data-index="${index}"
         data-value="${escapeHtml(choice.value || choice)}"
         tabindex="0"
         role="option"
         aria-selected="false">
      <div class="choice-indicator">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3">
          <polyline points="20 6 9 17 4 12"/>
        </svg>
      </div>
      <div class="choice-content">
        <div class="choice-label">${escapeHtml(choice.label || choice)}</div>
        ${choice.description ? `<div class="choice-description">${escapeHtml(choice.description)}</div>` : ''}
      </div>
    </div>
  `).join('');

  return `
    <div class="dialog" data-type="choose" data-multiple="${isMulti}">
      <div class="dialog-header">
        <div class="dialog-icon">
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M9 11l3 3L22 4"/>
            <path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11"/>
          </svg>
        </div>
        <h1 class="dialog-title">${escapeHtml(title || 'Choose')}</h1>
        <p class="dialog-message">${escapeHtml(message || 'Select an option')}</p>
      </div>

      ${renderToolbar()}

      <div class="choices" role="listbox" aria-label="${escapeHtml(title || 'Choose an option')}">
        ${choicesHtml}
      </div>

      <div class="dialog-actions">
        <button class="btn primary" data-action="submit" ${isMulti ? '' : 'disabled'}>Done</button>
        <button class="btn secondary" data-action="cancel">Cancel</button>
      </div>
    </div>
  `;
}

function renderTextDialog(question) {
  const { title, message, options = {} } = question;
  const placeholder = options.placeholder || 'Enter your response...';
  const isPassword = options.hidden || false;

  return `
    <div class="dialog" data-type="text">
      <div class="dialog-header">
        <div class="dialog-icon">
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            ${isPassword ?
              '<rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0110 0v4"/>' :
              '<path d="M12 19l7-7 3 3-7 7-3-3z"/><path d="M18 13l-1.5-7.5L2 2l3.5 14.5L13 18l5-5z"/><path d="M2 2l7.586 7.586"/>'
            }
          </svg>
        </div>
        <h1 class="dialog-title">${escapeHtml(title || 'Input')}</h1>
        <p class="dialog-message">${escapeHtml(message || 'Please provide your input')}</p>
      </div>

      ${renderToolbar()}

      <div class="text-input-container">
        <textarea
          class="text-input"
          id="text-response"
          placeholder="${escapeHtml(placeholder)}"
          ${isPassword ? 'style="-webkit-text-security: disc;"' : ''}
        ></textarea>
      </div>

      <div class="dialog-actions">
        <button class="btn primary" data-action="submit">Submit</button>
        <button class="btn secondary" data-action="cancel">Cancel</button>
      </div>
    </div>
  `;
}

function renderToolbar() {
  return `
    <div class="dialog-toolbar">
      <button class="toolbar-btn" data-toolbar="snooze">Snooze</button>
      <button class="toolbar-btn" data-toolbar="feedback">Feedback</button>
    </div>
    <div class="snooze-panel hidden" id="snooze-panel">
      <div class="snooze-options">
        <button class="snooze-option" data-minutes="1">1 min</button>
        <button class="snooze-option" data-minutes="5">5 min</button>
        <button class="snooze-option" data-minutes="15">15 min</button>
        <button class="snooze-option" data-minutes="30">30 min</button>
        <button class="snooze-option" data-minutes="60">1 hour</button>
      </div>
    </div>
    <div class="feedback-panel hidden" id="feedback-panel">
      <textarea class="text-input" id="feedback-text" placeholder="Send feedback to Claude..." rows="3"></textarea>
      <button class="btn secondary" data-action="send-feedback" style="margin-top: 12px; width: 100%;">Send Feedback</button>
    </div>
  `;
}

// ============================================================================
// Dialog Event Handlers
// ============================================================================

function setupDialogListeners() {
  const dialog = elements.dialogContainer.querySelector('.dialog');
  if (!dialog) return;

  const type = dialog.dataset.type;

  // Action buttons
  dialog.querySelectorAll('[data-action]').forEach(btn => {
    btn.addEventListener('click', () => handleAction(btn.dataset.action));
  });

  // Choice cards
  if (type === 'choose') {
    const isMulti = dialog.dataset.multiple === 'true';
    const cards = dialog.querySelectorAll('.choice-card');

    const selectCard = (card) => {
      if (isMulti) {
        card.classList.toggle('selected');
        card.setAttribute('aria-selected', card.classList.contains('selected'));
        const hasSelection = dialog.querySelector('.choice-card.selected');
        dialog.querySelector('[data-action="submit"]').disabled = !hasSelection;
      } else {
        cards.forEach(c => {
          c.classList.remove('selected');
          c.setAttribute('aria-selected', 'false');
        });
        card.classList.add('selected');
        card.setAttribute('aria-selected', 'true');
        dialog.querySelector('[data-action="submit"]').disabled = false;
      }
    };

    cards.forEach((card, index) => {
      card.addEventListener('click', () => selectCard(card));
      card.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          selectCard(card);
        } else if (e.key === 'ArrowDown' && index < cards.length - 1) {
          e.preventDefault();
          cards[index + 1].focus();
        } else if (e.key === 'ArrowUp' && index > 0) {
          e.preventDefault();
          cards[index - 1].focus();
        }
      });
    });
  }

  // Toolbar buttons
  dialog.querySelectorAll('[data-toolbar]').forEach(btn => {
    btn.addEventListener('click', () => toggleToolbarPanel(btn.dataset.toolbar));
  });

  // Snooze options
  dialog.querySelectorAll('.snooze-option').forEach(btn => {
    btn.addEventListener('click', () => handleSnooze(parseInt(btn.dataset.minutes)));
  });
}

function toggleToolbarPanel(panel) {
  const snoozePanel = document.getElementById('snooze-panel');
  const feedbackPanel = document.getElementById('feedback-panel');
  const snoozeBtn = document.querySelector('[data-toolbar="snooze"]');
  const feedbackBtn = document.querySelector('[data-toolbar="feedback"]');

  if (panel === 'snooze') {
    const isActive = snoozeBtn.classList.toggle('active');
    snoozePanel.classList.toggle('hidden', !isActive);
    feedbackPanel.classList.add('hidden');
    feedbackBtn.classList.remove('active');
  } else {
    const isActive = feedbackBtn.classList.toggle('active');
    feedbackPanel.classList.toggle('hidden', !isActive);
    snoozePanel.classList.add('hidden');
    snoozeBtn.classList.remove('active');
  }
}

async function handleAction(action) {
  if (!state.currentQuestion) return;

  const dialog = elements.dialogContainer.querySelector('.dialog');
  const type = dialog?.dataset.type;
  let response = null;

  switch (action) {
    case 'yes':
      response = { type: 'answer', value: true };
      break;
    case 'no':
      response = { type: 'answer', value: false };
      break;
    case 'submit':
      if (type === 'choose') {
        const selected = dialog.querySelectorAll('.choice-card.selected');
        const values = Array.from(selected).map(card => card.dataset.value);
        response = { type: 'answer', value: dialog.dataset.multiple === 'true' ? values : values[0] };
      } else if (type === 'text') {
        const text = document.getElementById('text-response')?.value || '';
        response = { type: 'answer', value: text };
      }
      break;
    case 'cancel':
      response = { type: 'cancel' };
      break;
    case 'send-feedback':
      const feedback = document.getElementById('feedback-text')?.value || '';
      if (feedback.trim()) {
        response = { type: 'feedback', value: feedback };
      }
      break;
  }

  if (response) {
    await submitResponse(response);
  }
}

async function handleSnooze(minutes) {
  if (!state.currentQuestion) return;

  await submitResponse({
    type: 'snooze',
    minutes: minutes
  });
}

async function submitResponse(response) {
  try {
    const res = await fetch(`${CONFIG.apiBase}/answer`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        questionId: state.currentQuestion.id,
        sessionId: state.sessionId,
        response
      })
    });

    if (res.ok) {
      hideQuestion();
    }
  } catch (error) {
    console.error('[App] Failed to submit response:', error);
  }
}

// ============================================================================
// Event Listeners
// ============================================================================

function setupEventListeners() {
  elements.enableNotifications?.addEventListener('click', requestNotificationPermission);
}

function handleServiceWorkerMessage(event) {
  console.log('[App] Message from SW:', event.data);

  if (event.data?.type === 'QUESTION_RECEIVED') {
    fetchAndShowQuestion(event.data.questionId);
  }
}

// ============================================================================
// UI Helpers
// ============================================================================

function showScreen(screen) {
  elements.installPrompt.classList.toggle('hidden', screen !== 'install');
  elements.mainScreen.classList.toggle('hidden', screen !== 'main');
}

function updateConnectionStatus(status) {
  const el = elements.connectionStatus;
  el.classList.remove('connected', 'disconnected');
  el.classList.add(status);
  el.querySelector('.status-text').textContent = status === 'connected' ? 'Connected' : 'Reconnecting...';
}

function updateSessionInfo() {
  if (elements.sessionInfo && state.sessionId) {
    elements.sessionInfo.textContent = `Session: ${state.sessionId.slice(0, 8)}...`;
  }
}

// ============================================================================
// Utility Functions
// ============================================================================

function getOrCreateSessionId() {
  let sessionId = localStorage.getItem('consult-user-session');
  if (!sessionId) {
    sessionId = crypto.randomUUID();
    localStorage.setItem('consult-user-session', sessionId);
  }
  return sessionId;
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

function urlBase64ToUint8Array(base64String) {
  const padding = '='.repeat((4 - base64String.length % 4) % 4);
  const base64 = (base64String + padding)
    .replace(/-/g, '+')
    .replace(/_/g, '/');

  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);

  for (let i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}

// ============================================================================
// Start Application
// ============================================================================

document.addEventListener('DOMContentLoaded', init);
