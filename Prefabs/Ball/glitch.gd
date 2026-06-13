class_name GlitchEffect extends Sprite2D

@onready var glitch_sprite: Sprite2D = $"."  # or wherever your Sprite2D is

func activate_glitch():
	# Wait for the frame to finish rendering first
	await RenderingServer.frame_post_draw
	
	# Grab the current screen as an image
	var img = get_viewport().get_texture().get_image()
	
	# Crop to just the ball's region
	var rect = $"../Root".get_rect()  # adjust path to your Root node
	var global_rect = Rect2i(
		Vector2i($"../Root".global_position - rect.size * 0.5),
		Vector2i(rect.size)
	)
	img.crop(global_rect.size.x, global_rect.size.y)  
	
	# Bake into a texture and assign
	var tex = ImageTexture.create_from_image(img)
	glitch_sprite.texture = tex
	glitch_sprite.visible = true
