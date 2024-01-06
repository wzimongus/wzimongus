extends CharacterBody2D

@export var speed = 600.0
var last_direction_x: float = -1

@onready var input = $Input
@onready var rollback_synchronizer = $RollbackSynchronizer
@onready var username_label = $UsernameLabel
@onready var animation_tree = $Skins/AnimationTree
@onready var player_sprite = $Skins/PlayerSprite
@onready var player_node = $"."

# zmienne do funkcji zabijania
var in_range_color = [180, 0, 0, 255]
var out_of_range_color = [0, 0, 0, 0]
var dead_username_color = Color.DARK_GOLDENROD
var can_kill: bool = false


func _ready():
	# Gracz jest własnością serwera.
	set_multiplayer_authority(1)

	# Wejście gracza jest własnością gracza.
	input.set_multiplayer_authority(name.to_int())

	# Konfiguruje synchronizację.
	rollback_synchronizer.process_settings()

	# Ustawia etykietę z nazwą gracza.
	username_label.text = GameManager.get_registered_player_key(name.to_int(), "username")

	# Aktywuje drzewo animacji postaci.
	animation_tree.active = true
	
	# Aktualizuje parametry animacji postaci.
	animation_tree["parameters/idle/blend_position"] = Vector2(last_direction_x, 0)
	animation_tree["parameters/walk/blend_position"] = Vector2(last_direction_x, 0)

	_toggle_highlight(player_node.name.to_int(),false)
	
	GameManager.player_killed.connect(_on_killed_player)
	
	if GameManager.get_current_player_key("is_lecturer"):
		can_kill = true

func _process(_delta):
	# Aktualizuje parametry animacji postaci.
	var direction = input.direction.normalized()
	
	_update_animation_parameters(direction)

func _rollback_tick(_delta, _tick, _is_fresh):
	# Oblicza kierunek ruchu na podstawie wejścia użytkownika.
	velocity = input.direction.normalized() * speed

	# Porusza postacią i obsługuje kolizje.
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor
	
	# Podświetla najbliższego gracza jako potencjalną ofiarę do oblania jeśli jestem impostorem,
	# żyje i cooldown na funcji zabij nie jest aktywny.
	if GameManager.get_current_player_key("is_lecturer"):
		if !GameManager.get_current_player_key("is_dead"):
			if can_kill:
				_update_highlight(closest_player(GameManager.get_current_player_id()))
			else:
				_update_highlight(0)

## Sprawdza, czy nie naciśnięto fail button. Jeśli tak to sprawdza, czy jesteśmy lecturerem
## i prosi serwer o oblanie najbliższego gracza w promieniu oblania.
func _input(event):
	if event.is_action("fail") and event.is_pressed() and not event.is_echo():
		if name.to_int() == GameManager.get_current_player_id():
			if GameManager.get_registered_player_key(name.to_int(),"is_lecturer"):
				if can_kill:
					var victim = closest_player(GameManager.get_current_player_id())
					if victim:
						can_kill = false
						GameManager.kill(victim)
						var timer = Timer.new()
						timer.timeout.connect(_on_timer_timeout)
						timer.one_shot = true
						timer.wait_time = GameManager.get_server_settings()["kill_cooldown"]
						add_child(timer)
						timer.start()


## Aktualizuje parametry animacji postaci.
func _update_animation_parameters(direction) -> void:
	# Ustawia parametry animacji w zależności od stanu ruchu.
	if direction == Vector2.ZERO:
		animation_tree["parameters/conditions/idle"] = true
		animation_tree["parameters/conditions/is_moving"] = false
	else:
		animation_tree["parameters/conditions/idle"] = false
		animation_tree["parameters/conditions/is_moving"] = true
		if direction.x != 0:
			animation_tree["parameters/idle/blend_position"] = direction
			animation_tree["parameters/walk/blend_position"] = direction
			last_direction_x = direction.x
		else:
			animation_tree["parameters/idle/blend_position"] = Vector2(last_direction_x, direction.y)
			animation_tree["parameters/walk/blend_position"] = Vector2(last_direction_x, direction.y)

## Włącza i wyłącza podświetlenie możliwości zabicia gracza
func _toggle_highlight(player: int, is_on: bool) -> void:
	var player_material = get_parent().get_node(str(player) + "/Skins/PlayerSprite").material
	if player_material:
		if is_on:
			player_material.set_shader_parameter('color', in_range_color)
		else:
			player_material.set_shader_parameter('color', out_of_range_color)

func _update_highlight(player: int) -> void:
		var all_players = GameManager.get_registered_players().keys()
		all_players.erase(GameManager.get_current_player_id())
		
		for i in all_players:
			if player != null and i == player:
				_toggle_highlight(i,true)
			else:
				_toggle_highlight(i,false)

## Zwraca id: int najbliższego gracza do "to_who", który nie jest impostorem i żyje
func closest_player(to_who: int) -> int:
	var players: Array = GameManager.get_registered_players().keys()
	players.erase(to_who)
	
	for i in players:
		if GameManager.get_registered_player_key(i,"is_lecturer") or GameManager.get_registered_player_key(i,"is_dead"):
			players.erase(i)
	
	if players.size() > 0:
		var kill_radius = GameManager.get_server_settings()["kill_radius"]
		var my_position: Vector2 = get_tree().root.get_node("Game/Maps/MainMap/Players/"+str(to_who)).global_position
		var curr_closest = null
		var curr_closest_dist = kill_radius**2 + 1
		
		for i in range(players.size()):
			var temp_position: Vector2 = get_tree().root.get_node("Game/Maps/MainMap/Players/"+str(players[i])).global_position
			var temp_dist = my_position.distance_squared_to(temp_position)
			
			if(temp_dist < curr_closest_dist):
				curr_closest = players[i]
				curr_closest_dist = temp_dist
				
		if curr_closest_dist < (kill_radius**2):
			return curr_closest
		return 0
	return 0

func _on_killed_player(victim: int) -> void:
	if GameManager.get_registered_player_key(victim,"is_dead"):
		_update_dead_player(victim)
		
		if GameManager.get_current_player_id() != victim:
			get_parent().get_node(str(victim)).visible = false
	
	if GameManager.get_current_player_key("is_dead"):
		for i in GameManager.get_registered_players().keys():
			get_parent().get_node(str(i)).visible = true
	
	var dead_body = preload("res://scenes/player/assets/dead_body.tscn").instantiate()
	get_parent().add_child(dead_body)
	dead_body.set_dead_player(victim)
	dead_body.get_node("DeadBodyLabel").text = GameManager.get_registered_player_key(victim,"username")+" dead body"

func _on_timer_timeout() -> void:
	can_kill = true
	for i in range(player_node.get_child_count()):
		var child: Node = player_node.get_child(i)
		if child.is_class("Timer"):
			child.queue_free()
			return

func _update_dead_player(victim: int):
	var victim_node: CharacterBody2D = get_tree().root.get_node("Game/Maps/MainMap/Players/"+str(victim))
	victim_node.get_node("UsernameLabel").add_theme_color_override("font_color", dead_username_color)
	victim_node.get_node("Skins/PlayerSprite").material = null
	victim_node.get_node("Skins/PlayerSprite").modulate = Color(1,1,1,0.35)
	victim_node.collision_mask = 0
