extends Area2D

## Określa czy przycisk
@export var is_button:bool = false
## Tekstura znalezionego ciała
@export var body_texture:Texture

## Interfejs
@onready var user_interface = get_tree().root.get_node("Game/Maps/MainMap/UserInterface")
## Przycisk alarmowy
@onready var emergency_button = get_tree().root.get_node("Game/Maps/MainMap/Objects/SamorzadStol/EmergencyButton")


## Określa czy gracz jest w zasięgu
var is_player_inside:bool = false

# Określa czy czas oczekiwania na włączenie się przycisku alarmowego się skończył
var is_wait_time_over:bool = false
 
## Sygnał aktywujący/deaktywujący przyciski w interfejsie
signal button_active(button_name:String, is_active:bool)
## Sygnał przełączający podświetlenie przycisku awaryjnego
signal toggle_button_highlight(is_active:bool)


func _ready():
	if is_button:
		emergency_button.emergency_timer_timeout.connect(_on_end_emergency_timer_timeout)
	
	button_active.connect(user_interface.toggle_button_active)
	GameManager.next_round_started.connect(on_next_round_started)


func _input(event):
	# Obłsuguje odpowiednio naciśnięcie przycisku do zebrania lub do reportowania
	if (
	((event.is_action_pressed("report") && !is_button) || ((event.is_action_pressed("interact") && is_button && is_wait_time_over)))
	&& !GameManager.get_current_game_key("is_input_disabled")
	&& !GameManager.get_current_game_key("paused") 
	&& is_player_inside 
	&& !GameManager.get_current_player_key("is_dead") 
	&& !GameManager.is_meeting_called):
		
		GameManager.is_meeting_called = true
		
		var body_id = null
		if !is_button:
			body_id = get_parent().victim_id
		
		emergency_button.handle_report(is_button, body_id)


## Obsługuje zakończenie emergeny_timer
func _on_end_emergency_timer_timeout(is_over: bool):
	is_wait_time_over = is_over
	if is_player_inside && !GameManager.get_registered_player_key(multiplayer.get_unique_id(), "is_dead") && !GameManager.is_meeting_called && is_wait_time_over:
		button_active.emit("InteractButton", true)
		toggle_button_highlight.emit(true)


## Usuwa ciało z mapy
func on_next_round_started():
	if !is_button:
		get_parent().queue_free()


## Obsługuje wejście gracza
func _on_body_entered(body):
	if body.name.to_int() == multiplayer.get_unique_id() && !GameManager.get_registered_player_key(body.name.to_int(), "is_dead") && !body.is_in_vent:
		is_player_inside = true

		if is_button:
			if is_wait_time_over && !GameManager.is_meeting_called:
				button_active.emit("InteractButton", true)
				toggle_button_highlight.emit(true)
		else:
			button_active.emit("ReportButton", true)
			body.can_report = true


## Obsługuje wyjście gracza
func _on_body_exited(body):
	if body.name.to_int() == multiplayer.get_unique_id() && !GameManager.get_registered_player_key(body.name.to_int(), "is_dead") && !body.is_in_vent:
		is_player_inside = false
		body.can_report = false

		if is_button:
			button_active.emit("InteractButton", false)
			toggle_button_highlight.emit(false)
		else:
			button_active.emit("ReportButton", false)