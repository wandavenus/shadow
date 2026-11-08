extends RefCounted
class_name LorongVillageCatalog

const VILLAGERS := [
	{
		"id": "pak_ranu",
		"name": "Pak Ranu",
		"role": "petani",
		"species": "goat",
		"sprite": "pak-ranu-goat",
		"tagline": "PETANI",
		"position": Vector2(925.0, 420.0),
		"routine_points": [Vector2(925.0, 420.0), Vector2(958.0, 438.0)],
		"routine_speed": 14.0,
	},
	{
		"id": "bu_sari",
		"name": "Bu Sari",
		"role": "pemilik kedai",
		"species": "cat",
		"sprite": "bu-sari-cat",
		"tagline": "PEMILIK KEDAI",
		"position": Vector2(250.0, 390.0),
		"routine_points": [],
		"routine_speed": 0.0,
	},
	{
		"id": "nara",
		"name": "Nara",
		"role": "tetangga pekebun",
		"species": "rabbit",
		"sprite": "nara-rabbit",
		"tagline": "PEKEBUN",
		"position": Vector2(720.0, 382.0),
		"routine_points": [],
		"routine_speed": 0.0,
	},
	{
		"id": "pak_jati",
		"name": "Pak Jati",
		"role": "perajin anyaman",
		"species": "bear",
		"sprite": "pak-jati-bear",
		"tagline": "PERAJIN ANYAMAN",
		"position": Vector2(1010.0, 565.0),
		"routine_points": [],
		"routine_speed": 0.0,
	},
	{
		"id": "lio",
		"name": "Lio",
		"role": "anak tetangga",
		"species": "dog",
		"sprite": "lio-dog",
		"tagline": "ANAK TETANGGA",
		"position": Vector2(520.0, 555.0),
		"routine_points": [Vector2(520.0, 555.0), Vector2(550.0, 542.0)],
		"routine_speed": 18.0,
	},
]

const WORLD_OBJECTS := [
	{
		"id": "keranjang_sayur",
		"name": "Keranjang sayur",
		"kind": "basket",
		"position": Vector2(882.0, 495.0),
		"color": Color(0.62, 0.37, 0.20, 1.0),
	},
	{
		"id": "bunga_kecil",
		"name": "Bunga kecil",
		"kind": "flower",
		"position": Vector2(610.0, 510.0),
		"color": Color(0.94, 0.72, 0.79, 1.0),
	},
]


static func all_villagers() -> Array:
	return VILLAGERS.duplicate(true)


static func all_world_objects() -> Array:
	return WORLD_OBJECTS.duplicate(true)


static func villager_ids() -> Array[String]:
	var result: Array[String] = []
	for villager: Dictionary in VILLAGERS:
		result.append(str(villager.id))
	return result


static func world_object_ids() -> Array[String]:
	var result: Array[String] = []
	for world_object: Dictionary in WORLD_OBJECTS:
		result.append(str(world_object.id))
	return result
