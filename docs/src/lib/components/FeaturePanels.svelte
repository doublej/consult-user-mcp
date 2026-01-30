<script lang="ts">
	import '../styles/dialog.css';

	let selectedSnooze = $state('15min');
	let feedbackText = $state('');
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
				<div class="dialog-text question">Snooze for how long?</div>
				<div class="snooze-options">
					<button
						class="snooze-btn"
						class:selected={selectedSnooze === '1min'}
						onclick={() => selectedSnooze = '1min'}
					>
						1 minute
					</button>
					<button
						class="snooze-btn"
						class:selected={selectedSnooze === '5min'}
						onclick={() => selectedSnooze = '5min'}
					>
						5 minutes
					</button>
					<button
						class="snooze-btn"
						class:selected={selectedSnooze === '15min'}
						onclick={() => selectedSnooze = '15min'}
					>
						15 minutes
					</button>
					<button
						class="snooze-btn"
						class:selected={selectedSnooze === '30min'}
						onclick={() => selectedSnooze = '30min'}
					>
						30 minutes
					</button>
					<button
						class="snooze-btn"
						class:selected={selectedSnooze === '1hour'}
						onclick={() => selectedSnooze = '1hour'}
					>
						1 hour
					</button>
				</div>
				<div class="button-row">
					<button class="btn secondary">Cancel</button>
					<button class="btn primary">Snooze <span class="key-hint">&#x23CE;</span></button>
				</div>
			</div>

			<div class="keyboard-hints">
				<span class="hint"><kbd>&#x23CE;</kbd> confirm</span>
				<span class="hint"><kbd>Esc</kbd> cancel</span>
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
				<div class="dialog-text question">Send feedback to the agent</div>
				<textarea
					class="feedback-input"
					placeholder="Type your feedback here..."
					bind:value={feedbackText}
					rows="4"
				></textarea>
				<div class="feedback-hint">
					The agent will receive this feedback and adjust its approach without canceling the operation.
				</div>
				<div class="button-row">
					<button class="btn secondary">Cancel</button>
					<button class="btn primary">Send <span class="key-hint">&#x23CE;</span></button>
				</div>
			</div>

			<div class="keyboard-hints">
				<span class="hint"><kbd>&#x23CE;</kbd> send</span>
				<span class="hint"><kbd>Esc</kbd> cancel</span>
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

	.snooze-options {
		display: flex;
		flex-direction: column;
		gap: 8px;
		margin-top: 4px;
	}

	.snooze-btn {
		padding: 10px 16px;
		background: #242428;
		border: 1px solid #3a3a3f;
		border-radius: 10px;
		color: #BFBFBF;
		font-size: 13px;
		font-weight: 500;
		cursor: pointer;
		transition: all 0.15s ease;
		font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
	}

	.snooze-btn:hover {
		background: #2a2a30;
		border-color: #4a4a4f;
	}

	.snooze-btn.selected {
		background: #2a2a30;
		border-color: #5A8CFF;
		color: white;
	}

	.feedback-input {
		width: 100%;
		background: #242428;
		border: 1px solid #3a3a3f;
		border-radius: 10px;
		padding: 12px;
		color: white;
		font-size: 13px;
		font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
		resize: vertical;
		min-height: 80px;
		margin-top: 4px;
	}

	.feedback-input::placeholder {
		color: #666666;
	}

	.feedback-input:focus {
		outline: none;
		border-color: #5A8CFF;
	}

	.feedback-hint {
		font-size: 11px;
		color: #666666;
		line-height: 1.4;
		margin-top: 8px;
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
