extends Label


func _ready() -> void:
	Stats.ressources_changees.connect(_on_ressources_changees)  # connecter
	text = str(Stats.ressources)   # affiche 0 au démarrage

func _on_ressources_changees(total: int) -> void:
	text = str(total)
