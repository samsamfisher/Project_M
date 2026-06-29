extends Node2D

func _ready() -> void:
	$AnimatedSprite2D.play("idle")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		$Interact.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		$Interact.visible = false
