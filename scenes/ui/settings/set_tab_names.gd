extends TabContainer

func _ready():
	# setting tab names
	set_tab_title(0,"Dźwięk i grafika")
	set_tab_title(1,"Sterowanie")
	set_tab_title(2,"Domyślne")

func _on_hidden():
	# setting first tab to default
	current_tab = 0