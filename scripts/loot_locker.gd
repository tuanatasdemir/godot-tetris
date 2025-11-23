extends HTTPRequest

const API_KEY = "dev_403a5207b5714c3fa95d5d54e60ef67b" 
const DEVELOPMENT_MODE = true 
var leaderboard_key = "global_highscore" 
var session_token = "" 
var player_id = ""

signal giris_yapildi
signal skor_yuklendi(data)
signal skor_gonderildi

func _ready():
	use_threads = true

func giris_yap():
	var url = "https://api.lootlocker.io/game/v2/session/guest"
	var headers = ["Content-Type: application/json"]
	
	var body = { "game_key": API_KEY, "game_version": "0.0.0.1", "development_mode": DEVELOPMENT_MODE }
	
	var error = request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	
	if error != OK:
		print("LootLocker Bağlantı Hatası!")

func _on_request_completed(_result, _response_code, _headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	
	if json and json.has("session_token"):
		session_token = json.session_token
		player_id = str(json.player_id)
		print("Online Giriş Başarılı! Player ID: ", player_id)
		emit_signal("giris_yapildi")
		return

	if json and json.has("items"): 
		print("Skorlar İndirildi")
		emit_signal("skor_yuklendi", json.items)
		return

	if json and json.has("rank"): 
		print("Skor Başarıyla Gönderildi!")
		emit_signal("skor_gonderildi")

func skor_gonder(skor, isim):
	if session_token == "": return 
	
	var url = "https://api.lootlocker.io/game/v1/leaderboards/" + leaderboard_key + "/submit"
	var headers = ["Content-Type: application/json", "x-session-token: " + session_token]
	
	oyuncu_ismi_ayarla(isim) 
	
	var body = { "score": skor } 
	request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func oyuncu_ismi_ayarla(isim):
	var _url = "https://api.lootlocker.io/game/v1/player/name"
	var _headers = ["Content-Type: application/json", "x-session-token: " + session_token]
	var _body = { "name": isim }
	
func skorlari_getir():
	if session_token == "": return

	var url = "https://api.lootlocker.io/game/v1/leaderboards/" + leaderboard_key + "/list?count=10"
	var headers = ["Content-Type: application/json", "x-session-token: " + session_token]
	
	request(url, headers, HTTPClient.METHOD_GET)

func isimi_sunucuda_guncelle(yeni_isim):
	if session_token == "": return
	
	print("LootLocker: İsim güncelleniyor -> ", yeni_isim)
	var url = "https://api.lootlocker.io/game/v1/player/name"
	var headers = ["Content-Type: application/json", "x-session-token: " + session_token]
	var body = { "name": yeni_isim }

	request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify(body))
