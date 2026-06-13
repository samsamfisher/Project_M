extends CharacterBody2D

# =========================================================
#  CONTRÔLEUR DE DÉPLACEMENT — Plateformer 2D (Godot 4)
#  Toutes les valeurs @export sont réglables dans l'éditeur.
#  Joue avec elles pour trouver TON feeling.
# =========================================================

# --- Déplacement horizontal ---
@export var max_speed: float = 300.0        # vitesse de pointe (px/s)
@export var acceleration: float = 2000.0    # montée en vitesse au sol
@export var friction: float = 2500.0        # freinage à l'arrêt au sol
@export var air_acceleration: float = 1500.0 # contrôle dans les airs (un peu moins qu'au sol)

# --- Saut ---
@export var jump_velocity: float = -450.0    # négatif car l'axe Y pointe vers le bas
@export var jump_cut_multiplier: float = 0.4 # saut variable : on coupe l'élan si on relâche tôt
@export var coyote_time: float = 0.1         # délai de grâce après avoir quitté le sol (s)
@export var jump_buffer_time: float = 0.1    # mémorise un appui saut juste avant d'atterrir (s)
@export var double_saut: bool = false        # passe à True si on peut éxecuter un Double Saut

# --- Gravité asymétrique ---
@export var gravity_up: float = 1200.0      # quand on monte
@export var gravity_down: float = 1800.0    # quand on tombe (plus fort = saut plus nerveux)

# --- Dash ---
@export var dash_speed: float = 700.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.5

# --- État interne ---
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var is_dashing: bool = false
var facing: int = 1   # 1 = droite, -1 = gauche

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D  # adapte si tu utilises AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# --- On fait avancer tous les timers ---
	coyote_timer -= delta
	jump_buffer_timer -= delta
	dash_cooldown_timer -= delta


	# Tant qu'on est au sol, on recharge le coyote time
	if is_on_floor():
		coyote_timer = coyote_time
		double_saut = true


	# --- Lecture de la direction ---
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0:
		facing = sign(direction)
		# Oriente le sprite (commente ces 2 lignes si tu n'as pas encore de sprite)
		if sprite:
			sprite.flip_h = facing < 0
		
	
	# --- DASH ---
	# Pendant un dash : vitesse fixe, pas de gravité, on ignore le reste.
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
		move_and_slide()
		return


	# Déclenchement du dash
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
		start_dash()
		return


	# --- Déplacement horizontal (accélération / friction) ---
	if direction != 0:
		var accel := acceleration if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, direction * max_speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		

	# --- Gravité (asymétrique) ---
	if not is_on_floor():
		var g := gravity_up if velocity.y < 0 else gravity_down
		velocity.y += g * delta


	# --- Jump buffer : on mémorise l'appui ---
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time


	# --- Saut : possible si on a un appui en mémoire ET du coyote time ---
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0
		coyote_timer = 0
		
	# --- Double saut ---	
	if not is_on_floor() and double_saut == true and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
		double_saut = false


	# --- Saut variable : relâcher tôt = saut plus court ---
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= jump_cut_multiplier

	move_and_slide()

	if not is_on_floor() and velocity.y < 0:
		sprite.play("jump")
	elif not is_on_floor() and velocity.y >= 0:
		sprite.play("fall")
	elif is_on_floor() and velocity.x != 0:
		sprite.play("run")
	else:
		sprite.play("idle")
	

func start_dash() -> void:
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	velocity = Vector2(facing * dash_speed, 0.0)  # dash horizontal pur
