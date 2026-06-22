extends Control

@export var value_max_jauge : float = 90
var ratio = Stats.time / value_max_jauge

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var color1 = 1
	var color2 = 1
	var color3 = 1

	$ProgressBar.value = Stats.time
	$ProgressBar.max_value = value_max_jauge
	color2 = 1 - ratio
	color3 = 1 - ratio
	$ProgressBar.modulate = Color(color1,color2,color3,1)
