extends Area2D

# parametry dla Sprite2D
@export var sprite : Texture2D
@export var scale_factor : float = 1

# Task ID przekazany przez serwer 
@export var task_id : int

# czy gracz wylosował tego taska
@export var disabled = true

# minigra która będzie włączona przez ten przecisk
@export var minigame_scene : PackedScene

var _is_player_inside : bool = false

func _ready():
	$Sprite2D.texture = sprite
	$Sprite2D.scale = Vector2(scale_factor, scale_factor)
	
	if not disabled:
		# Ustawia domyślny outline dla miejscu taska 
		$Sprite2D.material.set_shader_parameter('line_color', [0.5, 0.5, 0,5, 1])
		$Sprite2D.material.set_shader_parameter('line_thickness', 10.0)
	else:
		body_entered.disconnect(_on_body_entered)
		body_exited.disconnect(_on_body_exited)


func _on_body_entered(body):
	print(body.get_name())
	if "id" in body and body.id == multiplayer.get_unique_id():
		$Sprite2D.material.set_shader_parameter('line_color', [0.3, 0.9, 0,5, 1])
		_is_player_inside = true


func _on_body_exited(body):
	if "id" in body and body.id == multiplayer.get_unique_id():
		$Sprite2D.material.set_shader_parameter('line_color', [0.5, 0.5, 0,5, 1])
		_is_player_inside = false
