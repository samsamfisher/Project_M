extends Node

signal died
signal playerDied
signal ennemiesDied

func SendDiedEnnemies():
	print("Ennemy died")

func SendDied():
	died.emit()
	get_tree().paused = true

func SendPlayerDied():
	playerDied.emit()
	get_tree().paused = true
