extends Node3D

@export var card_1: Node3D
@export var card_2: Node3D
@export var next: Button
@export var new_game: Button
@export var exit: Button
@export var chaos_button: Button
@export var chaos_modal: Control
@export var chaos_round_label: Label
@export var chaos_title_label: Label
@export var chaos_desc_label: Control
@export var chaos_next_button: Button

var pressing = false
var enabled = true
var idx = 0
var current_round: int = 2
var drawn_chaos_ids: Array = []
var current_chaos_card: Dictionary = {}
var pulse_tween: Tween
var is_rolling_card: bool = false
var shake_time: float = 0.0
var shake_intensity: float = 0.0

func _ready():
	# Force every Sprite3D to broadcast its OWN SubViewport
	card_1.get_node("Sprite3D").texture = card_1.get_node("Sprite3D/SubViewport").get_texture()
	card_1.get_node("Sprite3D2").texture = card_1.get_node("Sprite3D2/SubViewport").get_texture()
	
	card_2.get_node("Sprite3D").texture = card_2.get_node("Sprite3D/SubViewport").get_texture()
	card_2.get_node("Sprite3D2").texture = card_2.get_node("Sprite3D2/SubViewport").get_texture()
	
	new_game.visible = false 
	if chaos_button:
		chaos_button.visible = false
	if chaos_modal:
		chaos_modal.visible = false 
	
	randomize()
	Global.decide_imposters()
	Global.decide_word()
	
	card_1.global_position.x = 0.0
	card_2.global_position.x = 5.0
	
	update_card(card_1, idx)
	update_card(card_2, idx + 1)


func _input(event):
	if chaos_modal and chaos_modal.visible:
		return
	if event is InputEventScreenTouch:
		if not event.pressed:
			pressing = false
		elif idx < len(Global.players) and event.position.y < next.position.y - (next.size.y / 1.5) and event.position.y > exit.position.y + exit.size.y:
			pressing = true


func _process(delta):
	# Camera shake decay
	if shake_time > 0.0:
		shake_time -= delta
		var cam = get_node_or_null("Camera3D")
		if cam:
			cam.h_offset = randf_range(-shake_intensity, shake_intensity)
			cam.v_offset = randf_range(-shake_intensity, shake_intensity)
			if shake_time <= 0.0:
				cam.h_offset = 0.0
				cam.v_offset = 0.0

	var wishpos = 0.0
	var wishrot = 0.0
	if pressing and enabled and idx < len(Global.players):
		wishpos = 0.25
		wishrot = PI
		next.visible = true
	
	card_1.global_position.z = lerp(card_1.global_position.z, wishpos, 0.1)
	card_1.global_rotation.y = lerp_angle(card_1.global_rotation.y, wishrot, 0.1)
	
	
	if not enabled:
		next.visible = false
		card_1.global_position.x = lerp(card_1.global_position.x, -5.0, 0.1)
		
		if idx + 1 <= len(Global.players):
			card_2.global_position.x = lerp(card_2.global_position.x, 0.0, 0.1)
		
		var card_1_done = abs(card_1.global_position.x + 5.0) < 0.01
		var card_2_done = true
		if idx + 1 <= len(Global.players):
			card_2_done = abs(card_2.global_position.x) < 0.01
			
		if card_1_done and card_2_done:
			if idx < len(Global.players):
				card_1.global_position.x = 5.0
				var temp = card_1
				card_1 = card_2
				card_2 = temp
				idx += 1
				update_card(card_2, idx + 1)
				enabled = true
				
				# If we just slid into the final Summary card, show the button
				if idx == len(Global.players):
					new_game.visible = true
					if chaos_button and Global.chaos_cards:
						chaos_button.visible = true
						_start_chaos_button_pulse()
					


