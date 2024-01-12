extends Control

func _on_sfx_slider_value_changed(value):
	if value <= -15:
		value = -72 # hitting exponential threshold, mute

	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), value)
	$oinker.play()


func _on_music_slider_value_changed(value):
	if value <= -15:
		value = -72 # hitting exponential threshold, mute
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value)
	

func _on_back_pressed():
	get_tree().change_scene_to_file($HBoxContainer/Back.get_meta("destination_scene"))
