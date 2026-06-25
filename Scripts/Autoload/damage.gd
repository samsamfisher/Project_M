extends Node

signal died
signal playerDied

func SendDied():
	died.emit()
	get_tree().paused = true

func SendPlayerDied():
	playerDied.emit()
	get_tree().paused = true
