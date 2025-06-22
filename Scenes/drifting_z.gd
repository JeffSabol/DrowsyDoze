extends Node2D

var drifting_z_scene = preload("res://DrowsyDoze/Scenes/DriftingZ.tscn")

func drift_and_fade():
	call_deferred("_do_drift_and_fade")  # Waits one frame so position is valid

func _do_drift_and_fade():
	# Start small
	scale = Vector2(0.5, 0.5)

	var tween := create_tween()
	var duration = randf_range(2.5, 3.5)

	# Random diagonal drift
	var direction = Vector2(
		randf_range(-40.0, 40.0),
		randf_range(-60.0, -40.0)
	)
	var end_pos = position + direction

	# Tween position drift up and right
	tween.tween_property(self, "position", end_pos, duration)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	# Tween scale at the same time as drift
	tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), randf_range(1, 5))
	tween.parallel().set_trans(Tween.TRANS_BACK)
	tween.parallel().set_ease(Tween.EASE_OUT)

	# Tween fade out
	tween.tween_property($Z, "modulate:a", 0.0, duration)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN)
	
	tween.tween_callback(Callable(self, "queue_free"))

func _on_z_timer_timeout():
	var z = drifting_z_scene.instantiate()
	z.position = Vector2(518.0, 308.0)
	get_tree().current_scene.add_child(z)
	z.drift_and_fade()
