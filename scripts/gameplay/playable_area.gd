class_name PlayableArea
extends RefCounted


# Single authoritative playable-area model for every gameplay entity.
#
# Main updates the cached viewport size and safe-area padding once per
# viewport resize; the player clamp, defender clamp/spawn, tower scatter
# limits, and dropped-stone placement/bounce all read the same cached data.
# Because the device safe-area padding is applied here exactly once, no
# entity can end up inside another entity's inset band (the old bug: drops
# clamped to the raw viewport while the player clamped to a padded rect,
# leaving edge stones unreachable).

# Authoritative player body radius; GullyPlayerController aliases this.
const PLAYER_RADIUS: float = 28.0
# Buffer beyond an actor's own radius so it never renders flush against the
# physical screen edge or a display cutout.
const EDGE_SAFE_INSET: float = 14.0
# Visible margin for stones so no stone renders partly off screen.
const STONE_EDGE_INSET: float = 10.0
# Configurable shrink applied to the pickup reach so stones always sit a
# little deeper inside the reachable band than strictly necessary.
const PICKUP_SAFETY_MARGIN: float = 6.0

static var _viewport_size: Vector2 = Vector2.ZERO
static var _safe_padding: Vector2 = Vector2.ZERO


# Called by Main on startup and on every viewport size change; bounds are
# never recomputed anywhere else.
static func update(viewport_size: Vector2) -> void:
	_viewport_size = viewport_size
	_safe_padding = ViewportSafeArea.get_padding()


static func get_viewport_size() -> Vector2:
	return _viewport_size


# Rect a circular actor's CENTER may occupy.
static func get_actor_bounds(actor_radius: float) -> Rect2:
	var inset: Vector2 = Vector2.ONE * (actor_radius + EDGE_SAFE_INSET) + _safe_padding
	return Rect2(inset, _viewport_size - inset * 2.0)


static func get_player_bounds() -> Rect2:
	return get_actor_bounds(PLAYER_RADIUS)


# Rect a collectible stone's CENTER must stay inside so that:
#   (a) the stone is fully visible (extents + STONE_EDGE_INSET), and
#   (b) the player's body can overlap the stone's pickup shape without
#       leaving its own movement bounds.
# The reach is divided by sqrt(2) so the guarantee also holds diagonally in
# corners, then shrunk by PICKUP_SAFETY_MARGIN: any center inside this rect
# is at most (PLAYER_RADIUS + pickup_radius - margin) from the nearest
# player-reachable point.
static func get_collectible_bounds(stone_extents: Vector2, pickup_radius: float) -> Rect2:
	var reach: float = maxf(
		(PLAYER_RADIUS + pickup_radius) / sqrt(2.0) - PICKUP_SAFETY_MARGIN,
		0.0
	)
	var player_inset: Vector2 = (
		Vector2.ONE * (PLAYER_RADIUS + EDGE_SAFE_INSET) + _safe_padding
	)
	var inset: Vector2 = Vector2(
		maxf(stone_extents.x + STONE_EDGE_INSET + _safe_padding.x, player_inset.x - reach),
		maxf(stone_extents.y + STONE_EDGE_INSET + _safe_padding.y, player_inset.y - reach)
	)
	return Rect2(inset, _viewport_size - inset * 2.0)


static func clamp_to_bounds(point: Vector2, bounds: Rect2) -> Vector2:
	return Vector2(
		clampf(point.x, bounds.position.x, bounds.end.x),
		clampf(point.y, bounds.position.y, bounds.end.y)
	)
