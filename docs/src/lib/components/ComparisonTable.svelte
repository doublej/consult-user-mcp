<script lang="ts">
	type Server = {
		name: string;
		author: string;
		url: string;
		stars: number;
		stack: string;
		platform: string;
		install: string;
		active: boolean;
	};

	type Feature = {
		name: string;
		category: string;
		values: Record<string, string>;
	};

	const servers: Server[] = [
		{ name: 'consult-user-mcp', author: 'doublej', url: 'https://github.com/doublej/consult-user-mcp', stars: 0, stack: 'Swift + TS', platform: 'macOS', install: "curl -sSL https://raw.githubusercontent.com/doublej/consult-user-mcp/main/install.sh | bash", active: true },
		{ name: 'interactive-mcp', author: 'ttommyth', url: 'https://github.com/ttommyth/interactive-mcp', stars: 332, stack: 'TypeScript', platform: 'macOS / Linux / Windows', install: 'npx -y interactive-mcp', active: true },
		{ name: 'ask-user-questions', author: 'paulp-o', url: 'https://github.com/paulp-o/ask-user-questions-mcp', stars: 37, stack: 'TypeScript', platform: 'macOS / Linux', install: 'npx auq-mcp-server server', active: true },
		{ name: 'HITL GUI', author: 'GongRzhe', url: 'https://github.com/GongRzhe/Human-In-the-Loop-MCP-Server', stars: 130, stack: 'Python', platform: 'macOS / Linux / Windows', install: 'uvx hitl-mcp-server', active: false },
		{ name: 'HITL Discord', author: 'KOBA789', url: 'https://github.com/KOBA789/human-in-the-loop', stars: 215, stack: 'Rust', platform: 'Cross-platform (Discord)', install: 'cargo install --git https://github.com/KOBA789/human-in-the-loop.git', active: false },
		{ name: 'mcp-interactive', author: 'ivan-mezentsev', url: 'https://github.com/ivan-mezentsev/mcp-interactive', stars: 2, stack: 'JS / HTML', platform: 'Cross-platform', install: 'npx mcp-interactive', active: false },
	];

	const features: Feature[] = [
		// Dialog types
		{ name: 'Yes / No confirmation', category: 'Dialog types', values: { 'consult-user-mcp': 'yes', 'interactive-mcp': 'no', 'ask-user-questions': 'no', 'HITL GUI': 'yes', 'HITL Discord': 'no', 'mcp-interactive': 'no' } },
		{ name: 'Single choice', category: 'Dialog types', values: { 'consult-user-mcp': 'Up to 20 options', 'interactive-mcp': 'Predefined options', 'ask-user-questions': '2\u201310 options', 'HITL GUI': 'Radio buttons', 'HITL Discord': 'no', 'mcp-interactive': 'Predefined options' } },
		{ name: 'Multi-select', category: 'Dialog types', values: { 'consult-user-mcp': 'yes', 'interactive-mcp': 'no', 'ask-user-questions': 'yes', 'HITL GUI': 'Checkboxes', 'HITL Discord': 'no', 'mcp-interactive': 'no' } },
		{ name: 'Free text input', category: 'Dialog types', values: { 'consult-user-mcp': 'Dedicated tool', 'interactive-mcp': 'yes', 'ask-user-questions': 'Via "Other" option', 'HITL GUI': 'yes', 'HITL Discord': 'Discord message', 'mcp-interactive': 'yes' } },
		{ name: 'Multi-line text', category: 'Dialog types', values: { 'consult-user-mcp': 'no', 'interactive-mcp': 'no', 'ask-user-questions': 'no', 'HITL GUI': 'Dedicated tool', 'HITL Discord': 'no', 'mcp-interactive': 'no' } },
		{ name: 'Hidden / password input', category: 'Dialog types', values: { 'consult-user-mcp': 'yes', 'interactive-mcp': 'no', 'ask-user-questions': 'no', 'HITL GUI': 'no', 'HITL Discord': 'no', 'mcp-interactive': 'no' } },
		{ name: 'Multi-question wizard', category: 'Dialog types', values: { 'consult-user-mcp': 'Wizard + accordion', 'interactive-mcp': 'no', 'ask-user-questions': 'Question sets', 'HITL GUI': 'no', 'HITL Discord': 'no', 'mcp-interactive': 'no' } },
		{ name: 'Typed input (int / float)', category: 'Dialog types', values: { 'consult-user-mcp': 'no', 'interactive-mcp': 'no', 'ask-user-questions': 'no', 'HITL GUI': 'yes', 'HITL Discord': 'no', 'mcp-interactive': 'no' } },
		{ name: 'Markdown in prompts', category: 'Dialog types', values: { 'consult-user-mcp': 'no', 'interactive-mcp': 'no', 'ask-user-questions': 'no', 'HITL GUI': 'no', 'HITL Discord': 'Discord native', 'mcp-interactive': 'yes' } },
		{ name: 'System notification', category: 'Dialog types', values: { 'consult-user-mcp': 'yes', 'interactive-mcp': 'yes', 'ask-user-questions': 'no', 'HITL GUI': 'Info message tool', 'HITL Discord': 'no', 'mcp-interactive': 'no' } },

		// UX & interaction
		{ name: 'UI approach', category: 'UX', values: { 'consult-user-mcp': 'Native SwiftUI', 'interactive-mcp': 'AppleScript / zenity / PowerShell', 'ask-user-questions': 'Terminal CLI', 'HITL GUI': 'Tkinter GUI', 'HITL Discord': 'Discord threads', 'mcp-interactive': 'Electron popup' } },
		{ name: 'Snooze / defer', category: 'UX', values: { 'consult-user-mcp': '1 min \u2013 1 hr', 'interactive-mcp': 'no', 'ask-user-questions': 'no', 'HITL GUI': 'no', 'HITL Discord': 'no', 'mcp-interactive': 'no' } },
		{ name: 'Feedback to redirect agent', category: 'UX', values: { 'consult-user-mcp': 'yes', 'interactive-mcp': 'no', 'ask-user-questions': 'Rejection + reason', 'HITL GUI': 'no', 'HITL Discord': 'no', 'mcp-interactive': 'no' } },
		{ name: 'Persistent chat mode', category: 'UX', values: { 'consult-user-mcp': 'no', 'interactive-mcp': 'Intensive chat', 'ask-user-questions': 'no', 'HITL GUI': 'no', 'HITL Discord': 'no', 'mcp-interactive': 'no' } },
		{ name: 'Remote answering', category: 'UX', values: { 'consult-user-mcp': 'no', 'interactive-mcp': 'no', 'ask-user-questions': 'SSH', 'HITL GUI': 'no', 'HITL Discord': 'Phone / Discord', 'mcp-interactive': 'no' } },
		{ name: 'Question queueing', category: 'UX', values: { 'consult-user-mcp': 'no', 'interactive-mcp': 'no', 'ask-user-questions': 'yes', 'HITL GUI': 'no', 'HITL Discord': 'no', 'mcp-interactive': 'no' } },
		{ name: 'Multi-agent support', category: 'UX', values: { 'consult-user-mcp': 'no', 'interactive-mcp': 'no', 'ask-user-questions': 'yes', 'HITL GUI': 'no', 'HITL Discord': 'no', 'mcp-interactive': 'no' } },

		// Configuration
		{ name: 'Menu bar app', category: 'Config', values: { 'consult-user-mcp': 'yes', 'interactive-mcp': 'no', 'ask-user-questions': 'no', 'HITL GUI': 'no', 'HITL Discord': 'no', 'mcp-interactive': 'no' } },
		{ name: 'Settings GUI', category: 'Config', values: { 'consult-user-mcp': 'yes', 'interactive-mcp': 'no', 'ask-user-questions': 'no', 'HITL GUI': 'no', 'HITL Discord': 'no', 'mcp-interactive': 'no' } },
		{ name: 'Baseprompt injection', category: 'Config', values: { 'consult-user-mcp': 'yes', 'interactive-mcp': 'no', 'ask-user-questions': 'no', 'HITL GUI': 'no', 'HITL Discord': 'no', 'mcp-interactive': 'Recommended rules' } },
		{ name: 'Dialog position config', category: 'Config', values: { 'consult-user-mcp': 'Left / right / center', 'interactive-mcp': 'no', 'ask-user-questions': 'no', 'HITL GUI': 'no', 'HITL Discord': 'no', 'mcp-interactive': 'no' } },
		{ name: 'Configurable timeout', category: 'Config', values: { 'consult-user-mcp': '10 min', 'interactive-mcp': 'CLI flag (30s default)', 'ask-user-questions': 'no', 'HITL GUI': '5 min', 'HITL Discord': 'no', 'mcp-interactive': 'CLI flag (60s default)' } },
		{ name: 'Disable specific tools', category: 'Config', values: { 'consult-user-mcp': 'no', 'interactive-mcp': 'CLI flag', 'ask-user-questions': 'no', 'HITL GUI': 'no', 'HITL Discord': 'no', 'mcp-interactive': 'no' } },
		{ name: 'Dialog history', category: 'Config', values: { 'consult-user-mcp': 'yes', 'interactive-mcp': 'no', 'ask-user-questions': 'no', 'HITL GUI': 'no', 'HITL Discord': 'Discord thread', 'mcp-interactive': 'no' } },
		{ name: 'Health check tool', category: 'Config', values: { 'consult-user-mcp': 'no', 'interactive-mcp': 'no', 'ask-user-questions': 'no', 'HITL GUI': 'yes', 'HITL Discord': 'no', 'mcp-interactive': 'no' } },
	];

	const categories = [...new Set(features.map(f => f.category))];
	const categoryLabels: Record<string, string> = {
		'Dialog types': 'Dialog Types',
		'UX': 'UX & Interaction',
		'Config': 'Configuration',
	};

	function cellClass(value: string): string {
		if (value === 'yes') return 'cell-yes';
		if (value === 'no') return 'cell-no';
		return 'cell-detail';
	}

	function cellDisplay(value: string): string {
		if (value === 'yes') return '\u2713';
		if (value === 'no') return '\u2014';
		return value;
	}
