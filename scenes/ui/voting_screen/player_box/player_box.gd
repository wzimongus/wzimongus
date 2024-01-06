extends Control

## Okienko z informacjami o graczu, ktory jest na liscie glosowania
##
## Interfejs użytownika, który wyświetla informacje o graczu, który jest na liście głosowania.
## Pozwala na zagłosowanie na danego gracza.
## Wyświetla listę graczy, którzy zagłosowali na danego gracza.


## Referencja do etykiety z nazwa gracza
@onready var username = get_node("%Username")
## Referencja do przycisku z decyzja
@onready var decision = get_node("%Decision")
## Referencja do kontenera z graczami, ktorzy glosowali na danego gracza
@onready var voted_by_container = get_node("%VotedBy")

## Sygnal emitowany, gdy gracz zaglosowal na danego gracza
signal player_voted
## Sygnal emitowany, gdy gracz zostal wybrany do glosowania
signal player_selected

## Klucz gracza
var player_key
## Tween do animacji
var display_tween

## Scena z graczem, ktory zaglosowal na danego gracza
var voted_by_scene = preload("res://scenes/ui/voting_screen/voted_by/voted_by.tscn")

## Funkcja inicjalizujaca okienko z informacjami o graczu
func init(username: String, player_key: int, voted_by):
	self.username.text = username
	self.player_key = player_key

	# Renderowanie graczy, ktorzy zaglosowali na danego gracza
	for vote in voted_by:
		var voted_by_instance = voted_by_scene.instantiate()
		voted_by_instance.modulate.a = 0;
		display_tween = get_tree().create_tween()
		display_tween.tween_property(voted_by_instance, "modulate:a", 1, 0.25)
		
		voted_by_container.add_child(voted_by_instance)
	
	# Jeżeli gracz jest martwy, to nie można na niego głosować
	if GameManager.get_current_player_key("died"):
		self.disconnect("player_voted", _on_button_pressed)

## Funkcja wywolywana, gdy gracz odddał głos na danego gracza
func _on_button_pressed():
	# Jeżeli gracz już zagłosował, to nie może głosować ponownie
	if GameManager.get_current_game_key("is_voted") || GameManager.get_current_game_key("is_vote_preselected"):
		return
	
	if decision.visible:
		decision.visible = false
		GameManager.set_current_game_key("is_vote_preselected", false)
		return
	
	decision.visible = true
	GameManager.set_current_game_key("is_vote_preselected", true)

## Funkcja wywolywana, gdy gracz cofnął głos na danego gracza
func _on_decision_no_pressed():
	decision.visible = false
	GameManager.set_current_game_key("is_vote_preselected", false)

## Funkcja wywolywana, gdy gracz potwierdził głos na danego gracza
func _on_decision_yes_pressed():
	decision.visible = false
	emit_signal("player_voted", player_key)
