extends Window


func _ready() -> void:
	borderless = true
	transparent = true
	

	get_viewport().transparent_bg = true

	size = Vector2i(300, 300)
