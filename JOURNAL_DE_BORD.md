# 📓 Journal de bord — Project_M

> Plateformer 2D pixel-néon · *Hyper Light Drifter* × Cthulhu
> Mécanique centrale : **tension vitesse ⇄ cupidité** (plus tu traînes, plus le boss gagne de vie, mais plus tu ramasses de ressources).
>
> Ce fichier est mon journal **et** mon tuto perso. Chaque entrée = un mini-sprint terminé.
> Quand je ne me souviens plus pourquoi j'ai écrit un truc, je relis ici.
>
> 📍 **Il vit à la racine du dépôt git** (`JOURNAL_DE_BORD.md`) → versionné, il voyage avec le projet, impossible de le perdre.

---

## Comment lire ce journal

Chaque entrée suit toujours la même structure :

- **🎯 Ce qu'on a fait** — le résumé en clair, sans jargon.
- **🔧 Comment ça marche** — la partie tuto : le modèle mental + les bouts de code clés expliqués.
- **🏷️ Concepts / mots-clés** — pour retrouver vite avec Ctrl+F.
- **🪤 Pièges / à surveiller** — les murs sur lesquels j'ai buté, ou les subtilités à garder en tête.

---

# PHASE 1 — Le feeling du héros ✅

> Principe directeur : **dans un jeu façon HLD, le mouvement EST le jeu.** On rend le perso jouissif à piloter avant de construire quoi que ce soit autour.
>
> Tout le mouvement vit dans **un seul script** `extends CharacterBody2D`, dans `_physics_process(delta)`. Les valeurs réglables sont des `@export` (modifiables directement dans l'éditeur Godot, sans toucher au code).

---

## Sprint — Setup git & projet
**Branche :** `main` · **Statut :** ✅

### 🎯 Ce qu'on a fait
Dépôt git propre : clé SSH, dépôt distant GitHub (`samsamfisher/Project_M`), `.gitignore` Godot correct.

### 🔧 Comment ça marche
```
.godot/      # cache et imports régénérés par Godot — JAMAIS versionné
/android/    # spécifique export Android
```
`project.godot` (le cœur du projet, sans lui personne ne peut l'ouvrir) **est** versionné. Bonne config.
```bash
git ls-files | grep .godot   # doit montrer QUE project.godot, pas le dossier .godot/
git status -sb               # doit montrer "## main...origin/main" (branche reliée au remote)
```

### 🏷️ Concepts / mots-clés
`.gitignore` · clé SSH · `git remote -v` · upstream · `project.godot` vs `.godot/`

### 🪤 Pièges / à surveiller
La ligne `project.godot` renvoyée par `git ls-files | grep .godot` n'est **pas** une ligne du `.gitignore` — c'est git qui liste le fichier qu'il suit. Tout va bien.

---

## Sprint — Déplacement gauche/droite + sol
**Statut :** ✅

### 🎯 Ce qu'on a fait
Une scène de test avec un sol, et le héros qui se déplace gauche/droite de façon réactive.

### 🔧 Comment ça marche
- Le héros a pour racine un **`CharacterBody2D`** (+ `CollisionShape2D` + un visuel).
- Le sol est un **`StaticBody2D`** avec sa propre collision.
- Le déplacement se code dans **`_physics_process(delta)`** et on confirme le mouvement avec **`move_and_slide()`**.
- Pour lire la direction d'un coup : **`Input.get_axis("move_left", "move_right")`** (renvoie un nombre entre -1 et 1).

### 🏷️ Concepts / mots-clés
`CharacterBody2D` · `StaticBody2D` · `_physics_process` · `move_and_slide()` · `Input.get_axis()` · `velocity`

### 🪤 Pièges / à surveiller
Héros qui passe **à travers le sol** au lancement → suspect n°1 : une **`CollisionShape2D` vide** (nœud posé mais sans forme assignée dans l'inspecteur).

---

## Sprint — Gravité
**Statut :** ✅

### 🎯 Ce qu'on a fait
Le héros tombe quand il n'est pas au sol, avec une gravité plus forte à la descente qu'à la montée (saut nerveux, pas flottant).

### 🔧 Comment ça marche
```gdscript
@export var gravity_up: float = 1200.0    # quand on monte
@export var gravity_down: float = 1800.0  # quand on tombe (plus fort = plus nerveux)

if not is_on_floor():
    var g := gravity_up if velocity.y < 0 else gravity_down
    velocity.y += g * delta
```
- **`not is_on_floor()`** → « s'il est en l'air ».
- **`:=`** → crée une variable locale et verrouille son type (ici `float`).
- L'**expression ternaire** *choisit une valeur* (elle ne peut pas contenir d'action comme `play()`).
- **`* delta`** → rend la chute indépendante du framerate (même allure à 60 ou 144 fps).

⚠️ **Piège fondamental de la 2D Godot :** l'axe Y pointe vers le **bas**. Donc `velocity.y < 0` = « le héros **monte** ».

### 🏷️ Concepts / mots-clés
`is_on_floor()` · gravité asymétrique · expression ternaire · `:=` · axe Y inversé · `delta` · expression vs instruction

### 🪤 Pièges / à surveiller
**Expression ≠ instruction.** Une expression *vaut* quelque chose, une instruction *fait* quelque chose. Pour faire une action selon une condition → vrai bloc `if/else` indenté, pas un ternaire.

---

## Sprint — Saut (coyote time, jump buffer, saut variable)
**Statut :** ✅

### 🎯 Ce qu'on a fait
Un saut qui « pardonne » et se contrôle finement : on peut sauter une fraction de seconde après avoir quitté le bord (coyote time), un appui juste avant d'atterrir n'est pas perdu (jump buffer), et relâcher tôt fait un saut plus court (saut variable).

### 🔧 Comment ça marche
Les `@export` :
```gdscript
@export var jump_velocity: float = -450.0     # négatif car Y pointe vers le bas
@export var jump_cut_multiplier: float = 0.4  # saut variable
@export var coyote_time: float = 0.1          # grâce après avoir quitté le sol (s)
@export var jump_buffer_time: float = 0.1     # mémorise un appui juste avant d'atterrir (s)
```
**Des timers qui décomptent chaque frame** (le pattern clé de tout le système) :
```gdscript
coyote_timer -= delta
jump_buffer_timer -= delta
# tant qu'on est au sol, on recharge le coyote time (et le double saut)
if is_on_floor():
    coyote_timer = coyote_time
    double_saut = true
```
**Jump buffer** = à l'appui, on arme un timer ; le saut se déclenche dès que les conditions sont réunies :
```gdscript
if Input.is_action_just_pressed("jump"):
    jump_buffer_timer = jump_buffer_time
```
**Saut "sol" via coyote** (voir la mise à jour Phase 2 : ce bloc est devenu un `if/elif` avec le double saut) :
```gdscript
if jump_buffer_timer > 0 and coyote_timer > 0:
    velocity.y = jump_velocity
    jump_buffer_timer = 0
    coyote_timer = 0
```
**Saut variable** = relâcher tôt alors qu'on monte coupe l'élan :
```gdscript
if Input.is_action_just_released("jump") and velocity.y < 0:
    velocity.y *= jump_cut_multiplier   # on garde 40% de l'élan
```

### 🏷️ Concepts / mots-clés
coyote time · jump buffer · saut variable (jump cut) · `is_action_just_pressed` / `is_action_just_released` · timers `-= delta`

### 🪤 Pièges / à surveiller
- **Coyote × double saut :** un seul appui en sortant d'une plateforme déclenchait *les deux* la même frame → double saut dépensé silencieusement. **✅ RÉSOLU** (voir *Phase 2 — Correctif coyote vs double saut*).
- **Re-saut à l'atterrissage (encore ouvert) :** un appui « jump » en l'air arme aussi le jump buffer ; si on atterrit dans les 0,1 s, ça peut provoquer un petit re-saut automatique. Pas constaté comme gênant → à surveiller si un jour le saut « repart tout seul » en touchant le sol.

---

## Sprint — Double saut
**Branche :** `feat/...` · **Statut :** ✅ (mergé)

### 🎯 Ce qu'on a fait
Un deuxième saut en l'air, qui se **recharge à l'atterrissage**.

### 🔧 Comment ça marche — MON approche réelle
Pas un compteur : un **simple booléen** `double_saut`.
```gdscript
@export var double_saut: bool = false   # true = un double saut est disponible

# rechargé au sol (dans le bloc is_on_floor() du saut) :
if is_on_floor():
    double_saut = true

# consommé une fois en l'air :
if not is_on_floor() and double_saut == true and Input.is_action_just_pressed("jump"):
    velocity.y = jump_velocity
    double_saut = false   # dépensé : plus de saut jusqu'au prochain sol
```
Logique : au sol → `double_saut = true`. En l'air, premier saut aérien → on remet `velocity.y` et on passe `double_saut` à `false`. **Propre et suffisant pour exactement 2 sauts.**

> Comparaison (pour culture, PAS à changer) : un **compteur** (`sauts_restants`, décrémenté à chaque saut, remis au max au sol) ne servirait que pour scaler vers triple/quadruple saut. Pour 2 sauts, le booléen est l'outil juste.

### 🏷️ Concepts / mots-clés
booléen d'état · recharge à l'atterrissage · `double_saut` · booléen vs compteur

### 🪤 Pièges / à surveiller
Bien penser à recharger le booléen au contact du sol, sinon un seul cycle puis plus rien. (Et voir le correctif coyote en Phase 2.)

---

## Sprint — Dash
**Branche :** (contrôleur d'origine) · **Statut :** ✅

### 🎯 Ce qu'on a fait
Une poussée horizontale rapide, à durée limitée, avec un temps de recharge (cooldown). Sert de « plus vite / plus loin ».

### 🔧 Comment ça marche
```gdscript
@export var dash_speed: float = 700.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.5
```
**1. L'« early return » pendant le dash.** Tant qu'on dashe, on fige une vitesse fixe, on ignore gravité + déplacement normal, et on `return` pour sortir de la frame :
```gdscript
if is_dashing:
    dash_timer -= delta
    if dash_timer <= 0:
        is_dashing = false
    move_and_slide()
    return   # ← coupe le reste : pendant le dash, RIEN d'autre ne s'applique
```
**2. Le cooldown.** On ne peut redasher que si `dash_cooldown_timer <= 0` :
```gdscript
if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
    start_dash()
    return

func start_dash() -> void:
    is_dashing = true
    dash_timer = dash_duration
    dash_cooldown_timer = dash_cooldown
    velocity = Vector2(facing * dash_speed, 0.0)   # dash horizontal pur, dans le sens du regard
```

### 🏷️ Concepts / mots-clés
`return` anticipé (early return) · `is_dashing` (état) · `dash_timer` / `dash_cooldown_timer` · `start_dash()` · `Vector2`

### 🪤 Pièges / à surveiller
Le `return` rend le dash « exclusif » (pas de gravité ni de contrôle horizontal pendant 0,15 s). C'est voulu — mais toute nouvelle mécanique de mouvement doit penser à ce cas (ex. : le dash n'a pas encore d'animation à cause de ce `return`).

---

## Décision de design — Sprint (m7) rayé ❌
**Statut :** abandonné volontairement (pas un échec)

Le perso **court par défaut** (c'est un jeu de vitesse), et le dash couvre déjà « plus vite / plus loin ». Un sprint en plus serait une couche morte. Choix de design assumé.

---

## Sprint — Animations (idle / run / jump / fall)
**Branche :** `feat/anim-saut` · **Statut :** ✅ (mergée + poussée)

### 🎯 Ce qu'on a fait
Les animations reflètent l'état du corps : idle, course, saut (montée), chute (descente).

### 🔧 Comment ça marche — LE modèle mental clé
**Une animation n'est pas déclenchée par une touche. C'est le *reflet* de ce que fait le corps, recalculé chaque frame.**

Donc **à la fin** de `_physics_process`, **après `move_and_slide()`**, UNE seule cascade de décision, dans l'ordre de priorité (états aériens AVANT le sol, idle en dernier filet) :
```gdscript
move_and_slide()

if not is_on_floor() and velocity.y < 0:
    sprite.play("jump")   # en l'air + monte
elif not is_on_floor() and velocity.y >= 0:
    sprite.play("fall")   # en l'air + descend
elif is_on_floor() and velocity.x != 0:
    sprite.play("run")    # au sol + bouge
else:
    sprite.play("idle")   # au sol + immobile
```
Le sprite est récupéré une fois au démarrage :
```gdscript
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
```

### 🏷️ Concepts / mots-clés
animation = miroir de l'état · point de décision unique · ordre de priorité · `if/elif/else` en cascade · `@onready` · `AnimatedSprite2D` · `play()`

### 🪤 Pièges / à surveiller
- **Symptôme « une frame puis retour idle » :** des `play()` éparpillés qui se battent dans la même frame, le dernier (souvent l'idle) gagne. **Cure : un seul bloc en cascade, après `move_and_slide()`.**
- **L'idle est le dernier `else`, jamais ailleurs.** S'il remonte plus haut, il écrase tout.
- Piège vécu : `velocity.x <= 0` pour « il court » est faux (vrai à l'arrêt et faux en courant à droite). La bonne condition est `velocity.x != 0`.

---

## Incident — Code « perdu » après relance
**Statut :** ✅ résolu (rien n'était perdu)

Au redémarrage, le code de la veille semblait disparu → en réalité juste sur une autre branche.

**Leçon à retenir pour toujours : la branche est jetable, le travail mergé est permanent.**

Diagnostic avant d'agir (jamais de `reset`/`checkout` agressif dans la panique) :
```bash
git status
git branch
git log --oneline -5   # le commit cherché doit apparaître ici
```
Réunir plusieurs branches sur la branche de travail :
```bash
git switch feat/niveau-1
git merge main -m "message"
git push -u origin feat/niveau-1   # -u relie au remote (ensuite : juste 'git push')
```

### 🏷️ Concepts / mots-clés
branche jetable vs travail mergé · `git log --oneline` · `git merge` · `git push -u` · `reflog`

---

# PHASE 2 — Donner un monde au héros 🚧

> Le héros bougeait magnifiquement… dans le vide. Cette phase lui donne du terrain à mordre : un vrai niveau, une caméra qui suit. C'est là que le mouvement commence à *servir*, et où vivra plus tard la tension vitesse ⇄ cupidité.

---

## Sprint — Première map test
**Branche :** `feat/niveau-1` · **Statut :** ✅

### 🎯 Ce qu'on a fait
Une map de test volontairement **moche et jetable**, traversable de bout en bout, qui sollicite tout le moveset (course, saut, double saut, dash) avec une courbe de difficulté croissante. Caméra `Camera2D` enfant du joueur, option **Position Smoothing** activée (légère latence = moins sec, anti-tournis).

### 🔧 Comment ça marche
- Terrain tracé en **`TileMapLayer`**, collisions de tileset configurées (sinon le héros passe à travers).
- **Courbe de difficulté** montante : départ plat → petites plateformes en escalier → trous (saut / double saut) → gros gouffre + verticalité (double saut **+** dash).
- **Repère de design clé : une map test se juge en la JOUANT, pas en la regardant.** Le seul vrai juge, c'est la traversée chronométrée.
- **Calibrage temporel :** ~30 s sur la partie plate en ligne droite, ~1 min sur le run complet. C'est une **première** estimation de la fenêtre où vivra la tension vitesse ⇄ cupidité (à retoucher quand les vrais éléments — ressources, boss — arriveront).

### 🏷️ Concepts / mots-clés
`TileMapLayer` · collision de tileset · `Camera2D` · Position Smoothing · courbe de difficulté · map test jetable · calibrage temporel · vitesse ⇄ cupidité

### 🪤 Pièges / à surveiller
- Juger une map à l'œil ment : un tracé joli peut être infranchissable ou trop facile manette en main. **Toujours valider par un run réel + chrono.**
- Caméra collée pile au perso = un peu raide dans un jeu rapide → réglé via le **Position Smoothing**. Si un jour ça donne le tournis, c'est le réglage à revoir.

---

## Correctif — coyote time vs double saut
**Branche :** `fix/coyote-double-saut` · **Statut :** ✅

### 🎯 Ce qu'on a fait
Réglé le bug : impossible de double-sauter après être sorti d'une plateforme en courant.

### 🔧 Comment ça marche
**Cause :** le saut « sol » (via coyote) et le double saut étaient deux `if` **parallèles** qui réagissaient au même appui sur la même frame. En sortant d'une plateforme dans la fenêtre de coyote, un seul appui rendait les deux blocs vrais → le double saut était dépensé *silencieusement* (`double_saut = false`), donc plus de second saut ensuite.

**Fix :** passer de deux `if` indépendants à un **`if / elif`** → les deux branches deviennent **mutuellement exclusives**, un appui ne peut en satisfaire qu'une.
```gdscript
if jump_buffer_timer > 0 and coyote_timer > 0:   # saut "sol" via coyote
    velocity.y = jump_velocity
    jump_buffer_timer = 0
    coyote_timer = 0
elif not is_on_floor() and double_saut == true and Input.is_action_just_pressed("jump"):
    velocity.y = jump_velocity
    double_saut = false
```

### 🏷️ Concepts / mots-clés
`if`/`elif` · mutuellement exclusif · coyote time · double saut · « deux systèmes qui ne se parlent pas »

### 🪤 Pièges / à surveiller
- Résout le piège noté dans l'entrée **Saut** de la Phase 1.
- ⚠️ L'autre piège du saut reste **ouvert** : appui « jump » en l'air → jump buffer armé → re-saut possible à l'atterrissage. Toujours en veille.
- **Leçon git du jour :** `git switch -c` **emporte les modifs non commitées** sur la nouvelle branche. Les changements non commités te suivent partout ; ils ne sont « épinglés » à une branche qu'au moment d'un commit. → toujours commiter avant de changer de contexte.

---

## 📍 État actuel du projet (au 18/06/2026)

- **Branche de travail :** `feat/niveau-1` (mouvement + animations + tileset + première map test + correctif coyote).
- **`main` :** Phase 1 propre.
- **Phase 1 : terminée.** Le mouvement existe et il est juteux.
- **Phase 2 : démarrée.** Première map test jouable et chronométrée ✅. Caméra qui suit ✅.
- **Prochain cap :** à définir ensemble (probable : peaufiner le niveau / commencer à y placer les premiers éléments de la boucle de jeu).

> _Prochaine entrée à écrire à la fin du prochain mini-sprint._


## Sprint — Son au ramassage
**Branche :** `feat/son` · **Statut :** ✅

### 🎯 Ce qu'on a fait
Quand on ramasse une ressource, un petit *« pop »* se joue. Le son passe par un **autoload dédié** (`Sound`) qui possède son propre lecteur, déclenché en direct depuis le script de la ressource.

### 🔧 Comment ça marche

**Le modèle mental (le vrai « pourquoi ») :** la ressource est *éphémère* — elle fait `queue_free()` dès qu'on la touche. Si le lecteur de son vivait sur elle, il mourrait avec elle → **son coupé net**. Donc le son a besoin d'un **hôte qui survit**. D'où l'autoload `Sound` (global, jamais détruit). Un job par autoload : `Stats` tient les chiffres, `Sound` fait le bruit.

**L'autoload fabrique son lecteur en code :**
```gdscript
# sound.gd  (autoload "Sound")
extends Node

var player: AudioStreamPlayer

func _ready() -> void:
	player = AudioStreamPlayer.new()                  # fabrique le lecteur (orphelin en mémoire)
	player.stream = preload("res://Sound/pop.wav")    # lui donne un son
	add_child(player)                                 # le branche dans l'arbre → il peut jouer

func _playSound() -> void:
	player.play()
```

**Le point clé — pourquoi `add_child` :** `.new()` crée bien l'objet, mais il flotte tout seul, *débranché*. Un nœud ne « vit » (et l'audio ne sort) **que s'il est dans l'arbre de la scène**. `add_child` le branche sur la prise. C'est le **miroir** du piège de `queue_free` : sortir de l'arbre = mort ; entrer dans l'arbre = vivant. **Seuls les nœuds dans l'arbre sont actifs.**

**Le déclenchement — appel direct :**
```gdscript
# ressources.gd
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		Stats.ajouter_ressource()
		Sound._playSound()        # appel direct à un service global, comme Stats
		queue_free()
```
Pas besoin de signal ici : un signal sert quand l'émetteur ne doit *pas* connaître qui écoute. `Sound` est un service global connu — l'appeler par son nom est plus simple et plus clair.

### 🏷️ Concepts / mots-clés
autoload dédié (un job par boîte) · `AudioStreamPlayer` · `.new()` vs `add_child()` · arbre de la scène (`SceneTree`) · nœud orphelin · `preload` · `queue_free()` · appel direct vs signal · service global

### 🪤 Pièges / à surveiller
- **Son sur la ressource + `queue_free()`** → son coupé. L'hôte du son doit survivre à la ressource.
- **`.new()` seul = orphelin muet.** Sans `add_child`, le `play()` ne sort rien (et si on oublie carrément le lecteur, erreur *« call 'play' on a null instance »*).
- **`AudioStreamPlayer2D` dans un autoload** = son *positionnel*, peut rester inaudible. Pour un SFX de ramassage/UI, prendre `AudioStreamPlayer` tout court.
- **Ne pas brancher le pop sur le signal `ressources_changees`** : ce signal part à *chaque* changement du total — donc aussi quand on **dépensera** à la boutique → le son sonnerait au mauvais moment. L'appel direct colle le son pile à l'événement « ramassage ».
- **Garder `_on_area_2d_body_entered` propre** : aujourd'hui 2 réactions (`Stats` + `Sound`), ça va. Quand elles se multiplient (particules, score, succès…) → basculer sur un signal « ramassé » que tout le monde écoute.
- **À nettoyer un jour (warnings ⚠) :** `$AnimatedSprite2D.play("icon")` dans `_process` tourne à chaque frame (le mettre dans `_ready`), et le `delta` de `_process` n'est pas utilisé.


## Sprint — Apparition du boss & sa vie selon le temps
**Branche :** `feat/boss-vie-scaling` · **Statut :** ✅

### 🎯 Ce qu'on a fait
Quand le joueur traverse une zone à la fin du niveau, un boss **apparaît**. Le boss n'est pas posé d'avance dans le niveau : il est fabriqué à partir de son fichier, pile au moment où on entre dans la zone. Et à sa naissance, il calcule sa vie à partir du temps écoulé — plus on a traîné, plus il est costaud. C'est le cœur du jeu qui prend vie.

### 🔧 Comment ça marche

**1. La zone qui fait apparaître le boss (le trigger)**

- Une `Area2D` posée à la fin du niveau. Elle a un signal intégré, `body_entered`, qui se déclenche tout seul quand un corps entre dedans. On ne crée pas ce signal, on l'**écoute** (branché via l'onglet Node → Signals).
- On filtre : n'importe quel corps déclenche le signal, donc on vérifie que c'est bien le joueur avec `is_in_group("Player")` (le joueur a été ajouté au groupe `Player`).
- Le boss est désigné par un **fichier de scène**, pas par un nœud : `@export var spawnBoss: PackedScene`. Dans l'inspecteur, on glisse `boss.tscn` dedans. (Un `PackedScene`, c'est une scène en boîte, prête à être copiée.)
- À l'entrée du joueur, on fabrique une copie et on la pose dans le niveau :

```gdscript
extends Area2D

@export var spawnBoss: PackedScene

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		var boss = spawnBoss.instantiate()                 # une copie neuve depuis le fichier
		add_child(boss)                                     # on l'ajoute à l'arbre D'ABORD
		boss.global_position = $Marker2D.global_position    # PUIS on la place
```

`instantiate()` fabrique une copie du fichier. `add_child()` la met dans la scène. Le `Marker2D` est un point qu'on déplace dans l'éditeur pour choisir où le boss atterrit.

**2. Le boss qui calcule sa vie (`boss.gd`)**

- `_ready()` ne tourne **qu'une seule fois**, au moment exact où le boss est créé. C'est là qu'on lit le temps, une fois :

```gdscript
extends Node2D

@export var vie_de_base = 800
@export var facteur = 1
var vie: float

func _ready() -> void:
	vie = vie_de_base + (Stats.time * facteur)
```

- Différence clé avec la jauge de menace : la jauge relit `Stats.time` à **chaque frame** (dans `_process`) parce qu'elle bouge sans arrêt. Le boss, lui, lit **une fois** et fige le chiffre. Deux outils pour deux besoins.
- `facteur`, c'est la molette d'équilibrage : il décide à quel point le temps fait gonfler la vie du boss.

### 🏷️ Concepts / mots-clés
`Area2D` · signal `body_entered` · onglet Node → Signals · groupes / `is_in_group` · `PackedScene` · `instantiate()` · `add_child()` · `Marker2D` · `_ready` vs `_process` · `@export` · `Stats.time` (source unique)

### 🪤 Pièges / à surveiller
- **« Assigner » ne montre que les nœuds de la scène ouverte.** Pour désigner un boss qui n'existe pas encore dans le niveau, utiliser un `PackedScene` (un fichier), pas une référence de nœud (`Node2D`).
- `@export var spawnBoss = PackedScene.new()` crée une scène **vide** par défaut. Écrire juste le type : `@export var spawnBoss: PackedScene`. Sinon, si on oublie de glisser le fichier, `instantiate()` fabrique du vide en silence.
- Régler `global_position` **avant** `add_child()` peut donner un placement faux. Ordre sûr : `add_child()` d'abord, position ensuite.
- « Le boss n'apparaît pas » était faux : il apparaissait, mais **hors écran** (la caméra suit le joueur, le boss naissait à ~860 px). S'il existe (les `print` le prouvent) mais qu'on ne le voit pas → vérifier son sprite et sa position, pas le spawn.
- Une `Area2D` ne détecte un corps que si son **masque de collision** inclut la couche du corps. Si `body_entered` ne se déclenche jamais, vérifier ça en premier.

---
## Sprint — Attaque à l'épée (le coup ne doit pas casser l'anim)
**Branche :** `feat/epee-attaque` · **Statut :** ✅

### 🎯 Ce qu'on a fait
Une attaque à l'épée déclenchée à la touche, dont l'animation se joue **en entier** (avant elle ne montrait qu'une frame puis revenait à idle), et dont la zone de frappe ne blesse **que pendant le coup**.

### 🔧 Comment ça marche

**Le bug « une frame puis idle » :** la cascade d'animations (le miroir de l'état, recalculé chaque frame, cf. sprint *Animations*) rejouait `idle` à chaque frame et **écrasait** l'attaque. Une animation d'**action** (l'attaque) n'est pas une animation miroir : il faut la **protéger** avec un verrou, exactement comme `is_dashing` protège le dash.

```gdscript
var is_attacking: bool = false

func sword_attack() -> void:
	is_attacking = true
	# … on allume aussi la hitbox (voir plus bas)
	sprite.play("attack_sword")

# dans _physics_process, juste après move_and_slide() :
if is_attacking:
	return   # tant qu'on attaque, la cascade d'anims ne tourne pas
# … cascade idle/run/jump/fall …
```

**Baisser le verrou au bon moment — le signal `animation_finished` :** on ne *teste* pas si l'anim est finie (erreur : la tester sur la frame de l'appui, alors qu'elle vient juste de démarrer). On **branche** le signal une fois, et c'est lui qui rappelle quand l'anim se termine.

```gdscript
func _ready() -> void:
	sprite.animation_finished.connect(_on_anim_finished)

func _on_anim_finished() -> void:
	if sprite.animation == "attack_sword":   # filtre : QUELLE anim a fini
		is_attacking = false
		# … on éteint la hitbox
```

> ⚠️ `animation_finished` (sur `AnimatedSprite2D`) **ne porte aucune info** : il ne dit pas *quelle* anim a fini. On interroge le nœud avec `sprite.animation`. (À l'inverse, `body_entered(body)` te tend le corps en argument — chaque signal choisit ce qu'il transporte.)

**La hitbox active seulement pendant le coup :** `visible` ne change RIEN à la collision. Le vrai levier, c'est la collision elle-même : éteinte par défaut, allumée dans `sword_attack()`, éteinte dans `_on_anim_finished()`.

```gdscript
# allumer / éteindre — set_deferred pour éviter l'erreur "flushing queries"
$Sword/CollisionShape2.set_deferred("disabled", false)  # allume
$Sword/CollisionShape2.set_deferred("disabled", true)   # éteint
```

### 🏷️ Concepts / mots-clés
verrou d'état (`is_attacking`) · animation d'action vs animation miroir · `return` anticipé (comme le dash) · signal `animation_finished` · signal vide vs signal avec argument · `sprite.animation` · hitbox timée · `visible` ≠ collision · `set_deferred`

### 🪤 Pièges / à surveiller
- **`==` vs `=` :** `is_attacking == false` *compare* (et jette le résultat), `is_attacking = false` *assigne*. (Cf. *expression ≠ instruction* du sprint Gravité.)
- **Anim d'attaque en boucle (Loop ON)** → `animation_finished` ne part **jamais** → le verrou reste levé pour toujours. L'attaque doit être en **Loop OFF**.
- **Hits multiples :** si la hitbox reste active un instant, elle peut toucher le même ennemi plusieurs fois. Le jour où ça gêne → tenir une liste « déjà touchés ce coup-ci », vidée à la fin de l'attaque.

---

## Sprint — L'épée touche, blesse et tue le boss
**Branche :** `feat/epee-attaque` · **Statut :** ✅

### 🎯 Ce qu'on a fait
La lame détecte le boss, lui retire de la vie à chaque coup, et le **tue** quand sa vie atteint 0. La boucle du jeu est complète : foncer → boss faible → mise à mort rapide. **Le cœur du concept MVP est validé.**

### 🔧 Comment ça marche

**1. La détection — `body_entered` ne voit QUE les corps physiques.** Au départ l'épée (Area2D) ne détectait pas le boss. Cause profonde : une `CollisionShape2D` sous un simple `Node2D` ne fait **rien** — il lui faut un parent qui existe dans le monde physique. On a donné un corps au boss : racine en **`CharacterBody2D`**. Dès lors `body_entered` le voit.

> Mémo : `body_entered` = corps physiques (CharacterBody2D, StaticBody2D…). `area_entered` = Area2D. Une Area2D ne voit une autre Area2D **que** par `area_entered`.

**2. Le groupe va sur le nœud que le signal te tend.** `body_entered(body)` te tend le **corps** (la racine `CharacterBody2D`). Donc le groupe « Boss » va sur la **racine**, jamais sur la CollisionShape (qu'aucun signal ne te tend).

```gdscript
func _on_sword_body_entered(body: Node2D) -> void:
	if body.is_in_group("Boss"):
		Damage.SendDamage(100)   # bus de dégâts (autoload Damage)
```

**3. Les couches de collision — traverser le boss tout en le frappant.** Le perso restait bloqué contre le boss car il avait le **calque du boss dans son Mask**. Règle d'or : **Layer = ce que je suis · Mask = ce que je regarde / percute.** On enlève le calque « Boss » du Mask du perso → il traverse. L'épée, elle, **garde** le calque « Boss » dans son Mask → elle touche toujours.

**4. La mort — taper sur la BONNE variable.** `vie_de_base` est la constante de départ ; `vieBoss` (= `vie_de_base + temps × facteur`) est la vraie vie courante. Les dégâts doivent fondre **`vieBoss`**, pas `vie_de_base`.

```gdscript
func takeDamageBoss(amount):
	vieBoss -= amount
	print(vieBoss)            # pour la voir descendre
	if vieBoss <= 0:
		queue_free()          # le boss meurt
```

**5. Le spawn différé — « Can't change this state while flushing queries ».** `add_child(boss)` dans `_on_body_entered` plantait : ce signal tourne *pendant* le calcul physique, et y brancher des collisions est interdit. Parade : tout différer.

```gdscript
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		spawn_boss.call_deferred()

func spawn_boss() -> void:
	var boss = spawnBoss.instantiate()
	add_child(boss)                                  # ok, on est après le calcul
	boss.global_position = $Marker2D.global_position # placé une fois dans l'arbre
```

### 🏷️ Concepts / mots-clés
`body_entered` vs `area_entered` · CollisionShape ⊂ objet de collision · `CharacterBody2D` · groupe sur le nœud que le signal tend · couches/masques (Layer = je suis, Mask = je regarde) · `vieBoss` vs `vie_de_base` · `queue_free()` · `call_deferred` / `set_deferred` · flushing queries · bus de dégâts (`Damage`)

### 🪤 Pièges / à surveiller
- **`CollisionShape2D` sous un `Node2D`** = inerte. Toujours un parent objet de collision.
- **Mask ≠ Layer.** Si deux corps se bloquent, l'un regarde le calque de l'autre. Pour s'ignorer : que personne ne regarde le calque de l'autre.
- **Si l'épée arrête de toucher après un changement de calque** → vérifier que son **Mask contient le calque du boss**.
- **Modifier collision/monitoring pendant un signal physique** (`body_entered`, `area_entered`) → différer avec `call_deferred` / `set_deferred`.
- **`_delta` :** le `delta` non utilisé de `_process` se renomme `_delta` pour calmer le warning jaune.

---

## 📍 État actuel du projet (au 23/06/2026)

- **Branche de travail :** `feat/epee-attaque` (attaque à l'épée + dégâts + mort du boss).
- **Phase 1 : terminée.** Le mouvement est juteux.
- **Phase 2 : bien avancée.** Map test ✅, caméra ✅, son au ramassage ✅, boss qui apparaît et scale avec le temps ✅, **et maintenant l'épée qui le blesse et le tue ✅**.
- **🎮 Cœur du MVP atteint :** foncer → boss faible → mise à mort rapide. La question « est-ce grisant ? » est enfin testable manette en main.
- **Prochains caps possibles :** écran de résultat (gagné/perdu + temps), une ou deux attaques du boss (il riposte), un type d'ennemi simple. Ensuite → les *signatures* (ressources, choix du coffre…).

---

# PHASE 2 — La boucle de jeu (suite)

## Sprint — Ennemi : patrouille
**Branche :** `feat/ecran-victoire` · **Statut :** ✅

### 🎯 Ce qu'on a fait
Création d'un ennemi simple (`enemy_patrol.tscn`) qui patrouille entre deux points. Il se retourne automatiquement quand il arrive à destination. Base posée pour ajouter la détection + CHASE au prochain sprint.

### 🔧 Comment ça marche
Deux `Marker2D` placés **dans le niveau** (pas enfants de l'ennemi — sinon ils bougent avec lui). Référencés via `@export` et assignés dans l'Inspecteur Godot.

```gdscript
@export var marker2D1: Marker2D
@export var marker2D2: Marker2D
var cible

func _ready() -> void:
    cible = marker2D1  # on initialise ici car les @export ne sont pas dispo avant _ready()

func _physics_process(delta):
    if abs(cible.global_position.x - global_position.x) <= 10:
        if cible == marker2D1:
            cible = marker2D2
        else:
            cible = marker2D1
    velocity.x = sign(cible.global_position.x - global_position.x) * SPEED
```

- `sign(a - b)` → retourne `1`, `-1` ou `0` selon si `a` est à droite, à gauche ou égal à `b`. Pratique pour obtenir une direction sans calcul.
- `abs()` → valeur absolue, pour mesurer une distance sans se soucier du signe.
- `global_position` plutôt que `position` → car les deux nœuds peuvent avoir des parents différents. `global_position` est toujours dans le même repère monde.

### 🏷️ Concepts / mots-clés
`sign()` · `abs()` · `global_position` vs `position` · `@export` · `_ready()` · `Marker2D` · machine à états (PATROL / CHASE)

### 🪤 Pièges / à surveiller
- **`@export` non assigné dans l'Inspecteur** → variable `Nil` → crash au premier accès. Toujours vérifier l'Inspecteur après avoir ajouté un `@export`.
- **Marker2D enfant de l'ennemi** → ils bougent avec lui. Toujours les mettre dans la scène parente.
- **Initialiser une variable avec un `@export` à la déclaration** → impossible, les nœuds ne sont pas encore chargés. Utiliser `_ready()`.
- **Oublier `* SPEED`** sur `velocity.x` → l'ennemi se déplace d'1 pixel/frame.

---

## Sprint — Riposte du boss
**Branche :** `feat/boss-riposte` · **Statut :** ✅

### 🎯 Ce qu'on a fait
Le boss attaque maintenant le joueur. Deux mains indépendantes (gauche et droite) frappent en alternance via deux `Timer`. Le joueur a une vraie vie (`vie: int = 3`) et une méthode `takeDamage(amount)`. Quand il tombe à 0, le signal `SendPlayerDied()` est émis.

### 🔧 Comment ça marche

**1. Structure du boss — corps + deux mains séparés.**
Trois `AnimatedSprite2D` indépendants (`Body`, `HandLeft`, `HandRight`), chacun avec sa propre hitbox (`Area2D` + `CollisionShape2D`). Ça permet d'animer et d'activer les collisions séparément pour chaque partie.

**2. Les hitboxes désactivées par défaut.**
Même pattern que l'épée du joueur : les `CollisionShape2D` des mains sont `disabled = true` dans `_ready()`. Elles ne s'activent que pendant l'animation d'attaque, et se désactivent à la fin.

```gdscript
func attackBossHandLeft():
    isAttacking = true
    collideHandLeftAttack.disabled = false
    spriteHandLeft.play("hand_attack")

func _on_hand_left_animation_finished() -> void:
    if spriteHandLeft.animation == "hand_attack":
        isAttacking = false
        collideHandLeftAttack.disabled = true
```

**3. Les Timers déclenchent les attaques.**
Deux `Timer` en autostart dans la scène, chacun connecté à sa méthode. Quand le timeout arrive → `attackBossHandLeft()` ou `attackBossHandRight()`. Simple et découplé du code.

**4. Communication boss → joueur : appel direct, pas de signal global.**
Au lieu de passer par le bus `Damage` (qui envoyait le signal à tout le monde, boss inclus), on appelle directement la méthode du joueur :

```gdscript
func _on_hand_collide_left_body_entered(body: Node2D) -> void:
    if body.is_in_group("Player"):
        body.takeDamage(1)
```

Règle à retenir : **les signaux globaux (autoload) servent à diffuser un événement à plusieurs écouteurs inconnus. Pour parler directement à un nœud qu'on vient de toucher, l'appel direct est plus propre.**

**5. Vie du joueur.**
Variable simple dans `Player.gd` :

```gdscript
@export var vie: int = 3

func takeDamage(amount):
    vie -= amount
    if vie <= 0:
        Damage.SendPlayerDied()
```

### 🏷️ Concepts / mots-clés
`Area2D` · `CollisionShape2D` disabled · `Timer` autostart · appel direct vs signal global · `is_in_group()` · `animation_finished` · `isAttacking` flag · vie joueur · `SendPlayerDied()`

### 🪤 Pièges / à surveiller
- **Signal global bidirectionnel** → si boss et joueur écoutent le même signal `SendDamage`, le boss se blesse lui-même quand ses mains touchent le joueur. Solution : appel direct sur le `body` récupéré dans `body_entered`.
- **Hitbox toujours active** → si on oublie de la désactiver après l'attaque, la main tue le joueur en continu au contact.
- **`isAttacking` partagé entre les deux mains** → les deux timers peuvent se déclencher simultanément, les deux mains attaquent en même temps. À garder en tête si on veut les rendre exclusives plus tard.

---

## Sprint — Écran game over (boutons Restart / Quit / Menu)
**Branche :** `main` (puis correctifs directs) · **Statut :** ✅

### 🎯 Ce qu'on a fait
L'écran de game over a maintenant des boutons qui répondent vraiment : **Quit** ferme le jeu, **Restart** relance le niveau proprement (vie, ressources et temps remis à zéro), **MainMenu** laissé en attente (pas de vrai menu principal pour l'instant).

### 🔧 Comment ça marche

**1. Le piège des boutons qui ne répondent pas du tout.** En `Inherit` (réglage par défaut), un nœud se fige dès que `get_tree().paused = true` est appelé — y compris ses boutons. Solution : sur le **nœud racine de l'UI de game over**, passer `Process Mode` sur **`When Paused`**. Les enfants héritent automatiquement.

```gdscript
# Process Mode du parent de l'UI de pause/game over → When Paused (pas Always)
# Always tournerait aussi en jeu normal = risque d'effets de bord inutiles
```

**2. Le restart qui laisse le perso figé.** `get_tree().reload_current_scene()` recrée bien la scène, mais les **Autoloads survivent** au rechargement — leurs variables ne se remettent pas à zéro toutes seules. `Damage.paused` restait à `true`, donc le joueur restait gelé après le restart.

**Fix : centraliser un `restart()` dans l'Autoload qui porte l'état du jeu (`Stats`).**

```gdscript
# Stats.gd
func restart():
    ressources = 0
    vie = 3
    time = 0
    get_tree().paused = false
    get_tree().reload_current_scene()
```

Pas besoin de réémettre les signaux (`vie_changee`, etc.) dans `restart()` : `reload_current_scene()` recrée tous les nœuds HUD depuis zéro, et leur `_ready()` relit directement les variables de `Stats`.

### 🏷️ Concepts / mots-clés
`Process Mode` (`Inherit` / `Always` / `When Paused`) · `get_tree().paused` · `reload_current_scene()` · Autoloads persistants entre scènes · `restart()` centralisé · signaux inutiles au reload

### 🪤 Pièges / à surveiller
- **Boutons muets en pause** → toujours vérifier le `Process Mode` du parent de l'UI avant de chercher ailleurs (signal mal connecté, collision qui bloque…).
- **Autoloads = état qui survit au reload.** Tout autoload qui porte de l'état doit avoir un moyen de le remettre à zéro, sinon le restart laisse des résidus invisibles.
- **`git push` sur une branche neuve** → `fatal: no upstream branch`. Normal la première fois : `git push --set-upstream origin <branche>`. Pour ne plus y penser : `git config --global push.autoSetupRemote true`.

---

## Sprint — Coffre / marchand avant le boss
**Branche :** `feat/coffre-avant-boss` · **Statut :** ✅

### 🎯 Ce qu'on a fait
Un marchand posé avant la zone du boss : si le joueur s'arrête et appuie sur **E**, ses ressources sont doublées après un court délai — mais s'arrêter coûte du temps, donc fait gonfler la vie du boss. Premier vrai choix risque/récompense du jeu.

### 🔧 Comment ça marche

**1. Détecter une `Area2D` avec une autre `Area2D`.** `body_entered` ne voit que les corps physiques (`CharacterBody2D`...). Pour qu'une zone de détection du joueur voie la zone du marchand, il faut **`area_entered`**.

```gdscript
func _on_detection_area_entered(area: Area2D) -> void:
    if area.is_in_group("Marchand"):
        is_nextToMarchand = true
```

**2. Le groupe va sur le nœud que le signal tend.** `area_entered(area)` tend l'**`Area2D`** elle-même — donc le groupe `"Marchand"` doit être sur l'`Area2D`, pas sur son parent `Node2D`. Piège classé déjà croisé avec le boss (sprint *épée touche le boss*), mais qui revient à chaque nouvelle interaction.

**3. `Input.is_action_just_pressed` dans un signal ne marche presque jamais.** Il ne reste vrai qu'**une frame**. Le mettre dans `body_entered`/`area_entered` revient à parier que le joueur appuie sur E exactement à la frame où il entre dans la zone. **Toujours lire les inputs dans `_process`/`_physics_process`**, le signal se contente de poser un état (booléen).

```gdscript
# le signal pose l'état
func _on_detection_area_entered(area):
    if area.is_in_group("Marchand"):
        is_nextToMarchand = true

# _physics_process lit l'input, chaque frame
if is_nextToMarchand and Input.is_action_just_pressed("interact"):
    timerTriggerMarchand = true
```

**4. Bloquer le joueur pendant un délai sans figer le timer.** `_physics_process` s'exécute de haut en bas, un `return` coupe tout ce qui suit. Astuce : placer le décompte du timer **avant** le `return`, et le `return` **avant** le bloc mouvement.

```gdscript
# Zone A — timers, toujours exécutés
if timerTriggerMarchand:
    timerMarchand -= delta
    if timerMarchand <= 0:
        Stats.ressources_doublees()
        timerTriggerMarchand = false

if timerTriggerMarchand:
    return   # le mouvement (zone B) est ignoré, le timer continue de tourner

# Zone B — mouvement, animations...
```

### 🏷️ Concepts / mots-clés
`area_entered` vs `body_entered` · groupe sur le nœud que le signal tend · `is_action_just_pressed` hors signal · pattern booléen déclencheur + timer manuel · ordre d'exécution de `_physics_process` · `return` anticipé

### 🪤 Pièges / à surveiller
- **Layers/masks** des deux `Area2D` doivent se recouvrir, sinon la détection ne se déclenche jamais malgré un code correct.
- **`ColorRect` plein écran suspecté de bloquer les clics** : piste explorée mais **non confirmée** sur ce projet — le vrai coupable était le `Process Mode`. À vérifier au cas par cas si le souci se représente.
- **Variable de délai mal placée** : si `timerMarchand <= 0` est testé à l'intérieur du `if Input.is_action_just_pressed(...)`, il ne se vérifie qu'à l'instant de l'appui (donc presque jamais vrai). Il doit être testé juste après le décompte, indépendamment de l'input.

---

## Sprint — Ennemi patrouilleur : attaque et mort
**Branche :** `feat/enemy-patrol` · **Statut :** ✅

### 🎯 Ce qu'on a fait
L'ennemi patrouilleur peut maintenant être tué par l'épée du joueur (avec une vraie animation de mort), et inflige des dégâts au joueur au contact.

### 🔧 Comment ça marche

**1. Vie et mort de l'ennemi — même pattern que le boss.**

```gdscript
# enemy_patrol.gd
var vieEnemyPatrol: int = 3

func takeDamage(amount):
    vieEnemyPatrol -= amount
    if vieEnemyPatrol <= 0:
        Damage.SendDiedEnnemies()

func _physics_process(delta):
    if vieEnemyPatrol <= 0:
        sprite.play("die")
        return   # fige l'ennemi pendant l'animation de mort
    ...

func _on_animated_sprite_2d_animation_finished() -> void:
    if sprite.animation == "die":
        queue_free()
```

**2. Détection par l'épée** — même logique que pour le boss : `_on_sword_body_entered` vérifie le groupe et applique les dégâts.

**3. Dégâts au contact (l'ennemi attaque le joueur)** — réutilise la zone `Detection` du joueur (celle qui sert aussi au marchand) : si l'`Area2D` détectée est dans le groupe `EnemyPatrol`, le joueur prend des dégâts directement.

### 🏷️ Concepts / mots-clés
`vieEnemyPatrol` · pattern `takeDamage` réutilisé (boss → ennemi) · animation de mort + `queue_free()` différé à la fin de l'anim · zone de détection partagée (marchand + ennemi)

### 🪤 Pièges / à surveiller
- **Une seule variable pour deux sens de dégâts** : `degatsEnnemies` servait à la fois pour « dégâts que le joueur inflige à l'ennemi » et « dégâts que l'ennemi inflige au joueur ». Ça marche tant que les deux valent la même chose par coïncidence, mais casse dès qu'on veut les différencier. **À surveiller : nommer clairement le sens des dégâts dès qu'un deuxième type d'ennemi arrive.**
- **Piste de refonte notée (pas encore d'actualité) :** un système de dégâts centralisé (type d'ennemi, type de dégâts, émetteur/receveur) plutôt que des variables éparpillées partout — pertinent dès qu'il y a 2-3 types d'ennemis, prématuré avant.
- **Signal déclaré mais jamais émis :** `Damage.ennemiesDied` existe en déclaration mais `SendDiedEnnemies()` ne l'émet pas (contrairement à `SendDied()` / `SendPlayerDied()` qui suivent tous les deux le même schéma signal + pause). Pas bloquant tant que rien ne l'écoute, mais incohérent avec le reste du bus `Damage`.

---

> _Prochaine entrée à écrire à la fin du prochain mini-sprint._