func update_card(card: Node3D, player_idx: int):
	var box1 = card.get_node("Sprite3D/SubViewport/Button/VBoxContainer")
	var box2 = card.get_node("Sprite3D2/SubViewport/Button/VBoxContainer")
	
	# Scenario A: Final Summary Card
	if player_idx == len(Global.players):
		card.visible = true
		
		# --- PERFECT PROBABILITY MATH ---
		var player_count = len(Global.players)
		var imposter_count = Global.imposter_indexes.size()
		var normal_count = player_count - imposter_count
		
		# Convert 100.0 into 1.0, 50.0 into 0.5, etc.
		var chance_multiplier = clampf(Global.imposter_starting_chance / 100.0, 0.0, 1.0)
		
		var imposter_prob = 0.0
		var normal_prob = 0.0
		
		if normal_count > 0:
			# 1. Figure out what the fair baseline chance is (e.g. 25% for 4 players)
			var base_chance = 1.0 / float(player_count)
			
			# 2. Scale the imposter's chance by the user setting (e.g. 50% of 25% = 12.5%)
			imposter_prob = base_chance * chance_multiplier
			
			# 3. Figure out how much probability is leftover
			var total_imposter_prob = imposter_prob * imposter_count
			var remaining_prob = 1.0 - total_imposter_prob
			
			# 4. Divide all remaining probability evenly among the normal players
			normal_prob = remaining_prob / float(normal_count)
		else:
			# Fallback just in case you somehow make a game of ONLY imposters
			imposter_prob = 1.0 / float(player_count)
			
		var weights = []
		for i in range(player_count):
			if i in Global.imposter_indexes:
				weights.append(imposter_prob)
			else:
				weights.append(normal_prob)
				
		# Roll a random number from 0 to 1
		var roll = randf()
		var current_weight = 0.0
		var starter_idx = 0
		
		# Figure out who won the roll
		for i in range(len(weights)):
			current_weight += weights[i]
			if roll <= current_weight:
				starter_idx = i
				break
				
		var starter_name = Global.players[starter_idx]
		
		# Set starter player name
		box1.get_node("Player").text = starter_name
		box2.get_node("Player").text = starter_name
		
		# Change Label2 text
		box1.get_node("Label2").text = "starts the conversation"
		
		# Hide extra stuff in Sprite3D (The simple side)
		box1.get_node("HSeparator").visible = false 
		box1.get_node("Label3").visible = false
		box1.get_node("TextureRect").visible = false
		
	# Scenario B: Standard active player card
	elif player_idx < len(Global.players):
		card.visible = true
		
		box1.get_node("Player").text = Global.players[player_idx]
		box2.get_node("Player").text = Global.players[player_idx]
		
		# Ensure extra stuff is visible in Sprite3D
		box1.get_node("HSeparator").visible = true
		box1.get_node("Label3").visible = true
		box1.get_node("TextureRect").visible = true
		
		if player_idx in Global.imposter_indexes:
			box2.get_node("PanelContainer/Word").text = "YOU ARE THE IMPOSTER!"
			box2.get_node("Hint").text = "Hint: " + Global.hint
			box2.get_node("Hint").visible = Global.imposter_hint
		else:
			box2.get_node("PanelContainer/Word").text = Global.word
			box2.get_node("Hint").visible = false
			
		new_game.visible = false
	else:
		card.visible = false


func _on_next_pressed():
	enabled = false
	pressing = false


func _on_finish_pressed():
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


func _on_reveal_pressed():
	get_tree().change_scene_to_file("res://scenes/imposter_reveal.tscn")


func _on_exit_pressed():
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


