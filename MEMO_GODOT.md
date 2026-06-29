# Mémo Godot — Project_M

> Référence vivante. On l'alimente au fur et à mesure des sprints.

---

## 1. Nœuds principaux utilisés

| Nœud | Rôle dans le projet |
|---|---|
| `CharacterBody2D` | Joueur, ennemi patrouilleur — corps avec physique et détection de sol |
| `Node2D` | Boss, ressources — nœud 2D générique sans physique intégrée |
| `Node` | Autoloads (Stats, Damage, Sound) — pas de visuel, juste de la logique |
| `Area2D` | Détection de zone : ramasser une ressource, déclencher le spawn du boss, mains du boss |
| `AnimatedSprite2D` | Sprites avec animations nommées |
| `CollisionShape2D` | Forme de collision (hitbox épée désactivée/réactivée à la demande) |
| `AudioStreamPlayer` | Lecture de son (créé dynamiquement dans Sound) |
| `Marker2D` | Point de référence dans la scène (bornes de patrouille, position de spawn) |
| `ProgressBar` | Jauge de menace (value / max_value / modulate) |
| `CanvasLayer` | Overlay UI (menus victoire et game over — reste par-dessus tout) |
| `Control` | Base des éléments d'interface (jauge de menace) |

---

## 2. Autoloads (Singletons)

Un autoload est un nœud chargé au démarrage du jeu, accessible depuis **n'importe quel script** par son nom.
Se configure dans **Projet → Paramètres du projet → Autoload**.

```
Stats     → Scripts/Autoload/Stats.gd
Damage    → Scripts/Autoload/damage.gd
Sound     → Scripts/Autoload/sound.gd
```

**Stats** — état global du jeu
```gdscript
var ressources: int = 0
var time: float = 0          # s'incrémente chaque frame avec delta
signal ressources_changees(total: int)

func ajouter_ressource():
    ressources += 1
    ressources_changees.emit(ressources)
```

**Damage** — bus de signaux de mort + pause
```gdscript
signal died         # boss mort → victoire
signal playerDied   # joueur mort → game over

func SendDied():
    died.emit()
    get_tree().paused = true

func SendPlayerDied():
    playerDied.emit()
    get_tree().paused = true
```

**Sound** — lecteur audio centralisé
```gdscript
func _ready():
    player = AudioStreamPlayer.new()
    player.stream = preload("res://Sound/mon_son.wav")
    add_child(player)
```

---

## 3. Signaux

```gdscript
# Déclarer
signal mon_signal(parametre: int)

# Émettre
mon_signal.emit(42)

# Connecter (dans _ready)
autre_noeud.mon_signal.connect(ma_fonction)

# Connecter un signal built-in via l'inspecteur ou en code
$Area2D.body_entered.connect(_on_body_entered)
animation_finished.connect(_on_anim_finished)
```

Signaux built-in utilisés :
- `AnimatedSprite2D.animation_finished` — détecter la fin d'une animation (ex : fin du slash d'épée)
- `Area2D.body_entered(body)` — un corps physique entre dans la zone

---

## 4. Mouvement — CharacterBody2D

```gdscript
# Lecture de direction (-1, 0, 1)
var direction := Input.get_axis("move_left", "move_right")

# Accélération / friction avec move_toward
velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
velocity.x = move_toward(velocity.x, 0.0, friction * delta)   # à l'arrêt

# Gravité manuelle (asymétrique : monte doucement, tombe vite)
if not is_on_floor():
    var g := gravity_up if velocity.y < 0 else gravity_down
    velocity.y += g * delta

# Appliquer le mouvement
move_and_slide()

# Vérifications utiles
is_on_floor()   # true si le perso touche le sol
```

Pour l'ennemi patrouilleur on utilise la gravité par défaut du projet :
```gdscript
velocity += get_gravity() * delta
```

---

## 5. Techniques de saut

