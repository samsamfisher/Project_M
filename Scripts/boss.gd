extends Node2D

@onready var spriteBody: AnimatedSprite2D = $Body  # adapte si tu utilises AnimatedSprite2D
@onready var spriteHandLeft: AnimatedSprite2D = $HandLeft  # adapte si tu utilises AnimatedSprite2D
@onready var spriteHandRight: AnimatedSprite2D = $HandRight  # adapte si tu utilises AnimatedSprite2D
@export var vieBoss : float
@export var vie_de_base = 100
@export var facteur = 1
var isAttacking: bool = false
@onready var collideHandLeftAttack = $HandLeft/HandCollideLeft/CollisionShape2D
@onready var collideHandRightAttack = $HandRight/HandCollideRight/CollisionShape2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	vieBoss = vie_de_base + (Stats.time * facteur)
	collideHandLeftAttack.disabled = true
	collideHandRightAttack.disabled = true

func _process(_delta: float) -> void:
	if vieBoss <= 0:
		spriteBody.play("death")
		spriteHandLeft.play("hand_death")
		spriteHandRight.play("hand_death")
	elif isAttacking == false:
		spriteBody.play("idle")
		spriteHandLeft.play("hand_idle")
		spriteHandRight.play("hand_idle")
	
func takeDamage(amount):
	vieBoss -= amount
	if vieBoss <= 0:
		Damage.SendDied()
		
func _on_hand_collide_left_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.takeDamage(1)

func _on_hand_collide_right_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.takeDamage(1)

#region attack boss
# --- Attaques Boss ---
func attackBossHandLeft():
	isAttacking = true
	collideHandLeftAttack.disabled = false
	spriteHandLeft.play("hand_attack")
	print("Left")

func attackBossHandRight():
	isAttacking = true
	collideHandRightAttack.disabled = false
	spriteHandRight.play("hand_attack")
	print("Right")
#endregion

#region anim finies
# --- Animations finies ---
func _on_body_animation_finished() -> void:
	if spriteBody.animation == "death":
		queue_free()
		
func _on_hand_left_animation_finished() -> void:
	if spriteHandLeft.animation == "hand_attack":
		isAttacking = false
		collideHandLeftAttack.disabled = true
		spriteHandLeft.play("hand_idle")

func _on_hand_right_animation_finished() -> void:
	if spriteHandRight.animation == "hand_attack":
		isAttacking = false
		collideHandRightAttack.disabled = true
		spriteHandRight.play("hand_idle")
#endregion

#region timer
# --- Timer finis ---
func _on_timer_attack_hand_left_timeout() -> void:
	attackBossHandLeft()

func _on_timer_attack_hand_right_timeout() -> void:
	attackBossHandRight()
#endregion
