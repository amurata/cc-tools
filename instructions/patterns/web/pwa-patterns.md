# Progressive Web App (PWA) Patterns

Modern patterns for building Progressive Web Applications.

## Service Worker

### Basic Service Worker Setup
```javascript
// service-worker.js
const CACHE_NAME = 'app-v1';
const urlsToCache = [
  '/',
  '/styles/main.css',
  '/scripts/app.js',
  '/offline.html'
];

// Install event - cache resources
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(urlsToCache))
      .then(() => self.skipWaiting())
  );
});

// Activate event - clean old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME)
          .map((name) => caches.delete(name))
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch event - serve from cache
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request)
      .then((response) => response || fetch(event.request))
      .catch(() => caches.match('/offline.html'))
  );
});
```

### Advanced Caching Strategies
```javascript
// Network first, cache fallback
async function networkFirst(request) {
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    const cachedResponse = await caches.match(request);
    return cachedResponse || caches.match('/offline.html');
  }
}

// Cache first, network fallback
async function cacheFirst(request) {
  const cachedResponse = await caches.match(request);
  if (cachedResponse) {
    return cachedResponse;
  }
  
  try {
    const networkResponse = await fetch(request);
    const cache = await caches.open(CACHE_NAME);
    cache.put(request, networkResponse.clone());
    return networkResponse;
  } catch (error) {
    return caches.match('/offline.html');
  }
}

// Stale while revalidate
async function staleWhileRevalidate(request) {
  const cache = await caches.open(CACHE_NAME);
  const cachedResponse = await cache.match(request);
  
  const fetchPromise = fetch(request).then((networkResponse) => {
    cache.put(request, networkResponse.clone());
    return networkResponse;
  });
  
  return cachedResponse || fetchPromise;
}
```

## Web App Manifest

### manifest.json
```json
{
  "name": "My Progressive Web App",
  "short_name": "MyPWA",
  "description": "A progressive web application",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#000000",
  "orientation": "portrait-primary",
  "icons": [
    {
      "src": "/icons/icon-72x72.png",
      "sizes": "72x72",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/icons/icon-96x96.png",
      "sizes": "96x96",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/icons/icon-128x128.png",
      "sizes": "128x128",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/icons/icon-144x144.png",
      "sizes": "144x144",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable any"
    }
  ],
  "shortcuts": [
    {
      "name": "Start Chat",
      "url": "/chat",
      "icons": [{ "src": "/icons/chat.png", "sizes": "96x96" }]
    }
  ],
  "categories": ["productivity", "utilities"]
}
```

## Offline Functionality

### IndexedDB for Offline Storage
```javascript
class OfflineStore {
  constructor(dbName = 'PWADatabase', version = 1) {
    this.dbName = dbName;
    this.version = version;
    this.db = null;
  }
  
  async init() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, this.version);
      
      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        this.db = request.result;
        resolve(this.db);
      };
      
      request.onupgradeneeded = (event) => {
        const db = event.target.result;
        
        // Create object stores
        if (!db.objectStoreNames.contains('items')) {
          const itemStore = db.createObjectStore('items', { 
            keyPath: 'id', 
            autoIncrement: true 
          });
          itemStore.createIndex('timestamp', 'timestamp', { unique: false });
          itemStore.createIndex('synced', 'synced', { unique: false });
        }
      };
    });
  }
  
  async addItem(data) {
    const transaction = this.db.transaction(['items'], 'readwrite');
    const store = transaction.objectStore('items');
    
    const item = {
      ...data,
      timestamp: Date.now(),
      synced: false
    };
    
    return new Promise((resolve, reject) => {
      const request = store.add(item);
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }
  
  async getUnsyncedItems() {
    const transaction = this.db.transaction(['items'], 'readonly');
    const store = transaction.objectStore('items');
    const index = store.index('synced');
    
    return new Promise((resolve, reject) => {
      const request = index.getAll(false);
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }
}
```

## Background Sync

### Background Sync API
```javascript
// Register background sync
async function registerBackgroundSync() {
  const registration = await navigator.serviceWorker.ready;
  
  try {
    await registration.sync.register('sync-data');
    console.log('Background sync registered');
  } catch (error) {
    console.log('Background sync failed:', error);
  }
}

// In service worker
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-data') {
    event.waitUntil(syncData());
  }
});

async function syncData() {
  const db = await openDatabase();
  const unsyncedData = await getUnsyncedData(db);
  
  for (const item of unsyncedData) {
    try {
      const response = await fetch('/api/sync', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(item)
      });
      
      if (response.ok) {
        await markAsSynced(db, item.id);
      }
    } catch (error) {
      console.error('Sync failed for item:', item.id);
    }
  }
}
```

## Push Notifications

