# Jeff Sabol
extends Node2D

@onready var scoreboard = $Sprite2/Sign
@onready var hover_zone = $Sprite2/HoverZone
@onready var upgrade_button = $UpgradeButton
@onready var z_timer = $ZTimer
var loading_bar_frames: Array[Texture2D] = []
var scoreboard_height: float = 0.0
var tween: Tween
var is_hovering = false
var is_showing_due_to_milestone = false
var scoreboard_unlocked := false

var total_clicks: int = 0
var save_file_path := "user://save_data.json"
var unlock_thresholds := [
	10, 25, 100, 200, 250, 500, 1000, 1150, 2000, 3000,	4000, 5000, 7500, 10000,
	 20000, 30000, 40000, 50000, 75000, 100000, 125000, 150000, 175000, 200000,
	 250000, 300000
]
var unlocked_milestones: Array = []
var click_value := 1

# Define custom milestone behavior
var milestones := {
	10: { "name": "Scoreboard", "action": func(): show_scoreboard_temporarily() },
	25: { "name": "Bubbles", "action": func(): bubble_handling() },
	100: { "name": "Click Power I", "action": func():  click_value = 2 },
	200: { "name": "Lantern", "action": func(): fade_in_sprite("Sprite1")},
	250: { "name": "Glowing stars fill cave background", "action": func(): fade_in_sprite("StarsGroup") },
	500: { "name": "Drifting Zs", "action": func(): start_drifting_zs() },
	1000: { "name": "Click Power II", "action": func(): click_value = 3 },
	2000: { "name": "Sleeping cap", "action": func(): fade_in_sprite("SleepingCap") },
	#3000: { "name": "Nose wiggle", "action": func(): a_func() },
	#3000: { "name": "Dreaming", "action": func():  print("TODO dreaming of various sprites") },
	#1100: { "name": "Nose wiggle", "action": func(): a_func() },
	#2700: { "name": "Sigh puff", "action": func(): a_func() },
	4000: { "name": "???", "action": func(): print("TODO") },
	5000: { "name": "Click Power III", "action": func(): click_value = 4 },
	7500: { "name": "???", "action": func(): print("TODO") },
	10000: { "name": "???", "action": func(): print("TODO") },
	20000: { "name": "???", "action": func(): print("TODO") },
	30000: { "name": "Click Power IV", "action": func(): click_value = 5 },
	40000: { "name": "???", "action": func(): print("TODO") },
	50000: { "name": "???", "action": func(): print("TODO") },
	75000: { "name": "???", "action": func(): print("TODO") },
	100000: { "name": "Click Power V", "action": func(): click_value = 6 },
	125000: { "name": "???", "action": func(): print("TODO") },
	150000: { "name": "???", "action": func(): print("TODO") },
	175000: { "name": "???", "action": func(): print("TODO") },
	200000: { "name": "???", "action": func(): print("TODO") },
	250000: { "name": "???", "action": func(): print("TODO") },
	300000: { "name": "Click Power V", "action": func(): click_value = 7 },
}


func _ready():
	load_game()
	update_click_counter()
	
	scoreboard_height = scoreboard.get_rect().size.y
	scoreboard.position.y = -scoreboard_height
	hover_zone.mouse_entered.connect(_on_hover_zone_mouse_entered)
	hover_zone.mouse_exited.connect(_on_hover_zone_mouse_exited)

# Reward the player for each tap
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		total_clicks += click_value
		update_click_counter()
		save_game()
		check_rewards()
		show_plus_one(get_global_mouse_position())

func _process(delta):
	if Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_R):
		reset_clicks()
		update_click_counter()
		click_value=1

func update_click_counter():
	$Sprite2/Sign/ClickCounter.text = str(total_clicks)
	$Sprite2/Sign/ClickCounter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func check_rewards():
	upgrade_button.visible = get_next_affordable_milestone() != -1

func fade_in_sprite(node_path: String):
	var sprite = get_node_or_null(node_path)
	if sprite:
		sprite.visible = true
		sprite.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 1.0, 1.0).from(0.0)

