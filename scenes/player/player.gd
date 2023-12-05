# Definiuje postać gracza.

extends CharacterBody2D

@export var id : int
@export var username : String

var direction : Vector2 = Vector2.ZERO
var last_direction_x : float
const SPEED = 300.0
var minigame: PackedScene
var minigame_instance:Node2D

@onready var minigame_container = get_parent().get_parent().get_node("Camera2D").get_node("MinigameContainer")
@onready var use_button = get_parent().get_parent().get_node("Camera2D").get_node("UseButton")
@onready var input = $InputSynchronizer
@onready var animation_tree = $Skins/AltAnimationTree
@onready var camera = get_parent().get_parent().get_node("Camera2D")


func _ready():
	# Ustawia autorytet gracza na jego id w celu jego identyfikacji w systemie multiplayer.
	input.set_multiplayer_authority(id)
	# Wyłącza synchronizację wejścia gracza, jeśli nie jest on obecnym graczem.
	if input.get_multiplayer_authority() == multiplayer.get_unique_id():
		MultiplayerManager.input_state_changed.connect(_on_input_state_changed)
	else:
		input.set_process(false)

	# Ustawia etykietę pseudonimu gracza.
	$UsernameLabel.text = username
	animation_tree.active = true
	last_direction_x = 1
	use_button.pressed.connect(_on_use_button_pressed)


func _process(_delta):
	update_animation_parameters()
	
	if name.to_int() == multiplayer.get_unique_id():
		var target_position = position
		camera.position = camera.position.lerp(target_position, 5 * _delta)


func _physics_process(_delta):
	# Pobiera pionowe i poziome wejście gracza, i odpowiednio ustawia pionową oraz poziomą prędkość.
	direction = Vector2(input.direction.x, input.direction.y)
	direction = direction.normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.y = direction.y * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
	# Zapamiętuje ostatni kierunek wzroku postaci
	if direction.x != 0:
		last_direction_x = direction.x
	# Porusza graczem i obsługuje kolizje.
	move_and_slide()


func update_animation_parameters():
	if velocity == Vector2.ZERO:
		animation_tree["parameters/conditions/idle"] = true
		animation_tree["parameters/conditions/is_moving"] = false
	else:
		animation_tree["parameters/conditions/idle"] = false
		animation_tree["parameters/conditions/is_moving"] = true
		if direction.x != 0:
			animation_tree["parameters/idle/blend_position"] = direction
			animation_tree["parameters/walk/blend_position"] = direction
		if direction.x == 0:
			animation_tree["parameters/idle/blend_position"] = Vector2(last_direction_x ,direction.y)
			animation_tree["parameters/walk/blend_position"] = Vector2(last_direction_x ,direction.y)


# Wyłącza ruch gracza gdy jest pauza, włącza gdy nie ma pauzy
func _on_input_state_changed(state: bool):
	input.set_process(state)
	input.direction = Vector2.ZERO

func show_use_button(id, minigame):
	if id == multiplayer.get_unique_id():
		self.minigame = minigame
		use_button.visible = true
		use_button.disabled = false


func hide_use_button(id):
	if id == multiplayer.get_unique_id():
		minigame = null
		use_button.visible = false
		use_button.disabled = true


func _on_use_button_pressed():
	if minigame != null:
		summon_window()


func _input(event):
	if event.is_action_pressed("interact") && minigame != null:
		summon_window()

func summon_window():
	minigame_container.visible = true
	var minigame_viewport = minigame_container.get_node("MinigameViewport")
	minigame_viewport.add_child(minigame.instantiate())
	minigame_instance = minigame_viewport.get_child(0)
	var x_scale = minigame_viewport.size.x / get_viewport_rect().size.x
	var y_scale = minigame_viewport.size.y / get_viewport_rect().size.y
	minigame_instance.scale = Vector2(x_scale, y_scale)
	use_button.visible = false
	use_button.disabled = true
	MultiplayerManager.set_input_state(false)
	minigame_instance.minigame_end.connect(end_minigame)

func end_minigame():
	minigame_instance.queue_free()
	minigame_container.visible = false
	MultiplayerManager.set_input_state(true)
