<script lang="ts">
	import releasesData from '$lib/data/releases.json';

	type ChangeItem = {
		text: string;
		type: 'added' | 'changed' | 'fixed' | 'removed';
		scope?: 'app' | 'server' | 'docs' | 'cli';
		featured?: boolean;
	};

	type Release = {
		version: string;
		platform: 'macos' | 'windows';
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

	const scopeLabels: Record<string, string> = {
		app: 'App',
		server: 'Server',
		docs: 'Docs',
		cli: 'CLI'
	};

	// Old macOS releases used v{version} tags; new ones use {platform}/v{version}
	const FIRST_PLATFORM_TAG_VERSION = '1.11.0';
	function releaseTag(release: Release): string {
		if (release.platform === 'windows') return `windows/v${release.version}`;
		if (release.version >= FIRST_PLATFORM_TAG_VERSION) return `macos/v${release.version}`;
		return `v${release.version}`;
	}
</script>

<div class="changelist">
	{#each releases as release, i}
		<div class="release" class:latest={i === 0}>
			<div class="release-header">
				<a href="https://github.com/doublej/consult-user-mcp/releases/tag/{releaseTag(release)}" class="version" target="_blank" rel="noopener">v{release.version}</a>
				<span class="platform-badge {release.platform}">
					{#if release.platform === 'macos'}
						<svg viewBox="0 0 384 512" width="11" height="11" fill="currentColor" aria-hidden="true"><path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5c0 26.2 4.8 53.3 14.4 81.2 12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zm-56.6-164.2c27.3-32.4 24.8-62.1 24-72.5-24.1 1.4-52 16.4-67.9 34.9-17.5 19.8-27.8 44.3-25.6 71.9 26.1 2 49.9-11.4 69.5-34.3z"/></svg>
					{:else}
						<svg viewBox="0 0 448 512" width="10" height="10" fill="currentColor" aria-hidden="true"><path d="M0 93.7l183.6-25.3v177.4H0V93.7zm0 324.6l183.6 25.3V268.4H0v149.9zm203.8 28L448 480V268.4H203.8v177.9zm0-380.6v180.1H448V32L203.8 65.7z"/></svg>
					{/if}
				</span>
				{#if i === 0}
					<span class="badge">Latest</span>
				{/if}
				<span class="date">{release.date}</span>
			</div>
			{#if release.highlight}
				<p class="highlight">{release.highlight}</p>
			{/if}
			<ul class="changes">
				{#each release.changes as change}
					<li class="change {change.type}">
						<span class="type-badge">{typeLabels[change.type]}</span>
						{#if change.scope}
							<span class="scope-badge {change.scope}">{scopeLabels[change.scope]}</span>
						{/if}
						<span class="change-text">{change.text}</span>
					</li>
				{/each}
			</ul>
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

	.platform-badge {
		display: inline-flex;
		align-items: center;
		color: #909090;
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
		gap: 8px;
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

	.scope-badge {
		font-size: 0.65rem;
		font-weight: 500;
		padding: 2px 5px;
		text-transform: uppercase;
		letter-spacing: 0.03em;
		flex-shrink: 0;
		margin-top: 2px;
		border: 1px solid;
	}

	.scope-badge.app {
		border-color: #d0d0d0;
		color: #707070;
	}

	.scope-badge.server {
		border-color: #c8e6c9;
		color: #388e3c;
	}

	.scope-badge.docs {
		border-color: #bbdefb;
		color: #1976d2;
	}

	.scope-badge.cli {
		border-color: #e1bee7;
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
