extends Node2D

@onready var page1 = get_node("%Page1")
@onready var page2 = get_node("%Page2")
@onready var page3 = get_node("%Page3")
@onready var page4 = get_node("%Page4")
@onready var page5 = get_node("%Page5")

@onready var password_input = get_node("%PasswordInput")

@onready var passwords = _generate_passwords()

@onready var page_scene = preload("res://scenes/minigames/find_password/page_scenes/page_scene.tscn")

var correct_password

func _ready():
	correct_password = passwords[randi() % 5]
	for i in range(5):
		var page_scene_instance = page_scene.instantiate()
		page_scene_instance.init(passwords[i])
		add_child(page_scene_instance)
		#page_scene_instance.visible = false
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
	self.queue_free()
