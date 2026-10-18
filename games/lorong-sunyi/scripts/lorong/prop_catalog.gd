extends RefCounted
class_name LorongPropCatalog

const PROPS := [
	{
		"id": "bangku",
		"name": "Bangku",
		"region": [400, 57, 18, 23],
		"position": Vector2(300, 520),
		"scale": 3.0,
		"collision_radius": 22.0,
		"action": "clue",
		"clue_key": "bangku",
		"clue_value": "4",
		"description": "Bangku pendek dengan goresan baru di bawah dudukannya.",
		"first_text": "Di bawah bangku tergores angka 4. Kayunya masih terasa hangat.",
		"repeat_text": "Goresan angka 4 itu belum berubah. Serpihan kayu menempel di jarimu.",
		"fear_on_first": 0.75
	},
	{
		"id": "laci",
		"name": "Laci meja",
		"region": [512, 23, 50, 25],
		"position": Vector2(450, 452),
		"scale": 2.25,
		"collision_radius": 25.0,
		"action": "key",
		"description": "Laci berat dengan satu tarikan yang masih bisa digerakkan.",
		"first_text": "Laci seret terbuka. Sebuah kunci kecil terbungkus kain lembap.",
		"repeat_text": "Laci itu sudah kosong. Kunci kecilnya ada padamu.",
		"fear_on_first": 0.65
	},
	{
		"id": "lemari",
		"name": "Lemari tua",
		"region": [0, 10, 25, 38],
		"open_region": [32, 10, 25, 38],
		"position": Vector2(1035, 485),
		"scale": 2.2,
		"collision_radius": 27.0,
		"action": "closet",
		"description": "Lemari tinggi. Dari dalamnya terdengar kain bergesek.",
		"first_text": "Kunci kecil berputar. Di balik mantel terselip angka 1.",
		"repeat_text": "Pintu lemari terbuka sedikit. Ruang di dalamnya cukup untuk bersembunyi.",
		"failure_text": "Gemboknya tidak bergerak. Kunci kecil mungkin cocok.",
		"fear_on_first": 0.5
	},
	{
		"id": "meja",
		"name": "Meja panjang",
		"region": [48, 62, 44, 18],
		"position": Vector2(675, 535),
		"scale": 2.8,
		"collision_radius": 31.0,
		"action": "order",
		"description": "Meja kosong dengan catatan terlipat di tepinya.",
		"first_text": "Catatan: ‘Bangku. Lemari. Cahaya.’ Urutkan tanda-tandanya sesuai nama benda.",
		"repeat_text": "Urutannya tetap sama: bangku, lemari, lalu cahaya.",
		"fear_on_first": 0.4
	},
	{
		"id": "lampu",
		"name": "Lampu lantai",
		"region": [224, 85, 16, 42],
		"position": Vector2(910, 475),
		"scale": 1.9,
		"collision_radius": 18.0,
		"action": "lamp",
		"clue_key": "lampu",
		"clue_value": "7",
		"description": "Saklarnya longgar; cahaya mungkin mengubah apa yang terlihat.",
		"first_text": "Lampu menyala. Di dinding, bayangan membentuk angka 7.",
		"repeat_text": "Saklar lampu berbunyi pelan. Angka 7 tetap tertinggal di ingatanmu.",
		"fear_on_first": 0.85
	},
	{
		"id": "jam",
		"name": "Jam bandul",
		"region": [256, 88, 21, 40],
		"position": Vector2(365, 330),
		"scale": 1.65,
		"collision_radius": 18.0,
		"action": "examine",
		"description": "Jam tua berhenti, tetapi bunyi detiknya belum hilang.",
		"first_text": "Jam mati pada pukul 02:14. Detik terakhirnya masih terdengar.",
		"repeat_text": "Jarumnya tidak bergerak. Bunyi detik itu datang dari arah lain.",
		"fear_on_first": 0.25
	},
	{
		"id": "potret",
		"name": "Potret tanpa wajah",
		"region": [320, 96, 27, 25],
		"position": Vector2(830, 330),
		"scale": 1.9,
		"collision_radius": 16.0,
		"action": "examine",
		"description": "Bingkai tua menampilkan sosok yang wajahnya tidak tergambar.",
		"first_text": "Sosok dalam potret tidak punya wajah. Tatapannya tetap mengikutimu.",
		"repeat_text": "Potret itu masih kosong. Sekarang bingkainya tampak sedikit miring.",
		"fear_on_first": 0.45
	},
	{
		"id": "pintu",
		"name": "Pintu lorong",
		"region": [240, 130, 32, 46],
		"position": Vector2(640, 218),
		"scale": 2.2,
		"collision_radius": 0.0,
		"action": "door",
		"description": "Pintu tertutup menuju lorong yang seharusnya berada di balik dinding.",
		"first_text": "Kunci angka tiga digit. Bangku, lemari, dan cahaya menyimpan urutannya.",
		"repeat_text": "Pintu itu menunggu tiga angka dan urutan yang benar.",
		"fear_on_first": 0.0
	}
]


static func all_props() -> Array:
	return PROPS.duplicate(true)


static func prop_ids() -> Array[String]:
	var result: Array[String] = []
	for item: Dictionary in PROPS:
		result.append(str(item.id))
	return result
