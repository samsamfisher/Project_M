extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D  # adapte si tu utilises AnimatedSprite2D
@export var vieBoss : float
@export var vie_de_base = 100
@export var facteur = 1


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	vieBoss = vie_de_base + (Stats.time * facteur)
	Damage.takeDamage.connect(takeDamageBoss)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	sprite.play("idle")
	
func takeDamageBoss(amount):
	vieBoss -= amount
	if vieBoss <= 0:
		Damage.SendDied()
		queue_free()
