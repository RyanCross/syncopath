extends AudioStreamPlayer2D

@onready
var volume = self.volume_db

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_time_to_fade_track_audio(fadeTrackBufferMs : int):
	var trackFadeTween : Tween = self.create_tween();
	trackFadeTween.tween_property(self, "volume_db", 0.0, fadeTrackBufferMs / 1000)
	await trackFadeTween.finished
	self.stop()
	
func _on_restart():
	self.set_volume_db(volume)
	self.seek(0)
