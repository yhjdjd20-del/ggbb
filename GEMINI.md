# GEMINI.md — instructions for AI coding agents in this repo

> The user speaks Russian. Always reply to the user in Russian.

## What this is

Aetheria — a complete iOS game (Swift, SpriteKit + SwiftUI): an RPG-platformer
with 4 levels, bosses, quests, skill trees, procedural audio/art. UI and content
are localized in Russian + English. There is no Xcode/Swift toolchain on Linux —
compilation happens only in GitHub Actions (macOS runner).

## Fast checks you CAN run here (no Mac needed)

- Validate content: every `Aetheria/Resources/Data/*.json` must stay valid JSON.
- After editing Swift, check brace balance on `Aetheria/**/*.swift`
  (strip string literals and `//`/`/* */` comments first).
- `python3 tools/generate_project.py` — REGENERATE after adding, removing or
  renaming any `.swift` file or resource, and commit the resulting `project.pbxproj`.

## Build (CI only)

`.github/workflows/ios-unsigned-ipa.yml`: validate (Linux) → `xcodebuild`
without signing on macos-15 → unsigned `.ipa` artifact.
Read compile errors from `gh run view <run-id>` annotations (`::error::` lines);
full-log download often fails, never rely on it.

## Hard rules (learned from real breakages)

- NEVER replace a whole file with stubs/extensions — ~45 Swift files reference
  each other; deleting an implementation breaks the build. Put new code in new
  files (see the `GameScene+VFX.swift` pattern).
- Swift: `override` is ILLEGAL inside extensions — edit the original method instead.
- `SKColor` is a `UIColor` typealias on iOS — pass it directly, `UIColor(color)`
  does not exist.
- Avoid multi-statement trailing-closure `.filter { ... }` (it collides with the
  Foundation `Predicate` overload) — use an explicit loop.
- Generated `project.pbxproj` values must never contain bare commas — the
  generator quotes them; keep that behavior.
- Keep `Icon-1024.png` exactly 1024×1024, opaque (actool rejects anything else).
- The game is landscape-only with a logical 1280×720 viewport
  (`GameScene.logicalSize`); HUD/layout code must use `visibleSize()`, never raw `size`.

## Workflow

- Work on the current branch; commit + push after every file/batch so progress
  stays visible (`git push origin <branch>`).
- Explain each change briefly (what + why), in Russian.
- After pushing, watch `gh run list` until the iOS workflow is green; fix failures.
