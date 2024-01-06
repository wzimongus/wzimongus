extends HBoxContainer

## Pojedynczy instancja pokoju w liście pokoi
##
## Zawiera nazwę pokoju oraz przyciski do przesuwania pokoju w górę i w dół

## Sygnał emitowany, gdy przycisk do przesuwania pokoju w górę zostanie wciśnięty
signal button_down

## Sygnał emitowany, gdy przycisk do przesuwania pokoju w dół zostanie wciśnięty
signal button_up

## Label z nazwą pokoju
var room_name = ""

## Funkcja inicjalizująca, ustawiająca nazwę pokoju oraz kolor tekstu
func init(room_name, room_color):
	$RoomName.text = "[color=" + room_color + "]" + room_name
	self.room_name = room_name

## Funkcja zwracająca nazwę pokoju
func get_room_name():
	return room_name

## Funkcja emitująca sygnał button_down
func _on_button_down_pressed():
	button_down.emit(self)

## Funkcja emitująca sygnał button_up
func _on_button_up_pressed():
	button_up.emit(self)
