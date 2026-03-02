<script lang="ts">
	import { base } from '$app/paths';
	import ComparisonTable from '$lib/components/ComparisonTable.svelte';
	import SiteNav from '$lib/components/SiteNav.svelte';
</script>

<svelte:head>
	<title>Comparison — consult-user-mcp</title>
	<link rel="preconnect" href="https://fonts.googleapis.com" />
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
	<link
		href="https://fonts.googleapis.com/css2?family=Instrument+Sans:wght@400;500;600&family=DM+Mono:wght@400;500&display=swap"
		rel="stylesheet"
	/>
</svelte:head>

<main>
	<SiteNav />

	<section class="comparison-section">
		<h1>Server Comparison</h1>
		<p class="lead">Side-by-side with other human-in-the-loop MCP servers.</p>
		<ComparisonTable />
	</section>

	<footer>
		<p><a href="{base}/">Back to home</a></p>
	</footer>
</main>

<style>
	:global(*) {
		box-sizing: border-box;
	}

	:global(body) {
		margin: 0;
		font-family: 'Instrument Sans', -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
		background: #f7f8fc;
		color: #2f3446;
		min-height: 100vh;
		line-height: 1.6;
		-webkit-font-smoothing: antialiased;
	}

	main {
		max-width: 1200px;
		margin: 0 auto;
		padding: 0 24px 56px;
	}

	.comparison-section {
		padding: 0 56px 48px;
	}

	h1 {
		font-size: 2rem;
		font-weight: 600;
		color: #1f263a;
		margin: 0 0 8px;
		letter-spacing: -0.03em;
	}

	.lead {
		color: #66708b;
		margin: 0 0 28px;
		font-size: 0.98rem;
	}

	footer {
		padding: 40px 56px 0;
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

	@media (max-width: 1000px) {
		.comparison-section {
			padding: 0 32px 40px;
		}

		footer {
			padding: 36px 32px 0;
		}
	}

	@media (max-width: 700px) {
		main {
			padding: 0 16px 48px;
		}

		.comparison-section {
			padding: 0 20px 36px;
		}

		h1 {
			font-size: 1.7rem;
		}

		footer {
			padding: 34px 20px 0;
		}
	}
</style>
