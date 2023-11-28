# Definiuje postać gracza.

extends CharacterBody2D

@export var id : int
@export var username : String

const SPEED = 300.0

@onready var input = $InputSynchronizer


func _ready():
	# Ustawia autorytet gracza na jego id w celu jego identyfikacji w systemie multiplayer.
	input.set_multiplayer_authority(id)
	# Wyłącza synchronizację wejścia gracza, jeśli nie jest on obecnym graczem.
	input.set_process(input.get_multiplayer_authority() == multiplayer.get_unique_id())
	# Ustawia etykietę pseudonimu gracza.
	$UsernameLabel.text = username


func _physics_process(delta):
	# Pobiera pionowe i poziome wejście gracza, i odpowiednio ustawia pionową oraz poziomą prędkość.
	var direction = Vector2(input.direction.x, input.direction.y)
	if direction:
		velocity.x = direction.x * SPEED
		velocity.y = direction.y * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
	
	# Porusza graczem i obsługuje kolizje.
	move_and_slide()
