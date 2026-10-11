class_name Match3Piece extends Node2D

signal selected
signal drag_started
signal drag_ended
signal triggered
signal queued

const GroupName: StringName = &"match3-pieces"
const SpecialGroupName: StringName = &"match3-special-pieces"
const ObstacleGroupName: StringName = &"match3-obstacle-pieces"

@export_category("Visual")
@export var texture_scale: float = 0.85
@export_category("Drag&Drop")
@export var reset_position_on_drag_release: bool = true
@export var drag_smooth_factor: float = 20.0

#region Inherit properties from Match3PieceConfiguration
var id: StringName
var type: Match3PieceConfiguration.PieceType = Match3PieceConfiguration.PieceType.Normal
var shape: StringName = &""
var color: Color = Color.WHITE
var priority: int = 0:
	set(value):
		priority = maxi(0, value)
var pieces_collision_layer: int = 8:
	set(value):
		pieces_collision_layer = clampi(value, 0, 32)
		
		if detection_area:
			detection_area.collision_mask = pieces_collision_layer
			
		if piece_area:
			piece_area.collision_mask = pieces_collision_layer

var can_be_swapped: bool = true
var can_be_moved: bool = true
var can_be_shuffled: bool = true
var can_be_triggered: bool = false
var can_be_replaced: bool = true
var can_be_consumed: bool = true
#endregion

var mouse_region: Button
var current_position: Vector2 = Vector2.ZERO
var m_offset: Vector2 = Vector2.ZERO

var is_locked: bool = false
var drag_enabled: bool = false:
	set(value):
		drag_enabled = value
		
		if drag_enabled:
			disable_piece_area()
			enable_detection_area()
		else:
			enable_piece_area()
			disable_detection_area()

		if is_inside_tree():
			set_process(drag_enabled and not is_locked)
	
## Could be Sprite2D or AnimatedSprite2D
var sprite: Node2D
var original_z_index: int = 0

var cell: Match3GridCell:
	set(value):
		if value != cell:
			cell = value
			
			if cell and is_inside_tree():
				_prepare_sprite()
				
var piece_area: Area2D
var detection_area: Area2D
var drag_target: Node2D = self

var is_triggered: bool = false:
	set(value):
		if value != is_triggered:
			is_triggered = value
			
			if is_triggered:
				triggered.emit()

var on_queue: bool = false:
	set(value):
		if value != on_queue:
			on_queue = value
			
			if on_queue:
				queued.emit()


static func from_configuration(configuration: Match3PieceConfiguration) -> Match3Piece:
	var piece: Match3Piece = configuration.scene.instantiate()
	piece.id = configuration.id
	piece.type = configuration.type
	piece.shape = configuration.shape
	piece.color = configuration.color
	piece.priority = configuration.priority
	piece.pieces_collision_layer = configuration.pieces_collision_layer
	piece.can_be_swapped = configuration.can_be_swapped
	piece.can_be_moved = configuration.can_be_moved
	piece.can_be_shuffled = configuration.can_be_shuffled
	piece.can_be_triggered = configuration.can_be_triggered
	piece.can_be_replaced = configuration.can_be_replaced
	piece.can_be_consumed = configuration.can_be_consumed
	
	return piece


func _enter_tree() -> void:
	add_to_group(GroupName)
	
	if is_special():
		add_to_group(SpecialGroupName)
	elif is_obstacle():
		add_to_group(ObstacleGroupName)
	
	name = "%s_%s" % [id, shape]
	z_index = 10
	original_z_index = z_index


func _ready() -> void:
	_prepare_sprite()
	await get_tree().process_frame
	
	_create_mouse_region_button()
	await get_tree().process_frame
	
	_prepare_area_detectors()
	set_process(drag_enabled and not is_locked)
	


func _process(delta: float) -> void:
	if drag_enabled:
		drag_target.global_position = drag_target.global_position.lerp(get_global_mouse_position(), drag_smooth_factor * delta) if drag_smooth_factor > 0 else get_global_mouse_position()
		current_position = drag_target.global_position + m_offset
	

func equals_to(other_piece: Match3Piece) -> bool:
	return same_type_as(other_piece) and same_shape_as(other_piece) and same_color_as(other_piece)


func same_type_as(other_piece: Match3Piece) -> bool:
	return type == other_piece.type 


func same_shape_as(other_piece: Match3Piece) -> bool:
	return shape == other_piece.shape 


func same_color_as(other_piece: Match3Piece) -> bool:
	return color.is_equal_approx(other_piece.color)


#region Behaviour configuration
func with_swapped(enabled: bool) -> Match3Piece:
	can_be_swapped = enabled
	
	return self


func with_moved(enabled: bool) -> Match3Piece:
	can_be_moved = enabled
	
	return self


func with_shuffled(enabled: bool) -> Match3Piece:
	can_be_shuffled = enabled
	
	return self


func with_triggered(enabled: bool) -> Match3Piece:
	can_be_triggered = enabled
	
	return self


func with_replaced(enabled: bool) -> Match3Piece:
	can_be_replaced = enabled
	
	return self
	
func with_consumed(enabled: bool) -> Match3Piece:
	can_be_consumed = enabled
	
	return self
#endregion

func change_priority(new_value: int) -> Match3Piece:
	priority = new_value
	
	return self

#region Types
func is_normal() -> bool:
	return type == Match3PieceConfiguration.PieceType.Normal


func is_special() -> bool:
	return type == Match3PieceConfiguration.PieceType.Special


func is_obstacle() -> bool:
	return type == Match3PieceConfiguration.PieceType.Obstacle
#endregion