### Push Notification Implementation
```javascript
// Request permission and subscribe
async function subscribeToPushNotifications() {
  // Check support
  if (!('PushManager' in window)) {
    console.log('Push notifications not supported');
    return;
  }
  
  // Request permission
  const permission = await Notification.requestPermission();
  if (permission !== 'granted') {
    console.log('Permission denied');
    return;
  }
  
  // Get service worker registration
  const registration = await navigator.serviceWorker.ready;
  
  // Subscribe to push
  const subscription = await registration.pushManager.subscribe({
    userVisibleOnly: true,
    applicationServerKey: urlBase64ToUint8Array(PUBLIC_VAPID_KEY)
  });
  
  // Send subscription to server
  await fetch('/api/push/subscribe', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(subscription)
  });
}

// In service worker - handle push events
self.addEventListener('push', (event) => {
  const data = event.data ? event.data.json() : {};
  
  const options = {
    body: data.body || 'New notification',
    icon: '/icons/icon-192x192.png',
    badge: '/icons/badge-72x72.png',
    vibrate: [100, 50, 100],
    data: {
      dateOfArrival: Date.now(),
      primaryKey: data.id
    },
    actions: [
      { action: 'explore', title: 'Open' },
      { action: 'close', title: 'Close' }
    ]
  };
  
  event.waitUntil(
    self.registration.showNotification(data.title || 'PWA Notification', options)
  );
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  
  if (event.action === 'explore') {
    event.waitUntil(
      clients.openWindow('/notifications/' + event.notification.data.primaryKey)
    );
  }
});
```

## App Shell Architecture

### App Shell Pattern
```javascript
// app-shell.js
class AppShell {
  constructor() {
    this.container = document.getElementById('app');
    this.loadingIndicator = document.getElementById('loading');
  }
  
  async init() {
    // Register service worker
    if ('serviceWorker' in navigator) {
      await navigator.serviceWorker.register('/service-worker.js');
    }
    
    // Load critical CSS
    this.loadCriticalCSS();
    
    // Initialize router
    this.initRouter();
    
    // Load initial content
    await this.loadContent(window.location.pathname);
  }
  
  loadCriticalCSS() {
    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = '/styles/critical.css';
    document.head.appendChild(link);
  }
  
  initRouter() {
    window.addEventListener('popstate', (event) => {
      this.loadContent(window.location.pathname);
    });
    
    document.addEventListener('click', (event) => {
      if (event.target.tagName === 'A' && event.target.href.startsWith(window.location.origin)) {
        event.preventDefault();
        const path = new URL(event.target.href).pathname;
        history.pushState(null, '', path);
        this.loadContent(path);
      }
    });
  }
  
  async loadContent(path) {
    this.showLoading();
    
    try {
      const response = await fetch(`/api/content${path}`);
      const content = await response.text();
      this.container.innerHTML = content;
    } catch (error) {
      this.container.innerHTML = '<p>Error loading content</p>';
    } finally {
      this.hideLoading();
    }
  }
  
  showLoading() {
    this.loadingIndicator.style.display = 'block';
  }
  
  hideLoading() {
    this.loadingIndicator.style.display = 'none';
  }
}
```

## Performance Optimization

### Web Vitals Monitoring
```javascript
// Monitor Core Web Vitals
import { getCLS, getFID, getLCP, getFCP, getTTFB } from 'web-vitals';

function sendToAnalytics(metric) {
  // Send to analytics endpoint
  navigator.sendBeacon('/analytics', JSON.stringify({
    name: metric.name,
    value: metric.value,
    id: metric.id,
    navigationType: metric.navigationType
  }));
}

getCLS(sendToAnalytics);
getFID(sendToAnalytics);
getLCP(sendToAnalytics);
getFCP(sendToAnalytics);
getTTFB(sendToAnalytics);

// Resource hints
const preconnectLinks = [
  'https://fonts.googleapis.com',
  'https://api.example.com'
];

preconnectLinks.forEach(href => {
  const link = document.createElement('link');
  link.rel = 'preconnect';
  link.href = href;
  document.head.appendChild(link);
});
```

## Installability

### Install Prompt
```javascript
let deferredPrompt;

window.addEventListener('beforeinstallprompt', (event) => {
  // Prevent default browser prompt
  event.preventDefault();
  
  // Store event for later use
  deferredPrompt = event;
  
  // Show custom install button
  showInstallButton();
});

function showInstallButton() {
  const installButton = document.getElementById('install-button');
  installButton.style.display = 'block';
  
  installButton.addEventListener('click', async () => {
    if (!deferredPrompt) return;
    
    // Show browser install prompt
    deferredPrompt.prompt();
    
    // Wait for user choice
    const { outcome } = await deferredPrompt.userChoice;
    
    // Log analytics
    console.log(`User ${outcome} the install prompt`);
    
    // Clear deferred prompt
    deferredPrompt = null;
    
    // Hide button
    installButton.style.display = 'none';
  });
}

// Detect if app is installed
window.addEventListener('appinstalled', () => {
  console.log('PWA was installed');
  
  // Hide install prompts
  hideInstallPrompts();
  
  // Track installation
  trackEvent('pwa_installed');
});

// Check display mode
function isPWAInstalled() {
  return window.matchMedia('(display-mode: standalone)').matches ||
         window.navigator.standalone ||
         document.referrer.includes('android-app://');
}
```

## Checklist
- [ ] Configure service worker
- [ ] Create web app manifest
- [ ] Implement offline storage
- [ ] Add push notifications
- [ ] Set up background sync
- [ ] Implement app shell
- [ ] Optimize performance
- [ ] Add install prompt
- [ ] Test on multiple devices