</script>

<div class="comparison-outer">
	<div class="table-scroll">
		<table>
			<thead>
				<tr>
					<th class="col-feature"></th>
					{#each servers as server}
						<th class="col-server" class:col-self={server.name === 'consult-user-mcp'}>
							<a href={server.url} target="_blank" rel="noopener">{server.name}</a>
							<span class="server-meta">
								{server.platform}
								{#if server.stars > 0}
									<span class="stars">{server.stars} stars</span>
								{/if}
							</span>
						</th>
					{/each}
				</tr>
			</thead>
			<tbody>
				{#each categories as category}
					<tr class="category-row">
						<td colspan={servers.length + 1}>{categoryLabels[category]}</td>
					</tr>
					{#each features.filter(f => f.category === category) as feature}
						<tr>
							<td class="feature-name">{feature.name}</td>
							{#each servers as server}
								{@const val = feature.values[server.name] ?? 'no'}
								<td
									class="{cellClass(val)}"
									class:col-self={server.name === 'consult-user-mcp'}
								>
									{cellDisplay(val)}
								</td>
							{/each}
						</tr>
					{/each}
				{/each}

				<tr class="category-row">
					<td colspan={servers.length + 1}>Install</td>
				</tr>
				<tr>
					<td class="feature-name">Stack</td>
					{#each servers as server}
						<td class:col-self={server.name === 'consult-user-mcp'} class="cell-detail">{server.stack}</td>
					{/each}
				</tr>
				<tr>
					<td class="feature-name">Actively maintained</td>
					{#each servers as server}
						<td
							class="{server.active ? 'cell-yes' : 'cell-no'}"
							class:col-self={server.name === 'consult-user-mcp'}
						>
							{server.active ? '\u2713' : '\u2014'}
						</td>
					{/each}
				</tr>
				<tr>
					<td class="feature-name">Install command</td>
					{#each servers as server}
						<td class="cell-install" class:col-self={server.name === 'consult-user-mcp'}>
							<code>{server.install}</code>
						</td>
					{/each}
				</tr>
			</tbody>
		</table>
	</div>

	<p class="table-note">
		Star counts as of February 2026. Active = committed to in last 3 months.
	</p>
</div>

<style>
	.comparison-outer {
		margin: 0;
	}

	.table-scroll {
		overflow-x: auto;
		-webkit-overflow-scrolling: touch;
	}

	table {
		width: 100%;
		min-width: 900px;
		border-collapse: collapse;
		font-size: 0.85rem;
		background: #fff;
		border: 1px solid #d0d0d0;
	}

	/* Header */
	thead th {
		padding: 14px 12px 10px;
		text-align: center;
		font-weight: 500;
		font-size: 0.8rem;
		background: #f8f8f8;
		border-bottom: 1px solid #d0d0d0;
		vertical-align: top;
		border-left: 1px solid #e8e8e8;
	}

	thead th:first-child {
		border-left: none;
	}

	thead th a {
		color: #1a1a1a;
		text-decoration: none;
		font-weight: 600;
		font-size: 0.85rem;
		display: block;
	}

	thead th a:hover {
		text-decoration: underline;
	}

	.server-meta {
		display: block;
		color: #909090;
		font-size: 0.7rem;
		font-weight: 400;
		margin-top: 3px;
		line-height: 1.4;
	}

	.stars {
		display: inline;
	}

	.stars::before {
		content: '\00b7\00a0';
	}

	.col-feature {
		width: 180px;
		min-width: 150px;
	}

	.col-server {
		width: calc((100% - 180px) / 6);
	}

	/* Highlight own column */
	.col-self {
		background: #f5f8ff;
	}

	thead .col-self {
		background: #edf2ff;
		border-bottom-color: #c0cce8;
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
		padding: 8px 12px;
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

	.cell-detail {
		color: #404040;
		font-size: 0.8rem;
	}

	.cell-install {
		text-align: left;
		max-width: 160px;
	}

	.cell-install code {
		font-family: 'DM Mono', monospace;
		font-size: 0.7rem;
		color: #505050;
		word-break: break-all;
		line-height: 1.5;
	}

	tbody tr:last-child td {
		border-bottom: none;
	}

	/* Hover row */
	tbody tr:not(.category-row):hover td {
		background: #fafafa;
	}

	tbody tr:not(.category-row):hover td.col-self {
		background: #edf2ff;
	}

	.table-note {
		font-size: 0.75rem;
		color: #a0a0a0;
		margin: 10px 0 0;
		text-align: right;
	}

	@media (max-width: 700px) {
		.col-feature {
			min-width: 120px;
		}
	}
</style>