#region Overridables
func match_with(other_piece: Match3Piece) -> bool:
	if is_obstacle() or other_piece.is_obstacle():
		return false
	
	if is_normal() and other_piece.is_normal():
		return equals_to(other_piece)
		
	if (is_special() and other_piece.is_normal()) or (is_normal() and other_piece.is_special()):
		return same_shape_as(other_piece)
		
	return false

## Special pieces run this function when triggered from board
func trigger(board: Match3Board) -> Array[Match3Sequence]:
	is_triggered = true
		
	return []

## When the piece comes from a sequence consume rule, this function choose
## in what cell is going to be spawned. It receives the board and the origin sequence
## in case you need additional information
func spawn(board: Match3Board, sequence: Match3Sequence) -> Match3GridCell:
	return sequence.middle_cell()

#endregion


func detect_near_piece() -> Match3Piece:
	var nearest_piece_area: Dictionary = Match3BoardPluginUtilities.get_nearest_node_by_distance(
		global_position, detection_area.get_overlapping_areas()
		)
	
	var piece_area = nearest_piece_area.get("target", null)
	
	if piece_area != null and piece_area is Area2D:
		return piece_area.get_parent() as Match3Piece
		
	return null
	
	
func lock() -> void:
	is_locked = true
	

func unlock() -> void:
	is_locked = false


func enable_drag(target: Node2D = self) -> void:
	drag_target = target
	drag_enabled = true
	
	
func disable_drag() -> void:
	drag_enabled = false


func reset_drag_position() -> void:
	if cell and is_instance_valid(cell):
		drag_target.position = cell.position


func enable_piece_area() -> void:
	piece_area.set_deferred("monitorable", true)

	
func disable_piece_area() -> void:
	piece_area.set_deferred("monitorable", false)


func enable_detection_area() -> void:
	detection_area.set_deferred("monitoring", true)

	
func disable_detection_area() -> void:
	detection_area.set_deferred("monitoring", false)


func calculate_texture_scale(texture: Texture2D, size: Vector2i = Vector2i(48, 48)) -> Vector2:
	var texture_size = texture.get_size()
	
	return Vector2(size.x / texture_size.x, size.y / texture_size.y) * texture_scale


func _create_mouse_region_button() -> void:
	if mouse_region == null:
		mouse_region = Button.new()
		mouse_region.self_modulate.a8 = 100 ## TODO - CHANGE TO 0 WHEN FINISH DEBUG
	
	var sprite = Match3BoardPluginUtilities.first_node_of_type(self, Sprite2D.new())
	
	if sprite == null:
		sprite = Match3BoardPluginUtilities.first_node_of_type(self, AnimatedSprite2D.new())
	
	assert(sprite != null, "Match3Piece: %s needs to have a Sprite2D or AnimatedSprite2D as child to create the mouse region" % name)
	
	sprite.add_child(mouse_region)
	
	mouse_region.position = Vector2.ZERO
	mouse_region.anchors_preset = Control.PRESET_FULL_RECT
	
	mouse_region.pressed.connect(on_mouse_region_pressed)
	mouse_region.button_down.connect(on_mouse_region_holded)
	mouse_region.button_up.connect(on_mouse_region_released)


func _prepare_sprite() -> void:
	sprite = Match3BoardPluginUtilities.first_node_of_type(self, Sprite2D.new())
	
	if sprite == null:
		sprite = Match3BoardPluginUtilities.first_node_of_type(self, AnimatedSprite2D.new())
	
	assert(sprite != null, "Match3Piece: %s needs to have a Sprite2D or AnimatedSprite2D as child to create the mouse region" % name)
	
	if sprite is Sprite2D:
		sprite.scale = calculate_texture_scale(sprite.texture, cell.size if cell else null)
	elif sprite is AnimatedSprite2D:
		sprite.scale = calculate_texture_scale(sprite.get_sprite_frames().get_frame(sprite.animation, sprite.get_frame()))


func _prepare_area_detectors() -> void:
	piece_area = Area2D.new()
	piece_area.name = "PieceArea"
	var piece_area_collision = CollisionShape2D.new()
	piece_area_collision.name = "PieceAreaCollisionShape"
	var piece_area_collision_shape = RectangleShape2D.new()
	piece_area_collision.shape = piece_area_collision_shape
	piece_area.add_child(piece_area_collision)
	
	detection_area = Area2D.new()
	detection_area.name = "DetectionArea"
	var detection_area_collision = CollisionShape2D.new()
	detection_area_collision.name = "DetectionAreaCollisionShape"
	
	var detection_area_collision_shape = RectangleShape2D.new()
	detection_area_collision.shape = detection_area_collision_shape
	
	detection_area.add_child(detection_area_collision)
	
	piece_area.collision_layer = pow(2, pieces_collision_layer - 1)
	piece_area.collision_mask = 0
	piece_area.monitoring = false
	piece_area.monitorable = true
	
	detection_area.collision_layer = 0
	detection_area.collision_mask = piece_area.collision_layer
	detection_area.monitoring = false ## Deactivated on initialization, it will active when piece is selected
	detection_area.monitorable = false
	
	piece_area_collision.shape.size = cell.size / 1.5 
	detection_area_collision.shape.size = cell.size / 1.5
	
	add_child(piece_area)
	add_child(detection_area)

#region Signal callbacks
func on_mouse_region_pressed() -> void:
	if is_locked:
		return
	
	selected.emit()


func on_mouse_region_holded() -> void:
	if is_locked:
		return
	
	z_index = original_z_index + 100
	z_as_relative = false
	
	## We don't want to enable drag when connecting lines as the pieces needs to be static
	#if not board.is_swap_mode_connect_line():
	m_offset = drag_target.transform.origin - get_global_mouse_position()
	drag_started.emit()
	

func on_mouse_region_released() -> void:
	z_index = original_z_index
	z_as_relative = true
	
	drag_ended.emit()

#endregion