func _start_chaos_button_pulse():
	if not chaos_button:
		return
	chaos_button.pivot_offset = Vector2(chaos_button.size.x / 2.0, chaos_button.size.y / 2.0)
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(chaos_button, "scale", Vector2(1.06, 1.06), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(chaos_button, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _shake_screen(duration: float = 0.25, intensity: float = 0.06):
	shake_time = duration
	shake_intensity = intensity


func _on_chaos_button_pressed():
	if is_rolling_card:
		return
	if not chaos_modal:
		return
	
	chaos_modal.visible = true
	var dimmer = chaos_modal.get_node_or_null("Dimmer")
	var panel = chaos_modal.get_node_or_null("Panel")
	
	if dimmer:
		dimmer.modulate.a = 0.0
		var dt = create_tween()
		dt.tween_property(dimmer, "modulate:a", 1.0, 0.15)
	
	if panel:
		panel.pivot_offset = Vector2(panel.size.x / 2.0, panel.size.y / 2.0)
		panel.scale = Vector2(0.4, 0.4)
		panel.modulate.a = 0.0
		var pt = create_tween()
		pt.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pt.parallel().tween_property(panel, "modulate:a", 1.0, 0.18)
	
	if current_chaos_card.is_empty():
		_roll_and_reveal_card()
	else:
		_display_current_chaos_card()


func _on_chaos_next_pressed():
	if is_rolling_card:
		return
	current_round += 1
	_roll_and_reveal_card()


func _on_chaos_close_pressed():
	if is_rolling_card:
		return
	if not chaos_modal:
		return
	
	var dimmer = chaos_modal.get_node_or_null("Dimmer")
	var panel = chaos_modal.get_node_or_null("Panel")
	var ct = create_tween()
	if panel:
		ct.tween_property(panel, "scale", Vector2(0.7, 0.7), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		ct.parallel().tween_property(panel, "modulate:a", 0.0, 0.15)
	if dimmer:
		ct.parallel().tween_property(dimmer, "modulate:a", 0.0, 0.15)
	ct.tween_callback(func(): chaos_modal.visible = false)


func _roll_and_reveal_card():
	if not chaos_modal:
		return
	is_rolling_card = true
	var panel = chaos_modal.get_node_or_null("Panel")
	var next_btn = chaos_modal.get_node_or_null("Panel/MarginContainer/VBoxContainer/Buttons/Next")
	var close_btn = chaos_modal.get_node_or_null("Panel/MarginContainer/VBoxContainer/Buttons/Close")
	if next_btn: next_btn.disabled = true
	if close_btn: close_btn.disabled = true
	
	if chaos_round_label:
		chaos_round_label.text = "⚡ ĐANG RÚT BIẾN CỐ (VÒNG " + str(current_round) + ") ⚡"
	if chaos_desc_label is RichTextLabel:
		chaos_desc_label.text = "[center][color=#AAAAAA]Đang xáo trộn biến cố...[/color][/center]"
	elif chaos_desc_label is Label:
		chaos_desc_label.text = "Đang xáo trộn biến cố..."
	
	# Rapid rolling shuffle (Slot Machine suspense)
	var roll_steps = 7
	for step in range(roll_steps):
		if chaos_title_label:
			var random_card = ChaosCards.CARDS.pick_random()
			chaos_title_label.text = random_card.get("title", "???")
		if panel:
			panel.rotation_degrees = randf_range(-2.5, 2.5)
			panel.scale = Vector2(0.96, 0.96) if step % 2 == 0 else Vector2(1.04, 1.04)
		await get_tree().create_timer(0.06).timeout
	
	# Slam down final card with elastic bounce & screen shake
	if panel:
		panel.rotation_degrees = 0.0
		panel.scale = Vector2(1.18, 1.18)
		var slam_tween = create_tween()
		slam_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	_shake_screen(0.25, 0.06)
	
	current_chaos_card = ChaosCards.draw_card(Global.players, drawn_chaos_ids)
	drawn_chaos_ids.append(current_chaos_card["id"])
	_display_current_chaos_card()
	
	if next_btn: next_btn.disabled = false
	if close_btn: close_btn.disabled = false
	is_rolling_card = false


func _display_current_chaos_card():
	if chaos_round_label:
		chaos_round_label.text = "⚡ THẺ BIẾN CỐ (VÒNG " + str(current_round) + ") ⚡"
	if chaos_title_label:
		chaos_title_label.text = current_chaos_card.get("title", "")
	if chaos_desc_label is RichTextLabel:
		chaos_desc_label.text = current_chaos_card.get("bbcode_description", current_chaos_card.get("description", ""))
	elif chaos_desc_label is Label:
		chaos_desc_label.text = current_chaos_card.get("description", "")
	if chaos_next_button:
		chaos_next_button.text = "🎲 Vòng " + str(current_round + 1)

