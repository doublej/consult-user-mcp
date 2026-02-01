<script lang="ts">
	let { children } = $props();
</script>

<svelte:head>
	<link rel="preconnect" href="https://fonts.googleapis.com">
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous">
	<link href="https://fonts.googleapis.com/css2?family=Instrument+Sans:wght@400;500;600&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
</svelte:head>

{@render children()}

<style>
	:global(body) {
		margin: 0;
		padding: 0;
		background: #0a0a0f;
		overflow: hidden;
	}

	:global(*) {
		animation-duration: 0s !important;
		animation-delay: 0s !important;
		transition-duration: 0s !important;
	}
</style>
