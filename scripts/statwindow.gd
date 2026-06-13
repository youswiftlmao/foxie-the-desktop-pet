extends Window


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	borderless = true
	transparent = true
	always_on_top = true
	unresizable = true
	size = Vector2i(300, 300)
	var screen = DisplayServer.screen_get_usable_rect()
	
	position = Vector2i(
		screen.end.x - size.x - 20,
		screen.position.y + 20
		
	)
