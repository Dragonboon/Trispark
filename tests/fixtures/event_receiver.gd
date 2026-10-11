extends Node

var received: Array[Match3BoardEvent] = []
var simple_calls: int = 0


func on_event(event: Match3BoardEvent) -> void:
	received.append(event)


func on_simple_event() -> void:
	simple_calls += 1
