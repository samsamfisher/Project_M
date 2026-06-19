extends Node

var ressources: int = 0
signal ressources_changees(total: int)   # déclarer


func ajouter_ressource() -> void:
	ressources += 1
	ressources_changees.emit(ressources)  # émettre
	
	
