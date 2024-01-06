extends CanvasLayer

## Czat
##
## Odpowiada za wyświetlanie wiadomości w czacie oraz wysyłanie ich do serwera.
## Wysyłanie wiadomości odbywa się za pomocą funkcji send_message, która jest
## wywoływana przez skrypt ChatInputText. Wysyłanie wiadomości odbywa się za
## pomocą RPC, dzięki czemu wiadomości są wysyłane do wszystkich graczy.

## Tryb czatu
enum Group { GLOBAL, LECTURER, DEAD, SYSTEM }

## Kolory grup
const GROUP_COLORS = {
	Group.GLOBAL: "white",
	Group.LECTURER: "red",
	Group.DEAD: "gray",
	Group.SYSTEM: "yellow"
}

## Czas po którym czat znika
const FADE_OUT_TIME = 0.25

## Referencja do etykiety, w którą wpisywane są wiadomości
@onready var input_text = $%InputText
## Referencja do timera, który odpowiada za znikanie czatu
@onready var timer = $%ChatDisappearTimer
## Referencja do kontenera, w którym znajdują się wiadomości
@onready var chat_logs_scroll_container = $%ChatLogsScrollbar
@onready var chat_logs_container = $%ChatLogsContainer
@onready var chat_logs_scrollbar = chat_logs_scroll_container.get_v_scroll_bar()
## Pobiera nazwę gracza
@onready var username = GameManager.get_current_player_key("username")

## Referencja do sceny wiadomości
var message_scene = preload("res://scenes/ui/chat/message/message.tscn")
## Referencja do sceny wiadomości systemowej
var system_message_scene = preload("res://scenes/ui/chat/system_message/system_message.tscn")

## Zmienna przechowująca ostatnią wartość scrollbara
var last_known_scroll_max = 0
## Zmienna przechowująca aktualną grupę
var current_group = Group.LECTURER
## Zmienna przechowująca tweena
var fade_out_tween 


func _ready():
	chat_logs_scrollbar.changed.connect(_update_scrollbar_position)
	input_text.hide()


func _input(event):
	if event.is_action_pressed("chat_open") && !input_text.visible:
		_open_chat()
		get_viewport().set_input_as_handled()
	if (event.is_action_pressed("chat_close") || event.is_action_pressed("pause_menu")) && input_text.visible:
		_close_chat()
		get_viewport().set_input_as_handled()


@rpc("any_peer", "call_local", "reliable")
## Funkcja wysyłająca wiadomość
func send_message(message, group, id):
	match group:
		Group.DEAD:
			if current_group == Group.DEAD:
				_create_message(GameManager.get_registered_player_key(id, "username"), message, Group.DEAD)
		Group.LECTURER:
			if current_group == Group.LECTURER:
				_create_message(GameManager.get_registered_player_key(id, "username"), message, Group.LECTURER)
			else:
				_create_message(GameManager.get_registered_player_key(id, "username"), message, Group.GLOBAL)
		Group.SYSTEM:
			var system_message_instance = system_message_scene.instantiate()
			chat_logs_container.add_child(system_message_instance)
			system_message_instance.init(message)
			chat_logs_scroll_container.modulate.a = 1
			
			if get_parent().name == "VotingScreen":
				return

			timer.start()
		_:
			_create_message(GameManager.get_registered_player_key(id, "username"), message, current_group)
	
	if multiplayer.is_server():
		for peer_id in GameManager.get_registered_players().keys():
			if peer_id != 1:
				send_message.rpc_id(peer_id, message, group, id)

## Funkcja wysyłająca wiadomość systemową
func send_system_message(message):
	const SYSTEM_MESSAGE_ID = 1
	send_message(message, Group.SYSTEM, SYSTEM_MESSAGE_ID)

## Funkcja tworząca wiadomość
func _create_message(username, message, group):
	chat_logs_scroll_container.modulate.a = 1

	var new_message = message_scene.instantiate()
	chat_logs_container.add_child(new_message)

	new_message.init(username, message, GROUP_COLORS[group])

	if get_parent().name == "VotingScreen":
		return

	timer.start()


func _on_input_text_visibility_changed():
	visibility_changed.emit()

## Zdarzenie wywoływane po naciśnięciu przycisku enter
func _on_input_text_text_submitted(submitted_text):
	submitted_text = submitted_text.strip_edges()

	if submitted_text == "":
		return
	
	# Wyślij wiadomość do serwera
	send_message.rpc_id(1, submitted_text, current_group, multiplayer.get_unique_id())	

	input_text.text = ""
	_close_chat()

## Zdarzenie wywoływane po wysłaniu wiadomości lub wyjściu z czatu
func _on_timer_timeout():
	if input_text.has_focus():
		return

	fade_out_tween = get_tree().create_tween()
	fade_out_tween.tween_property(chat_logs_scroll_container, "modulate:a", 0, FADE_OUT_TIME)

## Aktualizacja pozycji scrollbara
func _update_scrollbar_position():
	if last_known_scroll_max != chat_logs_scrollbar.max_value:
		last_known_scroll_max = chat_logs_scrollbar.max_value
		chat_logs_scroll_container.scroll_vertical = last_known_scroll_max

## Otwarcie czatu
func _open_chat():
	input_text.grab_focus()
	input_text.show()
	chat_logs_scroll_container.modulate.a = 1

## Zamknięcie czatu
func _close_chat():
	input_text.release_focus()
	input_text.hide()
	input_text.text = ""

	if get_parent().name == "VotingScreen":
		return

	timer.start()
	
