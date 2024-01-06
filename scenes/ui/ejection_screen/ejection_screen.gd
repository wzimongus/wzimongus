extends Control

## Ekran końcowy głosowania
##
## Wyświetla informacje o tym, kto został wyrzucony
## oraz uruchamia timer do następnej rundy

## Referencja do etykiety z informacją o wyrzuconym graczu
@onready var ejection_message = get_node("%EjectionMessage")
## Pobiera listę głosów
@onready var votes = GameManager.get_current_game_key("votes")

## Czas do następnej rundy
@export var NEXT_ROUND_TIME = 5
## Timer do następnej rundy
@onready var next_round_timer = Timer.new()

## Pobiera informacje o wyrzuconym graczu
@onready var most_voted_player = GameManager.get_current_game_key("most_voted_player")


func _ready():
	# Wyświetla informacje o wyrzuconym graczu
	if  most_voted_player == null:
		ejection_message.text = "[center]Nikt nie został wyrzucony.[/center]"
	elif most_voted_player["is_lecturer"]:
		ejection_message.text = "[center]" + most_voted_player['username'] + " został wyrzucony.[/center]"
	else:
		ejection_message.text = "[center]" + most_voted_player['username'] + " nie był wykładowcą.[/center]"

	# Inicjalizacja timera do następnej rundy
	add_child(next_round_timer)
	next_round_timer.autostart = true
	next_round_timer.one_shot = true
	next_round_timer.connect("timeout", _on_next_round_timer_timeout)
	next_round_timer.start(NEXT_ROUND_TIME)


## Funkcja wywoływana po zakończeniu timera do następnej rundy
func _on_next_round_timer_timeout():
	self.queue_free()
	self.get_parent().get_node("%Button").show()

	# Przechodzi do następnej rundy
	GameManager.next_round()