### Coyote time
Permet de sauter un court instant après avoir quitté un bord (grace window).
```gdscript
if is_on_floor():
    coyote_timer = coyote_time      # recharge tant qu'on est au sol

coyote_timer -= delta               # s'écoule dans les airs

if coyote_timer > 0:
    # autoriser le saut
```

### Jump buffer
Mémorise un appui saut juste *avant* d'atterrir, pour que le saut se déclenche dès le contact.
```gdscript
if Input.is_action_just_pressed("jump"):
    jump_buffer_timer = jump_buffer_time

jump_buffer_timer -= delta

if jump_buffer_timer > 0 and coyote_timer > 0:
    velocity.y = jump_velocity
    jump_buffer_timer = 0
    coyote_timer = 0
```

### Saut variable (jump cut)
Relâcher tôt = saut plus court.
```gdscript
if Input.is_action_just_released("jump") and velocity.y < 0:
    velocity.y *= jump_cut_multiplier   # ex : 0.4
```

### Double saut
```gdscript
# Au premier saut : double_saut = true
# Dans les airs :
elif not is_on_floor() and double_saut and Input.is_action_just_pressed("jump"):
    velocity.y = jump_velocity
    double_saut = false
```

---

## 6. Dash

Pendant le dash : vitesse fixe, on coupe le reste de la logique avec `return`.
```gdscript
func start_dash():
    is_dashing = true
    dash_timer = dash_duration
    dash_cooldown_timer = dash_cooldown
    velocity = Vector2(facing * dash_speed, 0.0)

# Dans _physics_process :
if is_dashing:
    dash_timer -= delta
    if dash_timer <= 0:
        is_dashing = false
    move_and_slide()
    return   # ← on ignore tout le reste
```

---

## 7. Timers manuels (sans nœud Timer)

Simple float décrémenté par delta — plus léger qu'un nœud Timer pour des cooldowns courts.
```gdscript
var mon_timer: float = 0.0

# Dans _physics_process :
mon_timer -= delta

# Déclencher :
mon_timer = duree_souhaitee

# Tester si expiré :
if mon_timer <= 0:
    # autoriser l'action
```

---

## 8. Animations

```gdscript
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

sprite.play("idle")
sprite.play("run")
sprite.play("attack_sword")

sprite.flip_h = true            # miroir horizontal (joueur)
sprite.scale.x = facing         # flip via scale (ennemi, -1 ou 1)
```

Détecter la fin d'une animation :
```gdscript
func _ready():
    sprite.animation_finished.connect(_on_anim_finished)

func _on_anim_finished():
    if sprite.animation == "attack_sword":
        is_attacking = false
        collisionEpee.disabled = true
```

---

## 9. Groupes

Assigner un groupe : inspecteur du nœud → onglet **Nœud** → **Groupes**.

```gdscript
# Vérifier l'appartenance
if body.is_in_group("Player"):
    body.takeDamage(1)

if body.is_in_group("Boss"):
    body.takeDamageBoss(100)
```

---

## 10. Instanciation dynamique de scène

```gdscript
@export var spawnBoss: PackedScene   # assigner dans l'inspecteur

func spawn_boss():
    var boss = spawnBoss.instantiate()
    add_child(boss)
    boss.global_position = $Marker2D.global_position
```

**`call_deferred()`** — différer un appel pour éviter les conflits quand on est dans un callback physique (`body_entered`) :
```gdscript
func _on_body_entered(body):
    if body.is_in_group("Player"):
        spawn_boss.call_deferred()   # pas spawn_boss() directement
```

**`queue_free()`** — supprimer un nœud proprement à la fin du frame (pas de `free()` brutal) :
```gdscript
queue_free()   # dans le nœud lui-même
autre_noeud.queue_free()   # depuis l'extérieur
```

---

## 11. Hitbox temporaire (épée)

Activer la hitbox uniquement pendant l'animation d'attaque, puis la désactiver.
```gdscript
@onready var collisionEpee = $Sword/CollisionShape2D

func _ready():
    collisionEpee.disabled = true   # désactivée au départ

func sword_attack():
    is_attacking = true
    collisionEpee.disabled = false  # active pendant l'animation
    sprite.play("attack_sword")

func _on_anim_finished():
    if sprite.animation == "attack_sword":
        is_attacking = false
        collisionEpee.disabled = true   # re-désactive
```

