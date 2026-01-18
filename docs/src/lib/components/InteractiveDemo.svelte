<script lang="ts">
	import '../styles/dialog.css';
	import TerminalSimulator from './TerminalSimulator.svelte';

	type Question = {
		question: string;
		options: string[];
		selectedIndex: number;
	};

	type Topic = {
		id: string;
		name: string;
		questions: Question[];
	};

	type LineType = 'mcp' | 'response' | 'thinking' | 'info';

	const topics: Topic[] = [
		{
			id: 'build',
			name: 'Build Error',
			questions: [
				{ question: 'Found 3 type errors in auth.ts — how to proceed?', options: ['Fix all now', 'Fix critical only', 'Skip with @ts-ignore'], selectedIndex: 0 },
				{ question: 'Missing return type on loginUser()', options: ['Infer from usage', 'Add Promise<User>', 'Add Promise<void>'], selectedIndex: 1 },
				{ question: 'Unused import: lodash — remove it?', options: ['Yes, remove', 'Keep for now'], selectedIndex: 0 },
				{ question: 'Run tests after fixes?', options: ['Full suite', 'Only affected', 'Skip tests'], selectedIndex: 1 },
				{ question: '2 tests failing — block build?', options: ['Fix before build', 'Build anyway', 'Skip failing tests'], selectedIndex: 0 }
			]
		},
		{
			id: 'camera',
			name: 'Camera Debug',
			questions: [
				{ question: 'Is the flash raised or closed?', options: ['Raised/up', 'Closed', 'Stuck/partial'], selectedIndex: 1 },
				{ question: 'Anything connected to camera?', options: ['Nothing', 'Hot shoe flash', 'USB cable'], selectedIndex: 0 },
				{ question: 'How does the orange lamp blink?', options: ['Steady 1-2/sec', 'Irregular', 'After shot attempt'], selectedIndex: 0 },
				{ question: 'Any warnings on screen?', options: ['Flash warning', 'MIC/REMOTE msg', 'No warnings'], selectedIndex: 2 },
				{ question: 'Power cycle — remove battery 60s?', options: ['Done', 'Skip'], selectedIndex: 0 },
				{ question: 'Result after power cycle?', options: ['Fixed!', 'Same issue', 'Different'], selectedIndex: 1 },
				{ question: 'Pop-up flash reseat — click it?', options: ['Done', 'Skip'], selectedIndex: 0 },
				{ question: 'Result after flash reseat?', options: ['Fixed!', 'Same issue'], selectedIndex: 1 },
				{ question: 'Remove SD card and test?', options: ['Done', 'Skip'], selectedIndex: 0 },
				{ question: 'Result without SD card?', options: ['Fixed!', 'Same issue', 'Different'], selectedIndex: 2 },
				{ question: 'How long until controls work?', options: ['Under 30s', '30-60s', 'Over a minute'], selectedIndex: 2 },
				{ question: 'Try disabling flash mode?', options: ['Testing now', 'Skip'], selectedIndex: 0 },
				{ question: 'Boot time with flash disabled?', options: ['Much faster!', 'Same ~1-2 min', "Can't find setting"], selectedIndex: 0 }
			]
		},
		{
			id: 'recipe',
			name: 'Recipe',
			questions: [
				{ question: "What's your dietary restriction?", options: ['Vegetarian', 'Vegan', 'Gluten-free', 'None'], selectedIndex: 0 },
				{ question: 'Substitute for cream?', options: ['Coconut milk', 'Cashew cream', 'Silken tofu'], selectedIndex: 0 },
				{ question: 'Spice level?', options: ['Mild', 'Medium', 'Hot'], selectedIndex: 1 },
				{ question: 'Portion size?', options: ['2 servings', '4 servings', '6 servings'], selectedIndex: 1 }
			]
		},
		{
			id: 'network',
			name: 'Network',
			questions: [
				{ question: 'Which devices affected?', options: ['All devices', 'Just one', 'Some devices'], selectedIndex: 2 },
				{ question: 'When did issues start?', options: ['Today', 'This week', 'Gradual'], selectedIndex: 0 },
				{ question: 'Router location?', options: ['Central', 'Corner/edge', 'Basement'], selectedIndex: 1 },
				{ question: 'Try rebooting router?', options: ['Done, still issues', 'Fixed it!', "Haven't tried"], selectedIndex: 0 }
			]
		},
		{
			id: 'merge',
			name: 'Git Merge',
			questions: [
				{ question: 'Conflict in auth.ts — keep?', options: ['Ours', 'Theirs', 'Manual'], selectedIndex: 0 },
				{ question: 'Conflict in config.json — keep?', options: ['Ours', 'Theirs', 'Manual'], selectedIndex: 1 },
				{ question: 'Run tests after merge?', options: ['Yes', 'Skip'], selectedIndex: 0 },
				{ question: 'Commit message', options: ['Auto-generate', 'Custom'], selectedIndex: 0 }
			]
		},
		{
			id: 'deploy',
			name: 'Deploy',
			questions: [
				{ question: 'Target environment', options: ['Production', 'Staging', 'Preview'], selectedIndex: 1 },
				{ question: 'Run tests first?', options: ['Yes', 'No', 'Only if changed'], selectedIndex: 0 },
				{ question: 'Notify team', options: ['Slack', 'Email', 'Both', 'None'], selectedIndex: 0 },
				{ question: 'Rollback strategy', options: ['Auto on failure', 'Manual', 'None'], selectedIndex: 0 }
			]
		}
	];

	let selectedTopicId = topics[0].id;
	let currentStep = 0;
	let isActive = false;
	let isComplete = false;
	let terminalLines: Array<{ text: string; type: LineType }> = [];

	$: selectedTopic = topics.find(t => t.id === selectedTopicId)!;
	$: totalSteps = selectedTopic.questions.length;
	$: currentQuestion = selectedTopic.questions[currentStep] ?? selectedTopic.questions[0];

	function selectTopic(topicId: string): void {
		selectedTopicId = topicId;
		startDemo();
	}

	function startDemo(): void {
		isActive = true;
		isComplete = false;
		currentStep = 0;
		terminalLines = [];
		showInitialTerminalState();
	}

	// Auto-start on mount
	$: if (selectedTopicId && !isActive && !isComplete) startDemo();

	function showInitialTerminalState(): void {
		const q = selectedTopic.questions[0];
		addLine(`ask_questions(mode: "wizard", questions: ${totalSteps})`, 'mcp');
		addLine(`Question 1/${totalSteps}: "${q.question}"`, 'info');
		addLine(`Options: ${JSON.stringify(q.options)}`, 'info');
		addLine(`Waiting for user input...`, 'thinking');
	}

	function handleNext(): void {
		if (!isActive || isComplete) return;

		const question = selectedTopic.questions[currentStep];
		const selectedOption = question.options[question.selectedIndex];

		addLine(`User selected: "${selectedOption}"`, 'response');

		if (currentStep >= totalSteps - 1) {
			completeDemo();
		} else {
			currentStep++;
			const nextQ = selectedTopic.questions[currentStep];
			addLine(`Question ${currentStep + 1}/${totalSteps}: "${nextQ.question}"`, 'info');
			addLine(`Options: ${JSON.stringify(nextQ.options)}`, 'info');
		}
	}

	function handleBack(): void {
		if (!isActive || isComplete) return;

		if (currentStep === 0) {
			reset();
		} else {
			currentStep--;
			addLine(`← Back to question ${currentStep + 1}`, 'thinking');
		}
	}

	function completeDemo(): void {
		addLine(`Wizard completed`, 'response');
		const answers = selectedTopic.questions.reduce(
			(acc, q) => ({ ...acc, [q.question.split('?')[0].split(' ').slice(-2).join('_').toLowerCase()]: q.options[q.selectedIndex] }),
			{}
		);
		addLine(`Returning: ${JSON.stringify(answers).slice(0, 60)}...`, 'mcp');
		isComplete = true;
	}

	function reset(): void {
		isActive = false;
		isComplete = false;
		currentStep = 0;
		terminalLines = [];
	}

	function addLine(text: string, type: LineType): void {
		terminalLines = [...terminalLines, { text, type }];
	}

	function getStepLabel(): string {
		if (isComplete) return 'Complete';
		if (isActive) return `${currentStep + 1} of ${totalSteps}`;
		return `${totalSteps} questions`;
	}
