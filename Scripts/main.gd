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
@onready var trackFadeTimerLabel := $VBoxContainer/TrackFadeTimerLabel

@onready var audioPlayer = $AudioStreamPlayer2D

@onready var gameTimerDebug := $VBoxContainer/GameTimerDebug

@onready var beatsPerMinute := 120
@onready var timeTillBeatTrackingStart := 10
@onready var beatTrackingDuration := 10
@onready var beatsPerSecond := beatsPerMinute / 60 

@onready var timeToStopTracking = timeTillBeatTrackingStart + beatTrackingDuration
@onready var beatDurationMs = 1000 / beatsPerSecond
@onready var beatsToTrack = beatTrackingDuration * beatsPerSecond

var gameStarted := false
var gameIsEnding := false
var gameOver := false
var beatTrackingStarted := false
var timeSinceGameStart = 0;
var perfectBeatTimings = Array()
var playerBeatTimings = Array()
var beatScores = Array()

func calculateFinalScore():
	var finalScore := 0;  
	for i in playerBeatTimings.size():
		var offBeatDistanceMs = abs(playerBeatTimings[i] - perfectBeatTimings[i])
		
		var maxDistance = 1000 / beatsPerSecond
		if (offBeatDistanceMs > maxDistance):
			offBeatDistanceMs = maxDistance # will convert to worst score
		# calculate score
		var beatScore : int = calculateBeatScore(offBeatDistanceMs)
		beatScores.append(beatScore) # TODO sideEffect, should probs encapsulate final score and beat scores in same data struct
		finalScore += beatScore
		
	return finalScore
			
func calculateBeatScore(distanceFromPerfect):
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

func fadeInAndMakeVisible(nodeToTween: Node):
	nodeToTween.set_visible(1)
	var tween: Tween = nodeToTween.create_tween()
	tween.tween_property(nodeToTween, "modulate", Color(1,1,1,1), .5)

func fadeOutAndDestroy(nodeToTween: Node):
	var tween: Tween = nodeToTween.create_tween()
	tween.tween_property(nodeToTween, "modulate", Color(1,1,1,0), .5)
	tween.tween_callback(nodeToTween.queue_free)

func generatePerfectBeatTimings():
	for i in range(0,beatsToTrack):
		if i > 0:
			perfectBeatTimings.append(timeTillBeatTrackingStart * 1000 + (i * beatDurationMs))
		else:
			perfectBeatTimings.append(timeTillBeatTrackingStart * 1000) 
	
	print("perfect beats array size")
	print(perfectBeatTimings.size())
		
	
func resetGame():
	pass
	
# Called when the node enters the scene tree for the first time.
func _ready():
	generatePerfectBeatTimings()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !gameOver:
		if gameStarted == false && Input.is_action_just_pressed("ui_accept"):
			emit_signal("game_has_started")
		if gameStarted:
			timeSinceGameStart += delta
			gameTimerDebug.set_text(String.num(round(timeSinceGameStart)))
			
			var gameEndingCountdown = timeToStopTracking - round(timeSinceGameStart)
			if (gameEndingCountdown > 0):
				# hidden until last 5 seconds of game
				$VBoxContainer/Prompt4/GameEndingCountdownLabel.set_text(String.num(gameEndingCountdown))
			else:
				$VBoxContainer/Prompt4/GameEndingCountdownLabel.set_text("0")
		if !beatTrackingStarted:
			if (timeTillBeatTrackingStart - round(timeSinceGameStart) >= 0):
				trackFadeTimerLabel.set_text(String.num(timeTillBeatTrackingStart - round(timeSinceGameStart)))
			else: 
				trackFadeTimerLabel.set_text("0")
				emit_signal("beat_tracking_has_started")
					
		if timeSinceGameStart > timeTillBeatTrackingStart:
			if Input.is_action_just_pressed("ui_accept"):
				if playerBeatTimings.size() < beatsToTrack: 
					print("Time of Beat: ", playerBeatTimings.size(), "is ", timeSinceGameStart)
					print("float time of beat * 1000: ", timeSinceGameStart * 1000 )
					print("Time of beat in MS: ", String.num(timeSinceGameStart * 1000, 5))
					var beatTiming : float = timeSinceGameStart * 1000
					playerBeatTimings.append(int(beatTiming))
					
		if !gameIsEnding && round(timeSinceGameStart) >= timeToStopTracking - 5:
			emit_signal("game_ending")
			
		if timeSinceGameStart > timeToStopTracking:
			# todo, could add a buffer so that user doesn't have to be frame perfect on last beat... which probably a good idea
			emit_signal("game_over")
		
func _on_game_has_started():
	print("Game Start")
	fadeOutAndDestroy(prompt) 
	fadeOutAndDestroy(title)
	gameStarted = true
	
	# timers are for juice, creatings small delays in visual/audio changes
	await get_tree().create_timer(.5).timeout
	audioPlayer.play() # Play the track
	await get_tree().create_timer(2).timeout
	fadeInAndMakeVisible(prompt2)
	await get_tree().create_timer(2).timeout
	fadeInAndMakeVisible(prompt3)
	fadeInAndMakeVisible(trackFadeTimerLabel)
	
func _on_game_over():
	calculateFinalScore()
	gameOver = true;


func _on_beat_tracking_has_started(): 
	audioPlayer.stop();
	fadeOutAndDestroy(prompt2)
	fadeOutAndDestroy(prompt3)
	fadeOutAndDestroy(trackFadeTimerLabel)
	beatTrackingStarted = true


func _on_game_ending():
	fadeInAndMakeVisible(prompt4)
	gameIsEnding = true;
	
	
	pass # Replace with function body.