---

## 12. UI

**ProgressBar colorée dynamiquement :**
```gdscript
$ProgressBar.value = Stats.time
$ProgressBar.max_value = value_max_jauge
$ProgressBar.modulate = Color(1, 1 - ratio, 1 - ratio, 1)  # blanc → rouge
```

**Afficher un float dans un Label :**
```gdscript
$Label.text = "%.2f" % Stats.time   # 2 décimales
```

**CanvasLayer** — rester par-dessus le jeu même quand la caméra bouge.
```gdscript
visible = false   # caché par défaut
visible = true    # affiché à la mort / victoire
```

---

## 13. Pause du jeu

```gdscript
get_tree().paused = true
get_tree().paused = false
```

Les nœuds continuent de fonctionner seulement si leur `Process Mode` est réglé sur `Always` ou `When Paused` dans l'inspecteur. Par défaut un nœud est mis en pause (`Inherit`).

**Choisir le bon mode pour l'UI de pause / game over :**
- `Always` → tourne tout le temps (avant ET pendant la pause) — risque d'effets de bord en jeu normal
- `When Paused` → actif **uniquement** quand le jeu est en pause — parfait pour les menus game over / victoire

```gdscript
# Dans l'inspecteur : nœud racine de l'UI → Process Mode → When Paused
# Tous les enfants héritent automatiquement via Inherit
```

**Piège :** si les boutons ne répondent pas en pause, c'est souvent le `Process Mode` du nœud parent qui est resté sur `Inherit` — il hérite de la pause de l'arbre principal et se gèle.

---

## 14. Patrouille entre deux points (Marker2D)

```gdscript
@export var marker2D1: Marker2D
@export var marker2D2: Marker2D
var cible: Marker2D

func _ready():
    cible = marker2D1

func _physics_process(delta):
    if abs(cible.global_position.x - global_position.x) <= 10:
        cible = marker2D2 if cible == marker2D1 else marker2D1

    velocity.x = sign(cible.global_position.x - global_position.x) * SPEED
```

---

## 15. Boss scalé par le temps

La vie du boss augmente en fonction du temps passé dans le niveau — plus le joueur traîne, plus c'est dur.
```gdscript
func _ready():
    vieBoss = vie_de_base + (Stats.time * facteur)
```

---

## 16. Déclarations importantes

```gdscript
@export var vitesse: float = 300.0   # visible ET modifiable dans l'inspecteur
@onready var sprite = $AnimatedSprite2D   # résolu quand le nœud est prêt (après _ready)

enum {PATROL, CHASE}   # machine à états simple
```

---

## 17. Changer de scène / relancer le niveau

```gdscript
# Recharger la scène courante
get_tree().reload_current_scene()

# Aller vers une scène spécifique
get_tree().change_scene_to_file("res://Scènes/main.tscn")
```

**Attention aux Autoloads :** ils persistent entre les rechargements de scène — leurs variables ne se remettent pas à zéro automatiquement. Il faut une méthode `restart()` dédiée.

```gdscript
# Dans Stats.gd
func restart() -> void:
    ressources = 0
    vie = 3
    time = 0
    get_tree().paused = false
    get_tree().reload_current_scene()
```

**Pourquoi ne pas émettre les signaux dans restart() ?** Parce que `reload_current_scene()` recrée tous les nœuds HUD depuis zéro — leurs `_ready()` relisent directement les variables de `Stats`. Les signaux sont inutiles ici.

---

## 18. Détection Area2D ↔ Area2D (interaction marchand)

Pour détecter une `Area2D` depuis une autre `Area2D`, utiliser `area_entered` et non `body_entered`.

| Signal | Détecte |
|---|---|
| `body_entered` | `CharacterBody2D`, `RigidBody2D` — corps avec physique |
| `area_entered` | `Area2D` — zones de détection sans physique |

