extends Node2D

@onready var spriteBody: AnimatedSprite2D = $Body  # adapte si tu utilises AnimatedSprite2D
@onready var spriteHandLeft: AnimatedSprite2D = $HandLeft  # adapte si tu utilises AnimatedSprite2D
@onready var spriteHandRight: AnimatedSprite2D = $HandRight  # adapte si tu utilises AnimatedSprite2D
@export var vieBoss : float
@export var vie_de_base = 100
@export var facteur = 1


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	vieBoss = vie_de_base + (Stats.time * facteur)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if vieBoss <= 0:
		spriteBody.play("death")
		spriteHandLeft.play("hand_death")
		spriteHandRight.play("hand_death")
	else:
		spriteBody.play("idle")
		spriteHandLeft.play("hand_idle")
		spriteHandRight.play("hand_idle")
	
func takeDamageBoss(amount):
	vieBoss -= amount
	if vieBoss <= 0:
		Damage.SendDied()
		



func _on_body_animation_finished() -> void:
	if spriteBody.animation == "death":
		queue_free()


func _on_hand_collide_left_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.takeDamage(1)
