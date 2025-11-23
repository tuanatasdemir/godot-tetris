extends Node2D

const BLOK_BOYUTU = 24
const SERI_INIS_HIZI = 0.05 
var asagi_sayac = 0.0
var main_scene 

var dusme_hizi = 1.0 
static var onceki_sekil = ""

var guncel_level = 1
var tum_sekiller = [] 
var adil_torba = [] 

const SEKILLER = {
	"I": [Vector2(0, 1), Vector2(1, 1), Vector2(2, 1), Vector2(3, 1)],
	"O": [Vector2(1, 0), Vector2(2, 0), Vector2(1, 1), Vector2(2, 1)],
	"T": [Vector2(1, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)],
	"L": [Vector2(2, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)],
	"J": [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)],
	"S": [Vector2(1, 0), Vector2(2, 0), Vector2(0, 1), Vector2(1, 1)],
	"Z": [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(2, 1)],
	
	"BigT": [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(1, 1)],
	"BigJ": [Vector2(0, 2), Vector2(1, 0), Vector2(1, 1), Vector2(1, 2)],
	"BigS": [Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(0, 2)],
	"TinyT": [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(1, 1)], 
	"BigL": [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(1, 2)]
}

var torba = []

var block_texture: ImageTexture # Main'den gelen dokuyu burada tutacağız
func set_texture(tex: ImageTexture):
	block_texture = tex
	
func _ready():
	randomize()
	$Timer.wait_time = dusme_hizi
	tum_sekiller = SEKILLER.keys().duplicate()

func zorluk_seviyesini_ayarla(level_no):
	guncel_level = level_no


func siradaki_parcayi_sec():
	var secilen_parca = ""

	match guncel_level:
		1, 2, 3:
			if adil_torba.size() == 0:
				adil_torba = tum_sekiller.duplicate()
				adil_torba.shuffle()
			secilen_parca = adil_torba.pop_back()
		
		_:
			var zalim_torba = tum_sekiller.duplicate()
			var zorluk_katsayisi = int((guncel_level - 1) / 3) 
			
			for i in range(zorluk_katsayisi):
				zalim_torba.append("S")
				zalim_torba.append("Z")

			secilen_parca = zalim_torba.pick_random()
	return secilen_parca
	
func hizi_ayarla(yeni_hiz):
	dusme_hizi = yeni_hiz
	$Timer.wait_time = dusme_hizi

func torbayi_doldur():
	torba = SEKILLER.keys().duplicate()
	torba.shuffle()

func baslat(main_ref):
	main_scene = main_ref
	var siradaki_sekil = ""

	while true:
		siradaki_sekil = siradaki_parcayi_sec()
		
		if siradaki_sekil != onceki_sekil:
			break
	onceki_sekil = siradaki_sekil
	
	print("Gelen Parça: ", siradaki_sekil, " | Level: ", guncel_level)
	sekil_olustur(siradaki_sekil)

func sekil_olustur(tip):
	var koordinatlar = SEKILLER[tip]
	var renk = Color.WHITE
	
	match tip:
		"I": renk = Color.html("#56B4E9")
		"O": renk = Color.html("#F0E442")
		"T": renk = Color.html("#CC79A7")
		"L": renk = Color.html("#FF6F00") 
		"J": renk = Color.html("#0072B2")
		"S": renk = Color.html("#009E73")
		"Z": renk = Color.html("#D55E00")
		
		"BigT": renk = Color.html("#D55E00") 
		"BigJ": renk = Color.html("#005599") 
		"BigS": renk = Color.html("#007755") 
		"TinyT": renk = Color.html("#AA4499") 
		"BigL": renk = Color.html("#DDAA33") 

	var bloklar = get_children()
	for child in bloklar:
		if child is Sprite2D: child.visible = false

	var blok_index = 0
	for child in bloklar:
		if child is Sprite2D:
			if blok_index >= koordinatlar.size(): break
			
			child.visible = true
			child.position = koordinatlar[blok_index] * BLOK_BOYUTU
			
			#var image = Image.create(BLOK_BOYUTU, BLOK_BOYUTU, false, Image.FORMAT_RGBA8)
			#image.fill(Color.WHITE)
			#var tex = ImageTexture.create_from_image(image)
			child.texture = block_texture
			
			child.self_modulate = Color.WHITE
			child.modulate = renk
			
			blok_index += 1

func _on_timer_timeout() -> void:
	asagi_ilerle()

func is_valid_position(yeni_pozisyon):
	if main_scene == null: return false
	for child in get_children():
		if child is Sprite2D:
			if not child.visible: continue
			
			var hedef_pos = yeni_pozisyon + child.position
			var grid_x = floor(hedef_pos.x / BLOK_BOYUTU)
			var grid_y = floor(hedef_pos.y / BLOK_BOYUTU)
			
			if grid_x < 0 or grid_x >= main_scene.GENISLIK: return false
			if grid_y >= main_scene.YUKSEKLIK: return false
			
			if grid_y >= 0:
				if main_scene.grid[grid_x][grid_y] != null: return false
	return true

func _process(delta):
	if Input.is_action_just_pressed("move_left"):
		if is_valid_position(position + Vector2(-BLOK_BOYUTU, 0)): position.x -= BLOK_BOYUTU
	if Input.is_action_just_pressed("move_right"):
		if is_valid_position(position + Vector2(BLOK_BOYUTU, 0)): position.x += BLOK_BOYUTU
	if Input.is_action_just_pressed("move_down"):
		asagi_ilerle()
		asagi_sayac = 0.0
	if Input.is_action_pressed("move_down"):
		asagi_sayac += delta
		if asagi_sayac > SERI_INIS_HIZI:
			asagi_ilerle()
			asagi_sayac = 0.0
	if Input.is_action_just_pressed("switch"): 
		dondur()

func asagi_ilerle():
	var hedef = position + Vector2(0, BLOK_BOYUTU)
	if is_valid_position(hedef):
		position = hedef
		$Timer.start()
		return true
	else:
		main_scene.play_land_sound()
		set_process(false)
		$Timer.stop()
		if main_scene != null: main_scene.parcayi_kilitle(self)
		return false

func dondur():
	$DonmeSesi.play()
	var sprite_bloklar = []
	for child in get_children():
		if child is Sprite2D and child.visible: sprite_bloklar.append(child)
			
	if sprite_bloklar.size() < 1: return

	var eski_pozisyonlar = []
	for blok in sprite_bloklar: eski_pozisyonlar.append(blok.position)
	
	var pivot = sprite_bloklar[1].position
	if sprite_bloklar[0].modulate == Color.html("#F0E442"): return

	for blok in sprite_bloklar:
		var rel_pos = blok.position - pivot
		var yeni_rel_pos = Vector2(-rel_pos.y, rel_pos.x)
		blok.position = pivot + yeni_rel_pos
		
	if not is_valid_position(position):
		if is_valid_position(position + Vector2(BLOK_BOYUTU, 0)): position.x += BLOK_BOYUTU
		elif is_valid_position(position + Vector2(-BLOK_BOYUTU, 0)): position.x -= BLOK_BOYUTU
		else:
			for i in range(sprite_bloklar.size()): sprite_bloklar[i].position = eski_pozisyonlar[i]
