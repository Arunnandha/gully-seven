class_name ProceduralSound
extends RefCounted


enum Waveform {
	SINE,
	SQUARE,
	TRIANGLE,
}

# 22.05kHz is plenty for short, simple arcade blips and halves the memory
# and generation cost of 44.1kHz — these are synthesized once at startup
# and cached, never regenerated during gameplay.
const MIX_RATE: int = 22050
const ATTACK_SECONDS: float = 0.004

var _noise_state: int = 0x2545F491


# One short synthesized note: a swept tone (optionally blended with cheap
# deterministic noise) under a linear-decay envelope with a brief attack
# ramp, so every clip starts/ends click-free.
func generate_tone(
	duration_seconds: float,
	freq_start: float,
	freq_end: float,
	waveform: Waveform,
	peak_volume: float = 0.6,
	noise_mix: float = 0.0
) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = _synthesize(duration_seconds, freq_start, freq_end, waveform, peak_volume, noise_mix)
	return stream


# Concatenates several notes back to back into a single stream (e.g. a
# short ascending arpeggio) without ever needing runtime mixing/timers.
func generate_sequence(notes: Array[Dictionary]) -> AudioStreamWAV:
	var combined: PackedByteArray = PackedByteArray()
	for note: Dictionary in notes:
		combined.append_array(_synthesize(
			note.get("duration", 0.1),
			note.get("freq_start", 440.0),
			note.get("freq_end", 440.0),
			note.get("waveform", Waveform.SINE),
			note.get("volume", 0.6),
			note.get("noise_mix", 0.0)
		))

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = combined
	return stream


func _synthesize(
	duration_seconds: float,
	freq_start: float,
	freq_end: float,
	waveform: Waveform,
	peak_volume: float,
	noise_mix: float
) -> PackedByteArray:
	var sample_count: int = maxi(int(MIX_RATE * duration_seconds), 1)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(sample_count * 2)
	var attack_samples: int = mini(int(MIX_RATE * ATTACK_SECONDS), sample_count / 4)
	var phase: float = 0.0

	for sample_index: int in range(sample_count):
		var t: float = float(sample_index) / float(sample_count)
		var frequency: float = lerpf(freq_start, freq_end, t)
		phase += frequency / float(MIX_RATE)

		var tone_sample: float = _wave_sample(waveform, phase)
		var noise_sample: float = _next_noise_sample()
		var raw: float = lerpf(tone_sample, noise_sample, noise_mix)

		var envelope: float = 1.0 - t
		if sample_index < attack_samples:
			envelope *= float(sample_index) / float(attack_samples)

		var sample_value: float = clampf(raw * envelope * peak_volume, -1.0, 1.0)
		bytes.encode_s16(sample_index * 2, int(sample_value * 32767.0))

	return bytes


func _wave_sample(waveform: Waveform, phase: float) -> float:
	var cycle: float = fmod(phase, 1.0)
	match waveform:
		Waveform.SQUARE:
			return 1.0 if cycle < 0.5 else -1.0
		Waveform.TRIANGLE:
			return 2.0 * absf(2.0 * cycle - 1.0) - 1.0
		_:
			return sin(TAU * phase)


# Tiny deterministic LCG noise source — cheap, seeded, reused across every
# generated clip so the whole synthesis pass stays allocation-free.
func _next_noise_sample() -> float:
	_noise_state = (_noise_state * 1103515245 + 12345) & 0x7fffffff
	return (float(_noise_state) / float(0x7fffffff)) * 2.0 - 1.0
