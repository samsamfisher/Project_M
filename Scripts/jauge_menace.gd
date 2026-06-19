extends Control

@export var value_max_jauge : float = 90
var color1 = 1
var color2 = 1
var color3 = 1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$ProgressBar.value = Stats.time
	$ProgressBar.max_value = value_max_jauge
	color2 = 1 - Stats.time / value_max_jauge
	color3 = 1 - Stats.time / value_max_jauge
	$ProgressBar.modulate = Color(color1,color2,color3,1)
	print(color2)
