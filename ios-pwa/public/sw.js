// Service Worker for Consult User PWA
const CACHE_NAME = 'consult-user-v5';
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/styles.css',
  '/app.js',
  '/manifest.json',
  '/icons/icon-192.png',
  '/icons/icon-512.png'
];

// Install event - cache static assets
self.addEventListener('install', (event) => {
  console.log('[SW] Installing service worker...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('[SW] Caching static assets');
        return cache.addAll(STATIC_ASSETS);
      })
      .then(() => self.skipWaiting())
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating service worker...');
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames
            .filter((name) => name !== CACHE_NAME)
            .map((name) => caches.delete(name))
        );
      })
      .then(() => self.clients.claim())
  );
});

// Fetch event - network first for JS, cache first for others
self.addEventListener('fetch', (event) => {
  // Skip API requests
  if (event.request.url.includes('/api/')) {
    return;
  }

  // Network first for JavaScript files (to get updates faster)
  if (event.request.url.endsWith('.js')) {
    event.respondWith(
      fetch(event.request)
        .then((response) => {
          // Update cache with new version
          const responseClone = response.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseClone);
          });
          return response;
        })
        .catch(() => caches.match(event.request))
    );
    return;
  }

  // Cache first for other static assets
  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        if (response) {
          return response;
        }
        return fetch(event.request);
      })
  );
});

// Push event - handle incoming push notifications
self.addEventListener('push', (event) => {
  console.log('[SW] Push notification received');

  let data = {
    title: 'Claude needs your input',
    body: 'Tap to respond',
    questionId: null,
    type: 'confirm',
    question: null
  };

  if (event.data) {
    try {
      data = { ...data, ...event.data.json() };
    } catch (e) {
      data.body = event.data.text();
    }
  }

  // Store question data for when user opens the app
  const questionData = data.question ? JSON.stringify(data.question) : '';

  const options = {
    body: data.body,
    icon: '/icons/icon-192.png',
    badge: '/icons/icon-192.png',
    tag: data.questionId || 'consult-user',
    renotify: true,
    requireInteraction: true,
    data: {
      questionId: data.questionId,
      type: data.type,
      question: data.question,
      url: `/?question=${data.questionId}&data=${encodeURIComponent(questionData)}`
    },
    actions: [
      { action: 'open', title: 'Respond' },
      { action: 'snooze', title: 'Snooze 5m' }
    ]
  };

  // Also send message to any open clients with the question
  event.waitUntil(
    Promise.all([
      self.registration.showNotification(data.title, options),
      clients.matchAll({ type: 'window' }).then((clientList) => {
        for (const client of clientList) {
          client.postMessage({
            type: 'QUESTION_RECEIVED',
            question: data.question
          });
        }
      })
    ])
  );
});

// Notification click event
self.addEventListener('notificationclick', (event) => {
  console.log('[SW] Notification clicked:', event.action);

  event.notification.close();

  if (event.action === 'snooze') {
    // Handle snooze - send to server
    const questionId = event.notification.data?.questionId;
    if (questionId) {
      event.waitUntil(
        fetch('/api/snooze', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ questionId, minutes: 5 })
        })
      );
    }
    return;
  }

  // Open or focus the app
  const urlToOpen = event.notification.data?.url || '/';
  const questionData = event.notification.data?.question;

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        // Check if app is already open
        for (const client of clientList) {
          if (client.url.includes(self.location.origin)) {
            // Send full question data to existing client
            client.postMessage({
              type: 'QUESTION_RECEIVED',
              questionId: event.notification.data?.questionId,
              question: questionData
            });
            return client.focus();
          }
        }
        // Open new window
        return clients.openWindow(urlToOpen);
      })
  );
});

// Message event - handle messages from main app
self.addEventListener('message', (event) => {
  console.log('[SW] Message received:', event.data);

  if (event.data?.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});
