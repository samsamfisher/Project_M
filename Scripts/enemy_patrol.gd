extends CharacterBody2D


@export var marker2D1: Marker2D
@export var marker2D2: Marker2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var vieEnemyPatrol: int = 3
var cible
var facing: int = 1   # 1 = droite, -1 = gauche
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
enum {PATROL,CHASE}

func _ready() -> void:
	cible = marker2D1

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if vieEnemyPatrol <= 0:
		sprite.play("die")
		return
		
	if abs(cible.global_position.x - global_position.x) <= 10:
		if cible == marker2D1:
			cible = marker2D2
		else:
			cible = marker2D1

	velocity.x = sign(cible.global_position.x - global_position.x) * SPEED
	
	facing = sign(cible.global_position.x - global_position.x)
	if sprite:
		sprite.scale.x = facing
		
	move_and_slide()

	if not is_on_floor() and velocity.y < 0:
		sprite.play("jump")
	elif not is_on_floor() and velocity.y >= 0:
		sprite.play("fall")
	elif is_on_floor() and velocity.x != 0:
		sprite.play("run")
	else:
		sprite.play("idle")


func takeDamage(amount):
	vieEnemyPatrol -= amount
	if vieEnemyPatrol <= 0:
		Damage.SendDiedEnnemies()


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "die":
		queue_free()
