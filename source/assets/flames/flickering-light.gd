extends Node

onready var anim = $AnimationPlayer


func _ready():
	anim.play("0")


func _on_animation_finished(_anim_name):
	anim.play(String(randi()%4))
	anim.playback_speed = float(randi()%16)/10 + 0.5
