<script lang="ts">
import { base } from '$app/paths';
import DialogPreviews from '$lib/components/DialogPreviews.svelte';
import FeaturePanels from '$lib/components/FeaturePanels.svelte';
import InteractiveDemo from '$lib/components/InteractiveDemo.svelte';
import SketchPane from '$lib/components/SketchPane.svelte';
import SiteNav from '$lib/components/SiteNav.svelte';
</script>

<svelte:head>
	<title>Demo — consult-user-mcp</title>
	<link rel="preconnect" href="https://fonts.googleapis.com" />
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
	<link
		href="https://fonts.googleapis.com/css2?family=Instrument+Sans:wght@400;500;600&family=DM+Mono:wght@400;500&display=swap"
		rel="stylesheet"
	/>
</svelte:head>

<main>
	<SiteNav />

	<div class="page-header">
		<h1>Dialog Gallery</h1>
		<p class="page-desc">Interactive flow demos and static previews for every consult-user-mcp dialog surface.</p>
	</div>

	<section class="section" id="flow">
		<h2>Interactive Flow</h2>
		<p class="section-desc">Click through a multi-step dialog scenario end-to-end.</p>
		<InteractiveDemo />
	</section>

	<!-- Dialog type panels -->
	<section class="section" id="dialogs">
		<h2>Dialog Types</h2>
		<p class="section-desc">Confirm, choose, type, or tweak — each backed by a dedicated MCP tool.</p>
		<DialogPreviews />
	</section>

	<!-- Snooze & Feedback -->
	<section class="section" id="features">
		<h2>Snooze &amp; Feedback</h2>
		<p class="section-desc">Every dialog has a snooze timer and a feedback field. Defer a question or redirect the agent without cancelling.</p>
		<FeaturePanels />
	</section>

	<!-- Sketch Pane -->
	<section class="section sketch-section" id="sketch">
		<h2>Layout Sketch</h2>
		<p class="section-desc">The <code>propose_layout</code> tool opens an interactive grid editor where users drag, resize, and arrange UI blocks.</p>
		<div class="sketch-container">
			<SketchPane />
		</div>
		<div class="sketch-footer">
			<span class="sketch-hint"><kbd>Drag</kbd> move</span>
			<span class="sketch-hint"><kbd>Corner</kbd> resize</span>
			<span class="sketch-hint"><kbd>Dbl-click</kbd> rename</span>
			<span class="sketch-hint"><kbd>&#x2318;Z</kbd> undo</span>
			<span class="sketch-hint"><kbd>&#x2318;D</kbd> duplicate</span>
			<span class="sketch-hint"><kbd>&#x232B;</kbd> delete</span>
		</div>
	</section>

	<footer>
		<p><a href="{base}/">Back to home</a></p>
	</footer>
</main>

<style>
	@keyframes fadeSlideUp {
		from { opacity: 0; transform: translateY(20px); }
		to { opacity: 1; transform: translateY(0); }
	}

	:global(*) { box-sizing: border-box; }

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

	/* Page header */
	.page-header {
		padding: 0 56px 32px;
		animation: fadeSlideUp 0.6s cubic-bezier(0.23, 1, 0.32, 1) backwards;
	}

	.page-header h1 {
		font-size: 2rem;
		font-weight: 600;
		color: #1a1a1a;
		margin: 0 0 8px;
		letter-spacing: -0.03em;
	}

	.page-desc {
		color: #707070;
		margin: 0;
		font-size: 1rem;
	}

	/* Sections */
	.section {
		padding: 48px 56px;
		border-top: 1px solid #e0e0e0;
		animation: fadeSlideUp 0.6s cubic-bezier(0.23, 1, 0.32, 1) backwards;
	}

	.section:nth-child(3) { animation-delay: 0.1s; }
	.section:nth-child(4) { animation-delay: 0.2s; }
	.section:nth-child(5) { animation-delay: 0.3s; }

	h2 {
		font-size: 1.4rem;
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

	.section-desc code {
		font-family: 'DM Mono', 'SF Mono', Monaco, monospace;
		font-size: 0.85rem;
		background: #e8e8e8;
		padding: 2px 6px;
		border-radius: 4px;
		color: #505050;
	}

	/* Sketch section */
	.sketch-section {
		overflow: visible;
	}

	.sketch-container {
		background: linear-gradient(180deg, #1a1a1f 0%, #0f0f12 100%);
		border-radius: 16px;
		padding: 32px 24px;
	}

	.sketch-footer {
		display: flex;
		justify-content: center;
		gap: 16px;
		margin-top: 16px;
		flex-wrap: wrap;
	}

	.sketch-hint {
		color: #999;
		font-size: 11px;
		display: flex;
		align-items: center;
		gap: 5px;
	}

	.sketch-hint kbd {
		background: #e8e8e8;
		padding: 2px 6px;
		border-radius: 4px;
		font-family: inherit;
		font-size: 10px;
		color: #606060;
		border: 1px solid #d0d0d0;
	}

	/* Footer */
	footer {
		padding: 48px 56px;
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
		.page-header { padding: 0 32px 32px; }
		.section { padding: 48px 32px; }
		footer { padding: 48px 32px; }
	}

	@media (max-width: 700px) {
		.page-header { padding: 0 20px 24px; }
		.section { padding: 40px 20px; }
		footer { padding: 48px 20px; }

		.page-header h1 { font-size: 1.6rem; }

		.sketch-container { padding: 20px 12px; }
		.sketch-footer { gap: 10px; }
	}
</style>
