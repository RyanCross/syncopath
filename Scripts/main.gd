extends Control

signal game_has_started
signal beat_tracking_has_started
signal game_over
signal game_ending

const MAX_BEAT_SCORE = 50
const MAX_TOTAL_SCORE = 1000

@onready var title := $Title
@onready var prompt := $VBoxContainer/Prompt
@onready var prompt2 := $VBoxContainer/Prompt2
@onready var prompt3 := $VBoxContainer/Prompt3
@onready var prompt4 := $VBoxContainer/Prompt4

@onready var audioPlayer = $AudioStreamPlayer2D
@onready var clapFx = $Clap

### DebuggerInformation
@onready var debugModeViewport = $DebugModeViewport
@onready var debugTimeTillTrackingStart := $DebugModeViewport/DebugContents/TimeInformation/TimeTillAudioFades
@onready var debugBeatsCaptured = $DebugModeViewport/DebugContents/PlayerBeatTracking/BeatsCaptured
@onready var debugMissedBeats = $DebugModeViewport/DebugContents/PlayerBeatTracking/MissedBeats
@onready var debugTimeSinceGameStart := $DebugModeViewport/DebugContents/TimeInformation/TimeSinceGameStarted
@onready var debugPlayerBeatTracking : VBoxContainer = $DebugModeViewport/DebugContents/PlayerBeatTracking

@onready var beatsPerMinute := 120
@onready var beatsPerSecond := beatsPerMinute / 60 
@onready var beatDurationMs : int = ceil(1000 / beatsPerSecond)
@onready var introDurationMs : int = 10000 
@onready var beatTrackingDurationMs : int = 10000 + beatWindowBufferMs
# a buffer in case player is early/late on first or last beat, respectively
@onready var beatWindowBufferMs : int = beatDurationMs # the window for beat input is before the next beat or after the previous
@onready var gameDurationMs = introDurationMs + beatTrackingDurationMs 
@onready var beatsToTrack = beatTrackingDurationMs / 1000 * beatsPerSecond
@onready var timeSinceGameStartMs = 0;

var gameStarted := false
var gameIsEnding := false
var gameOver := false
var beatTrackingStarted := false
var perfectBeatTimings = Array()
var playerBeatTimings = Array()
var beatScores = Array()
var endingCountdownFadeInTime = .5
var beatDistances = Array()

func calculateFinalScore():
	var finalScore := 0;  
	for i in playerBeatTimings.size():
		var offBeatDistanceMs = abs(playerBeatTimings[i] - perfectBeatTimings[i])
		beatDistances.append(playerBeatTimings[i] - perfectBeatTimings[i]) # TODO sideEffect
		
		var maxDistance = 1000 / beatsPerSecond
		if (offBeatDistanceMs > maxDistance):
			offBeatDistanceMs = maxDistance # will convert to worst score
		# calculate score
		var beatScore : int = calculateBeatScore(offBeatDistanceMs)
		beatScores.append(beatScore) # TODO sideEffect, should probs encapsulate final score and beat scores in same data struct
		finalScore += beatScore
		
	return finalScore
			
func calculateBeatScore(distanceFromPerfect : int):
	# https://stackoverflow.com/questions/929103/convert-a-number-range-to-another-range-maintaining-ratio
	# a little confusing here, as this is a bit of a bastardization of the top answer above
	# technically our MAX (best) distance is 0, our min is 1s / beatsPerSecond ( a new beat has already occured), but we can't divide by zero in the linear conversion formula which will be the case if newMin is also 0, which it is, so we must swap our oldMin and max to get the inverse value. 
	# eg if our score should be 26, the formula will give us 24, if newMAx is 50 then 50-24 = 26. So our formula is
	# newMax - newScore = score, i'm not sure what the math reason for this is.\
	
	
	# TODO realizing a bug with filling playerBeatTimings, we may need to fill missed beats, past a certain threshold of time
	
	var oldValue = distanceFromPerfect
	var oldMin = 0
	var oldMax = MAX_TOTAL_SCORE / beatsPerSecond
	var newMax = 50 # best score for individual beat
	var newMin = 0
	var oldRange = oldMax - 0
	var newRange = newMax - 0
	
	var score = newMax - round(((oldValue - oldMin) * newRange / oldRange) + newMin)
	return score

func fadeInAndMakeVisible(nodeToTween: Node, fadeTime := .5):
	nodeToTween.set_visible(1)
	var tween: Tween = nodeToTween.create_tween()
	tween.tween_property(nodeToTween, "modulate", Color(1,1,1,1), fadeTime)

func fadeOutAndDestroy(nodeToTween: Node, fadeTime := .5):
	var tween: Tween = nodeToTween.create_tween()
	tween.tween_property(nodeToTween, "modulate", Color(1,1,1,0), fadeTime)
	tween.tween_callback(nodeToTween.queue_free)
	
func fadeOut(nodeToTween: Node, fadeTime := .5):
	var tween: Tween = nodeToTween.create_tween()
	tween.tween_property(nodeToTween, "modulate", Color(1,1,1,0), fadeTime)
	tween.tween_callback(func(): nodeToTween.set_visible(false))
	return tween

