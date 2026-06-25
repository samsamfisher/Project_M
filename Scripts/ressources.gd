extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$AnimatedSprite2D.play("icon")



func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		Stats.ajouter_ressource()
		Sound._playSound()
		queue_free()
