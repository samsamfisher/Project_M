extends Label


func _ready() -> void:
	Stats.vie_changee.connect(_on_vie_changee)  # connecter
	text = str(Stats.viePlayer)

func _on_vie_changee(total: int) -> void:
	text = str(total)
