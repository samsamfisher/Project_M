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
