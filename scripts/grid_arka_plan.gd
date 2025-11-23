extends ColorRect

@export var blok_boyutu: int = 24
@export var grid_color: Color = Color(0.2, 0.2, 0.2)

func _draw():
	var x = 0.0
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)
		x += blok_boyutu

	var y = 0.0
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)
		y += blok_boyutu
