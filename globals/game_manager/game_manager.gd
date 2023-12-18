extends Node
## Klasa odpowiadająca za zarządzanie stanem gry, gracza i serwera.

## Emitowany po zarejestrowaniu nowego gracza na serwerze.
signal player_registered(id: int, player: Dictionary)

## Emitowany po wyrejestrowaniu gracza z serwera.
signal player_deregistered(id: int)

## Emitowany po zmianie statusu sterowania u gracza.
signal input_status_changed(is_paused: bool)

## Emitowany u klienta po pomyślnej rejestracji na serwerze.
signal registered_successfully()

## Emitowany po rozpoczęciu gry.
signal game_started()

## Emitowany po zakończeniu gry.
signal game_ended()

## Emitowany po wystąpieniu błędu.
signal error_occured(message: String)

# Przechowuje informacje o aktualnym stanie gry.
var _current_game = {
	"is_started": false,
	"is_paused": false,
	"is_input_disabled": false,
	"registered_players": {}
}

# Przechowuje dane o obecnym graczu.
var _current_player = {
	"username": "",
	"is_impostor": false,
	"is_dead": false
}

# Przechowuje ustawienia serwera.
var _server_settings = {
	"port": 9001,
	"max_players": 10,
	"max_impostors": 1
}

# Lista atrybutów gracza, które klient ma prawo zmieniać.
var _player_fillable = ["username"]

# Lista atrybutów gracza, których klient nie może widzieć.
var _player_hidden = ["is_impostor"]

# Predefiniowane atrybuty gracza, które nadpiszą informacje od klienta przy rejestracji.
var _player_attributes = {
	"is_impostor": false,
	"is_dead": false
}

func _ready():
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

## Tworzy nowy serwer gry.
func host_game(port: int, max_players: int, max_lecturers: int):
	# Ustawia parametry serwera.
	_server_settings["port"] = port
	_server_settings["max_players"] = max_players
	_server_settings["max_impostors"] = max_lecturers

	# Inicjalizuje serwer.
	var peer = ENetMultiplayerPeer.new()
	var status = peer.create_server(_server_settings["port"])

	if status != OK:
		_handle_error("Nie udało się nasłuchiwać na porcie " + str(_server_settings["port"]) + "!")
		return

	multiplayer.multiplayer_peer = peer

	# Oczekuje na wystartowanie serwera.
	await async_condition(
		func():
			return peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTING
	)

	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		_handle_error("Nie udało się uruchomić serwera!")
		return

	# Rejestruje hosta jako gracza.
	_add_registered_player(1, _current_player)
	_on_player_registered()

## Dołącza do istniejącego serwera gry.
func join_game(address:String, port:int):
	# Tworzy klienta gry.
	var peer = ENetMultiplayerPeer.new()
	var status = peer.create_client(address, port)

	if status != OK:
		_handle_error("Nie udało się utworzyć klienta! Powód: " + error_string(status))
		return

	multiplayer.multiplayer_peer = peer

	# Oczekuje na połączenie z serwerem.
	await async_condition(
		func():
			return peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTING
	)

	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		_handle_error("Nie udało się połączyć z " + str(address) + ":" + str(port) + "!")
		return

## Rozpoczyna grę.
func start_game():
	# Tylko host może rozpocząć grę.
	if multiplayer.is_server():
		# Wybiera morderców.
		_select_impostors()

		# Ładuje główną mapę.
		_on_game_started.rpc()

		# Przypisuje zadania.
		TaskManager.assign_tasks_server(1)

## Kończy grę.
func end_game():
	# Zamyka połączenie i przywraca domyślny peer.
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

	# Resetuje stan gry.
	_current_game["is_started"] = false
	_current_game["is_paused"] = false
	_current_game["is_input_disabled"] = false
	_current_game["registered_players"].clear()

	_current_player["username"] = ""
	_current_player["is_impostor"] = false
	_current_player["is_dead"] = false

	await get_tree().process_frame
	game_ended.emit()

## Zwraca informację o grze, która jest przechowywana pod danym kluczem.
func get_current_game_key(key:String):
	if _current_game.has(key):
		return _current_game[key]

	return null

## Zwraca słownik zarejestrowanych graczy.
func get_registered_players():
	return _current_game["registered_players"]

## Zwraca informację o danym graczu, która jest przechowywana pod danym kluczem.
func get_registered_player_key(id:int, key:String):
	if _current_game["registered_players"].has(id):
		if _current_game["registered_players"][id].has(key):
			return _current_game["registered_players"][id][key]

	return null

## Zwraca ID obecnego gracza.
func get_current_player_id():
	return multiplayer.get_unique_id()

## Zwraca informację o obecnym graczu, która jest przechowywana pod danym kluczem.
func get_current_player_key(key:String):
	if _current_player.has(key):
		return _current_player[key]

	return null

## Zmienia informację o obecnym graczu, która jest przechowywana pod danym kluczem.
func set_player_key(key:String, value):
	if _current_player.has(key):
		_current_player[key] = value

