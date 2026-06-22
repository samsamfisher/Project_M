extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D  # adapte si tu utilises AnimatedSprite2D
@export var vie : float
@export var vie_de_base = 800
@export var facteur = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	vie = vie_de_base + (Stats.time * facteur)
	print(vie)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	sprite.play("idle")
