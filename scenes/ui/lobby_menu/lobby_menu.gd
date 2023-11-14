extends Control

func _ready() -> void:
	# Ukrywa przycisk, jeśli użytkownik nie jest hostem
	if !multiplayer.is_server():
		$LobbyUI/StartGameButton.hide()
	
	# Początkowe wyświetlenie listy graczy
	update_display_player_list(multiplayer.get_unique_id(), MultiplayerManager.player_info)
	
	# Sprawienie, aby za każdym razem, gdy gracz dołącza lub
	# opuszcza listę graczy, była ona wyświetlana ponownie
	MultiplayerManager.player_connected.connect(update_display_player_list)
	MultiplayerManager.player_disconnected.connect(update_display_player_list)

func _on_start_game_button_button_down():
	# Tylko host jest w stanie rozpocząć grę
	if multiplayer.is_server():
		# Wysyłamy do klientów informację o rozpoczęciu gry
		start_game.rpc()


# Funkcja odpowiadająca za rozpoczęcie gry
@rpc("call_local", "reliable")
func start_game():
	# Chowamy lobby
	$LobbyUI.hide()
	
	# Robie, żeby wyświetlanie listy graczy nie będzie już aktualizowane.
	MultiplayerManager.player_connected.disconnect(update_display_player_list)
	MultiplayerManager.player_disconnected.disconnect(update_display_player_list)

	# Ładujemy mapę na serwerze, zostanie ona zsynchronizowana z klientami przez MapSpawner
	if multiplayer.is_server():
		change_map.call_deferred(load("res://scenes/map/map.tscn"))


# Funkcja dla serwera odpowiadająca za zmianę mapy
func change_map(scene: PackedScene):
	var map = $Map

	# Usuwamy obecną mapę
	for i in map.get_children():
		map.remove_child(i)
		i.queue_free()
	
	# Wyświetlamy nową mapę
	map.add_child(scene.instantiate())

# Wyświetla listę graczy na ekranie
func update_display_player_list(id, player_info):
	var players = MultiplayerManager.players
	var players_display = "Lista graczy:\n"
	var idx = 1
	for i in players:
		# Numerowanie graczy
		players_display += str(idx) + '. '
		
		# Wyświetlanie nazwisko gracza
		players_display += (players[i].username)
		
		# Newline symbol
		players_display += "\n"
		idx += 1
	
	# Wyświetlanie całości
	$LobbyUI/PlayerList.text = players_display
