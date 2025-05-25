# Jeff Sabol
extends Node2D

var total_clicks: int = 0
var save_file_path := "user://save_data.json"
var unlock_thresholds := [5, 15, 30, 60, 110, 200, 360, 650, 1150, 2000, 3600, 6500, 11000]
var unlocked_milestones: Array = []

# Define custom milestone behavior
var milestone_actions := {
	5: func(): print("TODO +1 for each click"),
	15: func(): fade_in_sprite("Sprite1"),
	30: func(): fade_in_sprite("Sprite2"),
	60: func(): flicker_light("LanternRed"),
	110: func(): print("TOOD"),
	200: func(): print("TOOD"),
	360: func(): print("TOOD"),
	650: func(): print("TOOD"),
	1150: func(): print("TOOD"),
	2000: func(): print("TOOD"),
	3600: func(): print("TOOD"),
	6500: func(): print("TOOD"),
	11000: func(): print("TOOD"),
}

func _ready():
	reset_clicks()
	load_game()
	update_click_counter()
	hide_all_sprites()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		total_clicks += 1
		update_click_counter()
		save_game()
		check_rewards()

func update_click_counter():
	$Sprite2/ClickCounter.text = str(total_clicks)
	$Sprite2/ClickCounter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	print_xp_gauge()

func check_rewards():
	for milestone in unlock_thresholds:
		if total_clicks == milestone and milestone not in unlocked_milestones:
			print("🎉 Milestone reached at %d clicks!" % milestone)
			if milestone_actions.has(milestone):
				milestone_actions[milestone].call()
			unlocked_milestones.append(milestone)

func fade_in_sprite(node_path: String):
	var sprite = get_node_or_null(node_path)
	if sprite and sprite is Sprite2D:
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

func print_xp_gauge():
	var next = get_next_milestone()
	var progress = float(total_clicks) / next
	var filled = int(progress * 20)
	var bar = "|"
	for i in range(20):
		bar += "█" if i < filled else "-"
	bar += "|"
	print("Clicks: %d / %d %s" % [total_clicks, next, bar])

func get_next_milestone() -> int:
	for milestone in unlock_thresholds:
		if total_clicks < milestone:
			return milestone
	return unlock_thresholds[-1]

func hide_all_sprites():
	for i in range(unlock_thresholds.size()):
		var sprite = get_node_or_null("Sprite" + str(i + 1))
		if sprite and sprite is Sprite2D:
			sprite.modulate.a = 0.0
			sprite.visible = false

func reset_clicks():
	total_clicks = 0
	unlocked_milestones.clear()
	save_game()
	update_click_counter()
	hide_all_sprites()

func save_game():
	var data = { "total_clicks": total_clicks }
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
	else:
		if FileAccess.file_exists(save_file_path):
			var file = FileAccess.open(save_file_path, FileAccess.READ)
			if file:
				var json_string = file.get_as_text()
				file.close()
				var result = JSON.parse_string(json_string)
				if result:
					total_clicks = result.get("total_clicks", 0)
