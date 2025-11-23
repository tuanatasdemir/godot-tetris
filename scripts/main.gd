extends Node2D

@export var tetromino_scene: PackedScene
@onready var oyun_sahnesi_kutusu = $OyunSahnesi 
@onready var sabit_bloklar_kutusu = $OyunSahnesi/SabitBloklar

@onready var menu_ekrani = $MenuKatmani/MenuEkrani
@onready var basla_buton = $MenuKatmani/MenuEkrani/BaslaButon
@onready var puan_label = $MenuKatmani/PuanLabel
@onready var kayit_ekrani = $MenuKatmani/KayitEkrani
@onready var isim_input = $MenuKatmani/KayitEkrani/ColorRect/IsimInput
@onready var ayarlar_kutusu = $MenuKatmani/AyarlarKutusu
@onready var lider_tablosu_kutusu = $MenuKatmani/LiderTablosuKutusu
@onready var skor_tablosu_grid = $MenuKatmani/LiderTablosuKutusu/SkorTablosuGrid
@onready var durdur_buton = $MenuKatmani/DurdurButon
@onready var muzik_calar = $MuzikCalar
@onready var ses_slider = $MenuKatmani/AyarlarKutusu/SesSlider
@onready var loot_locker = $LootLocker
@onready var dokunmatik_kontroller = $MenuKatmani/DokunmatikKontroller

const GENISLIK = 13
const YUKSEKLIK = 27
const BLOK_BOYUTU = 24
const KAYIT_DOSYASI = "user://tetris_leaderboard.save" 
const AYAR_KAYIT_DOSYASI = "user://settings.save"
const MAX_TABLO_BOYUTU = 5
const SABIT_HIZ = 0.8 

var skor_tablosu = [] 
var grid = []
var puan = 0
var level = 1
var oyun_bitti = false
var hedef_puan = 1000
var oyun_duraklatildi = false

var ayarlar = {
	"master_volume": 1.0
}
var white_block_texture: ImageTexture
var sfx_bus_index
var music_bus_index

