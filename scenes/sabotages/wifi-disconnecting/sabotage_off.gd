extends Node2D

#signal sabo_on

## Funkcja startująca wraz z uruchomieniem sceny - ukrywa widoczność panelu z komunikatem o naprawieniu wifi
func _ready():
	$Panel.visible = false
## Obsługa przycisku on - po naciśnięciu go z opóznieniem wyskakuje komunikat o naprawieniu wifi
func _on_on_button_down():
	# Zmiana grafiki na komunikat
	if $CzyPolaczyc.visible == true:
		# Ustawianie długości opóznienia
		await get_tree().create_timer(1).timeout
		$CzyPolaczyc.visible = false
		$Panel.visible = true
	print("sabotage has been cancelled")
	#SabotageGlobal.wifi_on.emit()

