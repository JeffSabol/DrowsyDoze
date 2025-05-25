extends Node2D

@onready var light = $'.'
var tween : Tween

func _ready():
	tween = create_tween()
	flicker_loop()

func flicker_loop():
	# Pick a random target energy
	var new_energy = randf_range(0.5, 1.0)
	var duration = randf_range(0.1, 0.25)

	# Smoothly interpolate energy
	tween = create_tween()
	tween.tween_property(light, "energy", new_energy, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(flicker_loop)
