extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Damage.died.connect(displayMenu)
	

func displayMenu():
	visible = true
	$VBoxContainer/Time.text = "%.2f" % Stats.time
	print($VBoxContainer/Time.text)