**Piège courant :** le groupe doit être sur le bon nœud. Si l'`Area2D` du marchand détecte le joueur, c'est **l'`Area2D`** qui doit être dans le groupe — pas son nœud parent.

```gdscript
# Dans Player.gd — détecte quand une Area2D entre dans la zone Detection
func _on_detection_area_entered(area: Area2D) -> void:
    if area.is_in_group("Marchand"):
        is_nextToMarchand = true

func _on_detection_area_exited(area: Area2D) -> void:
    if area.is_in_group("Marchand"):
        is_nextToMarchand = false
```

Les **layers/masks** doivent aussi correspondre entre les deux `Area2D` pour que la détection fonctionne.

---

## 19. Input dans un signal vs dans _process

`Input.is_action_just_pressed()` retourne `true` pendant **une seule frame**. Si tu le mets dans un signal (ex: `body_entered`, `area_entered`), la probabilité que le joueur appuie exactement cette frame-là est quasi nulle.

**Règle :** toujours lire les inputs dans `_process` ou `_physics_process`, jamais dans un callback de signal.

```gdscript
# Mauvais — ne fonctionnera presque jamais
func _on_detection_area_entered(area: Area2D) -> void:
    if Input.is_action_just_pressed("interact"):   # ← trop tard
        faire_quelque_chose()

# Bon — le signal met à jour un état, _physics_process lit l'input
func _on_detection_area_entered(area: Area2D) -> void:
    if area.is_in_group("Marchand"):
        is_nextToMarchand = true

func _physics_process(delta):
    if is_nextToMarchand and Input.is_action_just_pressed("interact"):
        faire_quelque_chose()
```

---

## 20. Bloquer le joueur avec un timer (pattern déclencheur)

Pour bloquer le joueur pendant un délai (ex: animation d'interaction) sans désactiver le nœud :

```gdscript
var timerMarchand: float = 10       # durée du blocage en secondes
var timerTriggerMarchand: bool = false  # true = doublage en cours

func _physics_process(delta):
    # ZONE A — timers (avant tout return, tournent toujours)
    if timerTriggerMarchand:
        timerMarchand -= delta
        if timerMarchand <= 0:
            Stats.ressources_doublees()
            timerTriggerMarchand = false

    # Bloque le mouvement pendant le doublage
    if timerTriggerMarchand:
        return

    # ZONE B — mouvement (ignoré pendant le doublage)
    ...

    # Déclenche le doublage sur appui E
    if is_nextToMarchand and Input.is_action_just_pressed("interact"):
        timerTriggerMarchand = true
```

**Pourquoi deux `if timerTriggerMarchand` ?** Le premier décrémente et termine le timer. Le second bloque le mouvement — mais seulement si le timer tourne encore (il passe à `false` quand terminé).

---

## Pièges connus

- **`call_deferred()` dans `body_entered`** : instancier une scène directement dans un callback physique peut crasher — toujours différer.
- **`queue_free()` pas `free()`** : `free()` immédiat peut crasher si d'autres nœuds référencent encore l'objet.
- **Pause et UI** : si les boutons ne répondent plus en pause, mettre le `Process Mode` du nœud racine de l'UI sur `When Paused` (pas `Always` — risque d'effets de bord).
- **`flip_h` vs `scale.x`** : `flip_h` ne retourne que le sprite ; `scale.x = -1` retourne le nœud entier et ses enfants (hitboxes comprises).
- **Autoloads et reload** : les singletons (Stats, Damage…) survivent au rechargement de scène. Toujours remettre leur état à zéro dans une méthode `restart()` avant `reload_current_scene()`.
- **ColorRect et Mouse Filter** : un `ColorRect` plein écran peut bloquer les clics sur les nœuds derrière lui. Vérifier la propriété `Mouse Filter` (la passer à `Ignore` si le ColorRect est purement décoratif). — *non vérifié en pratique sur ce projet, à tester si le cas se présente.*
