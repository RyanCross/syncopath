extends Control

const VU_COUNT = 30
const FREQ_MAX = 11050.0
const MIN_DB = 60 #minimum decibel value

##### for animating lights smoother, not necessary for basic input sending, might need to remove this for grayscale texture creation
const ANIMATION_SPEED = 0.1
const HEIGHT_SCALE = 8.0


@onready var color_rect = $Background
var spectrum
var min_values = []
var max_values = []

# Called when the node enters the scene tree for the first time.
func _ready():
	spectrum = AudioServer.get_bus_effect_instance(0,0)
	min_values.resize(VU_COUNT)
	min_values.fill(0.0)
	max_values.resize(VU_COUNT)
	max_values.fill(0.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
		var prez_hz = 0
		var data = []
		for i in range(1, VU_COUNT + 1):
			var hz = i * FREQ_MAX / VU_COUNT
			var f  = spectrum.get_magnitude_for_frequency_range(prez_hz, hz)
			var energy = clamp((MIN_DB + linear_to_db(f.length())) / MIN_DB, 0.0, 1.0)
			data.append(energy * HEIGHT_SCALE)
			prez_hz = hz
		for i in range(VU_COUNT):
			if data[i] > max_values[i]:
				max_values[i] = data[i]
			else:
				max_values[i] = lerp(max_values[i], data[i], ANIMATION_SPEED)
			if data[i] <= 0.0:
				min_values[i] = lerp(min_values[i], 0.0, ANIMATION_SPEED)
		var fft = []
		for i in range(VU_COUNT):
			fft.append(lerp(min_values[i], max_values[i], ANIMATION_SPEED))	
		color_rect.get_material().set_shader_parameter("freq_data", fft)
		
