extends Node

@export var facteur_speed_jauge : float = 1
var ressources: int = 0
var viePlayer: int = 3
var time : float = 0
var ressources_deja_doublees: bool = false

signal ressources_changees(total: int)   # déclarer
signal vie_changee(vie: int)
signal double_ressources

func _process(delta: float) -> void:
	time += facteur_speed_jauge * delta

func ajouter_ressource() -> void:
	ressources += 1
	ressources_changees.emit(ressources)  # émettre

func restart():
	ressources = 0
	viePlayer = 3
	time = 0
	ressources_deja_doublees = false
	get_tree().paused = false
	get_tree().reload_current_scene()

func ressources_doublees():
	if ressources_deja_doublees == false:
		print("Ressources actuelles : ", ressources)
		ressources *= 2
		ressources_changees.emit(ressources)
		print("Ressources doublées : ", ressources)
		ressources_deja_doublees = true
