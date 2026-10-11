class_name Match3SequenceConsumer extends RefCounted


var board: Match3Board
## Dictionary with structure <RuleId, SequenceConsumeRule>
var rules: Dictionary = {}


func _init(_board: Match3Board, consume_rules: Array[SequenceConsumeRule]):
	board = _board

	for rule: SequenceConsumeRule in consume_rules:
		rules.get_or_add(rule.id, rule)


func add_sequence_consume_rules(rules: Array[SequenceConsumeRule]) -> Match3SequenceConsumer:
	for rule: SequenceConsumeRule in rules:
		add_sequence_consume_rule(rule)
	
	return self
	
	
func add_sequence_consume_rule(rule: SequenceConsumeRule) -> Match3SequenceConsumer:
	rules.get_or_add(rule.id, rule)
	
	return self


func remove_rules(rules: Array[SequenceConsumeRule]) -> Match3SequenceConsumer:
	for rule in rules:
		remove_rule(rule)
		
	return self


func remove_rule(rule: SequenceConsumeRule) -> Match3SequenceConsumer:
	rules.erase(rule.id)
	
	return self


func sequences_to_combo_rules(matches: Array[Match3Sequence]) -> Array[Match3SequenceConsumer.Match3SequenceConsumeResult]:
	if matches.is_empty():
		return []
	
	var combos: Array[Match3SequenceConsumer.Match3SequenceConsumeResult] = []
	
	for sequence: Match3Sequence in matches:
		combos.append(consume_sequence(sequence))
		
	return combos
	

func consume_sequence(sequence: Match3Sequence) -> Match3SequenceConsumeResult:
	var found_rule: SequenceConsumeRule = null
	
	var active_rules: Array[SequenceConsumeRule] = []
	active_rules.assign(rules.values().duplicate())
	
	if active_rules.size() > 1:
		active_rules.sort_custom(
			func(a: SequenceConsumeRule, b: SequenceConsumeRule): return a.priority > b.priority)
	
	
	for rule: SequenceConsumeRule in active_rules:
		if rule.meet_conditions(sequence):
			found_rule = rule
			break
	
	if found_rule:
		## TODO - SEE HOW TO SPLIT COMBOS WHEN THE SEQUENCE IS MORE COMPLEX THAN SIMILAR PIECES
		if sequence.all_pieces_are_the_same():
			return Match3SequenceConsumeResult.new([
				Match3SequenceConsumeCombo.new(sequence, found_rule.piece_to_spawn)
				])
		
	return Match3SequenceConsumeResult.new([Match3SequenceConsumeCombo.new(sequence)])


#region Data container classes
class Match3SequenceConsumeResult:
	var sequence_size: int
	var combos: Array[Match3SequenceConsumeCombo]
	
	func _init(sequence_combos: Array[Match3SequenceConsumeCombo]) -> void:
		sequence_size = sequence_combos.reduce(func(accum, combo: Match3SequenceConsumeCombo): return accum + combo.size(), 0)
		combos = sequence_combos
	
	
	func unique_pieces() -> Array[Match3Piece]:
		var pieces: Array[Match3Piece] = []
		
		for combo: Match3SequenceConsumeCombo in combos:
			if pieces.any(func(piece: Match3Piece): return piece.id == combo.piece.id):
				continue
				
			pieces.append(combo.piece)
		
		return pieces


class Match3SequenceConsumeCombo:
	var sequence: Match3Sequence
	var special_piece_to_spawn: Match3PieceConfiguration
	
	func _init(_sequence: Match3Sequence, piece_to_spawn: Match3PieceConfiguration = null) -> void:
		sequence = _sequence
		special_piece_to_spawn = piece_to_spawn
	
	
	func size() -> int:
		return sequence.size()

#endregion
