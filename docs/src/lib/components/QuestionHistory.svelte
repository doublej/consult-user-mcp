<script lang="ts">
	import '../styles/dialog.css';

	interface HistoryEntry {
		type: 'confirm' | 'choose' | 'textInput' | 'questions';
		question: string;
		options?: string[];
		description?: string;
		answer?: string;
	}

	// Curated real questions from developer's history
	const entries: HistoryEntry[] = [
		{
			type: 'choose',
			question: 'Which dialog types should we test next?',
			options: ['Confirmation', 'Multiple choice', 'Questions', 'Text input'],
			answer: 'Questions',
			description: 'Testing the newly built history feature'
		},
		{
			type: 'confirm',
			question: 'This is a test confirmation dialog. Does the history feature work correctly?',
			answer: 'Yes',
			description: 'Validating new functionality'
		},
		{
			type: 'textInput',
			question: 'What improvements would you like to see in the history detail view?',
			answer: 'i dont see new history showing up',
			description: 'Bug report via free-form text'
		},
		{
			type: 'choose',
			question: 'Which reflection approach would you prefer?',
			options: [
				'CSS gradient (simple fade)',
				'DOM duplicate with perspective',
				'No reflection (cleaner look)'
			],
			answer: 'DOM duplicate with perspective',
			description: 'Designing the homepage dialog gallery'
		},
		{
			type: 'choose',
			question: 'For the text info below covers - should it also be reflected?',
			options: [
				'Cover only (simpler)',
				'Cover + text (full reflection)',
				'No reflection at all'
			],
			answer: 'Cover + text (full reflection)',
			description: 'Refining the visual design'
		},
		{
			type: 'choose',
			question: 'What version for this release?',
			options: [
				'1.3.3 (patch - bug fix)',
				'1.4.0 (minor - new feature)',
				'2.0.0 (major - breaking change)'
			],
			answer: '1.4.0 (minor - new feature)',
			description: 'Semantic versioning decision'
		},
		{
			type: 'choose',
			question: 'What should replace the emoji icons?',
			options: [
				'SVG icons from icon library',
				'Custom designed icons',
				'Remove icons entirely'
			],
			answer: 'Remove icons entirely',
			description: 'UI simplification choice'
		},
		{
			type: 'choose',
			question: 'How should we structure the single source of truth for releases?',
			options: [
				'releases.json feeds everything',
				'Separate files synced manually',
				'Git tags as source'
			],
			answer: 'releases.json feeds everything',
			description: 'Documentation architecture decision'
		},
		{
			type: 'choose',
			question: 'How should we handle the CHANGELOG.md vs releases.json redundancy?',
			options: [
				'Auto-generate CHANGELOG.md from releases.json',
				'Keep both, manual sync',
				'Remove CHANGELOG.md entirely'
			],
			answer: 'Auto-generate CHANGELOG.md from releases.json',
			description: 'Eliminating manual synchronization'
		},
		{
			type: 'choose',
			question: 'Choose your Slack authentication method',
			options: [
				'xoxc/xoxd - Extract tokens from browser',
				'xoxp - Create Slack app with User OAuth',
				'xoxb - Bot token (limited to invited channels)'
			],
			description: 'Configuring Slack MCP integration'
		},
		{
			type: 'choose',
			question: 'The changes add "feedback with partial answers". Should we add test cases for this?',
			options: [
				'Yes, comprehensive tests',
				'Yes, basic smoke tests',
				'No, skip for now'
			],
			answer: 'No, skip for now',
			description: 'Test coverage prioritization'
		},
		{
			type: 'choose',
			question: 'Where should the invite link be displayed?',
			options: [
				'Below room code (always visible)',
				'In a collapsible panel',
				'Both places'
			],
			answer: 'Both places',
			description: 'UI placement for multiplayer game'
		},
		{
			type: 'choose',
			question: 'What should the playlist manager do?',
			options: [
				'Admin UI to create/edit playlists',
				'Import from Spotify API',
				'Auto-generate from music library'
			],
			description: 'Planning new feature scope'
		},
		{
			type: 'questions',
			question: 'Which linting/formatting tool?',
			options: [
				'Run verification before commit?',
				'Tool: ESLint+Prettier / Biome / None',
				'Pre-commit hooks: lefthook / husky / none'
			],
			description: 'Project setup configuration wizard'
		},
		{
			type: 'confirm',
			question: 'Biome crashes on some Svelte files (known bug). Should I exclude .svelte files and use svelte-check instead?',
			answer: 'Yes',
			description: 'Workaround for tooling limitation'
		},
		{
			type: 'choose',
			question: 'How should agents communicate their project context to the app?',
			options: [
				'New MCP tool parameter on all calls',
				'Environment variable at startup',
				'Use process.cwd() automatically'
			],
			answer: 'Use process.cwd() automatically',
			description: 'Simplifying the integration'
		},
		{
			type: 'choose',
			question: 'Which feedback service should I set up?',
			options: [
				'GitHub Issues link (simplest)',
				'Formspree (email notifications)',
				'Custom backend with database'
			],
			answer: 'Formspree (email notifications)',
			description: 'User feedback infrastructure'
		},
		{
			type: 'choose',
			question: 'How should the feedback form appear?',
			options: [
				'Floating button + modal',
				'Link in footer/menu',
				'Dedicated page/route'
			],
			description: 'User feedback mechanism design'
		},
		{
			type: 'choose',
			question: 'When clients don\'t pass project_path, what should happen?',
			options: [
				'Show badge with "Unknown Project"',
				'No badge (opt-in only)',
				'Use current directory as fallback'
			],
			answer: 'No badge (opt-in only)',
			description: 'Default behavior for optional parameter'
		},
		{
			type: 'choose',
			question: '914 files changed - mostly artist images + playlists. How to proceed?',
			options: [
				'One big commit (faster)',
				'Smart-commit: separate by type',
				'Manual review: commit selectively'
			],
			answer: 'Smart-commit: separate by type',
			description: 'Large changeset organization'
		},
		{
			type: 'choose',
			question: 'What\'s your primary goal for the redesign?',
			options: [
				'Polished product (Linear, Notion, Raycast)',
				'Keep terminal aesthetic but modernize',
				'Minimal/brutalist design'
			],
			answer: 'Polished product (Linear, Notion, Raycast)',
			description: 'Design direction for app refresh'
		},
		{
			type: 'choose',
			question: 'Color scheme direction?',
			options: [
				'Light by default with dark mode support',
				'Dark by default with light mode',
				'Only dark mode (no light mode)'
			],
			answer: 'Light by default with dark mode support',
			description: 'Accessibility and user preference'
		},
		{
			type: 'choose',
			question: 'The current app has terminal gimmicks: boot sequence, scanlines, ASCII art. Which to keep?',
			options: [
				'Keep ALL — it\'s the brand',
				'Keep SOME — tasteful nods',
				'Remove ALL — clean slate'
			],
			answer: 'Remove ALL — clean slate',
			description: 'Stripping away skeuomorphism'
		},
		{
			type: 'choose',
			question: 'For Svelte 5 component libraries, which direction?',
			options: [
				'shadcn-svelte — best polished look',
				'Skeleton v3 — full design system',
				'Bits UI — headless primitives only'
			],
			answer: 'shadcn-svelte — best polished look',
			description: 'Component library selection'
		},
		{
			type: 'confirm',
			question: 'For the conversation viewer you want: compact density, collapsible tool calls, card-based messages. Is that right?',
			answer: 'Yes',
			description: 'Confirming UX requirements'
		},
		{
			type: 'choose',
			question: 'You have 5 drafts, but 3 are "Untitled". Which should I create short.io links for?',
			options: [
				'Only the 2 titled drafts',
				'All 5 drafts (I\'ll rename later)',
				'None (I\'ll do it manually)'
			],
			answer: 'Only the 2 titled drafts',
			description: 'Batch operation scoping'
		},
		{
			type: 'choose',
			question: 'Typography direction?',
			options: [
				'Sans-serif (Inter, SF Pro)',
				'Keep monospace but refined',
				'Mix: sans for UI, mono for code'
			],
			answer: 'Keep monospace but refined',
			description: 'Balancing personality with polish'
		},
		{
			type: 'questions',
			question: 'How do you like the new history detail view?',
			options: [
				'Feature quality',
				'Navigation ease',
				'Overall satisfaction'
			],
			description: 'Multi-question feedback collection'
		}
	];

	function isSelected(entry: HistoryEntry, option: string): boolean {
		if (!entry.answer) return false;
		return entry.answer.includes(option) || entry.answer === option;
	}
