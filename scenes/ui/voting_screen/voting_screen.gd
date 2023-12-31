extends Control

@onready var players = get_node("%Players")
@onready var end_vote_text = get_node("%EndVoteText")
@onready var skip_decision = get_node("%Decision")
@onready var skip_button = get_node("%SkipButton")
@onready var chat = get_node("%Chat")
@onready var chat_background = get_node("%ChatBackground")
@onready var chat_input = $Chat/ChatContainer/InputText

@export var VOTING_TIME = 10
@onready var voting_timer = Timer.new()

@export var EJECT_PLAYER_TIME = 5
@onready var eject_player_timer = Timer.new()

var player_box = preload("res://scenes/ui/voting_screen/player_box/player_box.tscn")
var ejection_screen = preload("res://scenes/ui/ejection_screen/ejection_screen.tscn")

var time = 0

var is_selected = false


func _ready():
	# Renderuje boxy z graczami (bez głosów)
	_render_player_boxes()

	chat.visible = false

	# END VOTING TIMER
	add_child(voting_timer)
	voting_timer.autostart = true
	voting_timer.one_shot = true
	voting_timer.connect("timeout", _on_end_voting_timer_timeout)
	voting_timer.start(VOTING_TIME)

	# EJECT PLAYER TIMER
	add_child(eject_player_timer)
	eject_player_timer.connect("timeout", _on_eject_player_timer_timeout)


func _process(delta):
	if time < VOTING_TIME:
		time += delta
		var time_remaining = VOTING_TIME - time
		end_vote_text.text = "Głosowanie kończy się za %02d sekund" % time_remaining


func _on_player_voted(voted_player_key):
	skip_button.disabled = true
	GameManager.set_current_game_key("is_voted", true)

	# Dodaje głos do listy głosów na serwerze
	if multiplayer.is_server():
		_add_player_vote(voted_player_key, multiplayer.get_unique_id())
	else:
		_add_player_vote.rpc_id(1, voted_player_key, multiplayer.get_unique_id())


@rpc("any_peer", "call_remote", "reliable")
func _add_player_vote(player_key, voted_by):
	GameManager.add_vote(player_key, voted_by)


## Wyświetla decyzję o skipowaniu
func _on_skip_button_pressed():
	if GameManager.get_current_game_key("is_voted") || GameManager.get_current_game_key("is_vote_preselected"):
		return
	
	skip_decision.visible = true
	GameManager.set_current_game_key("is_vote_preselected", true)


## Zamyka decyzję o skipowaniu
func _on_decision_yes_pressed():
	GameManager.set_current_game_key("is_voted", true)
	skip_decision.visible = false
	skip_button.disabled = true


func _on_decision_no_pressed():
	GameManager.set_current_game_key("is_vote_preselected", false)
	skip_decision.visible = false


## Renderuje boxy z graczami
@rpc("call_local", "reliable")
func _render_player_boxes():
	for child in players.get_children():
		child.queue_free()

	var registered_players = GameManager.get_registered_players()

	var votes = GameManager.get_current_game_key("votes")

	for key in registered_players.keys():
		var new_player_box = player_box.instantiate()
		players.add_child(new_player_box)

		var player_votes = votes[key] if key in votes else []
		new_player_box.init(registered_players[key].username, key, player_votes)
		new_player_box.connect("player_voted", _on_player_voted)


## Zamyka głosowanie
func _on_end_voting_timer_timeout():
	GameManager.set_current_game_key("is_voted", true)

	end_vote_text.text = "[center]Głosowanie zakończone![/center]"
	
	eject_player_timer.start(EJECT_PLAYER_TIME)

	# Serwer wysyła głosy do graczy, wynik głosowania i renderuje boxy z graczami
	if multiplayer.is_server():
		var most_voted_player_id = get_most_voted_player_id()

		for player_id in GameManager.get_current_game_key("votes").keys():
			var voted_by_players = GameManager.get_current_game_key("votes")[player_id]
			for voted_by in voted_by_players:
				_add_player_vote.rpc(player_id, voted_by)

		_render_player_boxes.rpc()

		GameManager.set_most_voted_player.rpc(GameManager.get_registered_players()[most_voted_player_id] if most_voted_player_id != null else null)

		GameManager.kill_player(most_voted_player_id)


## Zmienia scene na ekran wyrzucenia
func _on_eject_player_timer_timeout():
	_change_scene_to_ejection_screen.rpc()


@rpc("any_peer", "call_local", "reliable")
func _change_scene_to_ejection_screen():
	self.get_parent().add_child(ejection_screen.instantiate())
	self.queue_free()


func update_input():
	if chat_input:
		var input_status = !chat_input.visible
		GameManager.set_input_status(input_status)

## Zwraca id gracza z największą ilością głosów, jeśli jest remis zwraca null
func get_most_voted_player_id():
	var most_voted_players = []
	var max_vote = 0

	for vote_key in GameManager.get_current_game_key("votes").keys():
		var votes_count = GameManager.get_current_game_key("votes")[vote_key].size()
		if votes_count > max_vote:
			max_vote = votes_count
			most_voted_players = [vote_key]
		elif votes_count == max_vote:
			most_voted_players.append(vote_key)

	if most_voted_players.size() > 1 || most_voted_players.size() == 0:
		return null
	else:
		return most_voted_players[0]


func _on_open_chat_pressed():
	chat.visible = true
	chat._open_chat()
	chat_background.visible = true


func _on_close_chat_pressed():
	chat.visible = false
	chat_background.visible = false
	chat._close_chat()
