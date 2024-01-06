extends HBoxContainer

## Wiadomość Systemowa
##
## Wyświetla wiadomość systemową

## Referencja do etykiety z wiadomością
@onready var message = get_node("%Message")

## Inicjalizacja wiadomości systemowej
func init(text):
	message.text = text

