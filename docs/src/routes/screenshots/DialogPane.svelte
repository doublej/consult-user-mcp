<script lang="ts">
	import type { Slide } from './slides.js';

	let { slide, scale = 1.8, showToolName = true }: { slide: Slide; scale?: number; showToolName?: boolean } = $props();
	const isConfirmLike = $derived(
		slide.template === 'confirmation' || slide.template === 'snooze' || slide.template === 'feedback'
	);
</script>

<div class="scaled" style="zoom: {scale}">
	<div class="dialog-window">
		<div class="window-header">
			<div class="traffic-lights">
				<span class="light red"></span>
				<span class="light yellow"></span>
				<span class="light green"></span>
			</div>
		</div>

		<div class="dialog-body">
			{#if isConfirmLike}
				<div class="icon-circle">
					<span class="icon">?</span>
				</div>
				<div class="dialog-title">Confirmation</div>
				<div class="dialog-text">{slide.text}</div>
				<div class="button-row">
					<button class="btn secondary">No</button>
					<button class="btn primary">Yes <span class="key-hint">&#x23CE;</span></button>
				</div>

			{:else if slide.template === 'multiple-choice'}
				<div class="dialog-text question">{slide.question}</div>
				<div class="choice-list">
					{#each slide.choices ?? [] as choice}
						<div class="choice-item" class:selected={choice.selected}>
							<span class="checkbox" class:checked={choice.selected}>
								{#if choice.selected}&#x2713;{/if}
							</span>
							<span class="choice-label">{choice.label}</span>
						</div>
					{/each}
				</div>
				<div class="button-row">
					<button class="btn secondary">Cancel</button>
					<button class="btn primary">Done <span class="key-hint">&#x23CE;</span></button>
				</div>

			{:else if slide.template === 'wizard'}
				<div class="progress-bar">
					{#each Array(slide.totalSteps ?? 3) as _, i}
						<div class="progress-segment" class:filled={i < (slide.step ?? 1)}></div>
					{/each}
				</div>
				<div class="step-label">{slide.step} of {slide.totalSteps}</div>
				<div class="dialog-text question">{slide.question}</div>
				<div class="choice-list">
					{#each slide.choices ?? [] as choice}
						<div class="choice-item" class:selected={choice.selected}>
							<span class="radio" class:checked={choice.selected}></span>
							<span class="choice-label">{choice.label}</span>
						</div>
					{/each}
				</div>
				<div class="button-row">
					<button class="btn secondary">Back</button>
					<button class="btn primary">Next <span class="key-hint">&#x23CE;</span></button>
				</div>

			{:else if slide.template === 'text-input'}
				<div class="icon-circle small">
					<span class="icon">&#x270E;</span>
				</div>
				<div class="dialog-title">Input</div>
				<div class="dialog-text">{slide.text}</div>
				<div class="text-input">
					<span class="input-text">{slide.inputText}</span>
					<span class="cursor"></span>
				</div>
				<div class="button-row">
					<button class="btn secondary">Cancel</button>
					<button class="btn primary">Submit <span class="key-hint">&#x23CE;</span></button>
				</div>
			{/if}
		</div>

		{#if slide.template === 'snooze'}
			<div class="toolbar">
				<div class="toolbar-expanded">
					<div class="toolbar-label">Ask me again in:</div>
					<div class="snooze-row">
						{#each ['1m', '5m', '15m', '30m', '1h'] as duration}
							<button class="snooze-pill" class:selected={duration === slide.selectedDuration}>{duration}</button>
						{/each}
					</div>
				</div>
				<div class="toolbar-buttons">
					<button class="toolbar-btn active">
						<span class="toolbar-icon">&#x21BA;</span>
						<span class="toolbar-btn-label">Snooze</span>
					</button>
					<button class="toolbar-btn">
						<span class="toolbar-icon">&#x270E;</span>
						<span class="toolbar-btn-label">Feedback</span>
					</button>
				</div>
			</div>
		{:else if slide.template === 'feedback'}
			<div class="toolbar">
				<div class="toolbar-expanded">
					<div class="toolbar-label">Send feedback to agent:</div>
					<div class="feedback-row">
						<input class="feedback-field" type="text" value={slide.feedbackText} readonly />
						<button class="send-btn">Send</button>
					</div>
				</div>
				<div class="toolbar-buttons">
					<button class="toolbar-btn">
						<span class="toolbar-icon">&#x21BA;</span>
						<span class="toolbar-btn-label">Snooze</span>
					</button>
					<button class="toolbar-btn active">
						<span class="toolbar-icon">&#x270E;</span>
						<span class="toolbar-btn-label">Feedback</span>
					</button>
				</div>
			</div>
		{/if}

		<div class="keyboard-hints">
			<span class="hint"><kbd>&#x23CE;</kbd> confirm</span>
			<span class="hint"><kbd>Esc</kbd> cancel</span>
			<span class="hint"><kbd>S</kbd> snooze</span>
			{#if slide.template === 'snooze' || slide.template === 'feedback'}
				<span class="hint"><kbd>F</kbd> feedback</span>
			{/if}
		</div>
	</div>

	{#if showToolName}
		<code class="tool-name">{slide.toolName}</code>
	{/if}
</div>

<style>
	.scaled {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 14px;
	}

	.dialog-window { max-width: 360px; }

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

	.icon-circle.small { width: 38px; height: 38px; }

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

	.step-label { font-size: 11px; }

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
		margin-left: 1px;
	}

	.btn { cursor: default; }

	.tool-name {
		font-family: 'DM Mono', 'SF Mono', Monaco, monospace;
		font-size: 12px;
		color: #606060;
		background: rgba(255, 255, 255, 0.08);
		padding: 5px 12px;
		border-radius: 6px;
	}

	.toolbar { background: #242428; }
	.toolbar-expanded { padding: 12px 20px; }

	.toolbar-label {
		font-size: 12px;
		font-weight: 500;
		color: #9a9a9f;
		margin-bottom: 8px;
	}

	.snooze-row { display: flex; gap: 8px; }

	.snooze-pill {
		padding: 0;
		width: 48px;
		height: 36px;
		background: #242428;
		border: 1px solid #3a3a3f;
		border-radius: 8px;
		color: #e0e0e0;
		font-size: 13px;
		font-weight: 600;
		cursor: default;
		font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.snooze-pill.selected {
		background: #5A8CFF;
		border-color: #5A8CFF;
		color: white;
	}

	.feedback-row { display: flex; gap: 8px; }

	.feedback-field {
		flex: 1;
		background: #1a1a1f;
		border: 1.5px solid #3a3a3f;
		border-radius: 10px;
		padding: 0 14px;
		height: 40px;
		color: #e0e0e0;
		font-size: 13px;
		font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
		outline: none;
	}

	.send-btn {
		width: 70px;
		height: 40px;
		background: linear-gradient(135deg, #5A8CFF 0%, #4a7cf0 100%);
		border: none;
		border-radius: 10px;
		color: white;
		font-size: 13px;
		font-weight: 500;
		cursor: default;
		font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
	}

	.toolbar-buttons {
		display: flex;
		gap: 12px;
		padding: 8px 20px;
	}

	.toolbar-btn {
		display: flex;
		align-items: center;
		gap: 6px;
		padding: 6px 12px;
		background: transparent;
		border: none;
		border-radius: 8px;
		cursor: default;
		font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
	}

	.toolbar-icon { font-size: 12px; color: #9a9a9f; }
	.toolbar-btn-label { font-size: 12px; font-weight: 500; color: #9a9a9f; }

	.toolbar-btn.active { background: rgba(90, 140, 255, 0.15); }
	.toolbar-btn.active .toolbar-icon,
	.toolbar-btn.active .toolbar-btn-label { color: #5A8CFF; }
</style>
