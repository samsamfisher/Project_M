extends Node

signal takeDamage(amount)
signal died

func SendDamage(damage):
	takeDamage.emit(damage)
	
func SendDied():
	died.emit()
	get_tree().paused = true
