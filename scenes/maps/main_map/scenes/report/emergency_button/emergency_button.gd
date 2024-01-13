extends Node2D

## Timer
@onready var emergency_timer = Timer.new()
## Label pozostałego czasu
@onready var time_left_label = $TimeLeftLabel
## Tekstura przycisku
@onready var sprite_2d = $Sprite2D
## Label wyświetlający pozostałą ilość użyć
@onready var uses_left_label = $UsesLeftLabel
## Area reportu
@onready var report_area = $ReportArea
## Canvas w którym będzie instancjonowane głosowanie
@onready var voting_canvas = get_tree().root.get_node("Game/Maps/MainMap/VotingCanvas")
## Główna mapa
@onready var main_map = get_tree().root.get_node("Game/Maps/MainMap")
## Interfejs
@onready var user_interface = get_tree().root.get_node("Game/Maps/MainMap/UserInterface")

## Ekran głosowania
var voting_screen = preload("res://scenes/ui/voting_screen/voting_screen.tscn")
## Ekran reporta
var report_screen = preload("res://scenes/maps/main_map/scenes/report/report_screen/report_screen.tscn")

# Czas oczekiwania od początku rundy na aktywację przycisku
var wait_time = GameManager.get_server_settings()["emergency_cooldown"]
## Określa czy czas oczekiwania się skończył
var is_wait_time_over: bool = false

## Kolor podświetlenia przycisku w zasięgu
var in_range_color = [255, 255, 255, 255]
## Kolor podświetlenia przycisku poza zasięgiem
var out_of_range_color = [0, 0, 0, 0]

## Wszyscy gracze
var players

## Określa czy przycisk wywołał spotkanie czy ciało
var is_caller_button: bool

## Sygnał informujący o zakończeniu czasu oczekiwania na włączenie przycisku alarmowego
signal emergency_timer_timeout(is_over:bool)
## Sygnał aktywujący/deaktywujący przyciski w interfejsie
signal button_active(button_name:String, is_active:bool)


func _ready():
	GameManager.next_round_started.connect(on_next_round_started)
	GameManager.map_load_finished.connect(_on_map_load_finished)
	GameManager.player_killed.connect(_on_player_killed)
	
	report_area.toggle_button_highlight.connect(toggle_button_highlight)
	
	uses_left_label.text = "Pozostało użyć: 1"
	
	toggle_button_highlight(false)
	
	button_active.connect(user_interface.toggle_button_active)


func _process(_delta):
	# Wyświetla pozostały czas do możliwości użycia przycisku
	time_left_label.text = str(int(emergency_timer.get_time_left()))


## Wywoływane w momencie oblania gracza
func _on_player_killed(id: int, is_victim: bool):
	if multiplayer.get_unique_id() == id && is_victim:
		uses_left_label.text = ""
		toggle_button_highlight(false)
		button_active.emit("InteractButton", false)
		button_active.emit("ReportButton", false)


## Wywoływane po zakończeniu ładowania mapy
func _on_map_load_finished():
	add_child(emergency_timer)
	emergency_timer.autostart = true
	emergency_timer.one_shot = true
	emergency_timer.timeout.connect(_on_end_emergency_timer_timeout)
	emergency_timer.start(wait_time)


## Obsługuje zakończenie emergeny_timer
func _on_end_emergency_timer_timeout():
	is_wait_time_over = true
	set_process(false)
	time_left_label.text = ""
	emergency_timer_timeout.emit(true)


## Na początku rundy restartuje timer z czasem oczekiwania na aktywację przycisku, przywraca widoczność elementów interfejsu
func on_next_round_started():
	voting_canvas.get_child(0).queue_free()

	GameManager.is_meeting_called = false
	
	button_active.emit("ReportButton", false)
	button_active.emit("InteractButton", false)
	toggle_button_highlight(false)
	
	set_process(true)
	is_wait_time_over = false
	
	emergency_timer.start(wait_time)
	emergency_timer_timeout.emit(false)


## Włącza i wyłącza podświetlenie przycisku awaryjnego
func toggle_button_highlight(is_on: bool):
	if is_on:
		sprite_2d.material.set_shader_parameter('color', in_range_color)
	else:
		sprite_2d.material.set_shader_parameter('color', out_of_range_color)


## Wywoływane po naciśnięciu przycisku, wyłącza możliwość ponownego użycia
func button_used():
	uses_left_label.text = "Pozostało użyć: 0"
	report_area.monitoring = false
	report_area.monitorable = false


## Obsługuje report/zebranie awaryjne
func handle_report(is_button: bool, body_id):
	GameManager.is_meeting_called = true
	
	is_caller_button = is_button
	
	update_array()
	
	_request_displaying_report_screen.rpc_id(1, is_button, body_id)
	
	if is_caller_button:
		button_used()


## Aktualizuje tablice, która mogła ulec zmianie
func update_array():
	players = get_tree().root.get_node("Game/Maps/MainMap/Players").get_children()


@rpc("any_peer", "call_local", "reliable")
func _request_displaying_report_screen(is_button: bool, dead_body_id):
	if !multiplayer.is_server():
		return ERR_UNAUTHORIZED
	
	_display_report_screen.rpc(is_button, dead_body_id)


@rpc("call_local", "reliable")
func _display_report_screen(is_button: bool, dead_body_id):
	main_map.close_modals()

	instantiate_voting_screen()

	show_hide_report_screen(is_button, dead_body_id)


## Instancjonuje ekran głosowania
func instantiate_voting_screen():
	var voting_screen_instance = voting_screen.instantiate()
	voting_canvas.add_child(voting_screen_instance)

	GameManager.is_meeting_called = true
	is_wait_time_over = false

	button_active.emit("ReportButton", false)
	button_active.emit("InteractButton", false)


## Pokazuje ekran reporta na chwilę, po czym rozpoczyna głosowanie
func show_hide_report_screen(is_button: bool, dead_body_id):
	var report_screen_instance = report_screen.instantiate()
	report_screen_instance.is_emergency_meeting = is_button

	if !is_button && dead_body_id != null:
		report_screen_instance.body_texture_id = dead_body_id
	
	voting_canvas.add_child(report_screen_instance)
	
	await get_tree().create_timer(1.5).timeout
	voting_canvas.get_child(1).queue_free()
	
	# Rozpoczyna głosowanie
	voting_canvas.get_child(0).start_voting()
