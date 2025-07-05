extends TextureButton

func _on_menu_game_over(_finalScore, _beatDistances) -> void:
	TweenUtils.fadeInAndMakeVisible(self)

func _on_pressed() -> void: 
	TweenUtils.fadeOutAndHide(self)
