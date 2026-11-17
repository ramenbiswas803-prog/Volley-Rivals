extends Node
# Autoload "GameState": save/load, graphics quality aur 10 characters ka data yahan hai.

const SAVE_PATH := "user://volley_rivals_save.cfg"
const QUALITY_NAMES := ["LOW", "MEDIUM", "HIGH"]

var graphics_quality: int = 1
var selected_character: int = 0
var game_mode: String = "quick"
var coins: int = 0
var matches_played: int = 0
var story_chapter: int = 1

# 10 original characters. Stats 1-10.
var characters: Array = [
    {"name": "Ren Takamine", "role": "Ace Spiker", "speed": 7, "jump": 9, "stamina": 7, "power": 10, "receive": 4, "hair": Color(0.95, 0.35, 0.15), "jersey": Color(0.15, 0.45, 0.95), "special": "Blaze Smash"},
    {"name": "Sora Hoshino", "role": "Setter", "speed": 7, "jump": 6, "stamina": 8, "power": 5, "receive": 7, "hair": Color(0.35, 0.75, 1.0), "jersey": Color(0.15, 0.45, 0.95), "special": "Star Toss"},
    {"name": "Hikaru Mizuno", "role": "Libero", "speed": 10, "jump": 4, "stamina": 9, "power": 3, "receive": 10, "hair": Color(0.3, 0.9, 0.6), "jersey": Color(0.15, 0.45, 0.95), "special": "Iron Receive"},
    {"name": "Raiden Kurogane", "role": "Middle Blocker", "speed": 5, "jump": 8, "stamina": 7, "power": 8, "receive": 4, "hair": Color(0.15, 0.15, 0.2), "jersey": Color(0.15, 0.45, 0.95), "special": "Steel Wall"},
    {"name": "Yuto Shirogane", "role": "Opposite", "speed": 6, "jump": 8, "stamina": 6, "power": 9, "receive": 5, "hair": Color(0.9, 0.9, 0.95), "jersey": Color(0.15, 0.45, 0.95), "special": "Silver Cannon"},
    {"name": "Akira Fujisawa", "role": "Wing Spiker", "speed": 8, "jump": 8, "stamina": 7, "power": 7, "receive": 6, "hair": Color(0.7, 0.35, 0.95), "jersey": Color(0.15, 0.45, 0.95), "special": "Violet Slash"},
    {"name": "Kenji Amatsu", "role": "Serve Specialist", "speed": 6, "jump": 7, "stamina": 6, "power": 9, "receive": 5, "hair": Color(1.0, 0.8, 0.1), "jersey": Color(0.15, 0.45, 0.95), "special": "Thunder Serve"},
    {"name": "Taiga Minase", "role": "Blocker", "speed": 5, "jump": 9, "stamina": 8, "power": 6, "receive": 4, "hair": Color(0.1, 0.5, 0.45), "jersey": Color(0.15, 0.45, 0.95), "special": "Tiger Block"},
    {"name": "Nagi Kisaragi", "role": "Libero", "speed": 9, "jump": 5, "stamina": 8, "power": 4, "receive": 9, "hair": Color(1.0, 0.55, 0.7), "jersey": Color(0.15, 0.45, 0.95), "special": "Moon Dive"},
    {"name": "Mio Himura", "role": "Setter", "speed": 8, "jump": 6, "stamina": 7, "power": 5, "receive": 7, "hair": Color(0.85, 0.15, 0.2), "jersey": Color(0.15, 0.45, 0.95), "special": "Flare Set"},
]

func _ready() -> void:
    load_game()
    Engine.max_fps = 60
    apply_quality()

func apply_quality() -> void:
    var win := get_tree().root
    match graphics_quality:
        0:
            win.scaling_3d_scale = 0.67
            win.msaa_3d = Viewport.MSAA_DISABLED
        1:
            win.scaling_3d_scale = 0.85
            win.msaa_3d = Viewport.MSAA_DISABLED
        _:
            win.scaling_3d_scale = 1.0
            win.msaa_3d = Viewport.MSAA_2X

func set_quality(q: int) -> void:
    graphics_quality = clampi(q, 0, 2)
    apply_quality()
    save_game()

func save_game() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("player", "selected_character", selected_character)
    cfg.set_value("player", "coins", coins)
    cfg.set_value("player", "matches_played", matches_played)
    cfg.set_value("player", "story_chapter", story_chapter)
    cfg.set_value("settings", "graphics_quality", graphics_quality)
    cfg.save(SAVE_PATH)

func load_game() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    selected_character = int(cfg.get_value("player", "selected_character", 0))
    coins = int(cfg.get_value("player", "coins", 0))
    matches_played = int(cfg.get_value("player", "matches_played", 0))
    story_chapter = int(cfg.get_value("player", "story_chapter", 1))
    graphics_quality = int(cfg.get_value("settings", "graphics_quality", 1))
    selected_character = clampi(selected_character, 0, characters.size() - 1)
