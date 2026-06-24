extends CharacterBody2D


@export var marker2D1: Marker2D
@export var marker2D2: Marker2D
var cible

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D  # adapte si tu utilises AnimatedSprite2D
enum {PATROL,CHASE}

func _ready() -> void:
	cible = marker2D1

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta


	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	if abs(cible.global_position.x - global_position.x) <= 10:
		if cible == marker2D1:
			cible = marker2D2
		else:
			cible = marker2D1

	velocity.x = sign(cible.global_position.x - global_position.x) * SPEED
	
	
	move_and_slide()

	if not is_on_floor() and velocity.y < 0:
		sprite.play("jump")
	elif not is_on_floor() and velocity.y >= 0:
		sprite.play("fall")
	elif is_on_floor() and velocity.x != 0:
		sprite.play("run")
	else:
		sprite.play("idle")