func generatePerfectBeatTimings():
	for i in range(0,beatsToTrack):
		if i > 0:
			perfectBeatTimings.append(introDurationMs + (i * beatDurationMs))
		else:
			perfectBeatTimings.append(introDurationMs) 
	
	print("perfect beats array size")
	print(perfectBeatTimings.size())
		
func secondsToMs(timeInSeconds : int):
	return timeInSeconds * 1000

func msToSeconds(timeInMs : int):
	return timeInMs / 1000

func resetGame():
	pass
	
# Called when the node enters the scene tree for the first time.
func _ready():
	generatePerfectBeatTimings()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("toggle_debug_mode"): # F2
		debugModeViewport.set_visible(!debugModeViewport.is_visible())
	if !gameOver:
		if Input.is_action_just_pressed("ui_accept"):
			clapFx.play()
			
			if gameStarted == false:
				emit_signal("game_has_started")
		if gameStarted:
			timeSinceGameStartMs += roundi(delta * 1000)
			debugTimeSinceGameStart.set_text("Game Time: " +  String.num(roundi(timeSinceGameStartMs)) + " | ")
			
			var timeTillGameOver = gameDurationMs - timeSinceGameStartMs
			# if game ending display 0, otherwise update countdown node that will be displayed at last 5 seconds
			if (timeTillGameOver > 0):
				var displayTime = timeTillGameOver
				# hidden until last 5 seconds of game
				$VBoxContainer/Prompt4/GameEndingCountdownLabel.set_text(String.num(round(displayTime / 1000)))
			else:
				$VBoxContainer/Prompt4/GameEndingCountdownLabel.set_text("0")
		if !beatTrackingStarted:
			if (introDurationMs - timeSinceGameStartMs >= 0):
				debugTimeTillTrackingStart.set_text("Time till tracking start: " + String.num(introDurationMs - timeSinceGameStartMs))
			else: 
				debugTimeTillTrackingStart.set_text("Tracking Started")
				emit_signal("beat_tracking_has_started")
					
		if timeSinceGameStartMs >= introDurationMs - round(beatWindowBufferMs / 4): #subtract beat buffer length here in case player inputs early
			# pad missed beats
			# if worst score already made, then 
			if (playerBeatTimings.size() < beatsToTrack):
				if timeSinceGameStartMs >= perfectBeatTimings[playerBeatTimings.size()] + beatDurationMs:
					#player has missed a beat, pad the array so they can still recover 
					debug_capture_beat_info(String.num(perfectBeatTimings[playerBeatTimings.size()] + beatDurationMs))
					playerBeatTimings.append(perfectBeatTimings[playerBeatTimings.size()] + beatDurationMs)
	
			if Input.is_action_just_pressed("ui_accept"):
				if playerBeatTimings.size() < beatsToTrack: 
					var captureTimeMs : String = String.num(timeSinceGameStartMs, 5)
					debug_capture_beat_info(captureTimeMs)
					playerBeatTimings.append(int(captureTimeMs))			
		# at last five(ish) seconds of game, emit a warning
		if !gameIsEnding && timeSinceGameStartMs >= gameDurationMs - 5000 - endingCountdownFadeInTime - beatWindowBufferMs:
			emit_signal("game_ending")
			
		if timeSinceGameStartMs > gameDurationMs:
			# todo, could add a buffer so that user doesn't have to be frame perfect on last beat... which probably a good idea
			var finalScore = calculateFinalScore()
			emit_signal("game_over", finalScore, beatDistances)
		
func _on_game_has_started():
	print("Game Start")
	fadeOutAndDestroy(prompt) 
	fadeOut(title)
	gameStarted = true
	
	# timers are for juice, creatings small delays in visual/audio changes
	await get_tree().create_timer(.5).timeout
	audioPlayer.play() # Play the track 
	await get_tree().create_timer(2).timeout
	fadeInAndMakeVisible(prompt2)
	await get_tree().create_timer(2).timeout
	fadeInAndMakeVisible(prompt3)
	
func _on_game_over(_finalScore, _beatDistances):	
	fadeOutAndDestroy(prompt4, .5)
	gameOver = true;


func _on_beat_tracking_has_started(): 
	audioPlayer.stop();
	fadeOutAndDestroy(prompt2)
	fadeOutAndDestroy(prompt3)
	beatTrackingStarted = true


func _on_game_ending():
	fadeInAndMakeVisible(prompt4, endingCountdownFadeInTime)
	gameIsEnding = true;
	
	
	pass # Replace with function body.

func debug_capture_beat_info(captureTimeMs : String):
	var beatCaptureInfo: Label = Label.new()
	var beatNumber : String =  String.num(playerBeatTimings.size() + 1) 
	debugBeatsCaptured.set_text("Beats Captured: ")
	beatCaptureInfo.set_text(beatNumber + " | " + captureTimeMs + " ms | " + "Perfect: " + String.num(perfectBeatTimings[playerBeatTimings.size()]))
	debugPlayerBeatTracking.add_child(beatCaptureInfo)
	
