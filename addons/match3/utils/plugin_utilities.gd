class_name Match3BoardPluginUtilities


## Flatten any array with n dimensions recursively
static func flatten(array: Array[Variant]):
	var result := []
	
	for i in array.size():
		if typeof(array[i]) >= TYPE_ARRAY:
			result.append_array(flatten(array[i]))
		else:
			result.append(array[i])

	return result


static func pick_random_values(array: Array, items_to_pick: int = 1, duplicates: bool = true) -> Array:
	var result := []
	var target = flatten(array.duplicate())
	target.shuffle()
	
	items_to_pick = min(target.size(), items_to_pick)
	
	for i in range(items_to_pick):
		var item = target.pick_random()
		result.append(item)

		if not duplicates:
			target.erase(item)
		
	return result
	

static func remove_duplicates(array: Array[Variant]) -> Array[Variant]:
	var cleaned_array := []
	
	for element in array:
		if not cleaned_array.has(element):
			cleaned_array.append(element)
		
	return cleaned_array
	
	
static func remove_falsy_values(array: Array[Variant]) -> Array[Variant]:
	var cleaned_array := []
	
	for element in array:
		if element:
			cleaned_array.append(element)
		
	return cleaned_array
	
	
static func middle_element(array: Array):
	if array.size() > 2:
		return array[floor(array.size() / 2.0)]
		
	return null
	

## To detect if a contains elements of b
static func intersects(a: Array, b: Array) -> bool:
	for e: Variant in a:
		if b.has(e):
			return true
			
	return false


static func value_is_between(number: int, min_value: int, max_value: int, inclusive: = true) -> bool:
	if inclusive:
		return number >= min(min_value, max_value) and number <= max(min_value, max_value)
	else :
		return number > min(min_value, max_value) and number < max(min_value, max_value)


## Only works for native nodes like Area2D, Camera2D, etc.
## Example NodePositioner.find_nodes_of_type(self, Control.new())
static func find_nodes_of_type(node: Node, type_to_find: Node) -> Array:
	var  result := []
	
	var childrens = node.get_children(true)

	for child in childrens:
		if child.is_class(type_to_find.get_class()):
			result.append(child)
		else:
			result.append_array(find_nodes_of_type(child, type_to_find))
	
	return result


## Only works for native custom class not for GDScriptNativeClass
## Example NodePositioner.find_nodes_of_custom_class(self, MachineState)
static func find_nodes_of_custom_class(node: Node, class_to_find: Variant) -> Array:
	var  result := []
	
	var childrens = node.get_children(true)

	for child in childrens:
		if child.get_script() == class_to_find:
			result.append(child)
		else:
			result.append_array(find_nodes_of_custom_class(child, class_to_find))
	
	return result
	

## Only works for native Godot Classes like Area3D, Camera2D, etc.
## Example NodeTraversal.first_node_of_type(self, Control.new())
static func first_node_of_type(node: Node, type_to_find: Node):
	if node.get_child_count() == 0:
		return null

	for child in node.get_children():
		if child.is_class(type_to_find.get_class()):
			type_to_find.free()
			return child
	
	type_to_find.free()
	
	return null
	
## Only works for native custom class not for GDScriptNativeClass
## Example NodeTraversal.first_node_of_custom_class(self, MachineState)
static func first_node_of_custom_class(node: Node, class_to_find: GDScript):
	if node.get_child_count() == 0:
		return null

	for child in node.get_children():
		if child.get_script() == class_to_find:
			return child
	
	return null
	
	
static func get_nearest_node_by_distance(from: Vector2, nodes: Array = [], min_distance: float = 0.0, max_range: float = 9999) -> Dictionary:
	var result := {"target": null, "distance": null}
	
	for node in nodes.filter(func(node): return node is Node2D or node is Node3D): ## Only allows node that can use global_position in the world
		var distance_to_target: float = node.global_position.distance_to(from)
		
		if decimal_value_is_between(distance_to_target, min_distance, max_range) and (result.target == null or (distance_to_target < result.distance)):
			result.target = node
			result.distance = distance_to_target
		
	return result

static func set_owner_to_edited_scene_root(node: Node) -> void:
	if Engine.is_editor_hint() and node.get_tree():
		node.owner = node.get_tree().edited_scene_root


static func decimal_value_is_between(number: float, min_value: float, max_value: float, inclusive: = true, precision: float = 0.00001) -> bool:
	if inclusive:
		min_value -= precision
		max_value += precision

	return number >= min(min_value, max_value) and number <= max(min_value, max_value)
