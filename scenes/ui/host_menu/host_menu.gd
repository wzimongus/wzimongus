extends Control

@onready var username_input = $InputsContainer/UsernameContainer/UsernameInput
@onready var port_input = $InputsContainer/PortContainer/PortInput
@onready var max_connections = $InputsContainer/MaxConnectionsContainer/MaxConnectionsInputContainer/MaxConnectionsInput
@onready var max_lectureres = $InputsContainer/MaxLecturersContainer/MaxLecturersInputContainer/MaxLecturersInput
@onready var lecturers_amount_alert = $InputsContainer/LecturersAmountAlert

func _on_host_button_button_down():
	GameManager.set_player_key("username", username_input.text)
	GameManager.host_game(port_input.text.to_int(), max_connections.text.to_int(), max_lectureres.text.to_int())

func _on_connections_lecturers_item_selected(_index: int):
	lecturers_amount_alert.visible = true if ceil(max_connections.text.to_int() / 4.0) < max_lectureres.text.to_int() else false
