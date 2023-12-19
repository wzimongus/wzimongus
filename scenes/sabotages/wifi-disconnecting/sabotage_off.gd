extends Node2D

signal sabo_on
# zamykanie sabotazu 2/2
# ciąg dalszy sceny - sabotage_info.tscn
func _ready():
	$Panel.visible = false

func _on_on_button_down():
	print("wi-fi on")
	if $CzyPolaczyc.visible == true:
		await get_tree().create_timer(1).timeout
		$CzyPolaczyc.visible = false
		$Panel.visible = true
	print("sabotage has been cancelled")
	#SabotageGlobal.wifi_on.emit()

