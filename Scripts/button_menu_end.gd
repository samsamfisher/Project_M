extends Control

@onready var restart: Button = $VBoxContainer/Restart
@onready var MainMenu: Button = $VBoxContainer/MainMenu
@onready var Quit: Button = $VBoxContainer/Quit

func _on_restart_pressed() -> void:
	print("RESTART")
	Stats.restart()


func _on_main_menu_pressed() -> void:
	print("MAIN MENU")

func _on_quit_pressed() -> void:
	print("QUIT")
	get_tree().quit()
	
