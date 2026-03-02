	<script lang="ts">
		import { cubicIn, cubicOut } from 'svelte/easing';
		import { onMount } from 'svelte';
		import { fly } from 'svelte/transition';
		import '../styles/dialog.css';

	const animationKey = import.meta.hot
		? (import.meta.hot.data.animKey = (import.meta.hot.data.animKey ?? 0) + 1)
		: 0;

	const panes = [
		{ id: 'confirm', label: 'ask type=confirm' },
		{ id: 'choices', label: 'ask type=pick' },
		{ id: 'wizard', label: 'ask type=form' },
		{ id: 'text', label: 'ask type=text' },
		{ id: 'tweak', label: 'tweak' },
		{ id: 'notify', label: 'notify' },
		{ id: 'layout', label: 'propose_layout' }
	] as const;

	const tweakParams = [
		{ label: 'Card Scale', value: '1.58', unit: 'x', fill: 62 },
		{ label: 'Duration', value: '388', unit: 'ms', fill: 39 },
		{ label: 'Vertical Offset', value: '24.8', unit: 'px', fill: 50 }
	];

	const choiceItems = [
		{ label: 'Authentication', description: 'OAuth2 + JWT tokens', checked: true },
		{ label: 'Database ORM', description: 'Prisma with migrations', checked: false },
		{ label: 'Unit Testing', description: 'Jest + React Testing Library', checked: true }
	];

	const frameworkOptions = [
		{ label: 'React', description: 'Component-based UI library', selected: false },
		{ label: 'Svelte', description: 'Compile-time framework', selected: true },
		{ label: 'Vue', description: 'Progressive framework', selected: false }
	];

		const layoutBlocks = [
		{ label: 'Header', x: 0, y: 0, w: 6, h: 1, color: '#3B82F6' },
		{ label: 'Sidebar', x: 0, y: 1, w: 2, h: 3, color: '#8B5CF6' },
		{ label: 'Canvas', x: 2, y: 1, w: 4, h: 2, color: '#10B981' },
		{ label: 'Footer', x: 0, y: 4, w: 6, h: 1, color: '#EF4444' },
		{ label: 'Toolbar', x: 2, y: 3, w: 4, h: 1, color: '#F59E0B' }
		];

		const paneTransitionIn = { y: 12, duration: 360, easing: cubicOut };
		const paneTransitionOut = { y: -8, duration: 260, easing: cubicIn };

		let paneIndex = $state(0);

	onMount(() => {
		if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
		const id = setInterval(() => {
			paneIndex = (paneIndex + 1) % panes.length;
		}, 4000);
		return () => clearInterval(id);
	});
</script>

