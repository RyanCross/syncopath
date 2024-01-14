extends Control

const VU_COUNT = 30
const FREQ_MAX = 11050.0
const MIN_DB = 60 #minimum decibel value

@onready var color_rect = $Background
var spectrum


# Called when the node enters the scene tree for the first time.
func _ready():
	spectrum = AudioServer.get_bus_effect_instance(0,0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
		var prez_hz = 0
		var data = []
		for i in range(1, VU_COUNT + 1):
			var hz = i * FREQ_MAX / VU_COUNT
			var f  = spectrum.get_magnitude_for_frequency_range(prez_hz, hz)
			var energy = clamp((MIN_DB + linear_to_db(f.length())) / MIN_DB, 0.0, 1.0)
			data.append(energy)
			prez_hz = hz
		color_rect.get_material().set_shader_parameter("freq_data", data)
		
