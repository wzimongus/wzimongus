extends Node2D

@onready var password_input = get_node("%PasswordInput")

@onready var passwords = _generate_passwords()

@onready var page_scene = preload("res://scenes/minigames/find_password/page_scenes/page_scene.tscn")

var correct_password

var page_scenes = []

signal minigame_end

func _ready():
	correct_password = passwords[randi() % 5]
	for i in range(5):
		var page_scene_instance = page_scene.instantiate()
		page_scene_instance.init(passwords[i])
		page_scenes.append(page_scene_instance)
		add_child(page_scene_instance)
		page_scene_instance.visible = false
		page_scene_instance.position = Vector2(400, 400)

func _generate_passwords():
	var passwords = []
	for i in range(5):
		var password = ""
		for j in range(10):  # Generate a 10-character password
			var ascii = randi() % 26 + 97  # Generate a random lowercase letter
			password += char(ascii)
		passwords.append(password)
	return passwords

func _on_password_input_text_submitted(new_text):
	if new_text == correct_password:
		_close()
	else:
		password_input.clear()
		password_input.set_placeholder("Wrong password!")

func _on_button_pressed():
	pass

func _close():
	minigame_end.emit()
	self.queue_free()

func _on_page_1_pressed():
	page_scenes[0].visible = true


func _on_page_2_pressed():
	page_scenes[1].visible = true


func _on_page_3_pressed():
	page_scenes[2].visible = true


func _on_page_4_pressed():
	page_scenes[3].visible = true


func _on_page_5_pressed():
	page_scenes[4].visible = true
