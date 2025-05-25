extends ColorRect

@onready var lantern_player: AudioStreamPlayer2D = $"../../LanternSound"

func _ready():
	# Make sure this ColorRect can receive mouse input
	mouse_filter = Control.MOUSE_FILTER_STOP
	randomize()

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Lantern clicked!")
		play_random_lantern_sound()

func play_random_lantern_sound():
	var index = randi_range(1, 10)
	var path = "res://Assets/SFX/Lantern%d.wav" % index
	var stream = load(path)
	if stream:
		lantern_player.stream = stream
		lantern_player.play()
