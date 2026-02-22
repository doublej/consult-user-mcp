<script lang="ts">
	import '../styles/dialog.css';

	const dialogs = [
		{ name: 'ask type=confirm', content: 'confirm' },
		{ name: 'ask type=pick', content: 'choices' },
		{ name: 'ask type=form', content: 'wizard' },
		{ name: 'ask type=text', content: 'text' },
		{ name: 'tweak', content: 'tweak' }
	] as const;

	const tweakParams = [
		{ label: 'Card Scale', value: '1.58', unit: 'x', fill: 62 },
		{ label: 'Duration', value: '388', unit: 'ms', fill: 39 },
		{ label: 'Vertical Offset', value: '24.8', unit: 'px', fill: 50 }
	];

	const choiceItems = [
		{ label: 'Dark mode', checked: true },
		{ label: 'Notifications', checked: false },
		{ label: 'Auto-save', checked: true }
	];

	const frameworkOptions = [
		{ label: 'React', selected: false },
		{ label: 'Svelte', selected: true },
		{ label: 'Vue', selected: false }
	];
</script>

<div class="dialog-previews-container">
	<div class="dialog-previews">
		{#each dialogs as dialog, i}
			<div class="preview-wrapper" style="--delay: {i * 0.1}s">
				<div class="dialog-window">
					<div class="window-header">
						<div class="traffic-lights">
							<span class="light red"></span>
							<span class="light yellow"></span>
							<span class="light green"></span>
						</div>
					</div>

					<div class="dialog-body">
						{#if dialog.content === 'confirm'}
							<div class="icon-circle">
								<span class="icon">?</span>
							</div>
							<div class="dialog-title">Confirmation</div>
							<div class="dialog-text">Are you sure you want to proceed with this action?</div>
							<div class="button-row">
								<button class="btn secondary">Cancel</button>
								<button class="btn primary">Confirm <span class="key-hint">&#x23CE;</span></button>
							</div>

						{:else if dialog.content === 'choices'}
							<div class="dialog-text question">Which options do you want to enable?</div>
							<div class="choice-list">
								{#each choiceItems as item}
									<div class="choice-item" class:selected={item.checked}>
										<span class="checkbox" class:checked={item.checked}>{item.checked ? '✓' : ''}</span>
										<span class="choice-label">{item.label}</span>
									</div>
								{/each}
							</div>
							<div class="button-row">
								<button class="btn secondary">Cancel</button>
								<button class="btn primary">Done <span class="key-hint">&#x23CE;</span></button>
							</div>

						{:else if dialog.content === 'wizard'}
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
										<span class="radio" class:checked={option.selected}></span>
										<span class="choice-label">{option.label}</span>
									</div>
								{/each}
							</div>
							<div class="button-row">
								<button class="btn secondary">Back</button>
								<button class="btn primary">Next <span class="key-hint">&#x23CE;</span></button>
							</div>

						{:else if dialog.content === 'text'}
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

						{:else if dialog.content === 'tweak'}
							<div class="icon-circle small">
								<span class="icon slider-icon">≡</span>
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
						{/if}
					</div>

					<div class="keyboard-hints">
						{#if dialog.content === 'tweak'}
							<span class="hint"><kbd>&uarr;&darr;</kbd> navigate</span>
							<span class="hint"><kbd>&larr;&rarr;</kbd> adjust</span>
							<span class="hint"><kbd>Esc</kbd> close</span>
						{:else}
							<span class="hint"><kbd>&#x23CE;</kbd> confirm</span>
							<span class="hint"><kbd>Esc</kbd> cancel</span>
							<span class="hint"><kbd>S</kbd> snooze</span>
						{/if}
					</div>
				</div>
				<code class="tool-name">{dialog.name}</code>
			</div>
		{/each}
	</div>
</div>

<style>
	.dialog-previews-container {
		width: 100vw;
		margin-left: calc(-50vw + 50%);
		background: linear-gradient(180deg, #f0f0f0 0%, #fafafa 100%);
		padding: 48px 24px;
		margin-top: 32px;
	}

	.dialog-previews {
		display: grid;
		grid-template-columns: repeat(5, minmax(0, 1fr));
		gap: 28px;
		max-width: 1600px;
		margin: 0 auto;
	}

	@media (max-width: 1300px) {
		.dialog-previews {
			grid-template-columns: repeat(3, minmax(0, 1fr));
			max-width: 960px;
		}
	}

	@media (max-width: 800px) {
		.dialog-previews {
			grid-template-columns: repeat(2, minmax(0, 1fr));
			max-width: 640px;
		}
	}

	@media (max-width: 500px) {
		.dialog-previews {
			grid-template-columns: minmax(0, 1fr);
			max-width: 340px;
		}
	}

	.preview-wrapper {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 14px;
		animation: fadeUp 0.5s ease-out backwards;
		animation-delay: var(--delay);
	}

	@keyframes fadeUp {
		from {
			opacity: 0;
			transform: translateY(16px);
		}
		to {
			opacity: 1;
			transform: translateY(0);
		}
	}

	/* Override max-width for this component's smaller dialog cards */
	.dialog-window {
		max-width: 320px;
	}

	.icon-circle {
		width: 44px;
		height: 44px;
		border-radius: 50%;
		background: linear-gradient(135deg, #5A8CFF 0%, #4070e0 100%);
		display: flex;
		align-items: center;
		justify-content: center;
		margin: 0 auto 6px;
	}

	.icon-circle.small {
		width: 38px;
		height: 38px;
	}

	.icon {
		color: white;
		font-size: 22px;
		font-weight: 600;
	}

	.dialog-title {
		color: white;
		font-size: 15px;
		font-weight: 600;
		text-align: center;
		letter-spacing: -0.01em;
	}

	.dialog-text {
		color: #9a9a9f;
		font-size: 13px;
		text-align: center;
		line-height: 1.45;
	}

	.dialog-text.question {
		color: white;
		font-weight: 600;
		font-size: 14px;
		text-align: left;
		margin-bottom: 4px;
	}

	/* Override step-label font-size for this component */
	:global(.dialog-window) .step-label {
		font-size: 11px;
	}

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

	/* Non-interactive buttons */
	.btn {
		cursor: default;
	}

	.tool-name {
		font-family: 'DM Mono', 'SF Mono', Monaco, monospace;
		font-size: 12px;
		color: #606060;
		background: #e8e8e8;
		padding: 5px 12px;
		border-radius: 6px;
	}
</style>
