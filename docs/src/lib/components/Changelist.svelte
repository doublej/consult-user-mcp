<script lang="ts">
	import releasesData from '$lib/data/releases.json';

	type ChangeItem = {
		text: string;
		type: 'added' | 'changed' | 'fixed' | 'removed';
	};

	type Release = {
		version: string;
		date: string;
		highlight?: string;
		changes: ChangeItem[];
	};

	const releases: Release[] = releasesData.releases as Release[];

	const typeLabels: Record<string, string> = {
		added: 'New',
		changed: 'Updated',
		fixed: 'Fixed',
		removed: 'Removed'
	};
</script>

<div class="changelist">
	{#each releases as release, i}
		<div class="release" class:latest={i === 0} class:compact={i > 0}>
			<div class="release-header">
				<a href="https://github.com/doublej/consult-user-mcp/releases/tag/v{release.version}" class="version" target="_blank" rel="noopener">v{release.version}</a>
				{#if i === 0}
					<span class="badge">Latest</span>
				{/if}
				<span class="date">{release.date}</span>
			</div>
			{#if release.highlight}
				<p class="highlight">{release.highlight}</p>
			{/if}
			{#if i === 0}
				<ul class="changes">
					{#each release.changes as change}
						<li class="change {change.type}">
							<span class="type-badge">{typeLabels[change.type]}</span>
							<span class="change-text">{change.text}</span>
						</li>
					{/each}
				</ul>
			{/if}
		</div>
	{/each}
</div>

<style>
	.changelist {
		display: flex;
		flex-direction: column;
		gap: 16px;
	}

	.release {
		background: #fff;
		border: 1px solid #d0d0d0;
		padding: 16px;
	}

	.release.latest {
		border-color: #1a1a1a;
		padding: 20px;
	}

	.release.compact {
		padding: 12px 16px;
	}

	.release.compact .release-header {
		margin-bottom: 0;
	}

	.release.compact .highlight {
		margin: 6px 0 0;
		font-size: 0.85rem;
		font-weight: 400;
		color: #707070;
	}

	.release-header {
		display: flex;
		align-items: center;
		gap: 10px;
		margin-bottom: 8px;
	}

	.version {
		font-family: 'DM Mono', monospace;
		font-size: 0.95rem;
		font-weight: 500;
		color: #1a1a1a;
		text-decoration: none;
	}

	.version:hover {
		text-decoration: underline;
	}

	.badge {
		background: #1a1a1a;
		color: #fff;
		font-size: 0.7rem;
		font-weight: 500;
		padding: 2px 8px;
		text-transform: uppercase;
		letter-spacing: 0.03em;
	}

	.date {
		color: #909090;
		font-size: 0.85rem;
		margin-left: auto;
	}

	.highlight {
		color: #505050;
		font-size: 0.95rem;
		margin: 0 0 16px;
		font-weight: 500;
	}

	.changes {
		list-style: none;
		margin: 0;
		padding: 0;
		display: flex;
		flex-direction: column;
		gap: 8px;
	}

	.change {
		display: flex;
		align-items: flex-start;
		gap: 10px;
		font-size: 0.9rem;
		color: #606060;
	}

	.type-badge {
		font-size: 0.7rem;
		font-weight: 500;
		padding: 2px 6px;
		text-transform: uppercase;
		letter-spacing: 0.02em;
		flex-shrink: 0;
		margin-top: 2px;
	}

	.change.added .type-badge {
		background: #e8f5e9;
		color: #2e7d32;
	}

	.change.changed .type-badge {
		background: #e3f2fd;
		color: #1565c0;
	}

	.change.fixed .type-badge {
		background: #fce4ec;
		color: #c2185b;
	}

	.change.removed .type-badge {
		background: #f3e5f5;
		color: #7b1fa2;
	}

	.change-text {
		line-height: 1.4;
	}

	@media (max-width: 500px) {
		.release-header {
			flex-wrap: wrap;
		}

		.date {
			width: 100%;
			margin-left: 0;
			margin-top: 4px;
		}
	}
</style>
