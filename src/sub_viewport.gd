extends SubViewport

@export var framerate := 16
var timer := 0.0

func _process(delta):
	timer += delta
	var frame_intterval = 1.0/framerate
	if timer >= frame_intterval:
		timer = fmod(timer,frame_intterval)
		render_target_update_mode = SubViewport.UPDATE_ONCE
