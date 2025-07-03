extends TextureRect

@onready var finalScoreLabel : Label = $VBoxContainer/FinalScoreLabel
@onready var beatSlidersParent : VBoxContainer = $VBoxContainer/MarginContainer2/BeatSlidersVbox
@onready var sliderToCopy : HSlider = $VBoxContainer/MarginContainer2/BeatSlidersVbox/SliderToCopy
@onready var pointValues : HBoxContainer = $VBoxContainer/MarginContainer2/BeatSlidersVbox/PointValuesToCopy
@onready var verticalLine : VSeparator = $VBoxContainer/CanvasLayer/VSeparator
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_menu_game_over(finalScore, beatDistances):
	# set score
	finalScoreLabel.set_text("Final Score: " + String.num_int64(finalScore))
	
	TweenUtils.fadeInAndMakeVisible(self)
	TweenUtils.fadeInAndMakeVisible(verticalLine, 1)
	
	for i in beatDistances.size():
		var beatScoreSlider : HSlider = sliderToCopy.duplicate()
		beatScoreSlider.set_value(beatDistances[i])
		beatScoreSlider.set_visible(true)
		beatSlidersParent.add_child(beatScoreSlider)
	
	var pointValuesCopy = pointValues.duplicate()
	pointValuesCopy.set_visible(true)
	beatSlidersParent.add_child(pointValuesCopy)

func reset_scoreboard():
	finalScoreLabel.set_text("Final Score: 0")
	self.set_visible(false)
	for child in beatSlidersParent.get_children():
		if child is HSlider:
			child.set_visible(false)
			child.queue_free()
		elif child.name == "PointValuesToCopy":
			child.set_visible(false)
