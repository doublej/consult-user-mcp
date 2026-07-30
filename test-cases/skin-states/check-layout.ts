#!/usr/bin/env bun
// Layout audit.
//
// Reads the `*.layout.json` reports the renderer writes beside each shot and
// turns them into pass/fail. The renderer measures; this decides.
//
//   bun check-layout.ts <shots-dir> [--json] [--update-waivers]
//
// Every rule here answers a question a person would otherwise have to answer
// by squinting at a contact sheet:
//
//   overflow      did the content ask for more room than the window gave it?
//   escapes       is a widget's frame outside the surface that owns it?
//   truncated     is a label wider than the box it was laid into?
//   edge-ink      is anything drawn hard against the panel border?
//   panel-inset   did the panel eat the padding the window reserves for it?
//
// Known-bad states live in `waivers.json` with a reason and an issue id, so a
// bug that is being tracked does not stop the suite while still staying
// visible in the output. A waiver that stops matching is itself a failure —
// that is how a fix gets noticed.

import { readdirSync, readFileSync, existsSync, writeFileSync } from "node:fs";
import { join, dirname } from "node:path";

type Rule = "overflow" | "escapes" | "truncated" | "text-fit" | "overlap" | "edge-ink" | "panel-inset";

interface Violation {
  rule: Rule;
  detail: string;
}

interface Report {
  name: string;
  skin: string;
  kind: string;
  fixture: string;
  pane: string;
  overflowWidth?: number;
  overflowHeight?: number;
  atHeightCap?: boolean;
  window?: number[];
  hostingFrame?: number[];
  fitting?: number[];
  views?: Array<{
    class: string;
    frame: number[];
    intrinsic?: number[];
    textSize?: number[];
    textOverflowWidth?: number;
    textOverflowHeight?: number;
    interactive?: boolean;
    clipped?: boolean;
    truncatedWidth?: boolean;
    truncatedHeight?: boolean;
    escapes?: boolean;
  }>;
  pixels?: {
    size: number[];
    scale: number;
    panel: number[];
    ink?: number[];
    edgeInk?: Record<string, number>;
    panelInset?: Record<string, number>;
    inkInset?: Record<string, number>;
    backgroundShare?: number;
    error?: string;
  };
}

// A layout pass lands on fractional points; anything under a point is
// rounding, not a bug.
const OVERFLOW_TOLERANCE = 1.0;

// Device pixels of non-background colour allowed in the outermost 2pt band of
// the panel, per side. A rounded panel corner antialiases into that band and
// costs ~15 per side on its own; a cut frame arm or a clipped glyph costs
// hundreds. The gap between those two numbers is wide, so the threshold does
// not need to be precise.
const EDGE_INK_LIMIT = 120;

// The window reserves 8pt of padding around the hosting view for its shadow.
// A panel that reaches the capture edge has grown into it.
const MIN_PANEL_INSET = 1;

// A text box laid out to the point can miss its content by a fraction; two
// points is comfortably inside "a person would never see it".
const TEXT_FIT_TOLERANCE = 2.0;

// Interactive rectangles that graze each other by a fraction of a point are a
// rounding artefact. Real collisions — a pane opening over a footer — are
// several points deep and cover a meaningful part of the smaller element.
const OVERLAP_MIN_DEPTH = 1.5;
const OVERLAP_MIN_SHARE = 0.08;

const SIDES = ["top", "right", "bottom", "left"] as const;

// Dialog kinds that use the padded chassis from `createAutoSizedWindow`.
const PADDED_KINDS = new Set(["confirm", "choose", "text-input", "questions"]);

type ViewEntry = NonNullable<Report["views"]>[number];

function contains(outer: number[], inner: number[]): boolean {
  return (
    outer[0] <= inner[0] + 0.5 &&
    outer[1] <= inner[1] + 0.5 &&
    outer[0] + outer[2] >= inner[0] + inner[2] - 0.5 &&
    outer[1] + outer[3] >= inner[1] + inner[3] - 0.5
  );
}

