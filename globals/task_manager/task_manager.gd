extends Node

## Emitowane kiedy lista tasków podlega zmianie
signal tasks_change;

signal global_tasks_completed_amount_change();

## Task ID bieżącego zadania.
var current_task_id = null

## Minigry dostępne ma mapie.
var _minigames = {}

## Przechowuje zadania wszystkich graczy.
var _tasks = {}
## Przechowuje zadania bieżącego gracza.
var current_player_tasks = {}
#3 Ilość tasków w całej grze.
var global_tasks_amount : int
## Ilość już zrobionych tasków.
var global_tasks_completed_amount : int


## Przypisuje zadania graczom.
func assign_tasks(task_amount):
	if !multiplayer.is_server():
		return ERR_UNAUTHORIZED

	# Oczekuje jedną klatkę na wczytanie mapy._active
	await get_tree().process_frame

	_minigames = get_node("/root/Game/Maps/MainMap/Tasks").get_children()

	if multiplayer.is_server() and _tasks.is_empty():
		# Unikalny id dla każdego zadania.
		var id_counter = 0

		for i in GameManager.get_registered_players():
			if GameManager.get_registered_players()[i]["is_lecturer"]:
				continue
				
			var available_tasks = _minigames.duplicate(true)
			var tasks_dict = {}
			
			# Tworzy słownik task_amount ilości losowych zadań.
			for task_number in range(task_amount):
				var random_key = randi() % available_tasks.size()
				
				tasks_dict[id_counter] = available_tasks[random_key].get_path()
				available_tasks.remove_at(random_key)

				id_counter += 1

			_tasks[i] = tasks_dict
			_send_tasks.rpc_id(i, tasks_dict)
		
		set_global_tasks_amount.rpc(id_counter)


## Oznacza zadanie jako wykonane.
func mark_task_as_complete() -> void:
	# Usuwa zadanie z listy zadań bieżącego gracza.
	var player_id = multiplayer.get_unique_id()
	current_player_tasks[current_task_id].disable_task()
	current_player_tasks.erase(current_task_id)
	
	_send_task_completion.rpc_id(1, player_id, current_task_id)
	tasks_change.emit()
	current_task_id = null


@rpc("call_local", "reliable")
## Wysyła zadania do graczy.
func _send_tasks(tasks) -> void:
	await get_tree().process_frame
	for i in tasks:
		var task = get_node(tasks[i])
		task.enable_task(i)
		current_player_tasks[i] = task
		
	tasks_change.emit()


@rpc("authority", "reliable", "call_local")
func set_global_tasks_amount(amount: int) -> void:
	global_tasks_amount = amount


@rpc("any_peer", "reliable", "call_local")
## Wysyła infomację do serwera informujące o wykonaniu zadania.
func _send_task_completion(player_id: int, task_id: int):
	if !multiplayer.is_server():
		return ERR_UNAUTHORIZED

	# Usuwa zadanie z listy zadań na serwerze.
	_tasks[player_id].erase(task_id)

	# Usuwa gracza ze słownika zadań jeżeli wszystkie zadania są zrobione.
	if _tasks[player_id].is_empty():
		_tasks.erase(player_id)

	_update_global_completed_tasks_amount.rpc(_count_global_completed_tasks_amount())
	
	GameManager.check_winning_conditions()


func _count_global_completed_tasks_amount():
	if !multiplayer.is_server():
		return ERR_UNAUTHORIZED
	
	var amount = 0
	
	for i in _tasks:
		amount += _tasks[i].size()
	
	return global_tasks_amount - amount


@rpc('reliable', "authority", "call_local")
func _update_global_completed_tasks_amount(new_global_completed_tasks_amount) -> void:
	global_tasks_completed_amount = new_global_completed_tasks_amount
	global_tasks_completed_amount_change.emit()


## Usuwa wszystkie zadania przypisane do tego gracza na serwerowej liście zadań.
func remove_player_tasks(player_id: int):
	if !multiplayer.is_server():
		return ERR_UNAUTHORIZED

	_tasks.erase(player_id)
	_update_global_completed_tasks_amount.rpc(_count_global_completed_tasks_amount())	


## Resetuje zadania.
func reset():
	current_task_id = null
	_tasks.clear()
	current_player_tasks.clear()


# Zwraca słownik wszystkich niezakończonych zadań przepisanych do wszystkich graczę.
func get_tasks_server():
	return _tasks
