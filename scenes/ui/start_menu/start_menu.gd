extends Control

@onready var menu: Control = $Menu
@onready var settings: Control = $Settings


func _ready():
	settings.visible = false
	menu.visible = true
	# setting minimum size of window to 800x600
	DisplayServer.window_set_min_size(Vector2i(800,600))
	
func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/play_menu/play_menu.tscn")

func _on_settings_button_pressed():
	toggle_visibility()

func _on_exit_button_pressed():
	get_tree().quit()

func _on_settings_exit_settings():
	toggle_visibility()

func _on_back_button_pressed():
	toggle_visibility()

# makes the visible invisible and the invisible visible
func toggle_visibility():
	settings.visible = !settings.visible
	menu.visible = !menu.visible
