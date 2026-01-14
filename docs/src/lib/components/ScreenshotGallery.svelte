<script lang="ts">
	import { base } from '$app/paths';

	const screenshots = [
		{ src: 'confirm-dialog.png', alt: 'Confirmation dialog' },
		{ src: 'multiselect-features.png', alt: 'Multi-select features' },
		{ src: 'wizard-step1-framework.png', alt: 'Wizard step 1' },
		{ src: 'wizard-step2-styling.png', alt: 'Wizard step 2' },
		{ src: 'accordion-questions.png', alt: 'Accordion questions' },
		{ src: 'confirm-snooze-panel.png', alt: 'Snooze panel' },
		{ src: 'confirm-feedback-panel.png', alt: 'Feedback panel' }
	];

	let currentIndex = $state(0);

	function next() {
		currentIndex = (currentIndex + 1) % screenshots.length;
	}

	function prev() {
		currentIndex = (currentIndex - 1 + screenshots.length) % screenshots.length;
	}

	function getOffset(index: number): number {
		let diff = index - currentIndex;
		if (diff < 0) diff += screenshots.length;
		return diff;
	}

	function getStyles(index: number): string {
		const offset = getOffset(index);

		// Exiting item: continue path smoothly (one step beyond front)
		if (offset > 3) {
			return `
				right: calc(50% + 25px);
				top: -15px;
				opacity: 0;
				pointer-events: none;
				z-index: 0;
			`;
		}

		// Position from right edge, offset moves right and down
		const rightShift = offset * 25;
		const topShift = offset * 15;
		const blur = offset * 0.8;
		const zIndex = 10 - offset;

		return `
			right: calc(50% - ${rightShift}px);
			top: ${topShift}px;
			filter: blur(${blur}px);
			z-index: ${zIndex};
		`;
	}
</script>

<div class="cascade-gallery">
	<div class="stack-container" role="region" aria-label="Screenshot gallery">
		{#each screenshots as screenshot, i}
			<button
				class="stack-item"
				class:active={i === currentIndex}
				style={getStyles(i)}
				onclick={() => currentIndex = i}
				aria-label={screenshot.alt}
				aria-current={i === currentIndex ? 'true' : undefined}
			>
				<img
					src="{base}/screenshots/{screenshot.src}"
					alt={screenshot.alt}
				/>
			</button>
		{/each}
	</div>

	<div class="controls">
		<button class="nav-btn" onclick={prev} aria-label="Previous screenshot">
			<svg width="20" height="20" viewBox="0 0 20 20" fill="none">
				<path d="M12 15L7 10L12 5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
			</svg>
		</button>
		<div class="dots">
			{#each screenshots as _, i}
				<button
					class="dot"
					class:active={i === currentIndex}
					onclick={() => currentIndex = i}
					aria-label="Go to screenshot {i + 1}"
				></button>
			{/each}
		</div>
		<button class="nav-btn" onclick={next} aria-label="Next screenshot">
			<svg width="20" height="20" viewBox="0 0 20 20" fill="none">
				<path d="M8 5L13 10L8 15" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
			</svg>
		</button>
	</div>

	<p class="caption">{screenshots[currentIndex].alt}</p>
</div>

<style>
	.cascade-gallery {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 24px;
	}

	.stack-container {
		position: relative;
		height: 380px;
		width: 100%;
		display: flex;
		align-items: flex-start;
		justify-content: center;
	}

	.stack-item {
		position: absolute;
		top: 0;
		padding: 0;
		border: none;
		background: none;
		cursor: pointer;
		transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
	}

	.stack-item img {
		width: auto;
		height: auto;
		border-radius: 12px;
		zoom: 0.3;
	}

	.stack-item.active {
		cursor: default;
	}

	.stack-item:not(.active):hover {
		filter: blur(0) !important;
	}

	.controls {
		display: flex;
		align-items: center;
		gap: 16px;
	}

	.nav-btn {
		width: 40px;
		height: 40px;
		border-radius: 50%;
		border: 1px solid #d0d0d0;
		background: white;
		color: #606060;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
		transition: all 0.15s ease;
	}

	.nav-btn:hover {
		border-color: #1a1a1a;
		color: #1a1a1a;
		background: #f8f8f8;
	}

	.dots {
		display: flex;
		gap: 8px;
	}

	.dot {
		width: 8px;
		height: 8px;
		border-radius: 50%;
		border: none;
		background: #d0d0d0;
		cursor: pointer;
		padding: 0;
		transition: all 0.2s ease;
	}

	.dot:hover {
		background: #a0a0a0;
	}

	.dot.active {
		background: #5A8CFF;
		transform: scale(1.2);
	}

	.caption {
		color: #707070;
		font-size: 0.9rem;
		margin: 0;
	}

	@media (max-width: 700px) {
		.stack-container {
			height: 220px;
		}

		.stack-item img {
			zoom: 0.2;
		}
	}
</style>
