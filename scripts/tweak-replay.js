/**
 * Tweak Replay Client
 *
 * Include this script in your dev pages to enable automatic animation replay
 * when adjusting values via the Consult User MCP tweak pane.
 *
 * Usage:
 *   <script src="https://unpkg.com/consult-user-mcp/tweak-replay.js"></script>
 *
 * Or copy this file to your project and include it locally.
 */
(function() {
  const WS_PORT = 19876;
  let ws = null;
  let reconnectTimer = null;

  function connect() {
    if (ws && ws.readyState === WebSocket.OPEN) return;

    try {
      ws = new WebSocket(`ws://localhost:${WS_PORT}`);

      ws.onopen = () => {
        console.log('[TweakReplay] Connected to Consult User MCP');
        if (reconnectTimer) {
          clearInterval(reconnectTimer);
          reconnectTimer = null;
        }
      };

      ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          if (data.type === 'replay') {
            replayAnimations();
          }
        } catch (e) {
          // Ignore parse errors
        }
      };

      ws.onclose = () => {
        ws = null;
        scheduleReconnect();
      };

      ws.onerror = () => {
        ws?.close();
      };
    } catch (e) {
      scheduleReconnect();
    }
  }

  function scheduleReconnect() {
    if (!reconnectTimer) {
      reconnectTimer = setInterval(connect, 3000);
    }
  }

  function replayAnimations() {
    // Find all elements with CSS animations and restart them
    document.querySelectorAll('*').forEach(el => {
      const style = getComputedStyle(el);
      if (style.animationName && style.animationName !== 'none') {
        // Store current animation
        const animation = el.style.animation;
        // Remove animation
        el.style.animation = 'none';
        // Force reflow
        void el.offsetHeight;
        // Restore animation
        el.style.animation = animation || '';
      }
    });
    console.log('[TweakReplay] Animations replayed');
  }

  // Expose for manual triggering
  window.__tweakReplay = replayAnimations;

  // Start connection
  if (typeof window !== 'undefined') {
    connect();
  }
})();
