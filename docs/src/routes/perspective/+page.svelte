<script lang="ts">
	import PerspectiveDialog from '$lib/components/PerspectiveDialog.svelte';
</script>

<svelte:head>
	<title>Perspective Dialog - consult-user-mcp</title>
	<link rel="preconnect" href="https://fonts.googleapis.com">
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous">
	<link href="https://fonts.googleapis.com/css2?family=Instrument+Sans:wght@400;500;600&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
</svelte:head>

<main>
	<h1>Perspective Dialog</h1>
	<p class="desc">A styled UI window viewed from the right</p>
	<PerspectiveDialog />
</main>

<style>
	:global(*) {
		box-sizing: border-box;
	}

	:global(body) {
		margin: 0;
		font-family: 'Instrument Sans', -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
		background: #0a0a0f;
		color: #e0e0e0;
		min-height: 100vh;
		-webkit-font-smoothing: antialiased;
	}

	main {
		max-width: 900px;
		margin: 0 auto;
		padding: 60px 24px;
	}

	h1 {
		font-size: 2rem;
		font-weight: 600;
		color: white;
		margin: 0 0 8px;
		letter-spacing: -0.03em;
	}

	.desc {
		color: #707070;
		margin: 0 0 40px;
		font-size: 1rem;
	}
</style>
