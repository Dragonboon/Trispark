# Match3-Board: Godot 4.7 integration

This branch targets **Godot 4.7.2 stable**. Copy `addons/ninetailsrabbit.match3_board` to your project and enable **Match3-Board** in Project Settings → Plugins.

## Minimal game

1. Add a `Match3Board` (Node2D) to your scene.
2. Create a `Match3BoardConfiguration` Resource and assign it to `configuration`.
3. Set `grid_cell_scene` (the root must extend `Match3GridCell`) and add at least two `Match3PieceConfiguration` entries, each with a `Match3Piece` scene, unique ID, and a `Match3PieceWeight`.
4. Keep `auto_start = true`; otherwise call `await board.start_board()`.
5. Subscribe to `consumed_sequence`, `swap_accepted`, `swap_rejected` or `state_changed` to implement score, goals and UI.

A ready-to-open scene is available at `examples/quick_start.tscn`; it uses the plugin's demo resources, while the existing interactive demo remains intact.

```gdscript
extends Node2D

@onready var board: Match3Board = $Match3Board

func _ready() -> void:
    board.consumed_sequence.connect(_on_match)

func _on_match(sequence: Match3Sequence) -> void:
    print("Matched ", sequence.size(), " pieces")

func restart() -> void:
    # For a fresh board, instantiate a new board scene or rebuild your game scene.
    get_tree().reload_current_scene()

func matching_cells() -> Array[Match3Sequence]:
    return board.get_matches()

func cell_at(column: int, row: int) -> Match3GridCell:
    return board.get_cell(column, row)
```

## Modes and diagonal behavior

`swap_mode` defines **where pieces may be swapped**. `diagonal_shape = true` independently enables detection of same-color matching runs on both diagonal axes. Horizontal and vertical detection may be disabled separately. `fill_mode = Side` allows a falling piece to slide diagonally around blocked downward cells. Each moving piece is planned once, without mutating the live board during planning.

`min_match` defines the minimum match length. A longer contiguous run is returned whole (it is not split into chunks at `max_match`), so special-piece rules can inspect its real length. `max_match` remains a limit for manual line connection. T and L forms are classified when horizontal and vertical runs intersect.

## Headless regression

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_diagonals.gd
```

GitHub Actions runs these checks with Godot 4.7.2. Passing a parse/import check and regression suite is required before merging this branch. This is a migration branch; evaluate it against custom subclasses and saved scenes before shipping.
