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
	
func fadeInAndMakeVisible(nodeToTween: Node, fadeTime := .5):
	nodeToTween.set_visible(1)
	var tween: Tween = nodeToTween.create_tween()
	tween.tween_property(nodeToTween, "modulate", Color(1,1,1,1), fadeTime)

func _on_menu_game_over(finalScore, beatDistances):
	# set score
	finalScoreLabel.set_text("Final Score: " + String.num_int64(finalScore))
	
	fadeInAndMakeVisible(self)
	fadeInAndMakeVisible(verticalLine, 1)
	
	for i in beatDistances.size():
		var beatScoreSlider : HSlider = sliderToCopy.duplicate()
		beatScoreSlider.set_value(beatDistances[i])
		beatScoreSlider.set_visible(true)
		beatSlidersParent.add_child(beatScoreSlider)
	
	var pointValuesCopy = pointValues.duplicate()
	pointValuesCopy.set_visible(true)
	beatSlidersParent.add_child(pointValuesCopy)
