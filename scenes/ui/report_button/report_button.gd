extends Button

## Przycisk do głosowania
##
## Interfejs użytkownika, który pozwala na zgłoszenie śmierci gracza.

## Referencja do sceny głosowania
var voting_screen = preload("res://scenes/ui/voting_screen/voting_screen.tscn")

## Funkcja wywoływana po naciśnięciu przycisku
func _on_pressed():
	_open_voting_screen.rpc()


@rpc("call_local", "any_peer")
## Funkcja otwierająca scenę głosowania
func _open_voting_screen():
	var voting_screen_instance = voting_screen.instantiate()
	self.get_parent().add_child(voting_screen_instance)
	GameManager.set_input_status(false)
	self.hide()
