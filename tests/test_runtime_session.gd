extends SceneTree
## Real node generation from neutral assets: startup, refill and pause on two boards.
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func make_config() -> Match3BoardConfiguration:
	var piece: Match3Piece = Match3Piece.new()
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = GradientTexture2D.new()
	piece.add_child(sprite)
	sprite.owner = piece
	var scene: PackedScene = PackedScene.new()
	check(scene.pack(piece) == OK, "Neutral piece scene packs correctly.")
	piece.free()
	var definition: Match3PieceConfiguration = Match3PieceConfiguration.new()
	definition.id = &"neutral"
	definition.scene = scene
	var config: Match3BoardConfiguration = Match3BoardConfiguration.new()
	config.auto_start = false
	config.grid_width = 3
	config.grid_height = 3
	config.grid_cell_scene = load("res://addons/match3/src/cells/basic_grid_cell.tscn")
	config.available_pieces = [definition]
	# This fixture isolates generation from the independent sequence detector tests.
	config.horizontal_shape = false
	config.vertical_shape = false
	config.diagonal_shape = false
	config.tshape = false
	config.lshape = false
	return config

func _run() -> void:
	var config: Match3BoardConfiguration = make_config()
	var first: Match3Board = Match3Board.new()
	var second: Match3Board = Match3Board.new()
	first.configuration = config
	second.configuration = config
	root.add_child(first)
	root.add_child(second)
	await first.start_board()
	second.set_interaction_enabled(false)
	await second.start_board()
	for frame: int in range(4):
		await process_frame
	check(first.pieces().size() == 9 and second.pieces().size() == 9, "Each manual start generates its own pieces even when another board is populated.")
	check(first.configuration != second.configuration and first.configuration != config, "Shared presets become isolated runtime sessions.")
	var original: Match3Piece = second.get_cell(0, 0).piece
	check(original.is_locked and not first.get_cell(0, 0).piece.is_locked, "Paused startup locks only its own pieces.")
	await second.start_board()
	check(second.get_cell(0, 0).piece == original, "Repeated manual start keeps the existing session.")
	second.configuration.fill_mode = Match3BoardConfiguration.BoardFillModes.InPlace
	second.clear_cell(second.get_cell(0, 0))
	await second.fill_pieces()
	check(second.get_cell(0, 0).piece.is_locked, "Refill honors pause immediately, before completion callbacks.")
	second.unlock()
	second.unlock_all_pieces()
	for frame: int in range(4):
		await process_frame
	check(second.pieces().size() == 9, "Paused refill replaces the missing piece.")
	check(second.get_cell(0, 0).piece.is_locked, "New pieces respect the host pause after internal unlock.")
	check(first.pieces().size() == 9 and first.is_interaction_enabled(), "Refill never affects another session.")
	second.set_interaction_enabled(true)
	check(not second.get_cell(0, 0).piece.is_locked, "Host resume enables refilled pieces.")
	first.free()
	second.free()
	await process_frame
	if failures == 0:
		print("Match3 runtime session regression: PASS")
	quit(0 if failures == 0 else 1)
