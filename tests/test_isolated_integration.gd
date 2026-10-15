extends SceneTree
## A minimal, isolated project contract: no demo assets or UI scenes.
var source: Match3BoardConfiguration


func _initialize() -> void:
	var a := Match3PieceConfiguration.new()
	a.id = &"red"
	a.weight = Match3PieceWeight.new()
	a.weight.value = 3.0
	var b := Match3PieceConfiguration.new()
	b.id = &"blue"
	b.weight = Match3PieceWeight.new()
	b.weight.value = 1.0
	var disabled := Match3PieceConfiguration.new()
	disabled.id = &"off"
	disabled.weight = Match3PieceWeight.new()
	disabled.weight.value = 0.0

	var g1 := Match3PieceGenerator.new()
	var g2 := Match3PieceGenerator.new()
	var items: Array[Match3PieceConfiguration] = [a, b, disabled]
	g1.add_pieces(items)
	g2.add_pieces(items)
	g1.set_seed(1337)
	g2.set_seed(1337)
	for i in range(80):
		var first := g1.roll()
		var second := g2.roll()
		assert(first == second, "Seeded generation must be reproducible.")
		assert(first != disabled, "Zero-weight entry must never spawn.")
	assert(a.weight.total_accum_weight == 0.0, "Generator modified a Resource.")
	assert(a.weight.current_weight == 3.0)
	assert(g1.roll([a, b]) == null, "Zero-weight fallback must terminate.")
	assert(g1.roll(items) == null, "All-excluded configuration must terminate.")

	var base_config := Match3BoardConfiguration.new()
	base_config.available_moves_on_start = 13
	base_config.random_seed = 27
	base_config.available_pieces = items
	var runtime := base_config.duplicate(true) as Match3BoardConfiguration
	assert(runtime != base_config)
	runtime.swap_mode = Match3BoardConfiguration.BoardMovements.Row
	assert(base_config.swap_mode == Match3BoardConfiguration.BoardMovements.Adjacent)
	runtime.available_pieces.append(Match3PieceConfiguration.new())
	assert(base_config.available_pieces.size() == 3, "Configuration arrays must not be shared.")
	assert(runtime.random_seed == 27)

	var bare := load("res://addons/trispark/src/cells/basic_grid_cell.tscn") as PackedScene
	assert(bare != null, "Basic grid scene not included.")
	var cell := bare.instantiate() as Match3GridCell
	assert(cell != null and cell.odd_cell_texture == null, "Basic cell depends on demo assets.")
	cell.free()
	print("Match3 isolated integration regression: PASS")
	quit()
