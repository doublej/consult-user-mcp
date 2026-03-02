<script lang="ts">
	import '../styles/dialog.css';

	type Block = {
		label: string;
		x: number;
		y: number;
		w: number;
		h: number;
		color: string;
		role?: string;
		content?: string;
		importance?: 'primary' | 'secondary' | 'tertiary';
		elevation?: number;
		number?: string;
	};

	type Annotation = {
		x: number;
		y: number;
		text: string;
	};

	const blocks: Block[] = [
		{ label: 'Header', x: 0, y: 0, w: 12, h: 1, color: '#3B82F6', role: 'header', content: 'nav', importance: 'primary', elevation: 1, number: '1' },
		{ label: 'Sidebar', x: 0, y: 1, w: 3, h: 6, color: '#8B5CF6', role: 'sidebar', content: 'list', importance: 'secondary', elevation: 0, number: '2' },
		{ label: 'Canvas', x: 3, y: 1, w: 9, h: 4, color: '#10B981', role: 'canvas', content: 'text', importance: 'primary', elevation: 2, number: '3' },
		{ label: 'Toolbar', x: 3, y: 5, w: 9, h: 2, color: '#F59E0B', role: 'toolbar', content: 'button', importance: 'tertiary', elevation: 0, number: '4' },
		{ label: 'Footer', x: 0, y: 7, w: 12, h: 1, color: '#EF4444', role: 'footer', content: 'text', importance: 'secondary', elevation: 1, number: '5' },
	];

	const annotations: Annotation[] = [
		{ x: 6, y: 0, text: 'Main navigation with logo and links' },
		{ x: 1, y: 4, text: 'Collapsible filter panel' },
		{ x: 8, y: 3, text: 'Primary content area' },
	];

	const cols = 12;
	const rows = 8;
	const cellSize = 48;

	function getBlockStyle(block: Block): string {
		const left = block.x * cellSize;
		const top = block.y * cellSize;
		const width = block.w * cellSize;
		const height = block.h * cellSize;
		return `left:${left}px;top:${top}px;width:${width}px;height:${height}px`;
	}

	function getFillOpacity(importance?: string): number {
		if (importance === 'primary') return 0.35;
		if (importance === 'secondary') return 0.25;
		return 0.12;
	}

	function getBorderStyle(importance?: string): string {
		if (importance === 'primary') return '2px solid';
		if (importance === 'secondary') return '1.5px solid';
		return '0.5px dashed';
	}

	function getShadow(elevation?: number): string {
		if (elevation === 1) return '0 1px 2px rgba(0,0,0,0.1)';
		if (elevation === 2) return '0 3px 6px rgba(0,0,0,0.15)';
		if (elevation === 3) return '0 6px 12px rgba(0,0,0,0.2)';
		return 'none';
	}
</script>

