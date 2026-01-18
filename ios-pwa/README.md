# Consult User PWA

A Progressive Web App companion for `consult-user-mcp` that works on iOS, Android, and any modern browser.

> **Security Warning**
>
> This iOS PWA has different security characteristics than the native macOS app:
>
> - **Cloud-dependent**: All questions and responses pass through a third-party server (Vercel). The native macOS app runs entirely locally.
> - **No end-to-end encryption**: Data is encrypted in transit (HTTPS) but decrypted on the server. Server operators can see your questions and responses.
> - **Session IDs are sensitive**: Anyone with your session ID can respond to questions intended for you. Treat it like a password.
> - **Push notification metadata**: Push services (Apple/Google) can see notification metadata, though not message content.
> - **In-memory storage**: By default, data is stored in server memory and lost on restart. Production deployments using KV stores persist data on third-party infrastructure.
>
> **Recommendations**:
> - Use the native macOS app when possible for sensitive workflows
> - Don't use this PWA for security-critical decisions (deployments to production, financial transactions, etc.)
> - Self-host on your own infrastructure if you need the iOS PWA for sensitive use cases
> - Rotate session IDs periodically

## Overview

This PWA receives push notifications when Claude needs user input, displays native-feeling dialog interfaces, and sends responses back to the MCP server. It's designed to work with Claude iOS app's remote MCP support.

## Architecture

```
Claude iOS App
    ↓ Remote MCP (HTTPS)
Vercel Edge Functions (this project)
    ├── Stores questions in memory/KV
    ├── Sends Web Push notifications
    ↓
PWA (installed on device)
    ← Receives push notification
    ← Displays dialog UI
    ← User responds
    ↓
Vercel responds to Claude
```

## Deployment to Vercel

### 1. Push to GitHub

This project is already in the `ios-pwa/` directory of the repo.

### 2. Create Vercel Project

1. Go to [vercel.com](https://vercel.com) and sign in
2. Click "Add New" → "Project"
3. Import your GitHub repository
4. Set the **Root Directory** to `ios-pwa`
5. Framework Preset: Other
6. Build Command: (leave empty or `echo 'No build'`)
7. Output Directory: `public`

### 3. Generate VAPID Keys

VAPID keys are required for Web Push notifications. Generate them:

```bash
npx web-push generate-vapid-keys
```

This will output something like:
```
Public Key: BNx...
Private Key: abc...
```

> **VAPID Key Security**
>
> - **Keep your private key secret**: Never commit it to version control or share it publicly. Anyone with your private key can send push notifications to your subscribers.
> - **Use environment variables**: Store keys in Vercel's encrypted environment variables, not in code.
> - **Rotate if compromised**: If your private key is exposed, generate new keys and redeploy. Existing subscribers will need to re-subscribe.
> - **One key pair per deployment**: Don't reuse VAPID keys across different projects or environments.

### 4. Configure Environment Variables

In Vercel Dashboard → Settings → Environment Variables, add:

| Variable | Value |
|----------|-------|
| `VAPID_PUBLIC_KEY` | Your public key from step 3 |
| `VAPID_PRIVATE_KEY` | Your private key from step 3 |
| `VAPID_SUBJECT` | `mailto:your-email@example.com` |

### 5. Deploy

Click "Deploy" and wait for the build to complete.

## Usage

### Installing the PWA on iOS

1. Open your deployed Vercel URL in Safari on iOS
2. You'll see install instructions
3. Tap the **Share** button (square with arrow)
4. Scroll down and tap **Add to Home Screen**
5. Tap **Add** in the top right
6. Open the app from your home screen
7. Tap **Enable Notifications** when prompted

### Connecting to Claude

Once the PWA is installed and notifications are enabled:

1. Note the **Session ID** shown in the app
2. Configure Claude to use the remote MCP server at:
   ```
   https://your-project.vercel.app/api/mcp
   ```
3. Pass the `sessionId` parameter with each MCP tool call

### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/mcp/ask` | POST | Ask a question (confirmation, choice, or text) |
| `/api/mcp/notify` | POST | Send a notification without response |
| `/api/mcp/tools` | GET | Get MCP tool definitions |
| `/api/vapid-public-key` | GET | Get VAPID public key for push subscription |
| `/api/subscribe` | POST | Register push subscription |
| `/api/questions` | GET | Poll for pending questions |
| `/api/answer` | POST | Submit an answer |
| `/api/snooze` | POST | Snooze a question |

### Example: Ask Confirmation

```bash
curl -X POST https://your-project.vercel.app/api/mcp/ask \
  -H "Content-Type: application/json" \
  -d '{
    "sessionId": "your-session-id",
    "type": "confirm",
    "title": "Confirm Action",
    "message": "Do you want to proceed with the deployment?"
  }'
```

The request will wait (long-poll) until the user responds in the PWA.

### Example: Ask Choice

```bash
curl -X POST https://your-project.vercel.app/api/mcp/ask \
  -H "Content-Type: application/json" \
  -d '{
    "sessionId": "your-session-id",
    "type": "choose",
    "title": "Select Environment",
    "message": "Which environment should we deploy to?",
    "choices": [
      {"label": "Development", "value": "dev"},
      {"label": "Staging", "value": "staging"},
      {"label": "Production", "value": "prod", "description": "Requires approval"}
    ]
  }'
```

## Development

### Local Testing

For local development, you'll need Vercel CLI:

```bash
npm install -g vercel
cd ios-pwa
vercel dev
```

Note: Push notifications won't work locally without HTTPS. Use Vercel's preview deployments for testing push.

### Project Structure

```
ios-pwa/
├── api/                    # Vercel serverless functions
│   ├── lib/
│   │   ├── store.ts       # In-memory question/subscription store
│   │   └── push.ts        # Web Push notification helper
│   ├── mcp/
│   │   ├── ask.ts         # Main MCP question endpoint
│   │   ├── notify.ts      # Notification endpoint
│   │   └── tools.ts       # MCP tool definitions
│   ├── answer.ts          # Answer submission
│   ├── questions.ts       # Question polling
│   ├── snooze.ts          # Snooze handler
│   ├── subscribe.ts       # Push subscription
│   └── vapid-public-key.ts
├── public/                 # Static PWA files
│   ├── index.html         # Main PWA page
│   ├── app.js             # PWA application logic
│   ├── sw.js              # Service worker
│   ├── styles.css         # Styles (Midnight theme)
│   ├── manifest.json      # PWA manifest
│   └── icons/             # App icons
├── package.json
├── vercel.json            # Vercel configuration
└── README.md
```

## Limitations

- **In-memory store**: Questions and subscriptions are stored in memory. For production, use Vercel KV or Upstash Redis.
- **Single instance**: The current implementation works best with single Vercel function instances. For high availability, add a proper database.
- **iOS 16.4+ required**: Web Push on iOS requires iOS 16.4 or later.
- **Home screen required**: Push notifications only work when the PWA is installed to the home screen.

## Production Recommendations

1. **Use Vercel KV**: Replace the in-memory store with Vercel KV for persistent storage
2. **Add authentication**: Implement proper session authentication
3. **Rate limiting**: Add rate limiting to prevent abuse
4. **Monitoring**: Add error tracking (Sentry, etc.)
5. **Generate proper icons**: Replace SVG icons with proper PNG icons for better iOS support

## License

MIT
