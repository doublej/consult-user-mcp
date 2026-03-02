<script lang="ts">
	import SiteNav from '$lib/components/SiteNav.svelte';

	type CellState = 'yes' | 'no' | 'unknown';

	type Client = {
		name: string;
		short: string;
	};

	type Feature = {
		name: string;
		category: string;
		values: Record<string, CellState>;
	};

	const clients: Client[] = [
		{ name: 'Claude Code', short: 'Claude Code' },
		{ name: 'Claude Desktop', short: 'Claude Desktop' },
		{ name: 'Cursor', short: 'Cursor' },
		{ name: 'VS Code / Copilot', short: 'VS Code' },
		{ name: 'Visual Studio 2026', short: 'VS 2026' },
		{ name: 'Windsurf', short: 'Windsurf' },
		{ name: 'Zed', short: 'Zed' },
		{ name: 'Cline', short: 'Cline' },
		{ name: 'Continue', short: 'Continue' },
		{ name: 'Goose', short: 'Goose' },
		{ name: 'ChatGPT', short: 'ChatGPT' },
		{ name: 'JetBrains AI', short: 'JetBrains' },
		{ name: 'Sourcegraph Cody', short: 'Cody' },
		{ name: 'Amazon Q', short: 'Amazon Q' },
	];

	const features: Feature[] = [
		// Core
		{ name: 'Tools', category: 'Core', values: { 'Claude Code': 'yes', 'Claude Desktop': 'yes', 'Cursor': 'yes', 'VS Code / Copilot': 'yes', 'Visual Studio 2026': 'yes', 'Windsurf': 'yes', 'Zed': 'yes', 'Cline': 'yes', 'Continue': 'yes', 'Goose': 'yes', 'ChatGPT': 'yes', 'JetBrains AI': 'yes', 'Sourcegraph Cody': 'yes', 'Amazon Q': 'yes' } },
		{ name: 'Resources', category: 'Core', values: { 'Claude Code': 'yes', 'Claude Desktop': 'yes', 'Cursor': 'yes', 'VS Code / Copilot': 'yes', 'Visual Studio 2026': 'yes', 'Windsurf': 'yes', 'Zed': 'no', 'Cline': 'yes', 'Continue': 'yes', 'Goose': 'yes', 'ChatGPT': 'no', 'JetBrains AI': 'no', 'Sourcegraph Cody': 'yes', 'Amazon Q': 'no' } },
		{ name: 'Prompts', category: 'Core', values: { 'Claude Code': 'yes', 'Claude Desktop': 'yes', 'Cursor': 'yes', 'VS Code / Copilot': 'yes', 'Visual Studio 2026': 'yes', 'Windsurf': 'yes', 'Zed': 'yes', 'Cline': 'no', 'Continue': 'yes', 'Goose': 'yes', 'ChatGPT': 'no', 'JetBrains AI': 'no', 'Sourcegraph Cody': 'no', 'Amazon Q': 'yes' } },

		// Advanced
		{ name: 'Sampling', category: 'Advanced', values: { 'Claude Code': 'no', 'Claude Desktop': 'no', 'Cursor': 'no', 'VS Code / Copilot': 'yes', 'Visual Studio 2026': 'yes', 'Windsurf': 'no', 'Zed': 'no', 'Cline': 'no', 'Continue': 'no', 'Goose': 'yes', 'ChatGPT': 'no', 'JetBrains AI': 'no', 'Sourcegraph Cody': 'no', 'Amazon Q': 'no' } },
		{ name: 'Elicitation', category: 'Advanced', values: { 'Claude Code': 'no', 'Claude Desktop': 'no', 'Cursor': 'yes', 'VS Code / Copilot': 'yes', 'Visual Studio 2026': 'yes', 'Windsurf': 'no', 'Zed': 'no', 'Cline': 'no', 'Continue': 'no', 'Goose': 'yes', 'ChatGPT': 'no', 'JetBrains AI': 'no', 'Sourcegraph Cody': 'no', 'Amazon Q': 'no' } },
		{ name: 'Roots', category: 'Advanced', values: { 'Claude Code': 'yes', 'Claude Desktop': 'no', 'Cursor': 'yes', 'VS Code / Copilot': 'yes', 'Visual Studio 2026': 'yes', 'Windsurf': 'no', 'Zed': 'no', 'Cline': 'no', 'Continue': 'no', 'Goose': 'no', 'ChatGPT': 'no', 'JetBrains AI': 'no', 'Sourcegraph Cody': 'no', 'Amazon Q': 'no' } },
		{ name: 'MCP Apps', category: 'Advanced', values: { 'Claude Code': 'no', 'Claude Desktop': 'yes', 'Cursor': 'no', 'VS Code / Copilot': 'no', 'Visual Studio 2026': 'no', 'Windsurf': 'no', 'Zed': 'no', 'Cline': 'no', 'Continue': 'no', 'Goose': 'yes', 'ChatGPT': 'yes', 'JetBrains AI': 'no', 'Sourcegraph Cody': 'no', 'Amazon Q': 'no' } },

		// Transport
		{ name: 'stdio', category: 'Transport', values: { 'Claude Code': 'yes', 'Claude Desktop': 'yes', 'Cursor': 'yes', 'VS Code / Copilot': 'yes', 'Visual Studio 2026': 'yes', 'Windsurf': 'yes', 'Zed': 'yes', 'Cline': 'yes', 'Continue': 'yes', 'Goose': 'yes', 'ChatGPT': 'no', 'JetBrains AI': 'yes', 'Sourcegraph Cody': 'yes', 'Amazon Q': 'yes' } },
		{ name: 'SSE (legacy)', category: 'Transport', values: { 'Claude Code': 'yes', 'Claude Desktop': 'no', 'Cursor': 'yes', 'VS Code / Copilot': 'yes', 'Visual Studio 2026': 'yes', 'Windsurf': 'yes', 'Zed': 'no', 'Cline': 'yes', 'Continue': 'yes', 'Goose': 'no', 'ChatGPT': 'yes', 'JetBrains AI': 'yes', 'Sourcegraph Cody': 'no', 'Amazon Q': 'no' } },
		{ name: 'Streamable HTTP', category: 'Transport', values: { 'Claude Code': 'yes', 'Claude Desktop': 'no', 'Cursor': 'yes', 'VS Code / Copilot': 'yes', 'Visual Studio 2026': 'yes', 'Windsurf': 'yes', 'Zed': 'no', 'Cline': 'yes', 'Continue': 'yes', 'Goose': 'yes', 'ChatGPT': 'yes', 'JetBrains AI': 'yes', 'Sourcegraph Cody': 'no', 'Amazon Q': 'no' } },
	];

	const categories = [...new Set(features.map(f => f.category))];

	function cellIcon(state: CellState): string {
		if (state === 'yes') return '\u2713';
		if (state === 'no') return '\u2014';
		return '?';
	}

	function cellClass(state: CellState): string {
		if (state === 'yes') return 'cell-yes';
		if (state === 'no') return 'cell-no';
		return 'cell-unknown';
	}

	function featureCount(client: Client): number {
		return features.filter(f => f.values[client.name] === 'yes').length;
	}