/// Two things a person can click must not sit on top of each other. This is
/// the rule that catches a note pane opening across the footer — the geometry
/// stays self-consistent, `fittingSize` still agrees with the window, and
/// nothing is clipped; the elements simply land in the same place.
///
/// Nesting is not a collision: a text view lives inside its focus target, and
/// SwiftUI mounts both at the same frame. Only rectangles where neither
/// contains the other are considered.
function findOverlaps(views: ViewEntry[]): Violation[] {
  const targets = views.filter(
    (v) => v.interactive && !v.clipped && v.frame[2] > 0 && v.frame[3] > 0,
  );
  const out: Violation[] = [];
  const seen = new Set<string>();

  for (let i = 0; i < targets.length; i++) {
    for (let j = i + 1; j < targets.length; j++) {
      const a = targets[i].frame;
      const b = targets[j].frame;
      if (contains(a, b) || contains(b, a)) continue;

      const overlapW = Math.min(a[0] + a[2], b[0] + b[2]) - Math.max(a[0], b[0]);
      const overlapH = Math.min(a[1] + a[3], b[1] + b[3]) - Math.max(a[1], b[1]);
      if (overlapW <= 0 || overlapH <= 0) continue;

      // Depth is the shallower of the two axes: that is how far one element
      // has actually intruded into the other.
      const depth = Math.min(overlapW, overlapH);
      const smaller = Math.min(a[2] * a[3], b[2] * b[3]);
      const share = (overlapW * overlapH) / Math.max(smaller, 1);
      if (depth < OVERLAP_MIN_DEPTH || share < OVERLAP_MIN_SHARE) continue;

      const key = [targets[i].class, targets[j].class, Math.round(depth)].join("|");
      if (seen.has(key)) continue;
      seen.add(key);

      out.push({
        rule: "overlap",
        detail: `${targets[i].class} and ${targets[j].class} overlap by ${
          Math.round(depth * 10) / 10
        }pt (${Math.round(share * 100)}% of the smaller)`,
      });
    }
  }
  return out;
}

