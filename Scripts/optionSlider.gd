extends HSlider

var busIdx
var busVolume


# Called when the node enters the scene tree for the first time.
func _ready():
	busIdx = AudioServer.get_bus_index(get_meta("target_bus"))
	busVolume = AudioServer.get_bus_volume_db(busIdx)
	value = busVolume
