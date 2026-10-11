# Events and reactions

Match3 emits **Godot signals** and an additional, optional typed context via `event_emitted(event: Match3BoardEvent)`. You can use either: **reactions are not required** to play.

## Event contract

`Match3BoardEvent.Type` contains `PIECES_DRAWN`, `STATE_CHANGED`, `PIECE_CREATED`, `PIECE_SELECTED`, `PIECE_UNSELECTED`, `PIECE_DRAG_STARTED`, `PIECE_DRAG_FINISHED`, `PIECE_QUEUED`, `PIECE_TRIGGERED`, `SWAP_ACCEPTED`, `SWAP_REJECTED`, `SEQUENCE_CONSUMED`, `SHUFFLE_STARTED`, `SHUFFLE_FINISHED`, `MOVE_CONSUMED`, `OUT_OF_MOVES`.

The context has `type`, `board`, `piece`, `cell`, `other_cell`, `sequence`, `previous_state`, `new_state`, `moves_remaining`, `world_position` and `timestamp_msec`. Only fields relevant to a given event are set. In a swap event, `cell` is the source and `other_cell` is the destination.

**Timing matters:** `SEQUENCE_CONSUMED` occurs **before** matched normal pieces are removed, to preserve the previous `consumed_sequence` signal semantics. Do not persist references to consumed pieces; copy IDs/positions into your own game state if needed. `STATE_CHANGED` occurs when the state changes, not when its animations complete.

## Connect signals in GDScript

```gdscript
@onready var board: Match3Board = $Match3Board

func _ready() -> void:
    board.event_emitted.connect(_on_match3_event)

func _on_match3_event(event: Match3BoardEvent) -> void:
    match event.type:
        Match3BoardEvent.Type.SWAP_REJECTED:
            print("Invalid move from ", event.cell.board_position())
        Match3BoardEvent.Type.SEQUENCE_CONSUMED:
            print("Match length: ", event.sequence.size())
        Match3BoardEvent.Type.OUT_OF_MOVES:
            print("End of turn budget")
```

The original board and piece signals remain unchanged.

## Configure reactions without code

In a `Match3BoardConfiguration` Resource, open **Event Reactions** and add `Match3Reaction` Resources. Each reaction exposes an **Enabled** flag and an **Event Mask** (0 means all events). Reactions execute in array order after `event_emitted`.

- **Match3CallMethodReaction**: invoke a node method using `target_path` relative to the board (`../HUD`), `method_name`, and `pass_event` (true expects one `Match3BoardEvent`; false expects zero arguments).
- **Match3PlayAnimationReaction**: play an animation in a scene `AnimationPlayer` through `player_path` and `animation_name`.
- **Match3AudioReaction**: play a spatial `AudioStreamPlayer2D` at the event world position or a non-spatial `AudioStreamPlayer`, with configurable bus, volume and pitch.
- **Custom reaction**: extend `Match3Reaction`, override `react(board, event)` and keep shared Resource assets stateless. Store per-board counters in a `Node`, not on a shared Resource.

An example event-specific score receiver:

```gdscript
extends Label

var score := 0

func on_match3_event(event: Match3BoardEvent) -> void:
    if event.sequence == null:
        return
    score += event.sequence.size() * 100
    text = str(score)
```

Set a `Match3CallMethodReaction` filter to **Sequence Consumed**, `target_path` to the score Label's path relative to the board, `method_name` to `on_match3_event`, and `pass_event = true`. Do not combine this with another score listener unless you intend to score twice.

**Performance:** reactions are synchronous callbacks. Keep handlers short; defer heavy work and avoid changing board configuration inside an event callback.
