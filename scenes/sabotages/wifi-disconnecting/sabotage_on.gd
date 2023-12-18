extends Node2D

# uruchamianie sabotazu
# w zamysle ta scena powinna zostac zastapiona przez interaction point z paska impostora

signal wifi_off

func _on_off_button_down():
	print("wi-fi off")
	#SabotageGlobal.wifi_off.emit()
	get_tree().change_scene_to_file("res://scenes/sabotages/wifi-disconnecting/sabotage_info.tscn")


