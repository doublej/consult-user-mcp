<script lang="ts">
	import Changelist from '$lib/components/Changelist.svelte';
	import SiteNav from '$lib/components/SiteNav.svelte';
</script>

<svelte:head>
	<title>Changelog - consult-user-mcp</title>
	<link rel="preconnect" href="https://fonts.googleapis.com">
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous">
	<link href="https://fonts.googleapis.com/css2?family=Instrument+Sans:wght@400;500;600&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
</svelte:head>

<main>
	<SiteNav />

	<section class="changelog-section">
		<h1>Changelog</h1>
		<p class="section-desc">All releases and changes across the project. Each change is labeled with which part it affects.</p>
		<div class="scope-legend">
			<span class="scope-pill app">App</span>
			<span class="scope-pill server">Server</span>
			<span class="scope-pill docs">Docs</span>
			<span class="scope-pill cli">CLI</span>
			<span class="scope-pill pane">Tweak</span>
			<span class="scope-pill pane">Wizard</span>
			<span class="legend-label">etc.</span>
		</div>
		<Changelist />
	</section>

	<footer>
		<p>Built for <a href="https://claude.ai/claude-code" target="_blank" rel="noopener">Claude Code</a> and MCP-compatible agents</p>
		<p><a href="https://github.com/doublej/consult-user-mcp" target="_blank" rel="noopener">GitHub</a></p>
	</footer>
</main>

<style>
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
		padding: 0 24px 56px;
	}

	.changelog-section {
		padding: 0 56px 60px;
	}

	h1 {
		font-size: 2rem;
		font-weight: 600;
		color: #1a1a1a;
		margin: 0 0 8px;
		letter-spacing: -0.03em;
	}

	.section-desc {
		color: #707070;
		margin: 0 0 24px;
		font-size: 0.95rem;
	}

	.scope-legend {
		display: flex;
		gap: 10px;
		margin-bottom: 32px;
	}

	.scope-pill {
		font-size: 0.7rem;
		font-weight: 500;
		padding: 3px 8px;
		text-transform: uppercase;
		letter-spacing: 0.03em;
		border: 1px solid;
	}

	.scope-pill.app {
		border-color: #d0d0d0;
		color: #707070;
	}

	.scope-pill.server {
		border-color: #c8e6c9;
		color: #388e3c;
	}

	.scope-pill.docs {
		border-color: #bbdefb;
		color: #1976d2;
	}

	.scope-pill.cli {
		border-color: #e1bee7;
		color: #7b1fa2;
	}

	.scope-pill.pane {
		border-color: #e0d4b0;
		color: #8a7a4a;
		background: #fdf8ec;
	}

	.legend-label {
		font-size: 0.75rem;
		color: #909090;
		align-self: center;
	}

	footer {
		padding: 48px 56px 0;
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

	@media (max-width: 1000px) {
		.changelog-section {
			padding: 0 32px 52px;
		}

		footer {
			padding: 42px 32px 0;
		}
	}

	@media (max-width: 700px) {
		main {
			padding: 0 16px 48px;
		}

		.changelog-section {
			padding: 0 20px 44px;
		}

		footer {
			padding: 36px 20px 0;
		}
	}
</style>
