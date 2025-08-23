extends Node

signal audio_finished(instance_id: int);

var max_audio_players: int = 20;
var active_audio_players: int = 0;

func play_sfx(sfx:SFX, bus: StringName = "SFX", pitch:float = 1.0, offset: float = 0.0, fade_in: float = 0.0, forced:bool = true) -> NodePath:
	if (sfx == null):
		return NodePath();

	return play_sound(sfx.audio_stream, sfx.volume, bus, offset, fade_in, forced, pitch);

func play_sound(stream: AudioStream, volume: float, bus: StringName = "Master", offset: float = 0.0, fade_in: float = 0.0, forced:bool = false, pitch:float = 1.0) -> NodePath:
	if (!forced && active_audio_players >= max_audio_players):
		return NodePath();

	var instance = AudioStreamPlayer.new();
	instance.stream = stream;
	instance.bus = bus;
	instance.volume_db = volume;
	instance.pitch_scale = pitch;
	instance.finished.connect(on_play_sound_finished.bind(instance));
	add_child(instance);
	instance.play(offset);

	if (fade_in > 0.0):
		print("Fade in " + str(fade_in))
		instance.volume_db = -80.0;
		var tween = create_tween();
		tween.tween_property(instance, "volume_db", volume, fade_in);
		tween.play();

	active_audio_players += 1;
	return instance.get_path();

func on_play_sound_finished(instance: AudioStreamPlayer):
	audio_finished.emit(instance.stream.get_instance_id());
	instance.queue_free();
	active_audio_players -= 1;

func kill_audio_player(path: NodePath):
	var player = get_node_or_null(path);
	if player:
		player.stop();
		player.queue_free();
