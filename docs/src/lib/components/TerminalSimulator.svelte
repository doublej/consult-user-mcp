<script lang="ts">
	type LineType = 'mcp' | 'response' | 'thinking' | 'info';
	type Line = { text: string; type: LineType };

	export let lines: Line[] = [];
	export let isRunning = false;

	const prefixes: Record<LineType, string> = {
		mcp: '[MCP]',
		response: '[OK]',
		thinking: '[...]',
		info: '$'
	};

	let terminalEl: HTMLDivElement;

	$: if (lines.length > 0) scrollToBottom();

	function scrollToBottom(): void {
		setTimeout(() => {
			if (terminalEl) terminalEl.scrollTop = terminalEl.scrollHeight;
		}, 10);
	}
</script>

<div class="terminal" bind:this={terminalEl}>
	<div class="terminal-header">
		<div class="terminal-dots">
			<span class="dot red"></span>
			<span class="dot yellow"></span>
			<span class="dot green"></span>
		</div>
		<span class="terminal-title">Terminal</span>
	</div>
	<div class="terminal-body">
		{#if lines.length === 0}
			<div class="terminal-placeholder">
				<span class="prompt">$</span> Waiting for demo to start...
			</div>
		{/if}
		{#each lines as line, i (i)}
			<div class="terminal-line {line.type}" style="animation-delay: {i * 30}ms">
				<span class="prefix">{prefixes[line.type]}</span>
				<span class="text">{line.text}</span>
				{#if i === lines.length - 1 && isRunning}
					<span class="cursor-block"></span>
				{/if}
			</div>
		{/each}
	</div>
</div>

<style>
	.terminal {
		background: #0d0d0f;
		border-radius: 12px;
		overflow: hidden;
		font-family: 'SF Mono', 'Fira Code', Monaco, monospace;
		font-size: 12px;
		height: 100%;
		display: flex;
		flex-direction: column;
		border: 1px solid #2a2a2f;
	}

	.terminal-header {
		background: #1a1a1f;
		padding: 10px 14px;
		display: flex;
		align-items: center;
		gap: 12px;
		border-bottom: 1px solid #2a2a2f;
	}

	.terminal-dots {
		display: flex;
		gap: 6px;
	}

	.dot {
		width: 10px;
		height: 10px;
		border-radius: 50%;
		opacity: 0.7;
	}

	.dot.red { background: #ff5f57; }
	.dot.yellow { background: #febc2e; }
	.dot.green { background: #28c840; }

	.terminal-title {
		color: #666;
		font-size: 11px;
		font-family: -apple-system, BlinkMacSystemFont, sans-serif;
	}

	.terminal-body {
		flex: 1;
		padding: 14px;
		overflow-y: auto;
		display: flex;
		flex-direction: column;
		gap: 6px;
	}

	.terminal-placeholder {
		color: #4a4a4f;
	}

	.terminal-placeholder .prompt {
		color: #5A8CFF;
		margin-right: 8px;
	}

	.terminal-line {
		display: flex;
		align-items: flex-start;
		gap: 8px;
		line-height: 1.5;
		animation: fadeSlideIn 0.15s ease-out forwards;
		opacity: 0;
	}

	@keyframes fadeSlideIn {
		from {
			opacity: 0;
			transform: translateY(4px);
		}
		to {
			opacity: 1;
			transform: translateY(0);
		}
	}

	.terminal-line .prefix {
		flex-shrink: 0;
		font-weight: 500;
	}

	.terminal-line.mcp .prefix { color: #5A8CFF; }
	.terminal-line.mcp .text { color: #8ab4ff; }

	.terminal-line.response .prefix { color: #4ade80; }
	.terminal-line.response .text { color: #86efac; }

	.terminal-line.thinking .prefix { color: #666; }
	.terminal-line.thinking .text { color: #888; font-style: italic; }

	.terminal-line.info .prefix { color: #facc15; }
	.terminal-line.info .text { color: #fef08a; }

	.cursor-block {
		display: inline-block;
		width: 8px;
		height: 14px;
		background: #5A8CFF;
		animation: blink 1s step-end infinite;
		vertical-align: middle;
		margin-left: 2px;
	}

	@keyframes blink {
		0%, 100% { opacity: 1; }
		50% { opacity: 0; }
	}
</style>
