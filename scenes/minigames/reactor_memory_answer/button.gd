extends TextureButton


func _on_Button_pressed():
	get_parent().get_parent().player_pressed(self.name)
