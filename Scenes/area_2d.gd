extends Area2D

@onready var player = $"../LanternSound"
var lantern_sounds: Array[AudioStream] = []

func _ready():
	for i in range(1, 11):
		lantern_sounds.append(load("res://Lantern%d.wav" % i))

func _input_event(viewport, event, shape_idx):
	print("here1")
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("hey")
		play_random_lantern_sound()

func play_random_lantern_sound():
	var index = randi() % lantern_sounds.size()
	player.stream = lantern_sounds[index]
	player.play()
