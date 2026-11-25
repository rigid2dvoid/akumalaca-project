extends Node
## Audio pool sederhana: satu file musik loop + beberapa SFX yang diputar
## bergantian supaya suara tidak saling memotong.

const SFX_NAMES := [
	"jump", "dash", "slash1", "slash2", "slash3", "hit", "hit_heavy",
	"hurt", "land", "windup", "enemy_attack", "shockwave", "heal",
	"charge", "victory", "defeat",
]

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var muted := false

func _ready() -> void:
	for sfx_name in SFX_NAMES:
		var path := "res://assets/audio/%s.wav" % sfx_name
		if ResourceLoader.exists(path):
			_streams[sfx_name] = load(path)

	for i in range(10):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

	var music_path := "res://assets/audio/music.ogg"
	if ResourceLoader.exists(music_path):
		var stream = load(music_path)
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		_music = AudioStreamPlayer.new()
		_music.stream = stream
		_music.volume_db = -20.0
		add_child(_music)
		_music.play()

func play(sfx_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if muted or not _streams.has(sfx_name):
		return
	var chosen: AudioStreamPlayer = null
	for p in _players:
		if not p.playing:
			chosen = p
			break
	if chosen == null:
		chosen = _players[randi() % _players.size()]
	chosen.stream = _streams[sfx_name]
	chosen.volume_db = volume_db
	chosen.pitch_scale = clampf(pitch, 0.65, 1.6)
	chosen.play()

func toggle_mute() -> bool:
	muted = not muted
	if _music:
		_music.volume_db = -80.0 if muted else -20.0
	return muted
