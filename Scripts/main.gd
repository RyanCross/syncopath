extends Control

signal game_has_started
signal beat_tracking_has_started
signal game_over
signal game_ending

#region One Shot Signals
# configured as one shot by signal pane
signal time_to_fade_track_audio
signal display_intro_additional_prompt
#endregion 

#region Debug Variable Init
@onready var debugModeViewport = $DebugModeViewport
@onready var debugTimeTillTrackingStart := $DebugModeViewport/DebugContents/TimeInformation/TimeTillAudioFades
@onready var debugBeatsCaptured = $DebugModeViewport/DebugContents/PlayerBeatTracking/BeatsCaptured
@onready var debugMissedBeats = $DebugModeViewport/DebugContents/PlayerBeatTracking/MissedBeats
@onready var debugTimeSinceGameStart := $DebugModeViewport/DebugContents/TimeInformation/TimeSinceGameStarted
@onready var debugPlayerBeatTracking : VBoxContainer = $DebugModeViewport/DebugContents/PlayerBeatTracking
#endregion

@onready var title := $Title
@onready var inputToBeginPrompt_1 := $VBoxContainer/InputToBegin
@onready var tapAlongPrompt_2 := $VBoxContainer/TapAlong
@onready var keepTappingPrompt_3 := $VBoxContainer/KeepTapping
@onready var countdownPrompt_4 := $VBoxContainer/Countdown
@onready var trackPlayer = $ActiveTrack

@onready var gameStartVisiblePrompts = [
	title,
	inputToBeginPrompt_1,
]

@onready var gameStartHiddenPrompts = [
	tapAlongPrompt_2,
	keepTappingPrompt_3,
	countdownPrompt_4,
]

@onready var beatsPerMinute := 120 #TODO store each track in it's own audioplayer, store BPM as metadata on the track node
@onready var beatsPerSecond := beatsPerMinute / 60 
@onready var beatDurationMs : int = ceil(1000 / beatsPerSecond) # duration of a single beat
# the alotted time for instruction prompts and for player to get feel for the beat once they hit play
@onready var introDurationMs : int = 12000 
# the alotted time for beats to be tracked for a score, the "true" game duration
@onready var beatTrackingDurationMs : int = 10000 + beatWindowBufferMs
# a buffer in case player is early/late on first or last beat, respectively
@onready var beatWindowBufferMs : int = beatDurationMs # the window for beat input is before the next beat or after the previous
@onready var gameDurationMs = introDurationMs + beatTrackingDurationMs 
@onready var beatsToTrack = beatTrackingDurationMs / 1000 * beatsPerSecond

const MAX_BEAT_SCORE = 50
const MAX_TOTAL_SCORE = 1000

var timeElapsedBeforeGameStart
var timeSinceGameStartMs = 0;
var gameStarted := false
var beatTrackingStarted := false
var gameIsEnding := false
var gameOver := false

var perfectBeatTimings = Array()
var playerBeatTimings = Array()
var beatScores = Array()
var endingCountdownFadeInTime = .5
var beatDistances = Array()
var fadeTrackBufferMs = 3000

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
		
	var oldValue = distanceFromPerfect
	var oldMin = 0
	var oldMax = MAX_TOTAL_SCORE / beatsPerSecond
	var newMax = 50 # best score for individual beat
	var newMin = 0
	var oldRange = oldMax - 0
	var newRange = newMax - 0
	
	var score = newMax - round(((oldValue - oldMin) * newRange / oldRange) + newMin)
	return score

