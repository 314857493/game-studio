extends RefCounted

## Pure animation, input-buffer and pause state for story-003.
##
## The 3D scene owns the Tween and the board; this class owns the rules that
## can be checked headlessly: one buffered move, pause snapping and the
## design's durations.

const MOVE_DURATION := 0.12
const PUSH_DURATION := 0.16
const BUMP_DURATION := 0.10

var _animating: bool = false
var _paused: bool = false
var _buffered: Vector2i = Vector2i.ZERO
var _has_buffered: bool = false


func is_animating() -> bool:
	return _animating


func is_paused() -> bool:
	return _paused


func begin_animation() -> void:
	_animating = true


func end_animation() -> void:
	_animating = false


## R10: pauses and reports whether an in-flight animation had to be snapped.
func pause() -> bool:
	if _paused:
		return false
	var snapped: bool = _animating
	_animating = false
	_paused = true
	clear_buffer()
	return snapped


func resume() -> void:
	_paused = false


## R11: one slot; a newer direction replaces the old one.
func buffer_move(direction: Vector2i) -> void:
	_buffered = direction
	_has_buffered = true


func has_buffered() -> bool:
	return _has_buffered


func take_buffered() -> Vector2i:
	var direction: Vector2i = _buffered
	clear_buffer()
	return direction


func clear_buffer() -> void:
	_buffered = Vector2i.ZERO
	_has_buffered = false


func move_duration(pushed: bool) -> float:
	return PUSH_DURATION if pushed else MOVE_DURATION