<div class="sketch-pane">
	<!-- Sidebar -->
	<div class="sketch-sidebar">
		<div class="sidebar-actions">
			<button class="sidebar-icon-btn" disabled>
				<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 10h4l3-7 4 14 3-7h4"/></svg>
			</button>
			<button class="sidebar-icon-btn" disabled>
				<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 10h4l3-7 4 14 3-7h4" transform="scale(-1,1) translate(-24,0)"/></svg>
			</button>
		</div>
		<button class="sidebar-add-btn">
			<span class="add-icon">+</span>
			<span class="add-label">Add</span>
		</button>
		<div class="sidebar-dims">{cols}&times;{rows}</div>
	</div>

	<!-- Canvas -->
	<div class="sketch-canvas-wrapper">
		<!-- Browser frame -->
		<div class="browser-frame">
			<div class="browser-titlebar">
				<div class="browser-dots">
					<span class="dot red"></span>
					<span class="dot yellow"></span>
					<span class="dot green"></span>
				</div>
				<div class="browser-url">
					<span class="url-text">app.example.com/dashboard</span>
				</div>
			</div>

			<!-- Grid canvas -->
			<div class="sketch-grid" style="width:{cols * cellSize}px;height:{rows * cellSize}px">
				<!-- Grid lines -->
				{#each Array(cols + 1) as _, i}
					<div class="grid-line-v" style="left:{i * cellSize}px;height:{rows * cellSize}px"></div>
				{/each}
				{#each Array(rows + 1) as _, i}
					<div class="grid-line-h" style="top:{i * cellSize}px;width:{cols * cellSize}px"></div>
				{/each}

				<!-- Blocks -->
				{#each blocks as block}
					<div
						class="sketch-block"
						class:importance-primary={block.importance === 'primary'}
						class:importance-secondary={block.importance === 'secondary'}
						class:importance-tertiary={block.importance === 'tertiary'}
						style="{getBlockStyle(block)};
							background:{block.color}{Math.round(getFillOpacity(block.importance) * 255).toString(16).padStart(2, '0')};
							border:{getBorderStyle(block.importance)} {block.color};
							box-shadow:{getShadow(block.elevation)}"
					>
						<!-- Number badge -->
						<span class="block-number" style="background:{block.color}">{block.number}</span>

						<!-- Wireframe content -->
						<div class="wireframe" style="color:{block.color}">
							{#if block.content === 'nav'}
								<div class="wf-nav">
									<div class="wf-nav-logo"></div>
									<div class="wf-nav-links">
										<div class="wf-nav-pill"></div>
										<div class="wf-nav-pill"></div>
										<div class="wf-nav-pill"></div>
									</div>
								</div>
							{:else if block.content === 'list'}
								<div class="wf-list">
									{#each Array(5) as _}
										<div class="wf-list-row">
											<div class="wf-list-dot"></div>
											<div class="wf-list-bar"></div>
										</div>
									{/each}
								</div>
							{:else if block.content === 'text'}
								<div class="wf-text">
									<div class="wf-text-line full"></div>
									<div class="wf-text-line full"></div>
									<div class="wf-text-line half"></div>
								</div>
							{:else if block.content === 'button'}
								<div class="wf-buttons">
									<div class="wf-button"></div>
									<div class="wf-button short"></div>
								</div>
							{/if}
						</div>

						<!-- Label on hover (static for faux) -->
						<span class="block-label">{block.label}</span>
					</div>
				{/each}

				<!-- Annotation markers -->
				{#each annotations as ann, i}
					<div class="annotation-marker" style="left:{ann.x * cellSize + cellSize / 2}px;top:{ann.y * cellSize + cellSize / 2}px">
						{i + 1}
					</div>
				{/each}
			</div>
		</div>

		<!-- Annotation legend -->
		<div class="annotation-legend">
			{#each annotations as ann, i}
				<div class="annotation-row">
					<span class="annotation-num">{i + 1}</span>
					<span class="annotation-text">{ann.text}</span>
				</div>
			{/each}
		</div>
	</div>
</div>

<style>
	.sketch-pane {
		display: flex;
		gap: 12px;
		max-width: 720px;
		margin: 0 auto;
	}

	/* Sidebar */
	.sketch-sidebar {
		display: flex;
		flex-direction: column;
		gap: 10px;
		width: 64px;
		flex-shrink: 0;
	}

	.sidebar-actions {
		display: flex;
		gap: 4px;
	}

	.sidebar-icon-btn {
		width: 28px;
		height: 28px;
		background: #2a2a30;
		border: 1px solid #3a3a3f;
		border-radius: 6px;
		color: #666;
		display: flex;
		align-items: center;
		justify-content: center;
		cursor: default;
	}

	.sidebar-icon-btn:disabled {
		opacity: 0.4;
	}

	.sidebar-add-btn {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 2px;
		padding: 8px 4px;
		background: #242428;
		border: 1px solid #3a3a3f;
		border-radius: 8px;
		cursor: default;
		font-family: inherit;
	}

	.add-icon {
		color: #5A8CFF;
		font-size: 18px;
		font-weight: 300;
		line-height: 1;
	}

	.add-label {
		color: #9a9a9f;
		font-size: 10px;
		font-weight: 500;
	}

	.sidebar-dims {
		color: #666;
		font-size: 10px;
		font-family: 'DM Mono', 'SF Mono', monospace;
		text-align: center;
		background: #1a1a1f;
		padding: 3px 6px;
		border-radius: 4px;
	}

	/* Canvas wrapper */
	.sketch-canvas-wrapper {
		flex: 1;
		min-width: 0;
		overflow-x: auto;
	}

	/* Browser frame */
	.browser-frame {
		background: #1a1a1f;
		border-radius: 10px;
		border: 1px solid #3a3a3f;
		overflow: hidden;
	}

	.browser-titlebar {
		display: flex;
		align-items: center;
		gap: 12px;
		padding: 10px 14px;
		background: #242428;
		border-bottom: 1px solid #3a3a3f;
	}

	.browser-dots {
		display: flex;
		gap: 6px;
		flex-shrink: 0;
	}

	.dot {
		width: 10px;
		height: 10px;
		border-radius: 50%;
	}

	.dot.red { background: #ff5f57; }
	.dot.yellow { background: #febc2e; }
	.dot.green { background: #28c840; }

	.browser-url {
		flex: 1;
		background: #1a1a1f;
		border-radius: 5px;
		padding: 5px 10px;
	}

	.url-text {
		color: #666;
		font-size: 11px;
		font-family: 'DM Mono', 'SF Mono', monospace;
	}

	/* Grid */
	.sketch-grid {
		position: relative;
		background: white;
		margin: 8px;
		border-radius: 4px;
	}

	.grid-line-v,
	.grid-line-h {
		position: absolute;
		background: rgba(200, 220, 245, 0.5);
	}

	.grid-line-v {
		width: 0.5px;
		top: 0;
	}

	.grid-line-h {
		height: 0.5px;
		left: 0;
	}

	/* Blocks */
	.sketch-block {
		position: absolute;
		border-radius: 6px;
		overflow: hidden;
		transition: box-shadow 0.15s ease;
	}

	.block-number {
		position: absolute;
		top: 3px;
		left: 3px;
		width: 18px;
		height: 18px;
		border-radius: 4px;
		color: white;
		font-size: 10px;
		font-weight: 700;
		display: flex;
		align-items: center;
		justify-content: center;
		z-index: 2;
	}

	.block-label {
		position: absolute;
		bottom: 3px;
		left: 50%;
		transform: translateX(-50%);
		background: rgba(0, 0, 0, 0.7);
		color: white;
		font-size: 9px;
		font-weight: 500;
		padding: 1px 6px;
		border-radius: 3px;
		white-space: nowrap;
		z-index: 2;
	}

	/* Wireframe shapes */
	.wireframe {
		position: absolute;
		inset: 22px 8px 20px;
		opacity: 0.3;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	/* Nav wireframe */
	.wf-nav {
		display: flex;
		align-items: center;
		justify-content: space-between;
		width: 100%;
		gap: 12px;
	}

	.wf-nav-logo {
		width: 20px;
		height: 10px;
		background: currentColor;
		border-radius: 2px;
		flex-shrink: 0;
	}

	.wf-nav-links {
		display: flex;
		gap: 6px;
	}

	.wf-nav-pill {
		width: 28px;
		height: 8px;
		background: currentColor;
		border-radius: 4px;
	}

	/* List wireframe */
	.wf-list {
		display: flex;
		flex-direction: column;
		gap: 8px;
		width: 100%;
	}

	.wf-list-row {
		display: flex;
		align-items: center;
		gap: 6px;
	}

	.wf-list-dot {
		width: 6px;
		height: 6px;
		background: currentColor;
		border-radius: 50%;
		flex-shrink: 0;
	}

	.wf-list-bar {
		height: 6px;
		background: currentColor;
		border-radius: 3px;
		width: 70%;
	}

	/* Text wireframe */
	.wf-text {
		display: flex;
		flex-direction: column;
		gap: 6px;
		width: 100%;
	}

	.wf-text-line {
		height: 6px;
		background: currentColor;
		border-radius: 3px;
	}

	.wf-text-line.full { width: 100%; }
	.wf-text-line.half { width: 55%; }

	/* Button wireframe */
	.wf-buttons {
		display: flex;
		gap: 8px;
		align-items: center;
	}

	.wf-button {
		width: 52px;
		height: 16px;
		background: currentColor;
		border-radius: 4px;
	}

	.wf-button.short {
		width: 36px;
	}

	/* Annotation markers */
	.annotation-marker {
		position: absolute;
		width: 20px;
		height: 20px;
		background: #F97316;
		border-radius: 50%;
		color: white;
		font-size: 10px;
		font-weight: 700;
		display: flex;
		align-items: center;
		justify-content: center;
		transform: translate(-50%, -50%);
		z-index: 3;
		box-shadow: 0 1px 4px rgba(249, 115, 22, 0.4);
	}

	/* Annotation legend */
	.annotation-legend {
		display: flex;
		flex-direction: column;
		gap: 6px;
		margin-top: 10px;
		padding: 0 4px;
	}

	.annotation-row {
		display: flex;
		align-items: center;
		gap: 8px;
	}

	.annotation-num {
		width: 18px;
		height: 18px;
		background: #F97316;
		border-radius: 50%;
		color: white;
		font-size: 9px;
		font-weight: 700;
		display: flex;
		align-items: center;
		justify-content: center;
		flex-shrink: 0;
	}

	.annotation-text {
		color: #9a9a9f;
		font-size: 11px;
	}

	/* Responsive */
	@media (max-width: 700px) {
		.sketch-pane {
			flex-direction: column;
		}

		.sketch-sidebar {
			flex-direction: row;
			width: auto;
			align-items: center;
		}

		.sketch-canvas-wrapper {
			overflow-x: auto;
		}
	}
</style>
