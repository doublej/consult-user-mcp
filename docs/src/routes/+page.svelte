<script lang="ts">
  import { base } from "$app/paths";
  import { onMount } from "svelte";
  import { dev } from "$app/environment";
  import SiteNav from "$lib/components/SiteNav.svelte";
  import PerspectiveDialog from "$lib/components/PerspectiveDialog.svelte";
  import { browser } from "$app/environment";

  let copied = $state(false);
  let selectedPlatform = $state<"macos" | "windows">("macos");

  const clients = [
    { file: "claude.svg", name: "Claude", hasInstaller: true },
    { file: "codex.svg", name: "Codex", hasInstaller: true },
    { file: "gemini.svg", name: "Gemini", hasInstaller: true },
    { file: "jetbrains.svg", name: "JetBrains" },
    { file: "antigravity.svg", name: "Antigravity", hasInstaller: true },
    { file: "vscode.svg", name: "VS Code" },
    { file: "cursor.svg", name: "Cursor" },
    { file: "windsurf.svg", name: "Windsurf" },
    { file: "zed.svg", name: "Zed" },
    { file: "cline.svg", name: "Cline" },
    { file: "continue.svg", name: "Continue" },
    { file: "goose.svg", name: "Goose" },
    { file: "sourcegraph.svg", name: "Sourcegraph" },
    { file: "amazon-q.svg", name: "Amazon Q" },
  ];
  let cycleIndex = $state(0);
  let hovered = $state(-1);
  const activeIndex = $derived(hovered >= 0 ? hovered : cycleIndex);
  const activeClient = $derived(clients[activeIndex]);

  const phrases = [
    { subject: "agent", accent: "needs a human" },
    { subject: "human", accent: "doesn't feel like typing" },
    { subject: "agent", accent: "needs to understand layouts" },
    { subject: "code", accent: "needs a gut check" },
    { subject: "agent", accent: "can't pick alone" },
    { subject: "agent", accent: "needs your taste" },
    { subject: "human", accent: "wants to snooze it" },
    { subject: "agent", accent: "wants your approval" },
    { subject: "deploy", accent: "needs a green light" },
    { subject: "agent", accent: "found three options" },
    { subject: "human", accent: "is grabbing coffee" },
    { subject: "agent", accent: "needs a tiebreaker" },
    { subject: "refactor", accent: "needs a sanity check" },
    { subject: "agent", accent: "isn't sure about the name" },
    { subject: "pipeline", accent: "hits a decision point" },
    { subject: "human", accent: "prefers buttons over prompts" },
    { subject: "agent", accent: "needs a password" },
    { subject: "agent", accent: 'goes "hmm" for too long' },
    { subject: "agent", accent: "wants to mass-delete files" },
    { subject: "agent", accent: "needs emotional support" },
  ];
  let phraseIndex = $state(0);

  const macosInstallCommand =
    "curl -sSL https://raw.githubusercontent.com/doublej/consult-user-mcp/main/install.sh | bash";

  function copyInstall() {
    navigator.clipboard.writeText(macosInstallCommand);
    copied = true;
    setTimeout(() => (copied = false), 2000);
  }

  // Cycle through client logos
  onMount(() => {
    const id = setInterval(() => {
      cycleIndex = (cycleIndex + 1) % clients.length;
    }, 2000);
    return () => clearInterval(id);
  });

  // Cycle through hero phrases (start after page animation settles)
  onMount(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    let intervalId: ReturnType<typeof setInterval>;
    const timeoutId = setTimeout(() => {
      intervalId = setInterval(() => {
        phraseIndex = (phraseIndex + 1) % phrases.length;
      }, 4000);
    }, 3000);
    return () => {
      clearTimeout(timeoutId);
      clearInterval(intervalId);
    };
  });

  // Tweak replay: connect to tray app WebSocket in dev mode
  onMount(() => {
    if (!dev) return;

    let ws: WebSocket | null = null;
    let reconnectTimer: ReturnType<typeof setInterval> | null = null;

    function connect() {
      if (ws?.readyState === WebSocket.OPEN) return;
      try {
        ws = new WebSocket("ws://localhost:19876");
        ws.onopen = () => {
          console.log("[TweakReplay] Connected");
          if (reconnectTimer) {
            clearInterval(reconnectTimer);
            reconnectTimer = null;
          }
        };
        ws.onmessage = (e) => {
          const data = JSON.parse(e.data);
          if (data.type === "replay") replayAnimations();
        };
        ws.onclose = () => {
          ws = null;
          scheduleReconnect();
        };
        ws.onerror = () => ws?.close();
      } catch {
        scheduleReconnect();
      }
    }

    function scheduleReconnect() {
      if (!reconnectTimer) reconnectTimer = setInterval(connect, 3000);
    }

    function replayAnimations() {
      document.querySelectorAll("*").forEach((el) => {
        const style = getComputedStyle(el);
        if (style.animationName && style.animationName !== "none") {
          const anim = (el as HTMLElement).style.animation;
          (el as HTMLElement).style.animation = "none";
          void (el as HTMLElement).offsetHeight;
          (el as HTMLElement).style.animation = anim || "";
        }
      });
      console.log("[TweakReplay] Animations replayed");
    }

    connect();
    return () => {
      ws?.close();
      if (reconnectTimer) clearInterval(reconnectTimer);
    };
  });
