<script lang="ts">
	import '../styles/dialog.css';

	let selectedSnooze = $state('15m');
	let feedbackText = $state('Try a different approach');
</script>

<div class="feature-panels">
	<!-- Snooze Panel -->
	<div class="panel-wrapper">
		<div class="dialog-window compact">
			<div class="window-header">
				<div class="traffic-lights">
					<span class="light red"></span>
					<span class="light yellow"></span>
					<span class="light green"></span>
				</div>
			</div>

			<div class="dialog-body">
				<div class="dialog-text question">Deploy to production now?</div>
				<div class="button-row">
					<button class="btn secondary">Cancel</button>
					<button class="btn primary">Confirm <span class="key-hint">&#x23CE;</span></button>
				</div>
			</div>

			<!-- Toolbar with snooze expanded -->
			<div class="toolbar">
				<div class="toolbar-expanded">
					<div class="toolbar-label">Ask me again in:</div>
					<div class="snooze-row">
						{#each ['1m', '5m', '15m', '30m', '1h'] as duration}
							<button
								class="snooze-pill"
								class:selected={selectedSnooze === duration}
								onclick={() => selectedSnooze = duration}
							>
								{duration}
							</button>
						{/each}
					</div>
				</div>
				<div class="toolbar-buttons">
					<button class="toolbar-btn active">
						<span class="toolbar-icon">&#x21BA;</span>
						<span class="toolbar-btn-label">Snooze</span>
					</button>
					<button class="toolbar-btn">
						<span class="toolbar-icon">&#x1F4AC;</span>
						<span class="toolbar-btn-label">Feedback</span>
					</button>
				</div>
			</div>

			<div class="keyboard-hints">
				<span class="hint"><kbd>&#x23CE;</kbd> confirm</span>
				<span class="hint"><kbd>Esc</kbd> cancel</span>
				<span class="hint"><kbd>S</kbd> snooze</span>
				<span class="hint"><kbd>F</kbd> feedback</span>
			</div>
		</div>
		<div class="panel-caption">
			<h3>Snooze</h3>
			<p>Defer the dialog from 1 minute to 1 hour. The agent automatically retries when time is up.</p>
		</div>
	</div>

	<!-- Feedback Panel -->
	<div class="panel-wrapper">
		<div class="dialog-window compact">
			<div class="window-header">
				<div class="traffic-lights">
					<span class="light red"></span>
					<span class="light yellow"></span>
					<span class="light green"></span>
				</div>
			</div>

			<div class="dialog-body">
				<div class="dialog-text question">Deploy to production now?</div>
				<div class="button-row">
					<button class="btn secondary">Cancel</button>
					<button class="btn primary">Confirm <span class="key-hint">&#x23CE;</span></button>
				</div>
			</div>

			<!-- Toolbar with feedback expanded -->
			<div class="toolbar">
				<div class="toolbar-expanded">
					<div class="toolbar-label">Send feedback to agent:</div>
					<div class="feedback-row">
						<input
							class="feedback-field"
							type="text"
							placeholder="Type your feedback..."
							bind:value={feedbackText}
						/>
						<button class="send-btn" disabled={!feedbackText.trim()}>Send</button>
					</div>
				</div>
				<div class="toolbar-buttons">
					<button class="toolbar-btn">
						<span class="toolbar-icon">&#x21BA;</span>
						<span class="toolbar-btn-label">Snooze</span>
					</button>
					<button class="toolbar-btn active">
						<span class="toolbar-icon">&#x1F4AC;</span>
						<span class="toolbar-btn-label">Feedback</span>
					</button>
				</div>
			</div>

			<div class="keyboard-hints">
				<span class="hint"><kbd>&#x23CE;</kbd> confirm</span>
				<span class="hint"><kbd>Esc</kbd> cancel</span>
				<span class="hint"><kbd>S</kbd> snooze</span>
				<span class="hint"><kbd>F</kbd> feedback</span>
			</div>
		</div>
		<div class="panel-caption">
			<h3>Feedback</h3>
			<p>Send text feedback to redirect the agent without fully canceling the current operation.</p>
		</div>
	</div>
</div>

<style>
	.feature-panels {
		display: grid;
		grid-template-columns: repeat(2, 1fr);
		gap: 48px;
		max-width: 900px;
		margin: 32px auto 0;
	}

	.panel-wrapper {
		display: flex;
		flex-direction: column;
		gap: 20px;
		align-items: center;
	}

	.dialog-window.compact {
		max-width: 380px;
		width: 100%;
	}

	.panel-caption {
		text-align: center;
	}

	.panel-caption h3 {
		font-size: 1.1rem;
		font-weight: 600;
		color: #1a1a1a;
		margin: 0 0 8px;
	}

	.panel-caption p {
		font-size: 0.9rem;
		color: #606060;
		margin: 0;
		line-height: 1.5;
	}

	/* Toolbar - matches Swift DialogToolbar */
	.toolbar {
		background: #242428;
	}

	.toolbar-expanded {
		padding: 12px 20px;
	}

	.toolbar-label {
		font-size: 12px;
		font-weight: 500;
		color: #9a9a9f;
		margin-bottom: 8px;
	}

	/* Snooze row - horizontal compact pills matching Swift SnoozeButton */
	.snooze-row {
		display: flex;
		gap: 8px;
	}

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
		cursor: pointer;
		transition: all 0.15s ease;
		font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.snooze-pill:hover {
		background: #5A8CFF;
		color: white;
	}

	.snooze-pill.selected {
		background: #5A8CFF;
		border-color: #5A8CFF;
		color: white;
	}

	/* Feedback row - horizontal text field + send button matching Swift */
	.feedback-row {
		display: flex;
		gap: 8px;
	}

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

	.feedback-field:focus {
		border-color: #5A8CFF;
	}

	.feedback-field::placeholder {
		color: #666666;
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
		cursor: pointer;
		font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
	}

	.send-btn:disabled {
		opacity: 0.5;
	}

	/* Toolbar buttons row - matches Swift ToolbarButton */
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
		cursor: pointer;
		font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
	}

	.toolbar-icon {
		font-size: 12px;
		color: #9a9a9f;
	}

	.toolbar-btn-label {
		font-size: 12px;
		font-weight: 500;
		color: #9a9a9f;
	}

	.toolbar-btn.active {
		background: rgba(90, 140, 255, 0.15);
	}

	.toolbar-btn.active .toolbar-icon,
	.toolbar-btn.active .toolbar-btn-label {
		color: #5A8CFF;
	}

	@media (max-width: 900px) {
		.feature-panels {
			grid-template-columns: 1fr;
			gap: 48px;
			padding: 0 20px;
		}

		.dialog-window.compact {
			max-width: 100%;
		}
	}
</style>
