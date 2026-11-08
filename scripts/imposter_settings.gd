extends Control


@export var chance_label: Label

@export var chance_slider: Slider

@export var again_label: Label

@export var again_slider: Slider

@export var chaos_check: CheckButton

func _ready():
	var saved_value = Global.get_setting("imposter_starting_chance", chance_slider.value)
	var again_value = Global.get_setting("imposter_goes_again_chance", again_slider.value)
	chance_slider.value = saved_value
	again_slider.value = again_value
	if chaos_check:
		chaos_check.button_pressed = Global.get_setting("chaos_cards", Global.chaos_cards)
	_on_h_slider_value_changed(saved_value)

func _on_h_slider_value_changed(value):
	chance_label.text = str(int(value/chance_slider.max_value*100)) + "%" # I know the range is from 0-100 but its good practice to do this so Ion curr


func _on_done_pressed():
	Global.set_setting("imposter_starting_chance", chance_slider.value/chance_slider.max_value*100)
	Global.set_setting("imposter_goes_again_chance", again_slider.value/again_slider.max_value*100)
	if chaos_check:
		Global.set_setting("chaos_cards", chaos_check.button_pressed)
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


func _on_cancel_pressed():
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


func _on_again_slider_value_changed(value):
	again_label.text = str(int(value/again_slider.max_value*100)) + "%"
