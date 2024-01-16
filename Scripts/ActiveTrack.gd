extends AudioStreamPlayer2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_time_to_fade_track_audio(fadeTrackBufferMs : int):
	var trackFadeTween : Tween = self.create_tween();
	trackFadeTween.tween_property(self, "volume_db", 0.0, fadeTrackBufferMs / 1000)
	trackFadeTween.tween_callback(self.queue_free) # Replace with function body.
