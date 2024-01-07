extends Node2D

## Zmienna odpowiadająca za ilość czasu między startem sabotażu a możliwością jego wyłączenia 
var countdown_seconds = 30
## Zmienna ustawiająca etykietę timera odpowiadającego za odliczanie czasu między startem sabotażu a możliwością jego wyłączenia
var timer_label : Label
## Zmienna inicjalizująca timer odpowiadający za odliczanie czasu między startem sabotażu a możliwością jego wyłączenia
var timer : Timer
## Zmienna odpowiadająca za domyślny stan timera (0 - odlicza, 1 - skończył odliczanie) odpowiadającego za odliczanie czasu między startem sabotażu a możliwością jego wyłączenia
var timer_default = 0


## Funkcja startująca wraz z uruchomieniem sceny - uruchamia najpierw timer, a po zmianie wartości zmiennej timer_default z 0 na 1 pozwala na naciśniecie buttona
func _ready():
	
	# Konfiguracja timera i miejsca jego wyswietlania
	timer_label = Label.new()
	timer_label.position = Vector2(420, 185);
	timer = Timer.new()
	timer.wait_time = 1
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))

	self.add_child(timer_label)
	self.add_child(timer)

	
	# Start sabotazu (a co za tym idzie uruchomienie timera) , wysłanie info w konsoli
	print("sabotage just started")
	self.show()
	timer.start()

## Obsługa timera odpowiadająca za ilość czasu między startem sabotażu a możliwością jego wyłączeni
func _on_timer_timeout():
	# odliczanie czasu na timerze
	countdown_seconds -= 1
	
	timer_label.text = "Połącznie można naprawić za: " + str(countdown_seconds) + " sekund"
	
	
	if countdown_seconds <= 0:
		timer_label.text = "Połącznie można naprawić"
		timer_label.position = Vector2(460, 185);
		timer_default = 1
		

## Obsługa przycisku settings który przełącza do sceny końcowej (mozliwe dopiero gdy upłynie ustawiony czas na timerze)
func _on_settings_button_down():
	
	if(timer_default == 1):
		get_tree().change_scene_to_file("res://scenes/sabotages/wifi-disconnecting/sabotage_off.tscn")
		timer_default == 0
	
		