<div class="perspective-container">
	<div class="perspective-scene">
			{#key animationKey}
			<div class="dialog-wrapper">
				{#key paneIndex}
				<div class="dialog-window" in:fly={paneTransitionIn} out:fly={paneTransitionOut}>
					<div class="dialog-body">
					{#if panes[paneIndex].id === 'confirm'}
						<div class="icon-circle">
							<span class="icon">?</span>
						</div>
						<div class="dialog-title">Deploy to Production</div>
						<div class="dialog-text">You're about to deploy v2.4.1 to production servers.</div>
						<div class="toolbar-inline">
							<span class="toolbar-inline-btn"><span class="toolbar-icon">&#x23F1;</span><span class="toolbar-btn-label">Snooze</span></span>
							<span class="toolbar-inline-btn"><span class="toolbar-icon">&#x25A1;</span><span class="toolbar-btn-label">Feedback</span></span>
						</div>
						<div class="button-row">
							<button class="btn secondary">Cancel</button>
							<button class="btn primary">Deploy Now <span class="key-hint">&#x23CE;</span></button>
						</div>

					{:else if panes[paneIndex].id === 'choices'}
						<div class="dialog-text question">Select features to include:</div>
						<div class="choice-list">
							{#each choiceItems as item}
								<div class="choice-item" class:selected={item.checked}>
									<div class="choice-content">
										<span class="choice-label">{item.label}</span>
										<span class="choice-description">{item.description}</span>
									</div>
									<span class="checkbox" class:checked={item.checked}>{item.checked ? '✓' : ''}</span>
								</div>
							{/each}
						</div>
						<div class="button-row">
							<button class="btn secondary">Cancel</button>
							<button class="btn primary">Done <span class="key-hint">&#x23CE;</span></button>
						</div>

					{:else if panes[paneIndex].id === 'wizard'}
						<div class="progress-bar">
							<div class="progress-segment filled"></div>
							<div class="progress-segment filled"></div>
							<div class="progress-segment"></div>
						</div>
						<div class="step-label">2 of 3</div>
						<div class="dialog-text question">Select your framework</div>
						<div class="choice-list">
							{#each frameworkOptions as option}
								<div class="choice-item" class:selected={option.selected}>
									<div class="choice-content">
										<span class="choice-label">{option.label}</span>
										<span class="choice-description">{option.description}</span>
									</div>
									<span class="radio" class:checked={option.selected}></span>
								</div>
							{/each}
						</div>
						<div class="button-row">
							<button class="btn secondary">Back</button>
							<button class="btn primary">Next <span class="key-hint">&#x23CE;</span></button>
						</div>

					{:else if panes[paneIndex].id === 'text'}
						<div class="icon-circle small">
							<span class="icon">&#x270E;</span>
						</div>
						<div class="dialog-title">Input</div>
						<div class="dialog-text">Enter your project name</div>
						<div class="text-input">
							<span class="input-text">my-project</span>
							<span class="cursor"></span>
						</div>
						<div class="button-row">
							<button class="btn secondary">Cancel</button>
							<button class="btn primary">Submit <span class="key-hint">&#x23CE;</span></button>
						</div>

					{:else if panes[paneIndex].id === 'tweak'}
						<div class="icon-circle small">
							<span class="icon slider-icon">&#x2261;</span>
						</div>
						<div class="dialog-title">Debug</div>
						<div class="dialog-text">Tweaking card animation values</div>
						<div class="tweak-params">
							{#each tweakParams as param}
								<div class="tweak-param">
									<div class="param-header">
										<span class="param-label">{param.label}</span>
										<span class="param-value">{param.value}<span class="param-unit">{param.unit}</span></span>
									</div>
									<div class="slider-track">
										<div class="slider-fill" style="width: {param.fill}%"></div>
										<div class="slider-thumb" style="left: {param.fill}%"></div>
									</div>
								</div>
							{/each}
						</div>

					{:else if panes[paneIndex].id === 'notify'}
						<div class="icon-circle">
							<span class="icon">&#x1F514;</span>
						</div>
						<div class="dialog-title">Build Complete</div>
						<div class="dialog-text">Production build finished in 4.2s with 0 errors.</div>
						<div class="notify-badge">Fire-and-forget</div>

					{:else if panes[paneIndex].id === 'layout'}
						<div class="dialog-text question">Dashboard Layout</div>
						<div class="layout-grid">
							{#each layoutBlocks as block}
								<div
									class="layout-block"
									style="
										grid-column: {block.x + 1} / span {block.w};
										grid-row: {block.y + 1} / span {block.h};
										--block-color: {block.color};
									"
								>
									<span class="block-label">{block.label}</span>
								</div>
							{/each}
						</div>
						<div class="button-row">
							<button class="btn secondary">Reset</button>
							<button class="btn primary">Save <span class="key-hint">&#x23CE;</span></button>
						</div>
					{/if}
				</div>

				{#if panes[paneIndex].id !== 'notify'}
				<div class="keyboard-hints">
					{#if panes[paneIndex].id === 'tweak'}
						<span class="hint"><kbd>&uarr;&darr;</kbd> navigate</span>
						<span class="hint"><kbd>&larr;&rarr;</kbd> adjust</span>
						<span class="hint"><kbd>Esc</kbd> close</span>
					{:else if panes[paneIndex].id === 'layout'}
						<span class="hint"><kbd>drag</kbd> move</span>
						<span class="hint"><kbd>&#x23CE;</kbd> save</span>
						<span class="hint"><kbd>Esc</kbd> cancel</span>
					{:else}
						<span class="hint"><kbd>&#x23CE;</kbd> confirm</span>
						<span class="hint"><kbd>Esc</kbd> cancel</span>
						<span class="hint"><kbd>S</kbd> snooze</span>
					{/if}
				</div>
					{/if}
					</div>
				{/key}
				</div>
			{/key}
		</div>
	</div>

<style>
	.perspective-container {
		position: relative;
		padding: 0px;
		margin-right: -124px;
		overflow: visible;
	}

	.perspective-scene {
		perspective: 1000px;
		perspective-origin: 60% 50%;
		display: flex;
		justify-content: center;
	}

	.dialog-wrapper {
		position: relative;
		display: flex;
		justify-content: center;
		transform-style: preserve-3d;
		transform: rotateY(-10deg) rotateX(3deg) translateZ(0);
		animation: floatIn 3.0s cubic-bezier(0.23, 1, 0.32, 1) forwards;
	}

	@keyframes floatIn {
		from {
			opacity: 0;
			transform: rotateY(-30deg) rotateX(-2deg) translateZ(-60px) translateY(20px);
		}
		to {
			opacity: 1;
			transform: rotateY(-10deg) rotateX(3deg) translateZ(0) translateY(0);
		}
	}

	/* Override dialog-window for this context */
	.dialog-wrapper :global(.dialog-window) {
		position: absolute;
		top: 0;
		left: 0;
		right: 0;
		background: rgb(26, 26, 31);
		max-width: 400px;
		min-width: 340px;
		box-shadow:
			0 40px 80px -20px rgba(0, 0, 0, 0.4),
			0 25px 50px -25px rgba(0, 0, 0, 0.3),
			0 0 0 1px rgba(255, 255, 255, 0.06) inset,
			-30px 0 60px -20px rgba(90, 140, 255, 0.15),
			15px 15px 30px -10px rgba(0, 0, 0, 0.25);
		transform-style: preserve-3d;
		backface-visibility: hidden;
	}

		/* Stable height so the wrapper doesn't collapse */
		.dialog-wrapper :global(.dialog-body) {
			min-height: 310px;
		}

		/* Invisible sizer keeps the wrapper's flow height stable */
		.dialog-wrapper::after {
			content: '';
			display: block;
			min-height: 380px;
			width: 340px;
			visibility: hidden;
		}

	/* Icon styling */
	.icon-circle {
		width: 52px;
		height: 52px;
		border-radius: 50%;
		background: #3a3d5c;
		display: flex;
		align-items: center;
		justify-content: center;
		margin: 0 auto 10px;
	}

	.icon-circle.small {
		width: 46px;
		height: 46px;
	}

	.icon {
		color: #7B8FCC;
		font-size: 24px;
		font-weight: 700;
	}

	.dialog-title {
		color: white;
		font-size: 17px;
		font-weight: 700;
		text-align: center;
		letter-spacing: -0.02em;
	}

	.dialog-text {
		color: #9a9a9f;
		font-size: 13px;
		text-align: center;
		line-height: 1.5;
	}

	.dialog-text.question {
		color: white;
		font-weight: 600;
		font-size: 15px;
		text-align: left;
		margin-bottom: 4px;
	}

	/* Text input */
	.text-input {
		background: #1a1a1f;
		border: 1.5px solid #3a3a3f;
		border-radius: 10px;
		padding: 12px 14px;
		display: flex;
		align-items: center;
		gap: 1px;
	}

	.input-text {
		color: #e0e0e0;
		font-size: 13px;
		font-family: 'SF Mono', Monaco, monospace;
	}

	.cursor {
		width: 2px;
		height: 16px;
		background: #5A8CFF;
		animation: blink 1s step-end infinite;
		margin-left: 1px;
	}

	@keyframes blink {
		0%, 100% { opacity: 1; }
		50% { opacity: 0; }
	}

	/* Tweak slider styles */
	.slider-icon {
		font-size: 18px;
		letter-spacing: -1px;
	}

	.tweak-params {
		display: flex;
		flex-direction: column;
		gap: 10px;
	}

	.tweak-param {
		display: flex;
		flex-direction: column;
		gap: 6px;
	}

	.param-header {
		display: flex;
		justify-content: space-between;
		align-items: baseline;
	}

	.param-label {
		color: #BFBFBF;
		font-size: 12px;
	}

	.param-value {
		color: white;
		font-size: 13px;
		font-weight: 600;
		font-variant-numeric: tabular-nums;
	}

	.param-unit {
		color: #666;
		font-size: 11px;
		font-weight: 400;
		margin-left: 2px;
	}

	.slider-track {
		height: 6px;
		background: #2a2a30;
		border-radius: 3px;
		position: relative;
	}

	.slider-fill {
		height: 100%;
		background: linear-gradient(90deg, #5A8CFF 0%, #4a7cf0 100%);
		border-radius: 3px;
	}

	.slider-thumb {
		position: absolute;
		top: 50%;
		transform: translate(-50%, -50%);
		width: 12px;
		height: 12px;
		background: white;
		border-radius: 50%;
		box-shadow: 0 1px 4px rgba(0, 0, 0, 0.4);
	}

		/* Notify badge */
		.notify-badge {
		font-size: 11px;
		font-weight: 500;
		color: #666;
		text-align: center;
		padding: 6px 12px;
		background: rgba(255, 255, 255, 0.04);
		border-radius: 8px;
		border: 1px dashed #3a3a3f;
	}

	/* Layout grid */
	.layout-grid {
		display: grid;
		grid-template-columns: repeat(6, 1fr);
		grid-template-rows: repeat(5, 28px);
		gap: 3px;
	}

	.layout-block {
		background: color-mix(in srgb, var(--block-color) 20%, transparent);
		border: 1px solid color-mix(in srgb, var(--block-color) 40%, transparent);
		border-radius: 4px;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.block-label {
		font-size: 9px;
		font-weight: 500;
		color: rgba(255, 255, 255, 0.6);
	}

	/* Non-interactive buttons */
	:global(.dialog-window) .btn {
		cursor: default;
	}

	@media (max-width: 1200px) {
		.perspective-container {
			margin-right: -84px;
		}
	}

	@media (max-width: 1000px) {
		.perspective-container {
			margin-right: 0;
		}
	}
</style>
