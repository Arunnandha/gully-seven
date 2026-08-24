class_name FeedbackManager
extends Node


enum Event {
	BALL_RELEASE,
	TOWER_IMPACT,
	STONE_PICKUP,
	STONE_DEPOSIT,
	DEFENDER_TAG,
	BREATH_WARNING,
	BREATH_FAILURE,
	TOWER_COMPLETE,
	BUTTON_PRESS,
}

const SFX_BUS_NAME: String = "SFX"
const MUSIC_BUS_NAME: String = "Music"
const PLAYER_POOL_SIZE: int = 8

const MILD_HAPTIC_MSEC: int = 20
const MEDIUM_HAPTIC_MSEC: int = 50
const STRONG_HAPTIC_MSEC: int = 90
const MILD_HAPTIC_AMPLITUDE: float = 0.35
const MEDIUM_HAPTIC_AMPLITUDE: float = 0.65
const STRONG_HAPTIC_AMPLITUDE: float = 1.0

var haptics_enabled: bool = true

var _sfx_volume: float = 0.85
var _music_volume: float = 0.8
var _players: Array[AudioStreamPlayer] = []
var _next_player_index: int = 0
var _streams: Dictionary = {}


func _ready() -> void:
	_ensure_bus(SFX_BUS_NAME)
	_ensure_bus(MUSIC_BUS_NAME)
	_apply_sfx_volume()
	_apply_music_volume()
	_generate_sounds()

	for _pool_index: int in range(PLAYER_POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = SFX_BUS_NAME
		add_child(player)
		_players.append(player)


func trigger(event: Event) -> void:
	_play_sound(event)
	_play_haptic(event)


func stop_active_sounds() -> void:
	for player: AudioStreamPlayer in _players:
		player.stop()


func set_sfx_volume(linear_volume: float) -> void:
	_sfx_volume = clampf(linear_volume, 0.0, 1.0)
	_apply_sfx_volume()


func set_music_volume(linear_volume: float) -> void:
	_music_volume = clampf(linear_volume, 0.0, 1.0)
	_apply_music_volume()


func set_haptics_enabled(enabled: bool) -> void:
	haptics_enabled = enabled


func _apply_sfx_volume() -> void:
	var bus_index: int = AudioServer.get_bus_index(SFX_BUS_NAME)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(_sfx_volume, 0.0001)))
	AudioServer.set_bus_mute(bus_index, _sfx_volume <= 0.0)


func _apply_music_volume() -> void:
	var bus_index: int = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(_music_volume, 0.0001)))
	AudioServer.set_bus_mute(bus_index, _music_volume <= 0.0)


func _play_sound(event: Event) -> void:
	var stream: AudioStreamWAV = _streams.get(event)
	if stream == null:
		return
	var player: AudioStreamPlayer = _players[_next_player_index]
	_next_player_index = (_next_player_index + 1) % PLAYER_POOL_SIZE
	player.stream = stream
	player.play()


func _play_haptic(event: Event) -> void:
	if not haptics_enabled:
		return
	match event:
		Event.TOWER_IMPACT, Event.STONE_DEPOSIT:
			Input.vibrate_handheld(MILD_HAPTIC_MSEC, MILD_HAPTIC_AMPLITUDE)
		Event.BREATH_FAILURE:
			Input.vibrate_handheld(MEDIUM_HAPTIC_MSEC, MEDIUM_HAPTIC_AMPLITUDE)
		Event.DEFENDER_TAG, Event.TOWER_COMPLETE:
			Input.vibrate_handheld(STRONG_HAPTIC_MSEC, STRONG_HAPTIC_AMPLITUDE)
		_:
			pass


func _generate_sounds() -> void:
	var synth: ProceduralSound = ProceduralSound.new()
	_streams[Event.BALL_RELEASE] = synth.generate_tone(
		0.10, 500.0, 900.0, ProceduralSound.Waveform.SINE, 0.5
	)
	_streams[Event.TOWER_IMPACT] = synth.generate_tone(
		0.16, 160.0, 70.0, ProceduralSound.Waveform.SINE, 0.7, 0.45
	)
	_streams[Event.STONE_PICKUP] = synth.generate_tone(
		0.09, 900.0, 1300.0, ProceduralSound.Waveform.SINE, 0.5
	)
	_streams[Event.STONE_DEPOSIT] = synth.generate_tone(
		0.13, 300.0, 220.0, ProceduralSound.Waveform.SINE, 0.55, 0.12
	)
	_streams[Event.DEFENDER_TAG] = synth.generate_tone(
		0.22, 480.0, 220.0, ProceduralSound.Waveform.SQUARE, 0.5
	)
	_streams[Event.BREATH_WARNING] = synth.generate_tone(
		0.09, 750.0, 750.0, ProceduralSound.Waveform.SINE, 0.4
	)
	_streams[Event.BREATH_FAILURE] = synth.generate_tone(
		0.32, 500.0, 150.0, ProceduralSound.Waveform.SINE, 0.6
	)
	_streams[Event.TOWER_COMPLETE] = synth.generate_sequence([
		{"duration": 0.12, "freq_start": 523.0, "freq_end": 523.0, "waveform": ProceduralSound.Waveform.SINE, "volume": 0.55},
		{"duration": 0.12, "freq_start": 659.0, "freq_end": 659.0, "waveform": ProceduralSound.Waveform.SINE, "volume": 0.55},
		{"duration": 0.16, "freq_start": 784.0, "freq_end": 784.0, "waveform": ProceduralSound.Waveform.SINE, "volume": 0.6},
	])
	_streams[Event.BUTTON_PRESS] = synth.generate_tone(
		0.045, 600.0, 600.0, ProceduralSound.Waveform.TRIANGLE, 0.35
	)


static func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	var index: int = AudioServer.bus_count
	AudioServer.add_bus(index)
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")
