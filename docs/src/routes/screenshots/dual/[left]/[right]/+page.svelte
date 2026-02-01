<script lang="ts">
	import '$lib/styles/dialog.css';
	import DialogPane from '../../../DialogPane.svelte';

	let { data } = $props();
</script>

<div class="viewport">
	<div class="dual-container">
		<div class="pane">
			<DialogPane slide={data.left} scale={1.2} showToolName={false} />
		</div>
		<div class="pane">
			<DialogPane slide={data.right} scale={1.2} showToolName={false} />
		</div>
	</div>
</div>

<style>
	.viewport {
		width: 100vw;
		height: 100vh;
		display: flex;
		align-items: center;
		justify-content: center;
		background: radial-gradient(ellipse at center, #1a1a2e 0%, #0a0a0f 70%);
	}

	.dual-container {
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 60px;
	}

	.pane {
		display: flex;
		flex-direction: column;
		align-items: center;
	}
</style>
