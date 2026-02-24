<script lang="ts">
	import { base } from '$app/paths';
	import { onMount } from 'svelte';
	import { dev } from '$app/environment';
	import DialogPreviews from '$lib/components/DialogPreviews.svelte';
	import InteractiveDemo from '$lib/components/InteractiveDemo.svelte';
	import PerspectiveDialog from '$lib/components/PerspectiveDialog.svelte';
	import QuestionHistory from '$lib/components/QuestionHistory.svelte';
	import FeaturePanels from '$lib/components/FeaturePanels.svelte';
	import ComparisonTable from '$lib/components/ComparisonTable.svelte';

	let copied = false;
	let selectedPlatform: 'macos' | 'windows' = 'macos';
	const macosInstallCommand = 'curl -sSL https://raw.githubusercontent.com/doublej/consult-user-mcp/main/install.sh | bash';

	function copyInstall() {
		navigator.clipboard.writeText(macosInstallCommand);
		copied = true;
		setTimeout(() => copied = false, 2000);
	}

	// Tweak replay: connect to tray app WebSocket in dev mode
	onMount(() => {
		if (!dev) return;

		let ws: WebSocket | null = null;
		let reconnectTimer: ReturnType<typeof setInterval> | null = null;

		function connect() {
			if (ws?.readyState === WebSocket.OPEN) return;
			try {
				ws = new WebSocket('ws://localhost:19876');
				ws.onopen = () => {
					console.log('[TweakReplay] Connected');
					if (reconnectTimer) { clearInterval(reconnectTimer); reconnectTimer = null; }
				};
				ws.onmessage = (e) => {
					const data = JSON.parse(e.data);
					if (data.type === 'replay') replayAnimations();
				};
				ws.onclose = () => { ws = null; scheduleReconnect(); };
				ws.onerror = () => ws?.close();
			} catch { scheduleReconnect(); }
		}

		function scheduleReconnect() {
			if (!reconnectTimer) reconnectTimer = setInterval(connect, 3000);
		}

		function replayAnimations() {
			document.querySelectorAll('*').forEach(el => {
				const style = getComputedStyle(el);
				if (style.animationName && style.animationName !== 'none') {
					const anim = (el as HTMLElement).style.animation;
					(el as HTMLElement).style.animation = 'none';
					void (el as HTMLElement).offsetHeight;
					(el as HTMLElement).style.animation = anim || '';
				}
			});
			console.log('[TweakReplay] Animations replayed');
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
	<link rel="preconnect" href="https://fonts.googleapis.com">
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous">
	<link href="https://fonts.googleapis.com/css2?family=Instrument+Sans:wght@400;500;600&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
</svelte:head>

<main>
	<header class="animate-in">
		<nav>
			<a href="{base}/" class="nav-logo">consult-user-mcp</a>
			<div class="nav-links">
				<a href="#demo" class="nav-link">Demo</a>
				<a href="#dialogs" class="nav-link">Dialogs</a>
				<a href="#compare" class="nav-link">Compare</a>
				<a href="#install" class="nav-link">Install</a>
				<a href="{base}/changelog" class="nav-link">Changelog</a>
				<a href="https://github.com/doublej/consult-user-mcp" class="nav-link" target="_blank" rel="noopener">GitHub</a>
			</div>
		</nav>
	</header>

	<section class="hero-row">
		<div class="hero">
			<h1 class="animate-in">Native dialogs for <span class="nowrap">MCP agents</span></h1>
			<p class="lead animate-in" style="animation-delay: 200ms;">
				An MCP server that surfaces agent checkpoints as native dialogs.
				Respond to questions, snooze for later, or redirect the agent without switching windows.
			</p>
			<div class="platform-badges animate-in" style="animation-delay: 300ms;">
				<span class="platform-badge">
					<svg viewBox="0 0 384 512" width="14" height="14" fill="currentColor" aria-hidden="true">
						<path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5c0 26.2 4.8 53.3 14.4 81.2 12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zm-56.6-164.2c27.3-32.4 24.8-62.1 24-72.5-24.1 1.4-52 16.4-67.9 34.9-17.5 19.8-27.8 44.3-25.6 71.9 26.1 2 49.9-11.4 69.5-34.3z"/>
					</svg>
					macOS
				</span>
				<span class="platform-badge">
					<svg viewBox="0 0 448 512" width="13" height="13" fill="currentColor" aria-hidden="true">
						<path d="M0 93.7l183.6-25.3v177.4H0V93.7zm0 324.6l183.6 25.3V268.4H0v149.9zm203.8 28L448 480V268.4H203.8v177.9zm0-380.6v180.1H448V32L203.8 65.7z"/>
					</svg>
					Windows
				</span>
			</div>
			<div class="install-block animate-in" style="animation-delay: 400ms;">
				<div class="code-line">
					<code>{macosInstallCommand}</code>
					<button onclick={copyInstall} class="copy-btn" aria-label="Copy install command">
						{copied ? 'Copied' : 'Copy'}
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
	</section>

	<section class="section demo-section animate-in" style="animation-delay: 600ms;" id="demo">
		<h2>See It In Action</h2>
		<p class="section-desc">Click through scenarios to see how agents guide users through decisions—from cooking to coding to troubleshooting.</p>
		<InteractiveDemo />
	</section>

	<section class="section dialog-types-section animate-in" style="animation-delay: 700ms;" id="dialogs">
		<h2>Dialog Types</h2>
		<p class="section-desc">Multiple tool types for different interaction patterns.</p>
		<DialogPreviews />
	</section>

	<section class="section animate-in" style="animation-delay: 800ms;">
		<h2>Snooze and Feedback</h2>
		<p class="section-desc">Every dialog includes options beyond simple yes/no responses.</p>
		<FeaturePanels />
	</section>

	<section class="section animate-in" style="animation-delay: 900ms;" id="compare">
		<h2>Comparison</h2>
		<p class="section-desc">How consult-user-mcp compares to other human-in-the-loop MCP servers.</p>
		<ComparisonTable />
	</section>

	<section class="section animate-in" style="animation-delay: 1000ms;">
		<h2>Real Questions from Development</h2>
		<p class="section-desc">28 actual questions from building this MCP server and other projects. Scroll to see how Claude Code uses these dialogs during real development.</p>
		<QuestionHistory />
	</section>

	<section class="section animate-in" style="animation-delay: 1100ms;" id="install">
		<h2>Installation</h2>
		<p class="section-desc">Install the server and tray app for your platform.</p>

		<div class="platform-tabs">
			<button class="platform-tab" class:active={selectedPlatform === 'macos'} onclick={() => selectedPlatform = 'macos'}>
				<svg viewBox="0 0 384 512" width="14" height="14" fill="currentColor" aria-hidden="true"><path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5c0 26.2 4.8 53.3 14.4 81.2 12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zm-56.6-164.2c27.3-32.4 24.8-62.1 24-72.5-24.1 1.4-52 16.4-67.9 34.9-17.5 19.8-27.8 44.3-25.6 71.9 26.1 2 49.9-11.4 69.5-34.3z"/></svg>
				macOS
			</button>
			<button class="platform-tab" class:active={selectedPlatform === 'windows'} onclick={() => selectedPlatform = 'windows'}>
				<svg viewBox="0 0 448 512" width="13" height="13" fill="currentColor" aria-hidden="true"><path d="M0 93.7l183.6-25.3v177.4H0V93.7zm0 324.6l183.6 25.3V268.4H0v149.9zm203.8 28L448 480V268.4H203.8v177.9zm0-380.6v180.1H448V32L203.8 65.7z"/></svg>
				Windows
			</button>
		</div>

		{#if selectedPlatform === 'macos'}
			<div class="install-block standalone">
				<div class="code-line">
					<code>{macosInstallCommand}</code>
					<button onclick={copyInstall} class="copy-btn" aria-label="Copy install command">
						{copied ? 'Copied' : 'Copy'}
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
							<p>Downloads the app from GitHub and moves it to <code>/Applications</code></p>
						</div>
					</li>
					<li>
						<span class="step-num">2</span>
						<div class="step-content">
							<strong>Launch the app</strong>
							<p>Open "Consult User MCP" from Applications. A menu bar icon will appear.</p>
						</div>
					</li>
					<li>
						<span class="step-num">3</span>
						<div class="step-content">
							<strong>Run the install wizard</strong>
							<p>Click the menu bar icon and select "Install Guide". Follow the steps to configure Claude Code or Claude Desktop.</p>
						</div>
					</li>
					<li>
						<span class="step-num">4</span>
						<div class="step-content">
							<strong>Restart your MCP client</strong>
							<p>Quit and reopen Claude Code (or Claude Desktop) to load the MCP server</p>
						</div>
					</li>
					<li>
						<span class="step-num">5</span>
						<div class="step-content">
							<strong>Test it</strong>
							<p>Ask Claude a question that requires your input—a dialog should appear</p>
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
							<p>Get the Windows installer from the <a href="https://github.com/doublej/consult-user-mcp/releases" target="_blank" rel="noopener">GitHub releases page</a> (the release tagged <code>windows/v...</code>)</p>
						</div>
					</li>
					<li>
						<span class="step-num">2</span>
						<div class="step-content">
							<strong>Run the installer</strong>
							<p>The installer automatically configures the Claude Code MCP server. A system tray icon will appear when complete.</p>
						</div>
					</li>
					<li>
						<span class="step-num">3</span>
						<div class="step-content">
							<strong>Launch from Start Menu</strong>
							<p>Open "Consult User MCP" from the Start Menu. The app runs in the system tray.</p>
						</div>
					</li>
					<li>
						<span class="step-num">4</span>
						<div class="step-content">
							<strong>Restart your MCP client</strong>
							<p>Quit and reopen Claude Code (or Claude Desktop) to load the MCP server</p>
						</div>
					</li>
					<li>
						<span class="step-num">5</span>
						<div class="step-content">
							<strong>Test it</strong>
							<p>Ask Claude a question that requires your input—a dialog should appear</p>
						</div>
					</li>
				</ol>
			</div>
		{/if}

		<p class="manual-note">
			For manual installation or other MCP clients, see the <a href="https://github.com/doublej/consult-user-mcp#readme" target="_blank" rel="noopener">README</a>.
		</p>
		<div class="unsigned-note">
			<h3>Unsigned software</h3>
			<p>
				<strong>macOS:</strong> This app is not signed with an Apple Developer certificate. On first launch, macOS will show a warning. Right-click the app and select "Open", then click "Open" in the dialog.
				<strong>Windows:</strong> SmartScreen may warn about an unidentified publisher. Click "More info" then "Run anyway".
				You only need to do this once.
			</p>
		</div>
	</section>

	<footer class="animate-in" style="animation-delay: 1200ms;">
		<p>Built for <a href="https://claude.ai/claude-code" target="_blank" rel="noopener">Claude Code</a> and MCP-compatible agents</p>
		<p><a href="https://github.com/doublej/consult-user-mcp" target="_blank" rel="noopener">GitHub</a></p>
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
		font-family: 'Instrument Sans', -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
		background: #fafafa;
		color: #404040;
		min-height: 100vh;
		line-height: 1.6;
		-webkit-font-smoothing: antialiased;
	}

	main {
		max-width: 1200px;
		margin: 0 auto;
		padding: 0 24px;
	}

	/* Header */
	header {
		padding: 20px 0;
		border-bottom: 1px solid #e0e0e0;
		margin-bottom: 60px;
	}

	nav {
		display: flex;
		justify-content: space-between;
		align-items: center;
	}

	.nav-logo {
		text-decoration: none;
		color: #1a1a1a;
		font-weight: 600;
		font-size: 0.95rem;
	}

	.nav-links {
		display: flex;
		align-items: center;
		gap: 24px;
	}

	.nav-link {
		color: #707070;
		text-decoration: none;
		font-size: 0.90rem;
		font-weight: 500;
	}

	.nav-link:hover {
		color: #1a1a1a;
	}

	/* Hero row - two column layout */
	.hero-row {
		display: grid;
		grid-template-columns: 1fr 480px;
		gap: 40px;
		padding-bottom: 60px;
		align-items: center;
		max-width: 100%;
	}

	/* Hero */
	.hero {
		padding: 0;
		min-width: 0;
	}

	/* Hero visual sidebar */
	.hero-visual-sidebar {
		min-width: 0;
		overflow: visible;
	}

	h1 {
		font-size: 2.5rem;
		font-weight: 600;
		color: #1a1a1a;
		margin: 0 0 20px;
		letter-spacing: -0.030em;
		line-height: 1.15;
	}

	.nowrap {
		white-space: nowrap;
	}

	.lead {
		font-size: 1.10rem;
		color: #606060;
		max-width: 600px;
		margin: 0 0 40px;
	}

	/* Platform badges */
	.platform-badges {
		display: flex;
		gap: 16px;
		margin: 0 0 32px;
	}

	.platform-badge {
		display: inline-flex;
		align-items: center;
		gap: 6px;
		font-size: 0.85rem;
		font-weight: 500;
		color: #808080;
	}

	/* Platform tabs */
	.platform-tabs {
		display: flex;
		gap: 0;
		margin-bottom: 0;
		border-bottom: 1px solid #d0d0d0;
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
		font-family: 'Instrument Sans', sans-serif;
		color: #808080;
		transition: color 0.15s, background 0.15s;
		margin-bottom: -1px;
	}

	.platform-tab:hover {
		color: #404040;
	}

	.platform-tab.active {
		color: #1a1a1a;
		background: #fff;
		border-color: #d0d0d0;
		border-bottom-color: #fff;
	}

	/* Install block */
	.install-block {
		max-width: 100%;
	}

	.install-block.standalone {
		margin: 32px 0;
	}

	.code-line {
		display: flex;
		align-items: center;
		gap: 12px;
		background: #fff;
		border: 1px solid #d0d0d0;
		padding: 14px 16px;
		overflow: hidden;
	}

	code {
		font-family: 'DM Mono', 'SF Mono', Monaco, monospace;
		font-size: 0.85rem;
		color: #303030;
		flex: 1;
		overflow-x: auto;
		white-space: nowrap;
	}

	.copy-btn {
		background: #1a1a1a;
		color: #fff;
		border: none;
		padding: 8px 16px;
		cursor: pointer;
		font-size: 0.8rem;
		font-weight: 500;
		font-family: 'Instrument Sans', sans-serif;
		white-space: nowrap;
		transition: background 0.15s;
		min-width: 70px;
		text-align: center;
	}

	.copy-btn:hover {
		background: #333;
	}

	.install-note {
		font-size: 0.85rem;
		color: #808080;
		margin: 12px 0 0;
	}

	.install-note a {
		color: #505050;
		text-decoration: underline;
		text-underline-offset: 2px;
	}

	.install-note a:hover {
		color: #1a1a1a;
	}

	/* Sections */
	.section {
		padding: 60px 0;
		border-top: 1px solid #e0e0e0;
	}

	h2 {
		font-size: 1.5rem;
		font-weight: 600;
		color: #1a1a1a;
		margin: 0 0 8px;
		letter-spacing: -0.02em;
	}

	.section-desc {
		color: #707070;
		margin: 0 0 32px;
		font-size: 0.95rem;
	}

	/* Dialog types section */
	.dialog-types-section {
		overflow: visible;
	}

	/* Demo section */
	.demo-section {
		overflow: visible;
	}



	/* Manual note */
	.manual-note {
		font-size: 0.9rem;
		color: #707070;
	}

	.manual-note a {
		color: #505050;
		text-decoration: underline;
		text-underline-offset: 2px;
	}

	.manual-note a:hover {
		color: #1a1a1a;
	}

	/* Install steps */
	.install-steps {
		margin: 40px 0;
	}

	.install-steps h3 {
		font-size: 1rem;
		font-weight: 600;
		color: #1a1a1a;
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
		background: #fff;
		border: 1px solid #e0e0e0;
		padding: 16px;
	}

	.step-num {
		width: 28px;
		height: 28px;
		background: #f0f0f0;
		border-radius: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 0.85rem;
		font-weight: 600;
		color: #606060;
		flex-shrink: 0;
	}

	.step-content {
		flex: 1;
		min-width: 0;
	}

	.step-content strong {
		display: block;
		color: #1a1a1a;
		font-size: 0.95rem;
		margin-bottom: 4px;
	}

	.step-content p {
		margin: 0;
		font-size: 0.85rem;
		color: #606060;
		line-height: 1.5;
	}

	.step-content code {
		background: #f5f5f5;
		padding: 2px 6px;
		font-size: 0.8rem;
		color: #505050;
	}

	/* Unsigned note */
	.unsigned-note {
		margin-top: 32px;
		padding: 20px;
		background: #fff;
		border: 1px solid #d0d0d0;
	}

	.unsigned-note h3 {
		font-size: 0.9rem;
		font-weight: 600;
		color: #1a1a1a;
		margin: 0 0 8px;
	}

	.unsigned-note p {
		font-size: 0.85rem;
		color: #606060;
		margin: 0;
		line-height: 1.5;
	}

	/* Footer */
	footer {
		padding: 48px 0;
		border-top: 1px solid #e0e0e0;
		text-align: center;
		font-size: 0.85rem;
	}

	footer p {
		margin: 6px 0;
		color: #808080;
	}

	footer a {
		color: #505050;
		text-decoration: none;
	}

	footer a:hover {
		color: #1a1a1a;
	}

	/* Responsive */
	@media (max-width: 1000px) {
		.hero-row {
			grid-template-columns: 1fr;
			gap: 40px;
		}

		.hero-visual-sidebar {
			margin: 0;
			order: -1;
		}
	}

	@media (max-width: 700px) {
		header {
			margin-bottom: 48px;
		}

		h1 {
			font-size: 1.8rem;
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
	}
</style>
