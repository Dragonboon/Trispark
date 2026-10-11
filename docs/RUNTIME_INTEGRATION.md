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

## Minimal installation with your own assets

Copy the `addons/match3/` directory. The `src/cells/basic_grid_cell.tscn` scene is a neutral cell scene without any reference to demo textures. Create one or more scenes derived from `Match3Piece` with a `Sprite2D` child and configure them using `Match3PieceConfiguration`. Add them to the `available_pieces` array on a board Resource; configure optional `Match3PieceWeight` values for weighted spawning.

The older `src/cells/grid_cell.tscn` scene intentionally retains the original example artwork. If you remove `addons/match3/demo/` for a lean distribution, use the neutral cell scene or your own replacement and ensure no installed scenes point into the demo folder.

## Generation and failure cases

`Match3PieceGenerator` owns its own `RandomNumberGenerator`, does not mutate weight Resources during a roll, and returns `null` when no positive-weight candidate is available. Missing weight Resources default to weight 1; zero-weight entries are excluded. The board emits an error if a spawn is impossible. Initial-match elimination has a retry cap, and keeps the current pieces if the exclusions leave no legal replacement.

Use `random_seed = -1` for nondeterministic generation, or `random_seed = 1234` to reproduce initial weighted draws with the same setup. A fixed seed does not promise determinism for the entire game: shuffles and other random operations may use separate generators.

## Extensibility and events

The existing native signals remain the lowest-overhead integration method. Optional `event_reactions` are intended for configuration-driven SFX, VFX, and host-scene callbacks; see [event documentation](EVENTS_AND_REACTIONS.md). An event callback should read the immutable-by-convention event context and may schedule game-specific work, but should avoid immediate re-entrant manipulation of the board state machine.

For UI, subscribe to `consumed_sequence`, `swap_accepted`, `swap_rejected`, `state_changed` or `event_emitted`. For visual customization, override `Match3Animator` or `Match3Highlighter`, not the generator or gravity planner.
