<script lang="ts">
	import '../styles/dialog.css';
	import releasesData from '$lib/data/releases.json';

	// Get latest release from JSON
	const latestRelease = releasesData.releases[0];
	// Show max 4 changes for the hero preview
	const changes = latestRelease.changes.slice(0, 4);

	const typeLabels: Record<string, string> = {
		added: 'New',
		changed: 'Updated',
		fixed: 'Fixed',
		removed: 'Removed'
	};
</script>

<div class="perspective-container">
	<div class="perspective-scene">
		<div class="dialog-wrapper">
			<div class="dialog-window update-dialog">
				<div class="window-header">
					<div class="traffic-lights">
						<span class="light red"></span>
						<span class="light yellow"></span>
						<span class="light green"></span>
					</div>
				</div>

				<div class="dialog-body">
					<div class="icon-circle">
						<span class="icon">↑</span>
					</div>
					<div class="dialog-title">Update Consult User MCP?</div>
					<div class="dialog-text">Version {latestRelease.version} is now available</div>

					<div class="changelog">
						{#each changes as change}
							<div class="change-item {change.type}">
								<span class="change-badge">{typeLabels[change.type]}</span>
								<span class="change-text">{change.text}</span>
							</div>
						{/each}
					</div>

					<div class="button-row">
						<button class="btn secondary">Later</button>
						<a href="https://github.com/doublej/consult-user-mcp/releases/tag/v{latestRelease.version}" class="btn primary" target="_blank" rel="noopener">Update <span class="key-hint">&#x23CE;</span></a>
					</div>
				</div>

				<div class="keyboard-hints">
					<span class="hint"><kbd>&#x23CE;</kbd> update</span>
					<span class="hint"><kbd>Esc</kbd> later</span>
					<span class="hint"><kbd>S</kbd> snooze</span>
				</div>
			</div>
		</div>
	</div>
</div>

<style>
	.perspective-container {
		position: relative;
		padding: 20px;
		overflow: visible;
	}

	.perspective-scene {
		perspective: 1000px;
		perspective-origin: 15% 50%;
		display: flex;
		justify-content: center;
	}

	.dialog-wrapper {
		position: relative;
		transform-style: preserve-3d;
		transform: rotateY(-25deg) rotateX(6deg) translateZ(0);
		animation: floatIn 1.2s cubic-bezier(0.23, 1, 0.32, 1) forwards;
	}

	@keyframes floatIn {
		from {
			opacity: 0;
			transform: rotateY(-40deg) rotateX(12deg) translateZ(-100px) translateY(30px);
		}
		to {
			opacity: 1;
			transform: rotateY(-25deg) rotateX(6deg) translateZ(0) translateY(0);
		}
	}

	/* Override dialog-window for this context */
	.dialog-wrapper :global(.dialog-window) {
		max-width: 360px;
		box-shadow:
			0 40px 80px -20px rgba(0, 0, 0, 0.4),
			0 25px 50px -25px rgba(0, 0, 0, 0.3),
			0 0 0 1px rgba(255, 255, 255, 0.06) inset,
			-30px 0 60px -20px rgba(90, 140, 255, 0.15),
			15px 15px 30px -10px rgba(0, 0, 0, 0.25);
		transform-style: preserve-3d;
		backface-visibility: hidden;
	}

	/* Update dialog specific styles */
	.update-dialog {
		max-width: 360px;
	}

	/* Icon styling */
	.icon-circle {
		width: 48px;
		height: 48px;
		border-radius: 50%;
		background: linear-gradient(135deg, #34C759 0%, #30B350 100%);
		display: flex;
		align-items: center;
		justify-content: center;
		margin: 0 auto 10px;
		box-shadow: 0 6px 20px rgba(52, 199, 89, 0.35);
	}

	.icon {
		color: white;
		font-size: 24px;
		font-weight: 700;
	}

	.dialog-title {
		color: white;
		font-size: 16px;
		font-weight: 600;
		text-align: center;
		letter-spacing: -0.02em;
	}

	.dialog-text {
		color: #9a9a9f;
		font-size: 13px;
		text-align: center;
		line-height: 1.5;
	}

	/* Changelog styles */
	.changelog {
		display: flex;
		flex-direction: column;
		gap: 6px;
		margin-top: 4px;
	}

	.change-item {
		display: flex;
		align-items: flex-start;
		gap: 8px;
		font-size: 12px;
		color: #b0b0b5;
		line-height: 1.4;
	}

	.change-badge {
		font-size: 9px;
		font-weight: 600;
		padding: 2px 5px;
		border-radius: 4px;
		text-transform: uppercase;
		letter-spacing: 0.02em;
		flex-shrink: 0;
		margin-top: 1px;
	}

	.change-item.added .change-badge {
		background: rgba(52, 199, 89, 0.2);
		color: #34C759;
	}

	.change-item.fixed .change-badge {
		background: rgba(255, 149, 0, 0.2);
		color: #FF9500;
	}

	.change-item.changed .change-badge {
		background: rgba(90, 140, 255, 0.2);
		color: #5A8CFF;
	}

	.change-text {
		color: #c0c0c5;
	}

	/* Non-interactive buttons */
	:global(.btn.secondary) {
		cursor: default;
	}

	/* Make primary button clickable */
	a.btn.primary {
		text-decoration: none;
		cursor: pointer;
	}

	a.btn.primary:hover {
		filter: brightness(1.1);
	}
</style>