function inspect(report: Report): Violation[] {
  const out: Violation[] = [];
  const round = (n: number) => Math.round(n * 10) / 10;

  // A window pinned at the height cap with a scroll view inside it is meant to
  // hold more content than it can show — that is what the scroll view is for.
  // Overflow only means "clipped" when the window still had room to grow, or
  // when there is nothing there to scroll.
  const scrolls = (report.views ?? []).some((v) => v.clipped);
  const absorbed = (report.atHeightCap ?? false) && scrolls;

  const overflowH = report.overflowHeight ?? 0;
  const overflowW = report.overflowWidth ?? 0;
  if (overflowH > OVERFLOW_TOLERANCE && !absorbed) {
    out.push({
      rule: "overflow",
      detail: `content is ${round(overflowH)}pt taller than its window${
        report.atHeightCap ? " (window already at the height cap)" : ""
      }`,
    });
  }
  if (overflowW > OVERFLOW_TOLERANCE) {
    out.push({ rule: "overflow", detail: `content is ${round(overflowW)}pt wider than its window` });
  }

  for (const view of report.views ?? []) {
    // Only widgets. SwiftUI's private backing views routinely extend past the
    // surface — a scroll view's content view is *supposed* to be taller than
    // the clip view that shows it — and reporting those buries the one case
    // that matters: a control a person can reach sitting outside the window.
    if (view.escapes && view.interactive && !view.clipped) {
      const [x, y, w, h] = view.frame.map(round);
      out.push({ rule: "escapes", detail: `${view.class} at ${x},${y} ${w}x${h} is outside the surface` });
    }
    if (view.truncatedWidth && view.intrinsic) {
      const short = round(view.intrinsic[0] - view.frame[2]);
      out.push({ rule: "truncated", detail: `${view.class} is ${short}pt narrower than its content` });
    }
    if (view.truncatedHeight && view.intrinsic) {
      const short = round(view.intrinsic[1] - view.frame[3]);
      out.push({ rule: "truncated", detail: `${view.class} is ${short}pt shorter than its content` });
    }
    if (view.textOverflowHeight && view.textOverflowHeight > TEXT_FIT_TOLERANCE) {
      out.push({
        rule: "text-fit",
        detail: `${view.class} text needs ${round(view.textOverflowHeight)}pt more height than its box`,
      });
    }
    if (view.textOverflowWidth && view.textOverflowWidth > TEXT_FIT_TOLERANCE) {
      out.push({
        rule: "text-fit",
        detail: `${view.class} text needs ${round(view.textOverflowWidth)}pt more width than its box`,
      });
    }
  }

  out.push(...findOverlaps(report.views ?? []));

  // The pixel rules assume the padded chassis: a hosting view inset 8pt inside
  // the window so the shadow has somewhere to fall. `notify` and `preview` are
  // a different surface — they paint a backdrop flush to the window edge on
  // purpose — so measuring their margins says nothing about whether they fit.
  // Their clipping is caught by the escape rule instead.
  //
  // A window at the height cap is also exempt: its panel legitimately fills
  // the window top to bottom, which is not the same thing as being clipped.
  const pixels = PADDED_KINDS.has(report.kind) && !absorbed ? report.pixels : undefined;
  if (pixels && !pixels.error) {
    for (const side of SIDES) {
      const count = pixels.edgeInk?.[side] ?? 0;
      if (count > EDGE_INK_LIMIT) {
        out.push({ rule: "edge-ink", detail: `${count}px of content jammed against the ${side} border` });
      }
      const inset = pixels.panelInset?.[side] ?? MIN_PANEL_INSET;
      if (inset < MIN_PANEL_INSET) {
        out.push({ rule: "panel-inset", detail: `panel reaches the ${side} edge of the window` });
      }
    }
  }

  // One row per distinct problem. SwiftUI mounts the same widget through
  // several layers, so an identical line can arrive nine times; the repeats
  // say nothing the first one did not and push the other rules off screen.
  const seen = new Set<string>();
  return out.filter((v) => {
    const key = `${v.rule}|${v.detail}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

// MARK: - Waivers

interface Waiver {
  state: string;
  rules: Rule[];
  reason: string;
  issue?: string;
  // A bug is usually one skin's bug. A waiver with no skin applies to all of
  // them; one that names a skin is invisible to every other, so a caret bug
  // does not read as a stale waiver the moment the suite runs against classic.
  skin?: string;
}

function loadWaivers(dir: string): Waiver[] {
  // The waiver list belongs to the suite, not to a run's output directory.
  const path = join(dirname(new URL(import.meta.url).pathname), "waivers.json");
  if (!existsSync(path)) return [];
  return JSON.parse(readFileSync(path, "utf8")) as Waiver[];
}

// MARK: - Run

const args = process.argv.slice(2);
const dir = args.find((a) => !a.startsWith("--"));
const asJson = args.includes("--json");
const updateWaivers = args.includes("--update-waivers");

if (!dir || !existsSync(dir)) {
  console.error("usage: bun check-layout.ts <shots-dir> [--json] [--update-waivers]");
  process.exit(2);
}

const reports: Report[] = readdirSync(dir)
  .filter((f) => f.endsWith(".layout.json"))
  .sort()
  .map((f) => JSON.parse(readFileSync(join(dir, f), "utf8")) as Report);

if (reports.length === 0) {
  console.error(`no layout reports in ${dir} — did the renderer run?`);
  process.exit(2);
}

const skin = reports[0]?.skin ?? "";
const waivers = loadWaivers(dir).filter((w) => !w.skin || w.skin === skin);
const byState = new Map(waivers.map((w) => [w.state, w]));

interface Outcome {
  report: Report;
  violations: Violation[];
  waived: Violation[];
}

const outcomes: Outcome[] = reports.map((report) => {
  const found = inspect(report);
  const waiver = byState.get(report.name);
  if (!waiver) return { report, violations: found, waived: [] };
  const waived = found.filter((v) => waiver.rules.includes(v.rule));
  return { report, violations: found.filter((v) => !waiver.rules.includes(v.rule)), waived };
});

const failed = outcomes.filter((o) => o.violations.length > 0);
const waivedStates = outcomes.filter((o) => o.waived.length > 0);

// A waiver whose bug is gone is stale — it hides the next regression in the
// same place, so it fails the run until someone deletes it.
const stale = waivers.filter((w) => {
  const outcome = outcomes.find((o) => o.report.name === w.state);
  return outcome && outcome.waived.length === 0;
});

if (updateWaivers) {
  const generated: Waiver[] = failed.map((o) => ({
    state: o.report.name,
    rules: [...new Set(o.violations.map((v) => v.rule))],
    reason: o.violations.map((v) => v.detail).join("; "),
    skin,
  }));
  const path = join(dirname(new URL(import.meta.url).pathname), "waivers.json");
  writeFileSync(path, JSON.stringify(generated, null, 2) + "\n");
  console.log(`wrote ${generated.length} waivers to ${path}`);
  process.exit(0);
}

if (asJson) {
  console.log(
    JSON.stringify(
      {
        skin: reports[0]?.skin,
        total: reports.length,
        failed: failed.map((o) => ({ state: o.report.name, violations: o.violations })),
        waived: waivedStates.map((o) => ({ state: o.report.name, violations: o.waived })),
        stale: stale.map((w) => w.state),
      },
      null,
      2,
    ),
  );
} else {
  console.log(`\n=== Layout audit — ${skin || "?"} — ${reports.length} states ===\n`);
  for (const outcome of failed) {
    console.log(`FAIL  ${outcome.report.name}`);
    for (const v of outcome.violations) console.log(`        ${v.rule.padEnd(12)} ${v.detail}`);
  }
  for (const outcome of waivedStates) {
    const waiver = byState.get(outcome.report.name)!;
    console.log(`WAIVED ${outcome.report.name}  (${waiver.issue ?? "no issue"}) ${waiver.reason}`);
  }
  for (const w of stale) {
    console.log(`STALE  ${w.state}  waiver no longer matches — the bug looks fixed, delete it`);
  }
  console.log(
    `\n${reports.length} states · ${failed.length} failed · ${waivedStates.length} waived · ${stale.length} stale\n`,
  );
}

process.exit(failed.length > 0 || stale.length > 0 ? 1 : 0);