</script>

<svelte:head>
	<title>MCP Client Ecosystem - consult-user-mcp</title>
	<link rel="preconnect" href="https://fonts.googleapis.com">
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous">
	<link href="https://fonts.googleapis.com/css2?family=Instrument+Sans:wght@400;500;600&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
</svelte:head>

<main>
	<SiteNav />

	<h1>MCP Client Ecosystem</h1>
	<p class="lead">MCP feature support across AI coding tools.</p>

	<div class="table-scroll">
		<table>
			<thead>
				<tr>
					<th class="col-feature"></th>
					{#each clients as client}
						<th class="col-client">
							<span class="client-name">{client.short}</span>
							<span class="client-score">{featureCount(client)} / {features.length}</span>
						</th>
					{/each}
				</tr>
			</thead>
			<tbody>
				{#each categories as category}
					<tr class="category-row">
						<td colspan={clients.length + 1}>{category}</td>
					</tr>
					{#each features.filter(f => f.category === category) as feature}
						<tr>
							<td class="feature-name">{feature.name}</td>
							{#each clients as client}
								{@const state = feature.values[client.name] ?? 'unknown'}
								<td class={cellClass(state)}>{cellIcon(state)}</td>
							{/each}
						</tr>
					{/each}
				{/each}
			</tbody>
		</table>
	</div>

	<p class="table-note">Data as of March 2026. Based on publicly available documentation.</p>

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
		padding: 0 24px;
	}

	h1 {
		font-size: 1.8rem;
		font-weight: 600;
		margin: 0 0 8px;
		color: #1a1a1a;
	}

	.lead {
		font-size: 1rem;
		color: #707070;
		margin: 0 0 32px;
	}

	/* Table wrapper */
	.table-scroll {
		overflow-x: auto;
		-webkit-overflow-scrolling: touch;
	}

	table {
		width: 100%;
		min-width: 1100px;
		border-collapse: collapse;
		font-size: 0.85rem;
		background: #fff;
		border: 1px solid #d0d0d0;
	}

	/* Header */
	thead th {
		padding: 14px 10px 10px;
		text-align: center;
		font-weight: 500;
		font-size: 0.78rem;
		background: #f8f8f8;
		border-bottom: 1px solid #d0d0d0;
		vertical-align: top;
		border-left: 1px solid #e8e8e8;
	}

	thead th:first-child {
		border-left: none;
	}

	.col-feature {
		width: 150px;
		min-width: 130px;
	}

	.col-client {
		width: calc((100% - 150px) / 14);
		min-width: 75px;
	}

	.client-name {
		display: block;
		font-weight: 600;
		font-size: 0.82rem;
		color: #1a1a1a;
	}

	.client-score {
		display: block;
		font-family: 'DM Mono', monospace;
		font-size: 0.68rem;
		color: #909090;
		margin-top: 3px;
	}

	/* Category rows */
	.category-row td {
		padding: 10px 12px;
		font-size: 0.75rem;
		font-weight: 600;
		color: #808080;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		background: #f5f5f5;
		border-top: 1px solid #d0d0d0;
		border-bottom: 1px solid #e0e0e0;
	}

	/* Body cells */
	td {
		padding: 8px 10px;
		text-align: center;
		border-bottom: 1px solid #f0f0f0;
		border-left: 1px solid #f0f0f0;
		color: #404040;
		line-height: 1.4;
	}

	td:first-child {
		border-left: none;
	}

	.feature-name {
		text-align: left;
		font-weight: 500;
		color: #303030;
		white-space: nowrap;
	}

	.cell-yes {
		color: #2e7d32;
		font-weight: 600;
	}

	.cell-no {
		color: #c0c0c0;
	}

	.cell-unknown {
		color: #b0b0b0;
		font-style: italic;
	}

	/* Hover */
	tbody tr:not(.category-row):hover td {
		background: #f5f5f5;
	}

	tbody tr:last-child td {
		border-bottom: none;
	}

	.table-note {
		font-size: 0.75rem;
		color: #a0a0a0;
		margin: 10px 0 0;
		text-align: right;
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

	@media (max-width: 700px) {
		main {
			padding: 0 16px;
		}

		h1 {
			font-size: 1.4rem;
		}

		.col-feature {
			min-width: 110px;
		}
	}
</style>
