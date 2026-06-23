extends Area2D

@export var spawnBoss = PackedScene.new()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		spawn_boss.call_deferred()

func spawn_boss() -> void:
	var boss = spawnBoss.instantiate()
	add_child(boss)
	boss.global_position = $Marker2D.global_position
