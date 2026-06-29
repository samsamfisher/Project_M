extends CharacterBody2D

# =========================================================
#  CONTRÔLEUR DE DÉPLACEMENT
# =========================================================

# --- Déplacement horizontal ---
@export var max_speed: float = 300.0        # vitesse de pointe (px/s)
@export var acceleration: float = 2000.0    # montée en vitesse au sol
@export var friction: float = 5000.0        # freinage à l'arrêt au sol
@export var air_acceleration: float = 1500.0 # contrôle dans les airs (un peu moins qu'au sol)

# --- Saut ---
@export var jump_velocity: float = -450.0    # négatif car l'axe Y pointe vers le bas
@export var jump_cut_multiplier: float = 0.4 # saut variable : on coupe l'élan si on relâche tôt
@export var coyote_time: float = 0.1         # délai de grâce après avoir quitté le sol (s)
@export var jump_buffer_time: float = 0.1    # mémorise un appui saut juste avant d'atterrir (s)
@export var double_saut: bool = false        # passe à True si on peut éxecuter un Double Saut

# --- Gravité asymétrique ---
@export var gravity_up: float = 1300.0      # quand on monte
@export var gravity_down: float = 2800.0    # quand on tombe (plus fort = saut plus nerveux)

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
var is_attacking: bool = false
@onready var collisionEpee = $Sword/CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- Marchand ---
var timerMarchand: float = 10          # délai d'attente avant que les ressources soient doublées (s)
var is_nextToMarchand: bool = false    # true quand le joueur est dans la zone de détection du marchand
var timerTriggerMarchand: bool = false # true quand le joueur a appuyé sur E et que le doublage est en cours

func _ready() -> void:
	sprite.animation_finished.connect(_on_anim_finished)
	collisionEpee.disabled = true

func _on_anim_finished() -> void:
	if sprite.animation == "attack_sword":
		is_attacking = false
		collisionEpee.disabled = true

func _physics_process(delta: float) -> void:
	# --- On fait avancer tous les timers ---
	coyote_timer -= delta
	jump_buffer_timer -= delta
	dash_cooldown_timer -= delta
	# --- Doublage des ressources (marchand) ---
	# Le timer tourne ici, avant tout return, pour ne jamais se figer
	if timerTriggerMarchand:
		timerMarchand -= delta
		if timerMarchand <= 0:
			Stats.ressources_doublees()
			timerTriggerMarchand = false

	# Bloque tout le mouvement pendant le doublage — les animations et le timer continuent
	if timerTriggerMarchand:
		return
	
	# Tant qu'on est au sol, on recharge le coyote time
	if is_on_floor():
		coyote_timer = coyote_time
		#double_saut = true

	# --- Lecture de la direction ---
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0:
		facing = sign(direction)
		# Oriente le sprite
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
		double_saut = true
		
	# --- Double saut ---	
	elif not is_on_floor() and double_saut == true and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
		double_saut = false

	# --- Saut variable : relâcher tôt = saut plus court ---
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= jump_cut_multiplier
		
	# --- Sword Attack ---
	if Input.is_action_just_pressed("swordAttack") and not is_attacking:
		sword_attack()

	move_and_slide()
	
	if is_attacking:
		return

	if not is_on_floor() and velocity.y < 0:
		sprite.play("jump")
	elif not is_on_floor() and velocity.y >= 0:
		sprite.play("fall")
	elif is_on_floor() and velocity.x != 0:
		sprite.play("run")
	else:
		sprite.play("idle")
		
		
	# --- Interaction marchand ---
	# Déclenche le doublage si le joueur est dans la zone et appuie sur E
	if is_nextToMarchand:
		if not Stats.ressources_deja_doublees and Input.is_action_just_pressed("interact"):
			timerTriggerMarchand = true
			$AnimatedSprite2D.play("RessourceToMarchand")
		elif Stats.ressources_deja_doublees and Input.is_action_just_pressed("interact"):
			print("Ressources déjà doublées !")

func start_dash() -> void:
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	velocity = Vector2(facing * dash_speed, 0.0)  # dash horizontal pur

#region attaque à l'épée
func sword_attack() -> void:
	is_attacking = true
	collisionEpee.disabled = false
	sprite.play("attack_sword")
	print("attack !")
	
func _on_sword_body_entered(body: Node2D) -> void:
	if body.is_in_group("Boss"):
		body.takeDamageBoss(100)
		print("LE BOSS PERDS 100 DE VIE")
#endregion

func takeDamage(amount):
	Stats.vie -= amount
	Stats.vie_changee.emit(Stats.vie)
	print("Vie restantes : ", Stats.vie)
	print("Vie sur STATS : ", Stats.vie)
	if Stats.vie <= 0:
		Damage.SendPlayerDied()

#region dectection avec le marchand
func _on_detection_area_entered(area: Area2D) -> void:
	if area.is_in_group("Marchand"):
		is_nextToMarchand = true

func _on_detection_area_exited(area: Area2D) -> void:
	if area.is_in_group("Marchand"):
		is_nextToMarchand = false
#endregion
