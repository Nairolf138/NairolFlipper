extends RefCounted

## ViewportTexture excludes Window KEEP bars. Preserve pixels without scaling;
## this helper restores only the documented centered black window margins.
static func with_black_margins(content: Image, window_size: Vector2i) -> Image:
	if content.is_empty() or content.get_width() > window_size.x or content.get_height() > window_size.y:
		return null
	if content.get_size() == window_size:
		return content
	var frame := Image.create(window_size.x, window_size.y, false, content.get_format())
	frame.fill(Color.BLACK)
	frame.blit_rect(content, Rect2i(Vector2i.ZERO, content.get_size()), (window_size - content.get_size()) / 2)
	return frame
