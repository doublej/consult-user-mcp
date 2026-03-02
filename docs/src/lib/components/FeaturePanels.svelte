<script lang="ts">
	import '../styles/dialog.css';

	let selectedSnooze = $state('5m');
	let feedbackText = $state('Deploy 2.4.0 please');
</script>

<div class="feature-panels">
	<!-- Snooze Panel -->
	<div class="panel-wrapper">
		<div class="dialog-window compact">
			<div class="dialog-body">
				<div class="icon-circle">
					<span class="icon">?</span>
				</div>
				<div class="dialog-title">Deploy to Production</div>
				<div class="dialog-text">You're about to deploy v2.4.1 to production servers.</div>

				<!-- Snooze expanded content -->
				<div class="snooze-section">
					<div class="section-label">Ask me again in:</div>
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

				<div class="toolbar-inline">
					<span class="toolbar-inline-btn active">
						<span class="toolbar-icon">&#x23F1;</span>
						<span class="toolbar-btn-label">Snooze</span>
					</span>
					<span class="toolbar-inline-btn">
						<span class="toolbar-icon">&#x25A1;</span>
						<span class="toolbar-btn-label">Feedback</span>
					</span>
				</div>

				<div class="button-row">
					<button class="btn secondary">Cancel</button>
					<button class="btn primary">Deploy Now <span class="key-hint">&#x23CE;</span></button>
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
			<p>Defer for 1 minute to 1 hour. The agent re-asks automatically when time is up.</p>
		</div>
	</div>

	<!-- Feedback Panel -->
	<div class="panel-wrapper">
		<div class="dialog-window compact">
			<div class="dialog-body">
				<div class="icon-circle">
					<span class="icon">?</span>
				</div>
				<div class="dialog-title">Deploy to Production</div>
				<div class="dialog-text">You're about to deploy v2.4.1 to production servers.</div>

				<!-- Feedback expanded content -->
				<div class="feedback-section">
					<div class="section-label">Send feedback to agent:</div>
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

				<div class="toolbar-inline">
					<span class="toolbar-inline-btn">
						<span class="toolbar-icon">&#x23F1;</span>
						<span class="toolbar-btn-label">Snooze</span>
					</span>
					<span class="toolbar-inline-btn active">
						<span class="toolbar-icon">&#x25A1;</span>
						<span class="toolbar-btn-label">Feedback</span>
					</span>
				</div>

				<div class="button-row">
					<button class="btn secondary">Cancel</button>
					<button class="btn primary">Deploy Now <span class="key-hint">&#x23CE;</span></button>
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
			<p>Tell the agent to change course without cancelling the dialog.</p>
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
		color: #262d40;
		margin: 0 0 8px;
	}

	.panel-caption p {
		font-size: 0.9rem;
		color: #616b84;
		margin: 0;
		line-height: 1.5;
	}

	/* Icon circle - dark navy like real UI */
	.icon-circle {
		width: 48px;
		height: 48px;
		border-radius: 50%;
		background: #3a3d5c;
		display: flex;
		align-items: center;
		justify-content: center;
		margin: 0 auto 6px;
	}

	.icon {
		color: #7B8FCC;
		font-size: 22px;
		font-weight: 700;
	}

	.dialog-title {
		color: white;
		font-size: 17px;
		font-weight: 700;
		text-align: center;
	}

	.dialog-text {
		color: #9a9a9f;
		font-size: 13px;
		text-align: center;
		line-height: 1.45;
	}

	/* Active state for toolbar inline buttons */
	.toolbar-inline-btn.active {
		background: rgba(90, 140, 255, 0.15);
		padding: 4px 12px;
		border-radius: 8px;
	}

	.toolbar-inline-btn.active .toolbar-icon,
	.toolbar-inline-btn.active .toolbar-btn-label {
		color: #5A8CFF;
	}

	/* Section label shared between snooze/feedback */
	.section-label {
		font-size: 13px;
		font-weight: 500;
		color: #e0e0e0;
		margin-bottom: 8px;
	}

	/* Snooze row */
	.snooze-section {
		padding: 4px 0 0;
	}

	.snooze-row {
		display: flex;
		gap: 8px;
	}

	.snooze-pill {
		padding: 0;
		width: 52px;
		height: 38px;
		background: #2a2a30;
		border: 1.5px solid #3a3a3f;
		border-radius: 10px;
		color: #e0e0e0;
		font-size: 14px;
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

	/* Feedback row */
	.feedback-section {
		padding: 4px 0 0;
	}

	.feedback-row {
		display: flex;
		gap: 8px;
	}

	.feedback-field {
		flex: 1;
		background: #1a1a1f;
		border: 1.5px solid #5A8CFF;
		border-radius: 10px;
		padding: 0 14px;
		height: 40px;
		color: #e0e0e0;
		font-size: 13px;
		font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
		outline: none;
	}

	.feedback-field::placeholder {
		color: #666666;
	}

	.send-btn {
		width: 70px;
		height: 40px;
		background: #5A8CFF;
		border: none;
		border-radius: 10px;
		color: white;
		font-size: 14px;
		font-weight: 600;
		cursor: pointer;
		font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
	}

	.send-btn:disabled {
		opacity: 0.5;
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
