#!/usr/bin/env bun
/**
 * Generates CHANGELOG.md from releases.json
 * Run: bun run scripts/generate-changelog.ts
 */

import { readFileSync, writeFileSync } from 'fs';
import { join } from 'path';

const RELEASES_PATH = join(import.meta.dir, '../docs/src/lib/data/releases.json');
const CHANGELOG_PATH = join(import.meta.dir, '../CHANGELOG.md');

type ChangeType = 'added' | 'changed' | 'fixed' | 'removed';

interface Change {
  text: string;
  type: ChangeType;
}

interface Release {
  version: string;
  platform: 'macos' | 'windows';
  date: string;
  highlight?: string;
  changes: Change[];
}

interface ReleasesData {
  releases: Release[];
}

const TYPE_HEADERS: Record<ChangeType, string> = {
  added: 'Added',
  changed: 'Changed',
  fixed: 'Fixed',
  removed: 'Removed',
};

function groupByType(changes: Change[]): Map<ChangeType, string[]> {
  const groups = new Map<ChangeType, string[]>();
  for (const change of changes) {
    const list = groups.get(change.type) || [];
    list.push(change.text);
    groups.set(change.type, list);
  }
  return groups;
}

function generateChangelog(data: ReleasesData): string {
  const lines: string[] = [
    '# Changelog',
    '',
    'All notable changes to this project will be documented in this file.',
    '',
    '<!-- Auto-generated from docs/src/lib/data/releases.json -->',
    '<!-- Run: bun run scripts/generate-changelog.ts -->',
    '',
    '## [Unreleased]',
    '',
  ];

  for (const release of data.releases) {
    const platformLabel = release.platform === 'macos' ? 'macOS' : 'Windows';
    lines.push(`## [${release.version}] (${platformLabel}) - ${release.date}`);
    lines.push('');

    const groups = groupByType(release.changes);
    const typeOrder: ChangeType[] = ['added', 'changed', 'fixed', 'removed'];

    for (const type of typeOrder) {
      const items = groups.get(type);
      if (items && items.length > 0) {
        lines.push(`### ${TYPE_HEADERS[type]}`);
        for (const item of items) {
          lines.push(`- ${item}`);
        }
        lines.push('');
      }
    }
  }

  return lines.join('\n');
}

const data: ReleasesData = JSON.parse(readFileSync(RELEASES_PATH, 'utf-8'));
const changelog = generateChangelog(data);
writeFileSync(CHANGELOG_PATH, changelog);
console.log(`Generated ${CHANGELOG_PATH}`);
