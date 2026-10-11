# Runtime integration and multiple boards

## Presets vs. sessions

A `Match3BoardConfiguration` is the starting preset. `Match3Board._ready()` duplicates it for use by that board. This allows two boards to share an exported preset while changing their runtime movement or matching rules independently.

```gdscript
@onready var first: Match3Board = $FirstBoard
@onready var second: Match3Board = $SecondBoard

func _ready() -> void:
    first.configuration.swap_mode = Match3BoardConfiguration.BoardMovements.Row
    second.configuration.swap_mode = Match3BoardConfiguration.BoardMovements.Adjacent
```

Use `board.configuration` after `_ready()` to customize an active board. Do not write mutable session counters into the source `.tres` or shared scene resources. The state machine, piece positions, move count and selection are owned by the board, not by its settings file.

## Board ownership

Piece queries (`pieces()`, special/obstacle queries and Finder filters) read the owning board's logical grid. Locks, shuffle plans and manual startup therefore remain local even when another board is already populated. `owns_cell(cell)` and `owns_piece(piece)` let host integrations check ownership; matching coordinates alone do not establish ownership.

`Match3Animator`, `Match3Highlighter` and `Match3LineConnector` resolve their board in this order:

1. The explicitly assigned `board` property.
2. The nearest ancestor `Match3Board`.
3. The only board in the scene, for compatibility with single-board scenes.

A sibling component in a scene with several boards needs an explicit assignment. Ambiguous ownership produces an error instead of silently attaching to the first board. Prefer placing components beneath their board and assign the Board's `animator`, `highlighter` and `line_connector` properties as appropriate.

`can_swap_cells()` remains a pure rule query. It rejects foreign cells, as do swap commands and line connections. Drag detection filters out pieces belonging to other boards even if their collision layers overlap.

## Pause menus and in-flight operations

Use `set_interaction_enabled()` for host menus. It is independent of the internal `lock()` / `unlock()` used during animation and cascade resolution:

```gdscript
@onready var board: Match3Board = $Match3Board

func open_menu() -> void:
    board.set_interaction_enabled(false)
    $PauseMenu.show()

func close_menu() -> void:
    $PauseMenu.hide()
    board.set_interaction_enabled(true)
```

Disabling input cancels the active selection/drag or line gesture. Existing animations and cascades continue; finishing them cannot dismiss the host pause. Newly spawned pieces also respect that pause. Re-enabling input does not release a gameplay lock held by an unfinished operation.

`is_interaction_enabled()` reports the effective permission (host enabled, no internal lock, and waiting for input). `interaction_enabled_changed(enabled)` reports changes to the **host permission**; it does not signal every busy/idle transition. Use `state_changed` or the query for gameplay readiness. This API does not pause the scene tree or animation time.

`swap_pieces()` and `shuffle()` ignore requests while input is disabled or the board is busy. A swap reserves input before awaiting its animator, preventing overlapping swap commands. Pure queries such as `get_valid_swap_targets()` remain available for tools and previews.

## Minimal installation with your own assets

Copy the `addons/match3/` directory. The `src/cells/basic_grid_cell.tscn` scene is a neutral cell scene without any reference to demo textures. Create one or more scenes derived from `Match3Piece` with a `Sprite2D` child and configure them using `Match3PieceConfiguration`. Add them to the `available_pieces` array on a board Resource; configure optional `Match3PieceWeight` values for weighted spawning.

The older `src/cells/grid_cell.tscn` scene intentionally retains the original example artwork. If you remove `addons/match3/demo/` for a lean distribution, use the neutral cell scene or your own replacement and ensure no installed scenes point into the demo folder.

## Generation and failure cases

`Match3PieceGenerator` owns its own `RandomNumberGenerator`, does not mutate weight Resources during a roll, and returns `null` when no positive-weight candidate is available. Missing weight Resources default to weight 1; zero-weight entries are excluded. The board emits an error if a spawn is impossible. Initial-match elimination has a retry cap, and keeps the current pieces if the exclusions leave no legal replacement.

Use `random_seed = -1` for nondeterministic generation, or `random_seed = 1234` to reproduce initial weighted draws with the same setup. A fixed seed does not promise determinism for the entire game: shuffles and other random operations may use separate generators.

## Extensibility and events

The existing native signals remain the lowest-overhead integration method. Optional `event_reactions` are intended for configuration-driven SFX, VFX, and host-scene callbacks; see [event documentation](EVENTS_AND_REACTIONS.md). An event callback should read the immutable-by-convention event context and may schedule game-specific work, but should avoid immediate re-entrant manipulation of the board state machine.

For UI, subscribe to `consumed_sequence`, `swap_accepted`, `swap_rejected`, `state_changed` or `event_emitted`. For visual customization, override `Match3Animator` or `Match3Highlighter`, not the generator or gravity planner.

## Regression checks

Run `python3 scripts/ci/run_tests.py --godot /path/to/godot`. The suite includes real two-board startup/refill with neutral generated assets, ownership and type/color queries, pause during a yielding swap, component binding, movement modes, events and InPlace refill animations. Manual visual/input validation remains separate.
