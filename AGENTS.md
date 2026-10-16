# Agent guide — Trispark

Scope: entire repository. **Trispark (Match3-Board)** is a portable **Godot 4.7** match-3 addon, not a complete game. CI uses **Godot 4.7.2**. The distributable code is `addons/trispark/`; no autoloads or external runtime dependencies are required.

## Start small: task router

Work from current `main` and check for user changes. Read the README and only the owning scripts, adjacent caller and relevant test before modifying code.

| Problem | Start here | Focused evidence |
| --- | --- | --- |
| Match detection, swaps, board lifecycle | `addons/trispark/src/match3_board.gd`, `src/modules/`, `src/configurations/` | `tests/test_movement_api.gd`, `test_diagonals.gd` |
| Piece identity, weighted generation, refill | `src/pieces/`, `src/cells/`, board configuration | `test_fill_animation.gd`, `test_runtime_session.gd` |
| Rules, input modes, highlighting, presentation | `src/tools/`, `src/ui/`, `src/modules/` | `test_movement_api.gd`, `test_isolated_integration.gd` |
| Signals and optional reactions | `src/events/`, `docs/EVENTS_AND_REACTIONS.md` | `test_event_api.gd` |
| Multiple boards, runtime state, pause | `docs/RUNTIME_INTEGRATION.md`, board ownership | `test_board_isolation.gd`, `test_runtime_session.gd` |
| Inspector or plugin registration | `addons/trispark/inspector/`, `plugin.gd`, `plugin.cfg` | Godot import and manual editor check |
| Visual behavior | `addons/trispark/demo/demo.tscn` | Run and interact with the demo in Godot |

Paths beginning `src/` in the table are under `addons/trispark/`. Use `rg` with a targeted pattern, not a full-repository dump.

## Preserve these invariants

- Keep public `Match3Board`, `Match3BoardConfiguration`, piece/cell classes, signals and scene Resource compatibility stable. Do not rename serialized fields or IDs casually.
- Board instances own their runtime configuration, state, queries and interaction lock. The board copies its configuration at startup; callbacks must not mutate shared presets or other boards. For sibling visual helpers, set the board reference explicitly.
- Fixed `random_seed` only reproduces a sequence with unchanged configuration, piece order and generator-call order; do not promise deterministic shuffles beyond that contract.
- Preserve the nine movement modes, three selection modes, three refill modes and optional reaction API. Test diagonals, gravity and rejection behavior when those paths change.
- Follow existing `Match3MovementAdapter`, animator, highlighter, line connector and `Match3Reaction` extension points rather than embedding game-specific effects or UI in core logic.
- Keep the addon independently installable by copying only `addons/trispark/`; demo assets are illustrative and must not become hidden dependencies for minimal use.
- Respect lifecycle cleanup and event order; avoid new global state, implicit cross-board references, unnecessary allocations per frame and broad formatting churn.

## Progressive validation

For a pure logic change: inspect and run its nearest `tests/test_*.gd` first (after project import). For code or serialized Resource changes, execute the repository's strict CI runner:

```sh
godot --version
python3 scripts/ci/run_tests.py --godot godot --timeout 60
```

The runner imports the project and checks seven headless regressions; it is the source of truth for the CI test set. For changes to drag, slide, highlight, animation or inspector UI, also test `addons/trispark/demo/demo.tscn` interactively: headless green does **not** prove the visuals or interaction. Check `.github/workflows/godot-regression.yml` before changing commands or engine pins.

## Completion contract

Deliver a minimal, reviewable diff, update relevant public docs/examples and add a regression for changed behavior. Honor explicit authorization to commit to `main`, recheck the current head first, never force-push and do not overwrite unrelated edits. Report what was verified, what was not run (including graphical/touch tests), and link the published commit.
