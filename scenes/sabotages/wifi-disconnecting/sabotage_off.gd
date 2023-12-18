extends Node2D


# zamykanie sabotazu 2/2
# ciąg dalszy sceny - sabotage_info.tscn
# syganł jest emitowany ale nie jest kluczowy dla aktualnego działania programu


func _on_on_button_down():
	print("wi-fi on")
	print("sabotage has been cancelled")
	SabotageGlobal.wifi_on.emit()

