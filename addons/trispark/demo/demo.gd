extends Control

@onready var match_3_board: Match3Board = %Match3Board

#region UI
@onready var state_label: Label = %StateLabel
@onready var board_information: Label = %BoardInformation

@onready var selection_mode_option_button: OptionButton = %SelectionModeOptionButton
@onready var swap_mode_option_button: OptionButton = %SwapModeOptionButton
@onready var fill_mode_option_button: OptionButton = %FillModeOptionButton
@onready var min_match_spin_box: SpinBox = %MinMatchSpinBox
@onready var max_match_spin_box: SpinBox = %MaxMatchSpinBox
@onready var horizontal_shape_checkbox: CheckBox = %HorizontalShape
@onready var vertical_shape_checkbox: CheckBox = %VerticalShape
@onready var tshape_checkbox: CheckBox = %TShape
@onready var lshape_checkbox: CheckBox = %LShape
@onready var consume_sequence_animation_flow_option_button: OptionButton = %ConsumeSequenceAnimationFlow
@onready var fall_animation_flow_option_button: OptionButton = %FallAnimationFlow
@onready var fill_animation_flow_option_button: OptionButton = %FillAnimationFlow
@onready var shuffle_button: Button = %ShuffleButton

#endregion


#region UI configuration
var selection_modes: Dictionary = {
	0: Match3BoardConfiguration.BoardSelectionMode.Click,
	1: Match3BoardConfiguration.BoardSelectionMode.Drag,
	2: Match3BoardConfiguration.BoardSelectionMode.Slide,
}

var swap_modes: Dictionary = {
	0: Match3BoardConfiguration.BoardMovements.Adjacent,
	1: Match3BoardConfiguration.BoardMovements.AdjacentWithDiagonals,
	2: Match3BoardConfiguration.BoardMovements.AdjacentDiagonals,
	3: Match3BoardConfiguration.BoardMovements.Free,
	4: Match3BoardConfiguration.BoardMovements.Row,
	5: Match3BoardConfiguration.BoardMovements.Column,
	6: Match3BoardConfiguration.BoardMovements.Cross,
	7: Match3BoardConfiguration.BoardMovements.CrossDiagonal,
	8: Match3BoardConfiguration.BoardMovements.ConnectLine,
}

var fill_modes: Dictionary = {
	0: Match3BoardConfiguration.BoardFillModes.FallDown,
	1: Match3BoardConfiguration.BoardFillModes.Side,
	2: Match3BoardConfiguration.BoardFillModes.InPlace,
}

#endregion

func _ready() -> void:
	prepare_demo_ui()
	
	state_label.text = "WaitForInput"
	match_3_board.state_changed.connect(on_state_changed)
	
	board_information.text = "%d columns x %d rows | %d pieces" % [match_3_board.configuration.grid_width, match_3_board.configuration.grid_height, match_3_board.pieces().size()]


func prepare_demo_ui() -> void:
	prepare_swap_mode()
	prepare_selection_mode()
	prepare_fill_mode()
	prepare_min_max_match_spin_boxes()
	prepare_allowed_shapes()
	prepare_animation_flow()
	prepare_shuffle_button()
	
	
func prepare_shuffle_button() -> void:
	shuffle_button.pressed.connect(on_shuffle_button_pressed)
	match_3_board.shuffle_started.connect(func(): shuffle_button.disabled = true)
	match_3_board.shuffle_ended.connect(func(): shuffle_button.disabled = false)

	
func prepare_selection_mode() -> void:
	selection_mode_option_button.clear()
	selection_mode_option_button.add_item("Click", 0)
	selection_mode_option_button.add_item("Drag", 1)
	selection_mode_option_button.add_item("Slide", 2)
	selection_mode_option_button.item_selected.connect(on_selection_mode_selected)

	for selection_mode_id in selection_modes:
		if match_3_board.configuration.selection_mode == selection_modes[selection_mode_id]:
			selection_mode_option_button.select(selection_mode_option_button.get_item_index(selection_mode_id))
			
	
func prepare_swap_mode() -> void:
	swap_mode_option_button.clear()
	swap_mode_option_button.add_item("Adjacent", 0)
	swap_mode_option_button.add_item("AdjacentWithDiagonals", 1)
	swap_mode_option_button.add_item("AdjacentOnlyDiagonals", 2)
	swap_mode_option_button.add_item("Free", 3)
	swap_mode_option_button.add_item("Row", 4)
	swap_mode_option_button.add_item("Column", 5)
	swap_mode_option_button.add_item("Cross", 6)
	swap_mode_option_button.add_item("CrossDiagonal", 7)
	swap_mode_option_button.add_item("ConnectLine", 8)
	swap_mode_option_button.item_selected.connect(on_swap_mode_selected)
	
	for swap_mode_id in swap_modes:
		if match_3_board.configuration.swap_mode == swap_modes[swap_mode_id]:
			swap_mode_option_button.select(swap_mode_option_button.get_item_index(swap_mode_id))
		

