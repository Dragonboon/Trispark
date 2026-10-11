# Customize a Match3 board

The plugin is deliberately headless in its core decisions: board configuration controls the rules, while scenes and optional extension points control appearance.

## Customize cells and pieces

- The `Match3BoardConfiguration.grid_cell_scene` must instantiate a scene rooted at `Match3GridCell`. Add a `Sprite2D` or `AnimatedSprite2D`, and set `odd_cell_texture`, `even_cell_texture`, `empty_cell_texture`, `texture_scale` on the cell script.
- Each `Match3PieceConfiguration` describes a `Match3Piece` scene and stores `id`, `shape`, `color`, `type`, `weight`, and behavioral flags such as `can_be_swapped`, `can_be_moved`, `can_be_consumed`, and `can_be_triggered`.
- Custom `Match3Piece` subclasses can override `match_with(other_piece)`, `trigger(board)` (returns an array of `Match3Sequence`) and `spawn(board, sequence)` (returns the cell in which a special piece appears). The `triggered` and `queued` signals are also available.
- Use `SequenceConsumeRule` Resources to spawn specials: configure target pieces, shape filters, priority, strict size comparison and target special-piece configuration.

The existing demo includes configured gem scenes and two special-piece subclasses. Keep it as an executable reference; replace its image assets with your own when publishing your game.

## Customize movement and matches

There are nine `BoardMovements`: Adjacent, AdjacentWithDiagonals, AdjacentDiagonals, Free, Row, Column, Cross, CrossDiagonal and ConnectLine. Select Click, Drag or Slide input independently. FallDown, Side and InPlace control filling. Enable `diagonal_shape` independently of swap modes. Configure `min_match`, `max_match`, `horizontal_shape`, `vertical_shape`, `tshape`, `lshape` and `sequence_rules` for pattern behavior.

Subclass the optional `Match3MovementAdapter` Resource and override its **pure** `allows_swap(board, from_cell, to_cell)` for alternative spatial constraints. It is used only for non-ConnectLine swaps. The board still validates non-empty, swappable pieces and unusable cells. Both the swap logic and `get_valid_swap_targets(cell)` use the same rule, so the highlighter cannot disagree with gameplay.

## Customize highlight

A `Match3Highlighter` subclass is an optional Node assigned to the board's `highlighter` property. Override `highlight_cells(cells)`, `highlight_cell(cell)` and `remove_highlight()`; selection and line-connector events are wired automatically. The included `Match3DemoHighlighter` changes the cell `Sprite2D.texture` and has an exported `highlight_texture` Resource.

For more complex art, render glow, a ShaderMaterial, particles or an overlay in a subclass. Restore any modified visual state in `remove_highlight()`. Avoid mutating `cell.piece`, since that belongs to the board's model.

## Customize every animation

Assign an optional `Match3Animator` subclass to the board's `animator`. It declares the following overridable methods:

| Hook | Arguments | Purpose |
|---|---|---|
| `draw_cells` | cells | Initial cell reveal |
| `draw_pieces` | pieces | Initial gem reveal |
| `swap_pieces` | from, to, target positions | Accepted swap |
| `swap_rejected_pieces` | from, to, target positions | Snap back |
| `consume_sequence` | sequence | Serial matching |
| `consume_sequences` | consume results | Parallel matching |
| `fall_piece` | movement | Serial gravity |
| `fall_pieces` | movements | Parallel gravity |
| `spawn_piece` | cell | Serial refill |
| `spawn_pieces` | cells | Parallel refill |
| `trigger_special_piece` | piece | Special effect |
| `piece_drag_ended` | piece | Input release |
| `shuffle` | movements | Board reshuffle |

The **interactive demo animator** in `addons/match3/demo/demo_animator.gd` is the complete reference implementation. Override only what your game needs; the base class is intentionally no-op. Animation methods may `await tween.finished`; the board awaits them in relevant transitions. The `draw_cells_and_pieces_animation`, `sequence_animation`, `fall_animation` and `fill_animation` Resource properties select serial or parallel flow.

```gdscript
extends Match3Animator

func swap_pieces(from_piece: Match3Piece, to_piece: Match3Piece,
        from_target: Vector2, to_target: Vector2) -> void:
    var tween := create_tween().set_parallel(true)
    tween.tween_property(from_piece, "position", from_target, 0.18)
    tween.tween_property(to_piece, "position", to_target, 0.18)
    await tween.finished
```

Animate visual nodes only. Avoid freeing pieces directly in animation hooks: match consumption, gravity and refill belong to the board.

## Additional integration settings

- `available_moves_on_start = -1` means unlimited moves; it does not automatically enforce a game-over condition.
- `empty_cells` is an array of `Vector2i(column, row)` positions disabled for spawning or matching.
- `cell_size` and `cell_offset` define board layout in pixels.
- `auto_start = false` allows explicitly calling `await board.start_board()` after the node is ready.
- `allow_matches_on_start` determines whether initial matches are resolved.
- Optional `event_reactions` connect gameplay responses without subclassing the board; see [Events and reactions](EVENTS_AND_REACTIONS.md).

For editor preview, use the existing `Match3Preview` node and inspector tools. No editor preview node is required at runtime.
