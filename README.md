# Match3-Board

Lightweight, configurable match-3 gameplay for **Godot 4.7**. Nine swap modes, click/drag/slide input, falling or lateral refill, optional diagonals, special pieces, highlight and animation hooks.

![Interactive demo](images/demo.png)

## Install

Copy `addons/match3/` to the same path inside your Godot project. Enable **Match3-Board** under **Project Settings → Plugins**. No autoload or third-party dependency is required.

**Start with the interactive scene:** `addons/match3/demo/demo.tscn`. It demonstrates all movement, selection, refill, animation and highlighting options. Demo assets and scripts are examples, not part of the minimal runtime API.

## Make your own board

1. Create a Node2D with script `Match3Board`.
2. Assign a `Match3BoardConfiguration` Resource containing a `grid_cell_scene` (root `Match3GridCell`) and `available_pieces` (each a `Match3PieceConfiguration`, containing a scene with `Match3Piece`).
3. Choose `swap_mode`, `selection_mode` and `fill_mode`. `diagonal_shape` enables diagonal **matches**, independently of diagonal **swaps**.
4. Optionally assign `Match3Animator`, `Match3Highlighter` and `Match3LineConnector` child nodes. The board is playable without animator or highlighter. `ConnectLine` requires a line connector.

```gdscript
@onready var board: Match3Board = $Match3Board

func _ready() -> void:
    board.consumed_sequence.connect(func(sequence: Match3Sequence):
        print("Consumed: ", sequence.size()))
    # Keep configuration.auto_start true for automatic initial generation.
    # Otherwise, call await board.start_board() after the board is ready.

func get_possible_moves(cell: Match3GridCell) -> Array[Match3GridCell]:
    return board.get_valid_swap_targets(cell)

func match_snapshot() -> Array[Match3Sequence]:
    return board.get_matches()
```

## Configuration and extensibility

- **Nine swap modes:** Adjacent, AdjacentWithDiagonals, AdjacentDiagonals, Free, Row, Column, Cross, CrossDiagonal, ConnectLine.
- **Selection:** Click, Drag or Slide. **Refill:** FallDown, Side or InPlace.
- **Sequence detection:** Horizontal, Vertical, TShape, LShape and optional Diagonal. `min_match` controls the minimum run.
- **Custom movement:** assign a subclassed `Match3MovementAdapter` Resource to `configuration.movement_adapter` and implement pure `allows_swap(board, from_cell, to_cell)`. This overrides spatial restrictions in all non-ConnectLine modes; the board still checks piece swap permissions and obstacles. The highlighter reads the exact same valid target query.
- **Custom look:** subclass `Match3Highlighter` for a visual style or reuse the demo class and change its `highlight_texture`. Subclass `Match3Animator` to animate hooks such as `swap_pieces`, `fall_pieces`, `consume_sequences` and `spawn_pieces`.
- **Custom pieces:** subclass `Match3Piece` and override `match_with`, `trigger` or `spawn` to define special effects; use `SequenceConsumeRule` Resources to create special pieces on matches.

The public board API includes `start_board()`, `get_cell(column, row)`, `get_matches()`, `can_swap_cells(from, to)`, `get_valid_swap_targets(cell)`, `swap_pieces(from_piece, to_piece)`, `shuffle()`, `lock()` and `unlock()`. Subscribe to `state_changed`, `consumed_sequence`, `swap_accepted` and `swap_rejected` for game logic.

The editor preview is optional and remains inside the original demo, where the preview is generated on demand.

## Test

```sh
python3 scripts/ci/run_tests.py --godot godot
```

The test runner imports the project and checks diagonal/gravity and movement policies with Godot 4.7.2 in GitHub Actions.

Licensed under MIT. See [LICENSE](LICENSE).
