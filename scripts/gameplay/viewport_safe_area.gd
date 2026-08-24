class_name ViewportSafeArea
extends RefCounted


# Extra per-axis padding (in viewport pixels) to keep gameplay objects clear
# of a device's display cutout/notch/gesture-bar, on top of their own radius.
# On desktop (and any device without a safe-area API) this resolves to
# Vector2.ZERO, so it never shrinks the play area unnecessarily.
static func get_padding() -> Vector2:
	var screen_size: Vector2 = DisplayServer.screen_get_size()
	if screen_size.x <= 0.0 or screen_size.y <= 0.0:
		return Vector2.ZERO

	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var left: float = float(safe_area.position.x)
	var top: float = float(safe_area.position.y)
	var right: float = screen_size.x - float(safe_area.position.x + safe_area.size.x)
	var bottom: float = screen_size.y - float(safe_area.position.y + safe_area.size.y)

	return Vector2(
		maxf(maxf(left, right), 0.0),
		maxf(maxf(top, bottom), 0.0)
	)