</script>

<div class="demo-container">
	<div class="topic-tabs">
		{#each topics as topic}
			<button
				class="topic-tab"
				class:active={selectedTopicId === topic.id}
				onclick={() => selectTopic(topic.id)}
			>
				{topic.name}
			</button>
		{/each}
	</div>

	<div class="demo-split">
		<div class="demo-dialog">
			<div class="dialog-window">
				<div class="window-header">
					<div class="traffic-lights">
						<span class="light red"></span>
						<span class="light yellow"></span>
						<span class="light green"></span>
					</div>
				</div>

				<div class="dialog-body">
					<div class="progress-bar">
						{#each Array(totalSteps) as _, i}
							<div class="progress-segment" class:filled={i < currentStep || (isComplete && i < totalSteps)}></div>
						{/each}
					</div>
					<div class="step-label">{getStepLabel()}</div>

					<div class="question-text">{currentQuestion.question}</div>

					<div class="choice-list">
						{#each currentQuestion.options as option, i}
							{@const isSelected = i === currentQuestion.selectedIndex && (isActive || isComplete)}
							<div class="choice-item" class:selected={isSelected}>
								<span class="radio" class:checked={isSelected}></span>
								<span class="choice-label">{option}</span>
							</div>
						{/each}
					</div>

					<div class="button-row">
						<button class="btn secondary" disabled={!isActive || isComplete} onclick={handleBack}>
							{currentStep === 0 ? 'Cancel' : 'Back'}
						</button>
						<button class="btn primary" disabled={!isActive || isComplete} onclick={handleNext}>
							{currentStep >= totalSteps - 1 ? 'Done' : 'Next'}
							<span class="key-hint">&#x23CE;</span>
						</button>
					</div>
				</div>

				<div class="keyboard-hints">
					<span class="hint"><kbd>&#x2191;&#x2193;</kbd> navigate</span>
					<span class="hint"><kbd>Space</kbd> select</span>
					<span class="hint"><kbd>&#x23CE;</kbd> next</span>
				</div>
			</div>
		</div>

		<div class="demo-terminal">
			<TerminalSimulator lines={terminalLines} isRunning={isActive && !isComplete} />
		</div>
	</div>

	<div class="demo-controls">
		{#if isComplete}
			<button class="control-btn primary" onclick={startDemo}>Restart</button>
		{/if}
	</div>
</div>

<style>
	.demo-container {
		width: 100vw;
		margin-left: calc(-50vw + 50%);
		background: linear-gradient(180deg, #1a1a1f 0%, #0f0f12 100%);
		padding: 48px 24px;
	}

	.topic-tabs {
		display: flex;
		justify-content: center;
		gap: 8px;
		margin-bottom: 32px;
		flex-wrap: wrap;
		padding: 0 16px;
	}

	.topic-tab {
		padding: 10px 20px;
		background: #242428;
		border: 1px solid #3a3a3f;
		border-radius: 8px;
		color: #9a9a9f;
		font-size: 14px;
		font-weight: 500;
		font-family: inherit;
		cursor: pointer;
		transition: all 0.15s ease;
	}

	.topic-tab:hover:not(:disabled) {
		background: #2a2a30;
		color: white;
	}

	.topic-tab.active {
		background: #5A8CFF;
		border-color: #5A8CFF;
		color: white;
	}

	.topic-tab:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}

	.demo-split {
		display: grid;
		grid-template-columns: 360px 1fr;
		gap: 32px;
		max-width: 1000px;
		margin: 0 auto;
		align-items: start;
	}

	@media (max-width: 900px) {
		.topic-tabs {
			gap: 6px;
		}

		.topic-tab {
			padding: 8px 12px;
			font-size: 13px;
		}

		.demo-split {
			grid-template-columns: 1fr;
			max-width: 400px;
		}

		.demo-terminal {
			height: 300px;
			max-height: 300px;
		}
	}

	.demo-dialog {
		display: flex;
		justify-content: center;
	}

	/* Override shadow for dark background context */
	.dialog-window {
		box-shadow:
			0 30px 60px -15px rgba(0, 0, 0, 0.5),
			0 0 0 1px rgba(255, 255, 255, 0.05) inset;
	}

	.question-text {
		color: white;
		font-weight: 600;
		font-size: 15px;
		margin-top: 4px;
	}

	.demo-terminal {
		height: 400px;
		max-height: 400px;
		overflow: hidden;
	}

	.demo-controls {
		display: flex;
		justify-content: center;
		gap: 12px;
		margin-top: 32px;
	}

	.control-btn {
		padding: 12px 32px;
		border-radius: 10px;
		font-size: 14px;
		font-weight: 600;
		font-family: inherit;
		cursor: pointer;
		transition: all 0.15s ease;
		border: none;
	}

	.control-btn.primary {
		background: linear-gradient(135deg, #5A8CFF 0%, #4a7cf0 100%);
		color: white;
		box-shadow: 0 0 20px rgba(90, 140, 255, 0.5);
		animation: pulseGlow 2s ease-in-out infinite;
	}

	@keyframes pulseGlow {
		0%, 100% { box-shadow: 0 0 20px rgba(90, 140, 255, 0.5); }
		50% { box-shadow: 0 0 30px rgba(90, 140, 255, 0.8); }
	}

	.control-btn.primary:hover {
		transform: translateY(-1px);
		box-shadow: 0 0 35px rgba(90, 140, 255, 0.9);
		animation: none;
	}

	.control-btn.secondary {
		background: #2a2a30;
		color: #BFBFBF;
		border: 1px solid #3a3a3f;
	}

	.control-btn.secondary:hover {
		background: #3a3a40;
		color: white;
	}
</style>