## Zmienia status informacji o wyświetlaniu menu pauzy.
func set_pause_menu_status(is_paused:bool):
	_current_game["is_paused"] = is_paused
	input_status_changed.emit(!_current_game["is_paused"] && !_current_game["is_input_disabled"])

## Umożliwia zmianę statusu sterowania obecnego gracza.
func set_input_status(state:bool):
	_current_game["is_input_disabled"] = !state
	input_status_changed.emit(!_current_game["is_paused"] && !_current_game["is_input_disabled"])

## Obsługuje rozłączenie gracza na serwerze.
func _on_player_disconnected(id:int):
	_delete_deregistered_player.rpc(id)

## Obsługuje połączenie z serwerem u klienta.
func _on_connected():
	# Oczekuje na synchronizację czasu.
	# await NetworkTime.after_sync

	# Wysyła informacje o graczu do serwera w celu rejestracji.
	_register_player.rpc_id(1, _filter_player(_current_player))

## Obsługuje nieudane połączenie z serwerem u klienta.
func _on_connection_failed():
	_handle_error("Nie można połączyć się z serwerem!")
	end_game()

## Obsługuje rozłączenie z serwerem u klienta.
func _on_server_disconnected():
	_handle_error("Połączenie z serwerem zostało przerwane!")
	end_game()

## Filtruje informacje o graczu.
func _filter_player(player:Dictionary):
	var filtered_player = {}

	# Zostawia tylko atrybuty, które klient może zmieniać.
	for i in _player_fillable:
		if player.has(i):
			filtered_player[i] = player[i]

	return filtered_player

## Obsługuje błędy.
func _handle_error(message: String):
	await get_tree().process_frame
	error_occured.emit(message)

@rpc("any_peer", "reliable")
## Rejestruje gracza na serwerze.
func _register_player(player:Dictionary):
	var id = multiplayer.get_remote_sender_id()

	# Wyrzuca gracza, jeśli gra już się rozpoczęła.
	if _current_game["is_started"]:
		_kick_player.rpc_id(id, "Gra już się rozpoczęła!")
		return

	# Wyrzuca gracza, jeśli przekroczono limit graczy.
	if _current_game["registered_players"].size() >= _server_settings["max_players"]:
		_kick_player.rpc_id(id, "Przekroczono limit połączeń!")
		return

	# Informuje nowego gracza o obecnych graczach.
	for i in _current_game["registered_players"]:
		_add_registered_player.rpc_id(id, i, _filter_player(_current_game["registered_players"][i]))

	# Informuje pozostałych graczy o nowym graczu.
	_add_registered_player.rpc(id, _filter_player(player))

	# Informuje nowego gracza o poprawnej rejestracji.
	_on_player_registered.rpc_id(id)

@rpc("reliable")
## Obsługuje pomyślną rejestrację gracza u klienta.
func _on_player_registered():
	await get_tree().process_frame
	registered_successfully.emit()

@rpc("call_local", "reliable")
## Dodaje zarejestrowanego gracza do słownika.
func _add_registered_player(id:int, player:Dictionary):
	# Filtruje informacje od klienta.
	var filtered_player = _filter_player(player)

	# Dodaje predefiniowane atrybuty.
	filtered_player.merge(_player_attributes)

	# Usuwa atrybuty, których klient nie może widzieć.
	if !multiplayer.is_server():
		for i in _player_hidden:
			if filtered_player.has(i):
				filtered_player.erase(i)

	_current_game["registered_players"][id] = filtered_player
	player_registered.emit(id, filtered_player)

@rpc("call_local", "reliable")
## Usuwa wyrejestrowanego gracza ze słownika.
func _delete_deregistered_player(id:int):
	_current_game["registered_players"].erase(id)
	player_deregistered.emit(id)

@rpc("reliable")
## Wyrzuca gracza z serwera.
func _kick_player(reason: String):
	_handle_error(reason)
	end_game()

@rpc("call_local", "reliable")
## Obsługuje rozpoczęcie gry u graczy.
func _on_game_started():
	_current_game["is_started"] = true
	game_started.emit()

## Wybiera morderców.
func _select_impostors():
	var available_players = get_registered_players().keys()
	var impostors = []

	for i in range(_server_settings["max_impostors"]):
		var id = available_players[randi() % available_players.size()]

		impostors.append(id)
		available_players.erase(id)

	for i in impostors:
		_current_game["registered_players"][i]["is_impostor"] = true

		if i != 1:
			_send_impostor_status.rpc_id(i, impostors)
		else:
			_current_player["is_impostor"] = true

@rpc("reliable")
## Wysyła informacje o mordercach.
func _send_impostor_status(impostors):
	for i in get_registered_players():
		_current_game["registered_players"][i]["is_impostor"] = true if i in impostors else false

	_current_player["is_impostor"] = true

## Asynchronicznie czeka na warunek.
func async_condition(cond: Callable, timeout: float = 10.0) -> Error:
	timeout = Time.get_ticks_msec() + timeout * 1000
	while not cond.call():
		await get_tree().process_frame
		if Time.get_ticks_msec() > timeout:
			return ERR_TIMEOUT
	return OK