</script>

<div class="history-scroll-container">
	<div class="history-scroll">
		{#each entries as entry, i}
			<div class="dialog-wrapper" style="--delay: {i * 0.05}s">
				<div class="dialog-window">
					<div class="window-header">
						<div class="traffic-lights">
							<span class="light red"></span>
							<span class="light yellow"></span>
							<span class="light green"></span>
						</div>
					</div>

					<div class="dialog-body">
						{#if entry.type === 'confirm'}
							<div class="icon-circle">
								<span class="icon">?</span>
							</div>
							<div class="dialog-title">Confirmation</div>
							<div class="dialog-text">{entry.question}</div>
							<div class="button-row">
								<button class="btn secondary">No</button>
								<button class="btn primary">Yes <span class="key-hint">&#x23CE;</span></button>
							</div>

						{:else if entry.type === 'choose'}
							<div class="dialog-text question">{entry.question}</div>
							<div class="choice-list">
								{#each entry.options || [] as option}
									<div class="choice-item" class:selected={isSelected(entry, option)}>
										<span class="radio" class:checked={isSelected(entry, option)}></span>
										<span class="choice-label">{option}</span>
									</div>
								{/each}
							</div>
							<div class="button-row">
								<button class="btn secondary">Cancel</button>
								<button class="btn primary">Done <span class="key-hint">&#x23CE;</span></button>
							</div>

						{:else if entry.type === 'questions'}
							<div class="progress-bar">
								<div class="progress-segment filled"></div>
								<div class="progress-segment filled"></div>
								<div class="progress-segment"></div>
							</div>
							<div class="step-label">2 of 3</div>
							<div class="dialog-text question">{entry.question}</div>
							<div class="choice-list">
								{#each entry.options || [] as option, idx}
									<div class="choice-item">
										<span class="question-badge">{idx + 1}</span>
										<span class="choice-label">{option}</span>
									</div>
								{/each}
							</div>
							<div class="button-row">
								<button class="btn secondary">Back</button>
								<button class="btn primary">Next <span class="key-hint">&#x23CE;</span></button>
							</div>

						{:else if entry.type === 'textInput'}
							<div class="icon-circle small">
								<span class="icon">&#x270E;</span>
							</div>
							<div class="dialog-title">Input</div>
							<div class="dialog-text">{entry.question}</div>
							<div class="text-input">
								<span class="input-text">{entry.answer || ''}</span>
								<span class="cursor"></span>
							</div>
							<div class="button-row">
								<button class="btn secondary">Cancel</button>
								<button class="btn primary">Submit <span class="key-hint">&#x23CE;</span></button>
							</div>
						{/if}
					</div>

					<div class="keyboard-hints">
						<span class="hint"><kbd>&#x23CE;</kbd> confirm</span>
						<span class="hint"><kbd>Esc</kbd> cancel</span>
						<span class="hint"><kbd>S</kbd> snooze</span>
					</div>
				</div>
				<div class="dialog-caption">
					<div class="caption-text">{entry.description}</div>
				</div>
			</div>
		{/each}
	</div>

	<div class="scroll-hint">
		<span>← Scroll to see more real questions →</span>
	</div>
</div>

<style>
	.history-scroll-container {
		width: 100vw;
		margin-left: calc(-50vw + 50%);
		background: linear-gradient(180deg, #f0f0f0 0%, #fafafa 100%);
		padding: 48px 0;
		margin-top: 32px;
		position: relative;
		overflow: hidden;
	}

	.history-scroll {
		display: flex;
		gap: 32px;
		padding: 0 max(24px, calc((100vw - 1400px) / 2));
		overflow-x: auto;
		scroll-snap-type: x mandatory;
		scroll-padding: max(24px, calc((100vw - 1400px) / 2));
		-webkit-overflow-scrolling: touch;
		scrollbar-width: thin;
		scrollbar-color: #d0d0d0 transparent;
	}

	.history-scroll::-webkit-scrollbar {
		height: 8px;
	}

	.history-scroll::-webkit-scrollbar-track {
		background: transparent;
	}

	.history-scroll::-webkit-scrollbar-thumb {
		background: #d0d0d0;
		border-radius: 4px;
	}

	.history-scroll::-webkit-scrollbar-thumb:hover {
		background: #a0a0a0;
	}

	.dialog-wrapper {
		flex: 0 0 360px;
		scroll-snap-align: start;
		display: flex;
		flex-direction: column;
		gap: 16px;
		opacity: 0;
		animation: fadeInUp 0.5s ease forwards;
		animation-delay: var(--delay);
	}

	@keyframes fadeInUp {
		from {
			opacity: 0;
			transform: translateY(20px);
		}
		to {
			opacity: 1;
			transform: translateY(0);
		}
	}

	.dialog-caption {
		text-align: center;
		padding: 0 12px;
	}

	.caption-text {
		color: #707070;
		font-size: 13px;
		font-style: italic;
		line-height: 1.4;
	}

	.scroll-hint {
		text-align: center;
		padding: 24px 0 0;
		color: #909090;
		font-size: 13px;
		font-weight: 500;
	}

	.scroll-hint span {
		background: white;
		padding: 8px 16px;
		border-radius: 20px;
		display: inline-block;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
	}

	/* Additional dialog styles */
	.icon-circle {
		width: 48px;
		height: 48px;
		border-radius: 50%;
		background: linear-gradient(135deg, #5A8CFF 0%, #4a7cf0 100%);
		display: flex;
		align-items: center;
		justify-content: center;
		margin: 0 auto;
	}

	.icon-circle.small {
		width: 40px;
		height: 40px;
	}

	.icon {
		font-size: 24px;
		color: white;
		font-weight: 600;
	}

	.icon-circle.small .icon {
		font-size: 20px;
	}

	.dialog-title {
		color: white;
		font-size: 16px;
		font-weight: 600;
		text-align: center;
		margin-top: 8px;
	}

	.dialog-text {
		color: #BFBFBF;
		font-size: 13px;
		line-height: 1.5;
		text-align: center;
	}

	.dialog-text.question {
		color: white;
		font-weight: 500;
		margin-bottom: 4px;
	}

	.text-input {
		background: #242428;
		border: 1px solid #3a3a3f;
		border-radius: 10px;
		padding: 10px 12px;
		display: flex;
		align-items: center;
		gap: 2px;
		min-height: 38px;
	}

	.input-text {
		color: white;
		font-size: 13px;
		flex: 1;
	}

	.cursor {
		width: 1px;
		height: 16px;
		background: #5A8CFF;
		animation: blink 1s infinite;
	}

	@keyframes blink {
		0%, 49% { opacity: 1; }
		50%, 100% { opacity: 0; }
	}

	.question-badge {
		width: 20px;
		height: 20px;
		background: #3a3a3f;
		color: #9a9a9f;
		font-size: 11px;
		font-weight: 600;
		border-radius: 4px;
		display: flex;
		align-items: center;
		justify-content: center;
		flex-shrink: 0;
	}

	@media (max-width: 700px) {
		.history-scroll-container {
			padding: 32px 0;
		}

		.history-scroll {
			padding: 0 20px;
			gap: 24px;
			scroll-padding: 20px;
		}

		.dialog-wrapper {
			flex: 0 0 min(320px, calc(100vw - 40px));
		}

		.scroll-hint {
			font-size: 12px;
		}
	}
</style>
