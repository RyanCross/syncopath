extends TextureButton

@export var text: String = "Text"
@export var PRESS_OFFSET := Vector2(0.0, 20.0)
@onready var audio_stream_player := $AudioStreamPlayer
@onready var label := $Label

func move_button(label: Label, pressed:bool) -> void:
	label.position = label.position + PRESS_OFFSET if pressed else label.position - PRESS_OFFSET

func _ready():
	label.text = text

func _on_button_down():
	move_button(label, true)


func _on_button_up():
	move_button(label, false)


func _on_mouse_entered():
	audio_stream_player.play()