func prepare_fill_mode() -> void:
	fill_mode_option_button.clear()
	fill_mode_option_button.add_item("FallDown", 0)
	fill_mode_option_button.add_item("Side", 1)
	fill_mode_option_button.add_item("InPlace", 2)
	fill_mode_option_button.item_selected.connect(on_fill_mode_selected)

	for fill_mode_id in fill_modes:
		if match_3_board.configuration.fill_mode == fill_modes[fill_mode_id]:
			fill_mode_option_button.select(fill_mode_option_button.get_item_index(fill_mode_id))


func prepare_min_max_match_spin_boxes() -> void:
	min_match_spin_box.value = match_3_board.configuration.min_match
	max_match_spin_box.value = match_3_board.configuration.max_match
	
	min_match_spin_box.value_changed.connect(on_min_match_value_changed)
	max_match_spin_box.value_changed.connect(on_max_match_value_changed)


func prepare_allowed_shapes() -> void:
	horizontal_shape_checkbox.button_pressed = match_3_board.configuration.horizontal_shape
	vertical_shape_checkbox.button_pressed = match_3_board.configuration.vertical_shape
	tshape_checkbox.button_pressed = match_3_board.configuration.tshape
	lshape_checkbox.button_pressed = match_3_board.configuration.lshape
	
	horizontal_shape_checkbox.toggled.connect(on_allowed_shape_toggled.bind(&"horizontal"))
	vertical_shape_checkbox.toggled.connect(on_allowed_shape_toggled.bind(&"vertical"))
	tshape_checkbox.toggled.connect(on_allowed_shape_toggled.bind(&"tshape"))
	lshape_checkbox.toggled.connect(on_allowed_shape_toggled.bind(&"lshape"))
	

func prepare_animation_flow() -> void:
	consume_sequence_animation_flow_option_button.select(0 if match_3_board.configuration.sequence_animation_is_serial() else 1)
	fall_animation_flow_option_button.select(0 if match_3_board.configuration.fall_animation_is_serial() else 1)
	fill_animation_flow_option_button.select(0 if match_3_board.configuration.fill_animation_is_serial() else 1)
	
	consume_sequence_animation_flow_option_button.item_selected.connect(on_animation_flow_selected.bind(&"sequence"))
	fall_animation_flow_option_button.item_selected.connect(on_animation_flow_selected.bind(&"fall"))
	fill_animation_flow_option_button.item_selected.connect(on_animation_flow_selected.bind(&"fill"))


func on_selection_mode_selected(idx: int) -> void:
	match_3_board.configuration.selection_mode = selection_modes[selection_mode_option_button.get_item_id(idx)]


func on_swap_mode_selected(idx: int) -> void:
	match_3_board.configuration.swap_mode = swap_modes[swap_mode_option_button.get_item_id(idx)]


func on_fill_mode_selected(idx: int) -> void:
	match_3_board.configuration.fill_mode = fill_modes[fill_mode_option_button.get_item_id(idx)]


func on_min_match_value_changed(value: int) -> void:
	match_3_board.configuration.min_match = value


func on_max_match_value_changed(value: int) -> void:
	match_3_board.configuration.max_match = value


func on_allowed_shape_toggled(toggled_on: bool, shape: StringName) -> void:
	match shape:
		&"horizontal":
			match_3_board.configuration.horizontal_shape = toggled_on
		&"vertical":
			match_3_board.configuration.vertical_shape = toggled_on
		&"tshape":
			match_3_board.configuration.tshape = toggled_on
		&"lshape":
			match_3_board.configuration.lshape = toggled_on


func on_animation_flow_selected(idx: int, animation: StringName) -> void:
	match animation:
		&"sequence":
			match_3_board.configuration.sequence_animation = match_3_board.configuration.AnimationFlow.Serial if idx == 0 else match_3_board.configuration.AnimationFlow.Parallel 
		&"fall":
			match_3_board.configuration.fall_animation = match_3_board.configuration.AnimationFlow.Serial if idx == 0 else match_3_board.configuration.AnimationFlow.Parallel 
		&"fill":
			match_3_board.configuration.fill_animation = match_3_board.configuration.AnimationFlow.Serial if idx == 0 else match_3_board.configuration.AnimationFlow.Parallel 


func on_shuffle_button_pressed() -> void:
	match_3_board.shuffle()
	

func on_state_changed(from: Match3Board.BoardState, to: Match3Board.BoardState) -> void:
	var from_state: String = ""
	var to_state: String = ""
	
	if from == Match3Board.BoardState.WaitForInput:
		from_state = "WaitForInput"
	elif from == Match3Board.BoardState.Consume:
		from_state = "Consume"
	elif from == Match3Board.BoardState.SpecialConsume:
		from_state = "SpecialConsume"
	elif from == Match3Board.BoardState.Fall:
		from_state = "Fall"
	elif from == Match3Board.BoardState.Fill:
		from_state = "Fill"
		
	if to == Match3Board.BoardState.WaitForInput:
		to_state = "WaitForInput"
	elif to == Match3Board.BoardState.Consume:
		to_state = "Consume"
	elif to == Match3Board.BoardState.SpecialConsume:
		to_state = "SpecialConsume"
	elif to == Match3Board.BoardState.Fall:
		to_state = "Fall"
	elif to == Match3Board.BoardState.Fill:
		to_state = "Fill"
	
	state_label.text = "%s -> [%s]" % [from_state, to_state]
