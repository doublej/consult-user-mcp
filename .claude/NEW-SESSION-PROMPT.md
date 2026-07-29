# Starting the rendering-layer rebuild in a fresh session

Launch with the blindfold, from the repo root:

```bash
claude --settings .claude/ui-blind.settings.json
```

Then paste the prompt below verbatim.

---

## The prompt

```
Read .claude/commands/build-ui.md and follow it. Everything below is context that
document cannot infer, and it overrides the document where they differ.

VISUAL DIRECTION
  /Users/jurrejan/Downloads/Consult User MCP Interface Design-handoff.zip

  Unpack it to your scratchpad and read it before anything else. Two documents in
  it are not equal: "Brand Choices.dc.html" is an unanswered menu, "Logo System.dc.html"
  is the resolved system and wins. Its header states the locked picks outright.
  The exported .svg files are an older cut whose accent colour is stale — take the
  geometry from them, take every colour from the Logo System document.

WHAT HAPPENED LAST TIME
  A previous session built a skin called "Bracket" from this same direction. It
  was rejected as a recolour: it derived the conventional dialog arrangement from
  the behaviour contract's ordering rules and let the shipped chassis draw the
  report control, the project identity, the annotation editor and most of the body
  text. It is still on disk at dialog-cli/Sources/DialogCLI/Skins/Bracket/ and is
  blocked by the blindfold. Do not read it, do not extend it, do not name your
  layer Bracket. It has nothing you need — the palette in it is just a
  transcription of the handoff you are about to read yourself.

  The two failure modes it demonstrates, both of which /build-ui exists to prevent:
    1. Deriving arrangement from the contract feels like rigour and produces the
       incumbent. Read UI-BEHAVIOUR-SPECIFICATION.md §0.2 and §0.3 before §1.
    2. Reusing any shipped drawing component makes the result a palette swap,
       because those components are most of the pixels. Read
       UI-RENDERING-BOUNDARY.md in full — it is the correction and it is binding.

SCOPE DECISIONS ALREADY MADE
  - tweak: leave it falling through to the default style. §7.3 supports this
    explicitly. Return ClassicSkin.metrics(for: .tweak) from metrics(for:) so it is
    not sized for a layout it is not using. Do not spend effort here.
  - Light palette: §7.4 requires one and it is currently unmet. Build dark first
    and completely. Add the light palette before you call the work done, but shoot
    only a representative subset of states in it — one per surface plus the four
    chosen x focused combinations — not the whole manifest twice.
  - The other three §7.4 items — no hardcoded colour anywhere, right-to-left
    decided deliberately, text scaling under the measure-once law — are in scope
    and must be answered, in code or in a stated decision.

SETUP DETAIL THAT SILENTLY BREAKS THE LOOP
  The blindfold blanket-denies reading images so you cannot see the current UI's
  screenshots. That also blocks your own. Write captures OUTSIDE the repo:

      OUTDIR=<your scratchpad>/shots ./capture-states.sh

  A harness already exists at test-cases/skin-states/ (states.tsv plus
  capture-states.sh) from the previous attempt. The script is sound and honours
  OUTDIR; the manifest is a reasonable starting set. Both are yours to rewrite.
  Note capture-dialog.swift recompiles on every invocation, which takes longer
  than some states you are trying to catch — the script already precompiles it.

BEFORE YOU BUILD SURFACE TWO
  State your structural thesis in words, show me surface one rendered, and wait.
  A thesis is a claim about geometry I could not have guessed from the contract.
  If your layout can be described as "label, title, body, divider, chips, buttons
  bottom-right, hints", it is the incumbent and I will reject it again.
```

---

## Why each piece is here

| Block | Why a fresh session cannot infer it |
|---|---|
| Visual direction | The zip path, and that the resolved page beats the menu, and that the exported SVG accent is stale |
| What happened last time | `Skins/Bracket/` exists and is non-empty; `/build-ui` preflight says to stop and ask if so. This pre-answers it |
| Scope decisions | `tweak` and the light palette are both genuine forks with real cost; deciding them up front avoids a stall |
| Setup detail | The image deny-rule versus reading back your own captures is a silent failure — the agent sees "captured ok" and then cannot look |
| Before surface two | The one checkpoint that would have caught the last failure on day one |

## If you would rather start clean

`Skins/Bracket/` is committed at `55c6df2`. To remove it and its registry line:

```bash
git rm -r dialog-cli/Sources/DialogCLI/Skins/Bracket
# then drop the BracketSkin line from Skins/SkinRegistry.swift
```

The blindfold makes this unnecessary — a fresh agent cannot read it either way — but
deleting it also removes it from the acceptance grep in `UI-RENDERING-BOUNDARY.md` §6
and from anyone's `DIALOG_SKIN` autocomplete.