func _ready() -> void:
	var image = Image.create(BLOK_BOYUTU, BLOK_BOYUTU, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	white_block_texture = ImageTexture.create_from_image(image)
	
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	music_bus_index = AudioServer.get_bus_index("Music")
	
	kayit_ekrani.visible = false
	ayarlar_kutusu.visible = false
	lider_tablosu_kutusu.visible = false
	durdur_buton.visible = false 
	if dokunmatik_kontroller: 
		dokunmatik_kontroller.visible = false
		
	ayarlari_yukle()
	skor_tablosunu_yukle()
	menu_goster("TETRON", "START")
	
	loot_locker.giris_yapildi.connect(_on_online_giris_yapildi)
	loot_locker.skor_yuklendi.connect(_on_online_skorlar_geldi)
	loot_locker.giris_yap()

func _on_online_giris_yapildi():
	loot_locker.skorlari_getir()

func _on_online_skorlar_geldi(items):
	for child in skor_tablosu_grid.get_children():
		child.queue_free()
		
	baslik_ekle("RANK")
	baslik_ekle("PLAYER") 
	baslik_ekle("SCORE")
	
	for item in items:
		hucre_ekle(str(item.rank), Color.YELLOW)
		var ad = "Bilinmeyen"
		if item.has("player") and item.player.has("name"):
			ad = item.player.name
		elif item.has("player") and item.player.has("id"):
			ad = str(item.player.id)
		hucre_ekle(ad, Color.WHITE)
		hucre_ekle(str(item.score), Color.GREEN)
		
func yeni_oyun_baslat():
	get_tree().paused = false
	oyun_bitti = false
	oyun_duraklatildi = false
	puan = 0
	level = 1
	hedef_puan = 1000
	puan_label.text = "SCORE: 0"
	puan_label.visible = true
	durdur_buton.visible = true
	if dokunmatik_kontroller: 
		dokunmatik_kontroller.visible = true
		
	grid = []
	for x in range(GENISLIK):
		grid.append([]) 
		for y in range(YUKSEKLIK):
			grid[x].append(null)
			
	for child in sabit_bloklar_kutusu.get_children():
		child.queue_free()
		
	spawn_piece()

func spawn_piece():
	if oyun_bitti: return
	var new_piece = tetromino_scene.instantiate()
	oyun_sahnesi_kutusu.add_child(new_piece)
	new_piece.hizi_ayarla(SABIT_HIZ)
	new_piece.zorluk_seviyesini_ayarla(level)
	new_piece.set_texture(white_block_texture)
	new_piece.baslat(self)
	
	var spawn_x = (GENISLIK / 2) * BLOK_BOYUTU
	new_piece.position = Vector2(spawn_x, -BLOK_BOYUTU * 2) 
	
	if not new_piece.is_valid_position(new_piece.position):
		oyun_bitti_islemleri()
		new_piece.queue_free()

func oyun_bitti_islemleri():
	get_tree().paused = false
	$OyunBittiSesi.play()
	oyun_bitti = true
	durdur_buton.visible = false 
	puan_label.visible = false
	
	if dokunmatik_kontroller:
		dokunmatik_kontroller.visible = false
		
	# --- BU KISMI SİLDİK ---
	# var listeye_girer = false
	# if skor_tablosu.size() < MAX_TABLO_BOYUTU:
	# 	listeye_girer = true
	# else:
	# 	if puan > skor_tablosu.back()["skor"]:
	# 		listeye_girer = true
	# -----------------------
			
	if true: # Test için
		kayit_ekrani.visible = true
		menu_ekrani.visible = false
		isim_input.text = ""
	else:
		await get_tree().create_timer(1.0).timeout
		menu_goster("GAME OVER \nSCORE: " + str(puan), "PLAY AGAIN")

func _on_kaydet_buton_pressed():
	var oyuncu_ismi = isim_input.text
	if oyuncu_ismi == "": 
		oyuncu_ismi = "ANONİM"

	var yeni_kayit = {
		"isim": oyuncu_ismi,
		"skor": puan
	}
	
	skor_tablosu.append(yeni_kayit)
	skor_tablosu.sort_custom(func(a, b): return a["skor"] > b["skor"])
	
	if skor_tablosu.size() > MAX_TABLO_BOYUTU:
		skor_tablosu.pop_back()
	
	dosyaya_kaydet()

	loot_locker.isimi_sunucuda_guncelle(oyuncu_ismi)
	await get_tree().create_timer(0.5).timeout

	loot_locker.skor_gonder(puan, oyuncu_ismi)
	await get_tree().create_timer(1.0).timeout

	loot_locker.skorlari_getir()
	kayit_ekrani.visible = false
	menu_goster("Add to the List!", "PLAY AGAIN")
	
func dosyaya_kaydet():
	var dosya = FileAccess.open(KAYIT_DOSYASI, FileAccess.WRITE)
	dosya.store_var(skor_tablosu) 
	dosya.close()
	tabloyu_ekrana_yaz()

func skor_tablosunu_yukle():
	if FileAccess.file_exists(KAYIT_DOSYASI):
		var dosya = FileAccess.open(KAYIT_DOSYASI, FileAccess.READ)
		skor_tablosu = dosya.get_var(true)
		dosya.close()
	else:
		skor_tablosu = []
	tabloyu_ekrana_yaz()

func tabloyu_ekrana_yaz():
	for child in skor_tablosu_grid.get_children():
		child.queue_free()
	
	baslik_ekle("RANK")
	baslik_ekle("NAME")
	baslik_ekle("SCORE")
	
	var sira = 1
	for kayit in skor_tablosu:
		hucre_ekle(str(sira) + ".", Color.YELLOW)
		hucre_ekle(str(kayit["isim"]), Color.WHITE)
		hucre_ekle(str(kayit["skor"]), Color.GREEN)
		sira += 1

func hucre_ekle(yazi, renk):
	var lbl = Label.new()
	lbl.text = yazi
	lbl.modulate = renk
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skor_tablosu_grid.add_child(lbl)

func baslik_ekle(yazi):
	var lbl = Label.new()
	lbl.text = yazi
	lbl.modulate = Color.ORANGE
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skor_tablosu_grid.add_child(lbl)

func menu_goster(baslik, buton_metni):
	menu_ekrani.visible = true
	$MenuKatmani/MenuEkrani/Label.text = baslik
	basla_buton.text = buton_metni

func _on_basla_buton_pressed():
	menu_ekrani.visible = false
	durdur_buton.visible = true 
	yeni_oyun_baslat()
	
func puan_ekle(satir_sayisi):
	var kazanilan_puan = 0
	match satir_sayisi:
		1: kazanilan_puan = 100
		2: kazanilan_puan = 300
		3: kazanilan_puan = 500
		4: kazanilan_puan = 800
		_: kazanilan_puan = 1000
	puan += kazanilan_puan * level
	puan_label.text = "SCORE: " + str(puan)
	if puan >= hedef_puan:
		level_atla()

func level_atla():
	level += 1
	hedef_puan = puan + (level * 1500) 
	print("LEVEL PASSED: ", level)

func parcayi_kilitle(tetromino_parcasi):
	var bloklar = tetromino_parcasi.get_children()
	for blok in bloklar:
		if blok is Sprite2D and blok.visible:
			var yerel_pos = tetromino_parcasi.position + blok.position
			var grid_x = floor(yerel_pos.x / BLOK_BOYUTU)
			var grid_y = floor(yerel_pos.y / BLOK_BOYUTU)
			
			if grid_x >= 0 and grid_x < GENISLIK and grid_y < YUKSEKLIK and grid_y >= 0:
				var kayit_rengi = blok.modulate
				if kayit_rengi == Color(0, 0, 0) or kayit_rengi.a == 0: kayit_rengi = Color.WHITE
				grid[grid_x][grid_y] = kayit_rengi
				blok.get_parent().remove_child(blok)
				sabit_bloklar_kutusu.add_child(blok)
				blok.position = Vector2(grid_x * BLOK_BOYUTU, grid_y * BLOK_BOYUTU)
				
	tetromino_parcasi.queue_free()
	satirlari_kontrol_et_ve_temizle()
	spawn_piece()

func satirlari_kontrol_et_ve_temizle():
	var y_hedef = YUKSEKLIK - 1
	var temizlenen_var = false
	var temizlenen_satir_sayisi = 0
	for y_kaynak in range(YUKSEKLIK - 1, -1, -1):
		var satir_dolu = true
		for x in range(GENISLIK):
			if grid[x][y_kaynak] == null:
				satir_dolu = false
				break
		if not satir_dolu:
			if y_hedef != y_kaynak:
				for x in range(GENISLIK):
					grid[x][y_hedef] = grid[x][y_kaynak]
			y_hedef -= 1
		else:
			temizlenen_var = true
			temizlenen_satir_sayisi += 1
	while y_hedef >= 0:
		for x in range(GENISLIK):
			grid[x][y_hedef] = null
		y_hedef -= 1
	if temizlenen_var:
		puan_ekle(temizlenen_satir_sayisi)
		$SatirSilmeSesi.play()
		ekrani_temizle_ve_ciz()

func ekrani_temizle_ve_ciz():
	for child in sabit_bloklar_kutusu.get_children(): child.queue_free()
	await get_tree().process_frame
	for x in range(GENISLIK):
		for y in range(YUKSEKLIK):
			var hucre_verisi = grid[x][y]
			if hucre_verisi != null:
				var blok = Sprite2D.new()
				blok.texture = white_block_texture
				blok.centered = false
				if hucre_verisi is Color: blok.modulate = hucre_verisi
				else: blok.modulate = Color.WHITE
				blok.position = Vector2(x * BLOK_BOYUTU, y * BLOK_BOYUTU)
				sabit_bloklar_kutusu.add_child(blok)

func _on_ayarlar_buton_pressed() -> void:
	ayarlar_kutusu.visible = true

func _on_kapat_buton_pressed() -> void:
	ayarlar_kutusu.visible = false

func _on_skor_tablosu_ac_buton_pressed() -> void:
	tabloyu_ekrana_yaz()
	lider_tablosu_kutusu.visible = true
	ayarlar_kutusu.visible = false
	
func _on_tablo_kapat_buton_pressed() -> void:
	lider_tablosu_kutusu.visible = false
	if oyun_duraklatildi or menu_ekrani.visible:
		ayarlar_kutusu.visible = true
		
func _on_durdur_buton_pressed() -> void:
	if oyun_bitti: return
	
	oyun_duraklatildi = !oyun_duraklatildi 
	
	if oyun_duraklatildi:
		get_tree().paused = true 
		durdur_buton.text = "CONTINUE"
		ayarlar_kutusu.visible = true 
	else:
		get_tree().paused = false 
		durdur_buton.text = "PAUSE"
		ayarlar_kutusu.visible = false
		lider_tablosu_kutusu.visible = false
		
func _on_ses_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(value))
	ayarlar["master_volume"] = value
	ayarlari_kaydet()
	
func play_land_sound():
	$InmeSesi.play()

func ayarlari_yukle():
	if FileAccess.file_exists(AYAR_KAYIT_DOSYASI):
		var dosya = FileAccess.open(AYAR_KAYIT_DOSYASI, FileAccess.READ)
		var yuklenen_ayarlar = dosya.get_var(true)
		dosya.close() 

		if yuklenen_ayarlar is Dictionary:
			ayarlar = yuklenen_ayarlar
	
	var sfx_vol = ayarlar.get("master_volume", 1.0)
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(sfx_vol))
	
	if ses_slider:
		ses_slider.value = sfx_vol
		
func ayarlari_kaydet():
	var dosya = FileAccess.open(AYAR_KAYIT_DOSYASI, FileAccess.WRITE)
	dosya.store_var(ayarlar)
	dosya.close()