func generatePerfectBeatTimings(audioOutputDelayMs):
	for i in range(0,beatsToTrack):
		if i > 0:
			perfectBeatTimings.append(introDurationMs + (i * beatDurationMs) + audioOutputDelayMs)
		else:
			perfectBeatTimings.append(introDurationMs + audioOutputDelayMs) 
	
	print("perfect beats array size")
	print(perfectBeatTimings.size())
		

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("toggle_debug_mode"): # F2
		debugModeViewport.set_visible(!debugModeViewport.is_visible())
	if !gameOver:
		if Input.is_action_just_pressed("primary_action"):
			if gameStarted == false:
				emit_signal("game_has_started")
		if gameStarted:
			timeSinceGameStartMs = Time.get_ticks_msec() - timeElapsedBeforeGameStart
			debugTimeSinceGameStart.set_text("Game Time: " +  String.num(roundi(timeSinceGameStartMs)) + " | ")
			
			var timeTillGameOver = gameDurationMs - timeSinceGameStartMs
			# if game ending display 0, otherwise update countdown node that will be displayed at last 5 seconds
			var countdownLabel : Label = countdownPrompt_4.get_node("GameEndingCountdownLabel")

			if (timeTillGameOver > 0):
				var displayTime = timeTillGameOver
				# hidden until last 5 seconds of game
				countdownLabel.set_text(String.num(round(displayTime / 1000)))
			else:
				countdownLabel.set_text("0")
		if timeSinceGameStartMs >= introDurationMs / 2:
			emit_signal("display_intro_additional_prompt")
		if !beatTrackingStarted:
			if(introDurationMs - fadeTrackBufferMs - timeSinceGameStartMs <= 0):
					emit_signal("time_to_fade_track_audio", fadeTrackBufferMs)

			if (introDurationMs - timeSinceGameStartMs >= 0):
				debugTimeTillTrackingStart.set_text("Time till tracking start: " + String.num(introDurationMs - timeSinceGameStartMs))
			else: 
				debugTimeTillTrackingStart.set_text("Tracking Started")
				emit_signal("beat_tracking_has_started")
					
		if timeSinceGameStartMs >= introDurationMs - round(beatWindowBufferMs / 3): #subtract a fraction of beat buffer length in case player inputs early
			# pad missed beats
			if (playerBeatTimings.size() < beatsToTrack):
				if timeSinceGameStartMs >= perfectBeatTimings[playerBeatTimings.size()] + beatDurationMs:
					# player has missed a beat, pad the array so subsequent beats are still compared in the proper order
					debug_capture_beat_info(String.num(perfectBeatTimings[playerBeatTimings.size()] + beatDurationMs))
					playerBeatTimings.append(perfectBeatTimings[playerBeatTimings.size()] + beatDurationMs)
	
			if Input.is_action_just_pressed("primary_action"):
				if playerBeatTimings.size() < beatsToTrack: 
					var captureTimeMs : String = String.num(timeSinceGameStartMs, 5)
					debug_capture_beat_info(captureTimeMs)
					playerBeatTimings.append(int(captureTimeMs))			
		# at last five(ish) seconds of game, emit a warning
		if !gameIsEnding && timeSinceGameStartMs >= gameDurationMs - 5000 - endingCountdownFadeInTime - beatWindowBufferMs:
			emit_signal("game_ending")
			
		if timeSinceGameStartMs > gameDurationMs:
			var finalScore = calculateFinalScore()
			emit_signal("game_over", finalScore, beatDistances)

func restart_game():
	# reset all game state variables
	gameStarted = false
	beatTrackingStarted = false
	gameIsEnding = false
	gameOver = false
	timeSinceGameStartMs = 0
	perfectBeatTimings.clear()
	playerBeatTimings.clear()
	beatScores.clear()
	beatDistances.clear()
	# reset the track player
	trackPlayer.stop()
	trackPlayer.seek(0)

	# restart all prompts to their default state
	for prompt in gameStartVisiblePrompts:
		prompt.set_visible(true)
		for child in prompt.get_children():
			if child is Control:
				child.modulate_opacity = 1.0
	for prompt in gameStartHiddenPrompts:
		prompt.set_visible(false)
		for child in prompt.get_children():
			if child is Control:
				child.modulate_opacity = 0.0
	# reset the scoreboard
	$ScorePanel.reset_scoreboard()
	
	return
		
func _on_game_has_started():
	print("Game Start")
	TweenUtils.fadeOutAndHide(inputToBeginPrompt_1) 
	TweenUtils.fadeOutAndHide(title)	
	$CassetteHum.stop()
	$CassettePlay.play()
	await $CassettePlay.finished
	await get_tree().create_timer(1).timeout
	
	timeElapsedBeforeGameStart = Time.get_ticks_msec()
	gameStarted = true
	
	var audioOutputDelayMs = ceil(( AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency() ) * 1000)
	trackPlayer.play()
	generatePerfectBeatTimings(audioOutputDelayMs)
	# timers are for juice, creatings small delays in visual/audio changes
	await get_tree().create_timer(.5).timeout
	await get_tree().create_timer(2).timeout
	TweenUtils.fadeInAndMakeVisible(tapAlongPrompt_2)

	
func _on_beat_tracking_has_started(): 
	TweenUtils.fadeOutAndHide(keepTappingPrompt_3)
	beatTrackingStarted = true
	
func _on_game_over(_finalScore, _beatDistances):	
	TweenUtils.fadeOutAndHide(countdownPrompt_4, .5)
	gameOver = true;

func _on_game_ending():
	TweenUtils.fadeInAndMakeVisible(countdownPrompt_4, endingCountdownFadeInTime)
	gameIsEnding = true;

func debug_capture_beat_info(captureTimeMs : String):
	var beatCaptureInfo: Label = Label.new()
	var beatNumber : String =  String.num(playerBeatTimings.size() + 1) 
	debugBeatsCaptured.set_text("Beats Captured: ")
	beatCaptureInfo.set_text(beatNumber + " | " + captureTimeMs + " ms | " + "Perfect: " + String.num(perfectBeatTimings[playerBeatTimings.size()]))
	debugPlayerBeatTracking.add_child(beatCaptureInfo)
	
func _on_display_intro_additional_prompt():
	TweenUtils.fadeOutAndHide(tapAlongPrompt_2)
	await get_tree().create_timer(1).timeout
	TweenUtils.fadeInAndMakeVisible(keepTappingPrompt_3)
