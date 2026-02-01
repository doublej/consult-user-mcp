import { chromium } from 'playwright';
import { spawn, type ChildProcess } from 'child_process';
import { mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const docsDir = join(__dirname, '..');
const projectRoot = join(docsDir, '..');
const outDir = process.argv[2] || join(projectRoot, 'local', 'promotion');

const sets: Record<string, string[]> = {
	a: Array.from({ length: 10 }, (_, i) => `a-${String(i + 1).padStart(2, '0')}`),
	b: Array.from({ length: 10 }, (_, i) => `b-${String(i + 1).padStart(2, '0')}`),
	c: Array.from({ length: 10 }, (_, i) => `c-${String(i + 1).padStart(2, '0')}`),
	d: Array.from({ length: 10 }, (_, i) => `d-${String(i + 1).padStart(2, '0')}`),
};

const platforms: Record<string, { width: number; height: number }> = {
	threads: { width: 1080, height: 1350 },
	substack: { width: 1080, height: 1350 },
	x: { width: 1600, height: 900 },
};

const PORT = 5188;
const BASE = `http://localhost:${PORT}`;

function startDevServer(): ChildProcess {
	return spawn('bun', ['run', 'vite', 'dev', '--port', String(PORT)], {
		cwd: docsDir,
		stdio: 'pipe',
	});
}

async function waitForServer(maxWait = 30_000): Promise<void> {
	const start = Date.now();
	while (Date.now() - start < maxWait) {
		try {
			const res = await fetch(BASE);
			if (res.ok) return;
		} catch { /* not ready yet */ }
		await new Promise((r) => setTimeout(r, 300));
	}
	throw new Error(`Dev server not ready after ${maxWait}ms`);
}

async function main() {
	mkdirSync(outDir, { recursive: true });

	let ownServer: ChildProcess | null = null;
	try {
		await fetch(BASE);
	} catch {
		console.log(`Starting dev server on port ${PORT}...`);
		ownServer = startDevServer();
		await waitForServer();
	}
	console.log('Dev server ready.');

	const browser = await chromium.launch();
	let total = 0;

	try {
		for (const [platform, size] of Object.entries(platforms)) {
			const context = await browser.newContext({ viewport: size });
			const page = await context.newPage();

			for (const [setName, slideIds] of Object.entries(sets)) {
				const setDir = join(outDir, `set-${setName}`, platform);
				mkdirSync(setDir, { recursive: true });

				for (let i = 0; i < slideIds.length; i++) {
					const id = slideIds[i];
					const url = `${BASE}/screenshots/${id}/${platform}`;
					await page.goto(url, { waitUntil: 'load' });
					await page.waitForTimeout(800);

					const filename = `${String(i + 1).padStart(2, '0')}.png`;
					await page.screenshot({ path: join(setDir, filename) });
					console.log(`  set-${setName}/${platform}/${filename}`);
					total++;
				}
			}

			await context.close();
		}
	} finally {
		await browser.close();
		if (ownServer) {
			ownServer.kill();
			console.log('Dev server stopped.');
		}
	}

	console.log(`\nDone — ${total} screenshots in ${outDir}`);
}

main().catch((err) => {
	console.error(err);
	process.exit(1);
});