func flicker_light(node_path: String):
	var light = get_node_or_null(node_path)
	if light and light is Light2D:
		var tween := create_tween()
		tween.tween_property(light, "energy", 0.0, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(light, "energy", 1.0, 0.1)

func get_previous_redeemed_milestone() -> int:
	var prev = 0
	for milestone in unlock_thresholds:
		if milestone in unlocked_milestones:
			prev = milestone
		else:
			break
	return prev

func get_next_unlocked_milestone() -> int:
	for milestone in unlock_thresholds:
		if milestone not in unlocked_milestones:
			return milestone
	return unlock_thresholds[-1]  # All milestones done

#func hide_all_sprites():
	#for i in range(unlock_thresholds.size()):
		#var sprite = get_node_or_null("Sprite" + str(i + 1))
		#if sprite and sprite is Sprite2D:
			#sprite.modulate.a = 0.0
			#sprite.visible = false

func reset_clicks():
	total_clicks = 0
	unlocked_milestones.clear()
	save_game()
	update_click_counter()

func save_game():
	var data = { 
		"total_clicks": total_clicks,
		"unlocked_milestones": unlocked_milestones,
		"click_value": click_value
	 }
	var json_string = JSON.stringify(data)

	if OS.has_feature("web"):
		JavaScriptBridge.eval("localStorage.setItem('my_clicker_save', " + json_string + ");")
	else:
		var file = FileAccess.open(save_file_path, FileAccess.WRITE)
		if file:
			file.store_string(json_string)
			file.close()

func load_game():
	if OS.has_feature("web"):
		var json_string = JavaScriptBridge.eval("localStorage.getItem('my_clicker_save');")
		if json_string != null and json_string != "":
			var result = JSON.parse_string(json_string)
			if result:
				total_clicks = result.get("total_clicks", 0)
				unlocked_milestones = result.get("unlocked_milestones", []).map(func(m): return int(m))
				click_value = result.get("click_value", 1)
	else:
		if FileAccess.file_exists(save_file_path):
			var file = FileAccess.open(save_file_path, FileAccess.READ)
			if file:
				var json_string = file.get_as_text()
				file.close()
				var result = JSON.parse_string(json_string)
				if result:
					total_clicks = result.get("total_clicks", 0)
					unlocked_milestones = result.get("unlocked_milestones", []).map(func(m): return int(m))
					click_value = result.get("click_value", 1)
	load_milestones()
				
func load_milestones():
	# Re-apply unlocked milestone effects
	for milestone in unlocked_milestones:
		if milestones.has(milestone):
			var action = milestones[milestone].get("action")
			if action:
				action.call()

func show_plus_one(pos: Vector2):
	var plus = Sprite2D.new()
	match click_value: 
		1:
			plus.texture = preload("res://Assets/PlusOne.png")
		2:
			plus.texture = preload("res://Assets/PlusTwo.png")
		3:
			plus.texture = preload("res://Assets/PlusThree.png")
		4:
			plus.texture = preload("res://Assets/PlusFour.png")
		5:
			plus.texture = preload("res://Assets/PlusFive.png")
		6:
			plus.texture = preload("res://Assets/PlusSix.png")
		7:
			plus.texture = preload("res://Assets/PlusSeven.png")
		8:
			plus.texture = preload("res://Assets/PlusEight.png")
		9:
			plus.texture = preload("res://Assets/PlusNine.png")
	plus.position = pos
	plus.z_index = 100
	# Make sure it's on top
	add_child(plus)
	show_plus_tween(plus, pos)

func show_plus_tween(plus, pos):
	var tween = create_tween()
	tween.tween_property(plus, "position:y", pos.y - 30, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(plus, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(Callable(plus, "queue_free"))

func slide_scoreboard(to_y: float, duration := 0.5):
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(scoreboard, "position:y", to_y, duration).set_trans(Tween.TRANS_SINE)

func show_scoreboard_temporarily():
	if is_showing_due_to_milestone:
		return
	
	scoreboard_unlocked = true
	is_showing_due_to_milestone = true
	slide_scoreboard(22.0)

	await get_tree().create_timer(1.5).timeout

	if not is_hovering:
		slide_scoreboard(-scoreboard_height)
	is_showing_due_to_milestone = false
	
func get_next_affordable_milestone() -> int:
	var sorted_keys = milestones.keys()
	sorted_keys.sort()
	for milestone in sorted_keys:
		if total_clicks >= milestone and milestone not in unlocked_milestones:
			return milestone
	return -1

func _on_hover_zone_mouse_entered():
	if scoreboard_unlocked:
		is_hovering = true
		slide_scoreboard(22.0)

func _on_hover_zone_mouse_exited():
	if scoreboard_unlocked:
		is_hovering = false
		if not is_showing_due_to_milestone:
			slide_scoreboard(-scoreboard_height)

func _on_upgrade_button_button_up():
	var milestone = get_next_affordable_milestone()
	if milestone == -1:
		return

	total_clicks -= milestone
	unlocked_milestones.append(milestone)
	update_click_counter()
	save_game()
	check_rewards()
	$UpgradeButton/AudioStreamPlayer.play()
	var action = milestones[milestone].get("action")
	if action:
		action.call()

func _on_upgrade_button_mouse_entered():
	var sorted_keys = milestones.keys()
	sorted_keys.sort()

	for milestone in sorted_keys:
		if milestone not in unlocked_milestones and total_clicks >= milestone:
			var name = milestones[milestone].get("name", "???")
			$UpgradeButton.tooltip_text = "Unlock: %s\nCost: %d clicks" % [name, milestone]
			return

	# If none are affordable, show the next locked one (even if too expensive)
	for milestone in sorted_keys:
		if milestone not in unlocked_milestones:
			var remaining = milestone - total_clicks
			var name = milestones[milestone].get("name", "???")
			$UpgradeButton.tooltip_text = "Next: %s\nCost: %d clicks (%d more needed)" % [name, milestone, remaining]
			return

func play_random_lantern_sound():
	var index = randi_range(1, 10)
	var path = "res://Assets/SFX/Lantern%d.wav" % index
	print("Audio path:" + path)
	var stream = load(path)
	if stream:
		$LanternSound.stream = stream
		$LanternSound.play()

func bubble_handling():
	fade_in_sprite("Bubble")
	$Bubble.play("default")

func _on_bubble_frame_changed():
	if $Bubble.frame == 18:
		show_plus_one($Bubble.global_position)
		total_clicks += 1
		update_click_counter()

func start_drifting_zs():
	var timer = $DriftingZ/ZTimer
	timer.start()