</script>

<svelte:head>
  <title>consult-user-mcp</title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link
    rel="preconnect"
    href="https://fonts.gstatic.com"
    crossorigin="anonymous"
  />
  <link
    href="https://fonts.googleapis.com/css2?family=Instrument+Sans:wght@400;500;600&family=DM+Mono:wght@400;500&display=swap"
    rel="stylesheet"
  />
</svelte:head>

<main>
  <div class="animate-in">
    <SiteNav />
  </div>

  <section class="hero-row">
    {#if browser}
      {#await import("$lib/components/FieldCanvas.svelte") then { default: FieldCanvas }}
        <FieldCanvas />
      {/await}
    {/if}
    <div class="hero">
      <p class="hero-label animate-in">Human Consultation Interface</p>
      <h1 class="animate-in" style="animation-delay: 100ms;">
        When your {#key phraseIndex}<span class="hero-cycling"
            ><span class="hero-cycle-word">{phrases[phraseIndex].subject}</span>
            <span class="accent hero-cycle-accent"
              >{phrases[phraseIndex].accent}</span
            ></span
          >{/key}
      </h1>
      <p class="lead animate-in" style="animation-delay: 200ms;">
        Your AI agent pops up a native dialog when it needs input — pick an
        option, type an answer, or snooze it for later. No window switching, no
        terminal babysitting.
      </p>
      <div class="client-logos animate-in" style="animation-delay: 350ms;">
        <span class="client-logos-label"
          >Works with
          {#key activeIndex}<span class="active-name"
              >{clients[activeIndex].name}</span
            >{/key}{#if activeClient.hasInstaller}&nbsp;and autoconfigures{/if}</span
        >
        <!-- svelte-ignore a11y_no_static_element_interactions -->
        <div
          class="client-logos-row"
          onmouseleave={() => {
            hovered = -1;
          }}
        >
          {#each clients as client, i}
            <!-- svelte-ignore a11y_no_static_element_interactions -->
            <div
              class="logo-item"
              class:active={activeIndex === i}
              class:installer={client.hasInstaller}
              onmouseenter={() => {
                hovered = i;
              }}
            >
              <img src="{base}/logos/{client.file}" alt={client.name} />
            </div>
          {/each}
        </div>
      </div>
      <div class="install-block animate-in" style="animation-delay: 400ms;">
        <div class="code-line">
          <code>{macosInstallCommand}</code>
          <button
            onclick={copyInstall}
            class="copy-btn"
            aria-label="Copy install command"
          >
            {copied ? "Copied" : "Copy"}
          </button>
        </div>
        <p class="install-note">
          macOS one-liner · <a href="#install">Windows &amp; manual install</a>
        </p>
      </div>
    </div>
    <aside class="hero-visual-sidebar">
      <PerspectiveDialog />
    </aside>
    <div class="platform-badges animate-in" style="animation-delay: 450ms;">
      <span class="platform-badge">
        <svg
          viewBox="0 0 384 512"
          width="14"
          height="14"
          fill="currentColor"
          aria-hidden="true"
        >
          <path
            d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5c0 26.2 4.8 53.3 14.4 81.2 12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zm-56.6-164.2c27.3-32.4 24.8-62.1 24-72.5-24.1 1.4-52 16.4-67.9 34.9-17.5 19.8-27.8 44.3-25.6 71.9 26.1 2 49.9-11.4 69.5-34.3z"
          />
        </svg>
        macOS
      </span>
      <span class="platform-badge">
        <svg
          viewBox="0 0 448 512"
          width="13"
          height="13"
          fill="currentColor"
          aria-hidden="true"
        >
          <path
            d="M0 93.7l183.6-25.3v177.4H0V93.7zm0 324.6l183.6 25.3V268.4H0v149.9zm203.8 28L448 480V268.4H203.8v177.9zm0-380.6v180.1H448V32L203.8 65.7z"
          />
        </svg>
        Windows
      </span>
    </div>
  </section>

  <section
    class="section animate-in"
    style="animation-delay: 600ms;"
    id="install"
  >
    <h2>Installation</h2>
    <p class="section-desc">
      Install the server and tray app for your platform.
    </p>

    <div class="platform-tabs">
      <button
        class="platform-tab"
        class:active={selectedPlatform === "macos"}
        onclick={() => (selectedPlatform = "macos")}
      >
        <svg
          viewBox="0 0 384 512"
          width="14"
          height="14"
          fill="currentColor"
          aria-hidden="true"
          ><path
            d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5c0 26.2 4.8 53.3 14.4 81.2 12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zm-56.6-164.2c27.3-32.4 24.8-62.1 24-72.5-24.1 1.4-52 16.4-67.9 34.9-17.5 19.8-27.8 44.3-25.6 71.9 26.1 2 49.9-11.4 69.5-34.3z"
          /></svg
        >
        macOS
      </button>
      <button
        class="platform-tab"
        class:active={selectedPlatform === "windows"}
        onclick={() => (selectedPlatform = "windows")}
      >
        <svg
          viewBox="0 0 448 512"
          width="13"
          height="13"
          fill="currentColor"
          aria-hidden="true"
          ><path
            d="M0 93.7l183.6-25.3v177.4H0V93.7zm0 324.6l183.6 25.3V268.4H0v149.9zm203.8 28L448 480V268.4H203.8v177.9zm0-380.6v180.1H448V32L203.8 65.7z"
          /></svg
        >
        Windows
      </button>
    </div>

    {#if selectedPlatform === "macos"}
      <div class="install-block standalone">
        <div class="code-line">
          <code>{macosInstallCommand}</code>
          <button
            onclick={copyInstall}
            class="copy-btn"
            aria-label="Copy install command"
          >
            {copied ? "Copied" : "Copy"}
          </button>
        </div>
      </div>

      <div class="install-steps">
        <h3>Setup steps</h3>
        <ol class="steps-list">
          <li>
            <span class="step-num">1</span>
            <div class="step-content">
              <strong>Run the install command</strong>
              <p>
                Downloads the app from GitHub and moves it to <code
                  >/Applications</code
                >
              </p>
            </div>
          </li>
          <li>
            <span class="step-num">2</span>
            <div class="step-content">
              <strong>Launch the app</strong>
              <p>
                Open "Consult User MCP" from Applications. A menu bar icon will
                appear.
              </p>
            </div>
          </li>
          <li>
            <span class="step-num">3</span>
            <div class="step-content">
              <strong>Run the install wizard</strong>
              <p>
                Click the menu bar icon and select "Install Guide". Follow the
                steps to configure Claude Code or Claude Desktop.
              </p>
            </div>
          </li>
          <li>
            <span class="step-num">4</span>
            <div class="step-content">
              <strong>Restart your MCP client</strong>
              <p>
                Quit and reopen Claude Code (or Claude Desktop) to load the MCP
                server
              </p>
            </div>
          </li>
          <li>
            <span class="step-num">5</span>
            <div class="step-content">
              <strong>Test it</strong>
              <p>
                Ask Claude a question that requires your input—a dialog should
                appear
              </p>
            </div>
          </li>
        </ol>
      </div>
    {:else}
      <div class="install-steps">
        <h3>Setup steps</h3>
        <ol class="steps-list">
          <li>
            <span class="step-num">1</span>
            <div class="step-content">
              <strong>Download the installer</strong>
              <p>
                Get the Windows installer from the <a
                  href="https://github.com/doublej/consult-user-mcp/releases"
                  target="_blank"
                  rel="noopener">GitHub releases page</a
                >
                (the release tagged <code>windows/v...</code>)
              </p>
            </div>
          </li>
          <li>
            <span class="step-num">2</span>
            <div class="step-content">
              <strong>Run the installer</strong>
              <p>
                The installer automatically configures the Claude Code MCP
                server. A system tray icon will appear when complete.
              </p>
            </div>
          </li>
          <li>
            <span class="step-num">3</span>
            <div class="step-content">
              <strong>Launch from Start Menu</strong>
              <p>
                Open "Consult User MCP" from the Start Menu. The app runs in the
                system tray.
              </p>
            </div>
          </li>
          <li>
            <span class="step-num">4</span>
            <div class="step-content">
              <strong>Restart your MCP client</strong>
              <p>
                Quit and reopen Claude Code (or Claude Desktop) to load the MCP
                server
              </p>
            </div>
          </li>
          <li>
            <span class="step-num">5</span>
            <div class="step-content">
              <strong>Test it</strong>
              <p>
                Ask Claude a question that requires your input—a dialog should
                appear
              </p>
            </div>
          </li>
        </ol>
      </div>
    {/if}

    <p class="manual-note">
      For manual installation or other MCP clients, see the <a
        href="https://github.com/doublej/consult-user-mcp#readme"
        target="_blank"
        rel="noopener">README</a
      >.
    </p>
    <div class="unsigned-note">
      <h3>Unsigned software</h3>
      <p>
        <strong>macOS:</strong> This app is not signed with an Apple Developer
        certificate. On first launch, macOS will show a warning. Right-click the
        app and select "Open", then click "Open" in the dialog.
        <strong>Windows:</strong> SmartScreen may warn about an unidentified publisher.
        Click "More info" then "Run anyway". You only need to do this once.
      </p>
    </div>
  </section>

  <footer class="animate-in" style="animation-delay: 1200ms;">
    <p>
      Works with <a
        href="https://claude.ai/claude-code"
        target="_blank"
        rel="noopener">Claude Code</a
      >, Claude Desktop, Cursor, and any MCP-compatible client
    </p>
    <p>
      <a
        href="https://github.com/doublej/consult-user-mcp"
        target="_blank"
        rel="noopener">GitHub</a
      >
    </p>
  </footer>
</main>

<style>
  /* Entrance animation keyframes */
  @keyframes fadeSlideUp {
    from {
      opacity: 0;
      transform: translateY(20px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  .animate-in {
    animation: fadeSlideUp 0.6s cubic-bezier(0.23, 1, 0.32, 1) backwards;
  }

  :global(*) {
    box-sizing: border-box;
  }

  :global(body) {
    margin: 0;
    font-family:
      "Instrument Sans",
      -apple-system,
      BlinkMacSystemFont,
      system-ui,
      sans-serif;
    background: radial-gradient(circle at 20% -10%, #eef1fb 0%, transparent 45%),
      radial-gradient(circle at 80% -30%, #eceff8 0%, transparent 40%), #f7f8fc;
    color: #2f3446;
    min-height: 100vh;
    line-height: 1.6;
    -webkit-font-smoothing: antialiased;
  }

  main {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 24px 72px;
  }

  /* Hero row - two column layout */
  .hero-row {
    position: relative;
    overflow: visible;
    isolation: isolate;
    display: grid;
    grid-template-columns: minmax(0, 1.12fr) minmax(360px, 0.88fr);
    gap: 24px;
    padding-bottom: 56px;
    align-items: center;
    max-width: 100%;
    background: linear-gradient(165deg, #0a0a0f, #131320, #0f0f1a);
    box-shadow: 0 22px 50px rgba(16, 18, 28, 0.22);
    border-radius: 20px;
    padding: 56px 56px;
  }

  /* Hero */
  .hero {
    padding: 0;
    min-width: 0;
    max-width: 620px;
    position: relative;
    z-index: 2;
  }

  /* Hero visual sidebar */
  .hero-visual-sidebar {
    min-width: 0;
    overflow: visible;
    display: flex;
    justify-content: flex-end;
    align-items: center;
    position: relative;
    z-index: 2;
  }

  /* Hero label */
  .hero-label {
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: #5a8cff;
    margin: 0 0 26px;
  }

  h1 {
    font-size: 3rem;
    font-weight: 600;
    color: #f0f0f5;
    margin: 42px 0 22px;
    letter-spacing: -0.035em;
    line-height: 1.1;
  }

  /* Hero phrase cycling */
  @keyframes phraseIn {
    from {
      opacity: 0;
      transform: translateY(8px);
      filter: blur(6px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
      filter: blur(0);
    }
  }

  .hero-cycling {
    display: contents;
  }

  .hero-cycle-word,
  .hero-cycle-accent {
    display: inline-block;
    padding-block: 0.15em;
    margin-block: -0.15em;
  }

  .hero-cycle-word {
    animation: phraseIn 0.40s cubic-bezier(0.23, 1, 0.32, 1);
  }

  .hero-cycle-accent {
    white-space: nowrap;
    animation: phraseIn 0.5s cubic-bezier(0.23, 1, 0.32, 1) 0.36s backwards;
  }

  @media (prefers-reduced-motion: reduce) {
    .hero-cycle-word,
    .hero-cycle-accent {
      animation: none;
    }
  }

  /* Gradient text accent */
  .accent {
    background: linear-gradient(135deg, #5a8cff, #7aa0ff);
    -webkit-background-clip: text;
    background-clip: text;
    -webkit-text-fill-color: transparent;
  }

  .lead {
    font-size: 1.1rem;
    color: #9a9aa5;
    max-width: 520px;
    margin: 0 0 64px;
  }

  /* Platform badges */
  .platform-badges {
    display: flex;
    gap: 10px;
    justify-content: flex-end;
    position: absolute;
    right: 40px;
    bottom: 40px;
    margin: 0;
    opacity: 0.68;
    z-index: 3;
  }

  .platform-badge {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    font-size: 0.78rem;
    font-weight: 500;
    color: rgba(255, 255, 255, 0.58);
    padding: 4px 10px;
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 100px;
    background: rgba(255, 255, 255, 0.02);
  }

  /* Client logos strip */
  @keyframes nameIn {
    from {
      opacity: 0;
      transform: translateY(4px);
      filter: blur(4px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
      filter: blur(0);
    }
  }

  .client-logos {
    margin: 0 0 60px;
  }

  .client-logos-label {
    font-size: 0.85rem;
    font-weight: 500;
    color: rgba(255, 255, 255, 0.35);
    display: block;
    margin-bottom: 14px;
  }

  .active-name {
    color: rgba(255, 255, 255, 0.55);
    font-weight: 500;
    display: inline-block;
    animation: nameIn 0.35s cubic-bezier(0.23, 1, 0.32, 1);
  }

  .client-logos-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .logo-item {
    position: relative;
    cursor: default;
  }

  .logo-item.installer::after {
    content: "";
    position: absolute;
    top: -4px;
    right: -4px;
    width: 5px;
    height: 5px;
    border-radius: 999px;
    background: #7aa0ff;
    box-shadow: 0 0 0 2px rgba(13, 13, 18, 0.95);
    opacity: 0.5;
  }

  .logo-item img {
    height: 20px;
    width: auto;
    opacity: 0.2;
    filter: brightness(0) invert(1);
    transition: opacity 0.4s;
  }

  .logo-item.active img {
    opacity: 0.55;
  }

  /* Platform tabs */
  .platform-tabs {
    display: flex;
    gap: 0;
    margin-bottom: 0;
    border-bottom: 1px solid #d7dbe8;
  }

  .platform-tab {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 10px 20px;
    background: none;
    border: 1px solid transparent;
    border-bottom: none;
    cursor: pointer;
    font-size: 0.9rem;
    font-weight: 500;
    font-family: "Instrument Sans", sans-serif;
    color: #7b849f;
    transition:
      color 0.15s,
      background 0.15s;
    margin-bottom: -1px;
  }

  .platform-tab:hover {
    color: #272d40;
  }

  .platform-tab.active {
    color: #1f2434;
    background: rgba(255, 255, 255, 0.8);
    border-color: #d7dbe8;
    border-bottom-color: #f7f8fc;
  }

  /* Install block */
  .install-block {
    max-width: 100%;
  }

  .hero .install-block {
    margin-top: 18px;
  }

  .install-block.standalone {
    margin: 32px 0;
  }

  .code-line {
    display: flex;
    align-items: center;
    gap: 12px;
    background: #fff;
    border: 1px solid #d7dce9;
    border-radius: 12px;
    padding: 14px 16px;
    overflow: hidden;
  }

  /* Hero-scoped dark overrides for install block */
  .hero-row .code-line {
    background: rgba(255, 255, 255, 0.06);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 10px;
  }

  code {
    font-family: "DM Mono", "SF Mono", Monaco, monospace;
    font-size: 0.85rem;
    color: #2f3445;
    flex: 1;
    overflow-x: auto;
    white-space: nowrap;
    scrollbar-width: none;
  }

  code::-webkit-scrollbar {
    display: none;
  }

  .hero-row code {
    color: #c0c0c8;
  }

  .copy-btn {
    background: #242b3d;
    color: #fff;
    border: none;
    padding: 8px 16px;
    cursor: pointer;
    font-size: 0.8rem;
    font-weight: 500;
    font-family: "Instrument Sans", sans-serif;
    white-space: nowrap;
    transition:
      background 0.15s,
      box-shadow 0.15s;
    min-width: 70px;
    text-align: center;
  }

  .copy-btn:hover {
    background: #1d2333;
  }

  .hero-row .copy-btn {
    background: #5a8cff;
    border-radius: 4px;
    color: #fff;
  }

  .hero-row .copy-btn:hover {
    background: #4a7cef;
    box-shadow: 0 0 20px rgba(90, 140, 255, 0.3);
  }

  .install-note {
    font-size: 0.85rem;
    color: #727c98;
    margin: 12px 0 0;
  }

  .hero-row .install-note {
    font-size: 0.78rem;
    color: rgba(255, 255, 255, 0.3);
  }

  .install-note a {
    color: #3f4c71;
    text-decoration: underline;
    text-underline-offset: 2px;
  }

  .hero-row .install-note a {
    color: rgba(148, 160, 230, 0.72);
  }

  .install-note a:hover {
    color: #1f2740;
  }

  .hero-row .install-note a:hover {
    color: rgba(176, 188, 255, 0.84);
  }

  /* Sections */
  .section {
    padding: 64px 56px;
    border-top: 1px solid #dfe3ee;
  }

  #install {
    border-top: none;
  }

  h2 {
    font-size: 1.5rem;
    font-weight: 600;
    color: #21273a;
    margin: 0 0 8px;
    letter-spacing: -0.02em;
  }

  .section-desc {
    color: #66708b;
    margin: 0 0 32px;
    font-size: 0.95rem;
  }

  /* Manual note */
  .manual-note {
    font-size: 0.9rem;
    color: #66708b;
  }

  .manual-note a {
    color: #3f4c71;
    text-decoration: underline;
    text-underline-offset: 2px;
  }

  .manual-note a:hover {
    color: #1f2740;
  }

  /* Install steps */
  .install-steps {
    margin: 40px 0;
  }

  .install-steps h3 {
    font-size: 1rem;
    font-weight: 600;
    color: #252c40;
    margin: 32px 0 16px;
  }

  .install-steps h3:first-child {
    margin-top: 0;
  }

  .steps-list {
    list-style: none;
    padding: 0;
    margin: 0;
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  .steps-list li {
    display: flex;
    gap: 16px;
    border-left: 2px solid #d6dbea;
    padding: 8px 0 8px 16px;
  }

  .step-num {
    width: 28px;
    height: 28px;
    background: #e8ebf4;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 0.85rem;
    font-weight: 600;
    color: #505b77;
    flex-shrink: 0;
  }

  .step-content {
    flex: 1;
    min-width: 0;
  }

  .step-content strong {
    display: block;
    color: #1f2639;
    font-size: 0.95rem;
    margin-bottom: 4px;
  }

  .step-content p {
    margin: 0;
    font-size: 0.85rem;
    color: #68718b;
    line-height: 1.5;
  }

  .step-content code {
    background: #eef1f8;
    padding: 2px 6px;
    font-size: 0.8rem;
    color: #3f4760;
  }

  /* Unsigned note */
  .unsigned-note {
    margin-top: 32px;
    padding: 20px;
    background: #f1f4fb;
    border-left: 2px solid #cfd6ea;
  }

  .unsigned-note h3 {
    font-size: 0.9rem;
    font-weight: 600;
    color: #252c40;
    margin: 0 0 8px;
  }

  .unsigned-note p {
    font-size: 0.85rem;
    color: #68718b;
    margin: 0;
    line-height: 1.5;
  }

  /* Footer */
  footer {
    padding: 50px 56px 0;
    border-top: 1px solid #dde2ec;
    text-align: center;
    font-size: 0.85rem;
  }

  footer p {
    margin: 6px 0;
    color: #727d98;
  }

  footer a {
    color: #3f4c71;
    text-decoration: none;
  }

  footer a:hover {
    color: #1f2740;
  }

  /* Responsive */
  @media (max-width: 1000px) {
    .hero-row {
      grid-template-columns: 1fr;
      gap: 40px;
      padding: 48px 32px;
    }

    .hero-visual-sidebar {
      margin: 0;
      order: -1;
    }

    .platform-badges {
      position: static;
      right: auto;
      bottom: auto;
      width: 100%;
      margin: 8px 0 0;
      justify-content: flex-end;
    }

    .section {
      padding: 60px 32px;
    }

    footer {
      padding: 48px 32px;
    }
  }

  @media (max-width: 700px) {
    .section {
      padding: 60px 20px;
    }

    footer {
      padding: 48px 20px;
    }

    .hero-row {
      padding: 36px 20px;
      border-radius: 16px;
    }

    h1 {
      font-size: 2rem;
    }

    .lead {
      font-size: 1rem;
    }

    .code-line {
      flex-direction: column;
      align-items: stretch;
      gap: 10px;
    }

    code {
      text-align: left;
    }

    .copy-btn {
      align-self: flex-start;
    }

    .platform-badges {
      margin-top: 18px;
      opacity: 0.72;
    }
  }
</style>
