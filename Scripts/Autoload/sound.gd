extends Node

var player: AudioStreamPlayer

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.stream = preload("res://Sound/DSGNTonl_USABLE-Magic Coin_HY_PC-001.wav")
	add_child(player)

func _playSound() -> void:
	player.play()
