extends Node

@export var facteur_speed_jauge : float = 1
var ressources: int = 0
var vie: int = 3
var time : float = 0
signal ressources_changees(total: int)   # déclarer
signal vie_changee(vie: int)

func _process(delta: float) -> void:
	time += facteur_speed_jauge * delta
	
func ajouter_ressource() -> void:
	ressources += 1
	ressources_changees.emit(ressources)  # émettre
