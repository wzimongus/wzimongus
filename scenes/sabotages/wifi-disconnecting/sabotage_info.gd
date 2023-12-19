extends Node2D

# zamykanie sabotazu 1/2
# scena powinna być tylko widoczna dla zwykłych graczy w momencie jak impostor włacza sabotaz
# na chwile obecną działanie sabotażu to jest jakby dodatkowy task do zrobienia dla gracza 
# w momencie odpalenia się scena puszcza timer na ustalony czas, po którym dopiero jest mozliwosc przejscia dlaej

# jak tylko rozgryze jak poprawnie połączyć tą scene z sygnałem emitowanym na scenie impostora (sabotage_on.tscn) to zamienie żeby ta scena była wywoływana przez ten sygnał a nie było przejście ze sceny do sceny
# ale na chwile obecną jestem po 20 poradnikach na yt i przekopaniu połowy internetu i nie wiem dalej jak to zrobic poprawnie żeby działało i odbierało ten sygnał

var countdown_seconds = 5
var timer_label : Label
var timer : Timer
var timer_default = 0



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

# Wyswietlanie timera
func _on_timer_timeout():
	countdown_seconds -= 1
	
	timer_label.text = "Połącznie można naprawić za: " + str(countdown_seconds) + " sekund"
	

	if countdown_seconds <= 0:
		timer_label.text = "Połącznie można naprawić"
		timer_label.position = Vector2(460, 185);
		timer_default = 1
		

# Przejscie do kolejnego etapu wyłączania sabotazu, mozliwe dopiero gdy upłynie ustawiony czas od włączenie sabotazu
func _on_settings_button_down():
	
	if(timer_default == 1):
		get_tree().change_scene_to_file("res://scenes/sabotages/wifi-disconnecting/sabotage_off.tscn")
		timer_default == 0
	
		
