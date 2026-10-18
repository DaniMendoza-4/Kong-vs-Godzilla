# Este código controla todos los sonidos y músicas del juego
# Se registra como AUTOLOAD con el nombre "Audio" para poder usarlo desde cualquier escena
# Hereda de Node porque no necesita nada de 2D
extends Node

# Carpeta donde están los efectos de sonido
const CARPETA_SFX: String = "res://assets/sonidos/"

# Carpeta donde están las músicas del juego
const CARPETA_MUSICA: String = "res://assets/musica/"

# Extensiones de audio que busca el sistema, en este orden
const EXTENSIONES: Array[String] = ["ogg", "wav", "mp3"]

# Cantidad de efectos de sonido que pueden sonar a la vez
const VOCES: int = 8

# Tabla de efectos de sonido: nombre que usa el código, archivo, volumen (db), segundo donde empieza y duración máxima
const SONIDOS: Dictionary = {
	# Sonido al recoger un diamante
	"diamante": {"rutas": ["diamante"], "db": 3.0, "inicio": 0.05, "max": 0.9},
	# Sonido del salto de Kong
	"salto": {"rutas": ["kong/salto_kong"], "db": 10.0, "inicio": 0.05, "max": 0.4},
	# Sonido cuando Kong recibe daño leve (se prueba con ñ y sin ñ por si el archivo se llama distinto)
	"kong_daño": {"rutas": ["kong/daño_leve_kong", "kong/dano_leve_kong"], "db": 0.5, "inicio": 0.08, "max": 0.75},
	# Sonido de la muerte de Kong
	"kong_muerte": {"rutas": ["kong/daño_muerte_kong", "kong/dano_muerte_kong"], "db": 4.5, "inicio": 0.06, "max": 2.2},
	# Sonido de Kong comiendo un ave
	"comer": {"rutas": ["kong/comer_ave_kong"], "db": 1.0, "inicio": 0.05, "max": 1.0},
	# Sonido de los pinchos
	"pinchos": {"rutas": ["kong/tocar_pinchos_kong"], "db": -1.5, "inicio": 0.07, "max": 0.7},
	# El golpe de Kong usa el mismo archivo dividido en dos partes: el golpe al aire
	"golpe_aire": {"rutas": ["kong/golpe_suelo_kong"], "db": 0.5, "inicio": 0.04, "max": 0.3},
	# y el impacto cuando le da a Godzilla
	"impacto_kong": {"rutas": ["kong/golpe_suelo_kong"], "db": 1.5, "inicio": 0.33, "max": 0.85},
	# Golpe de cola de Godzilla
	"godzilla_cola": {"rutas": ["godzilla/golpe_cola_godzilla"], "db": -6.0, "inicio": 0.0, "max": 1.0},
	# Rayo atómico de Godzilla
	"godzilla_rayo": {"rutas": ["godzilla/aliento_atomico_godzilla"], "db": -1.0, "inicio": 0.03, "max": 2.2},
	# Godzilla recibe daño
	"godzilla_daño": {"rutas": ["godzilla/recibe_daño_godzilla", "godzilla/recibe_dano_godzilla"], "db": -5.0, "inicio": 0.14, "max": 1.1},
	# Muerte de Godzilla
	"godzilla_muerte": {"rutas": ["godzilla/muerte_godzilla"], "db": 2.5, "inicio": 0.03, "max": 2.2},
	# Rugido ocasional de Godzilla mientras camina
	"godzilla_rugido": {"rutas": ["godzilla/rugido_ocacional_godzilla", "godzilla/rugido_ocasional_godzilla"], "db": -4.5, "inicio": 0.06, "max": 3.8},
	# Rugido que suena al ganar el nivel 5
	"rugido_victoria": {"rutas": ["rugido_victoria"], "db": 0.0, "inicio": 0.0, "max": 0.0},
}

# Tabla de músicas de los niveles: volumen, segundo donde empieza y segundo donde termina para repetirse
const MUSICAS: Dictionary = {
	# Música del nivel 1
	"nivel_1": {"db": -1.0, "inicio": 0.21, "fin": 59.35},
	# Música del nivel 2
	"nivel_2": {"db": 0.0, "inicio": 0.0, "fin": 0.0},
	# Música del nivel 3
	"nivel_3": {"db": 6.0, "inicio": 0.1, "fin": 126.78},
	# Música del nivel 4
	"nivel_4": {"db": -1.0, "inicio": 0.02, "fin": 183.0},
	# Música del nivel 5
	"nivel_5": {"db": -5.0, "inicio": 0.05, "fin": 0.0},
}

# Lista de sonidos que usa el juego, sirve para revisar cuáles existen y cuáles faltan
const SONIDOS_USADOS: Array[String] = [
	"diamante", "nivel_completo", "salto", "golpe_aire", "impacto_kong", "kong_daño", "comer",
	"pinchos", "kong_muerte", "godzilla_paso", "godzilla_giro", "godzilla_cola", "godzilla_carga",
	"godzilla_rayo", "godzilla_daño", "godzilla_muerte", "godzilla_rugido", "godzilla_salto",
	"godzilla_aterriza", "impacto_fuerte", "explosion_rayo", "boton_hover", "boton_click",
	"rugido_victoria",
]

# Lista de músicas que usa el juego
const MUSICAS_USADAS: Array[String] = ["musica_inicio", "nivel_1", "nivel_2", "nivel_3", "nivel_4", "nivel_5", "musica_final"]

# Volumen general de los efectos de sonido
var volumen_sfx_db: float = 6.0 #0.0

# Volumen general de la música
var volumen_musica_db: float = 9.0 #-3.0

# Tiempo mínimo entre dos sonidos iguales, evita que se repitan demasiado seguidos
const ESPERA_GENERAL: float = 0.05

# Tiempo mínimo de espera para algunos sonidos en concreto
const ESPERA_MINIMA: Dictionary = {
	"kong_daño": 0.25,
	"godzilla_daño": 0.3,
	"godzilla_paso": 0.12,
	"pinchos": 0.2,
	"godzilla_rugido": 2.0,
}

# Reproductores que se usan para los efectos de sonido
var _voces: Array[AudioStreamPlayer] = []

# Identificador de cada sonido que está sonando
var _ids: Dictionary = {}

# Cuenta de los identificadores creados
var _contador_id: int = 0

# Último momento en que sonó cada efecto
var _ultimo: Dictionary = {}

# Sonidos ya cargados para no buscarlos otra vez
var _cache_sfx: Dictionary = {}

# Reproductor que se usa para la música
var _musica: AudioStreamPlayer

# Nombre de la música que está sonando
var _musica_actual: String = ""

# Indica si la música se tiene que repetir
var _repetir_musica: bool = true

# Segundo donde empieza la música
var _inicio_musica: float = 0.0

# Segundo donde termina la música
var _fin_musica: float = 0.0

# Tween que controla los cambios de volumen de la música
var _tween_musica: Tween

# Tween que controla el temblor de la cámara
var _tween_camara: Tween

# Se ejecuta una sola vez al iniciar el sistema de audio
func _ready() -> void:
	# Hace que el audio siga funcionando aunque el juego esté en pausa
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Crea los reproductores para los efectos de sonido
	for i in VOCES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_voces.append(p)

	# Crea el reproductor de la música
	_musica = AudioStreamPlayer.new()

	# Le pone el volumen inicial a la música
	_musica.volume_db = volumen_musica_db

	# Detecta cuando termina una música
	_musica.finished.connect(_on_musica_terminada)

	# Agrega el reproductor de música como hijo
	add_child(_musica)

	# Desactiva el proceso hasta que haga falta repetir una música
	set_process(false)

	# Si el juego está en modo de prueba, revisa qué sonidos existen
	if OS.is_debug_build():
		_revisar_sonidos()

# Se ejecuta en cada frame, solo mientras hace falta repetir la música
func _process(_delta: float) -> void:
	# Revisa si la música llegó al punto donde tiene que volver a empezar
	if _musica.playing and _fin_musica > 0.0 and _musica.get_playback_position() >= _fin_musica:
		# Vuelve a poner la música en su punto de inicio
		_musica.play(_inicio_musica)

# Función que reproduce un efecto de sonido
func sfx(nombre: String, pitch: float = 1.0, volumen_db: float = 0.0, variacion: float = 0.05) -> void:
	# Busca la información del sonido
	var info: Dictionary = _info_sfx(nombre)

	# Si no encuentra el sonido, no hace nada
	if info.is_empty():
		# Sale de la función
		return

	# Guarda el tiempo actual para controlar que no se repita muy rápido
	var ahora: int = Time.get_ticks_msec()

	# Obtiene el tiempo mínimo de espera de ese sonido
	var espera: float = ESPERA_MINIMA.get(nombre, ESPERA_GENERAL)

	# Si el sonido sonó hace muy poco, no lo vuelve a reproducir
	if _ultimo.has(nombre) and ahora - int(_ultimo[nombre]) < int(espera * 1000.0):
		return

	# Guarda el momento en que sonó
	_ultimo[nombre] = ahora

	# Empieza usando el primer reproductor
	var voz: AudioStreamPlayer = _voces[0]

	# Busca un reproductor que esté libre
	for p in _voces:
		if not p.playing:
			voz = p
			break

	# Le pone el sonido al reproductor
	voz.stream = info["stream"]

	# Cambia un poco el tono para que no suene siempre igual
	voz.pitch_scale = pitch * randf_range(1.0 - variacion, 1.0 + variacion)

	# Calcula el volumen final del sonido
	voz.volume_db = volumen_sfx_db + float(info["db"]) + volumen_db

	# Aumenta el identificador
	_contador_id += 1

	# Guarda el identificador de este sonido
	var id: int = _contador_id
	_ids[voz] = id

	# Reproduce el sonido desde el segundo indicado
	voz.play(float(info["inicio"]))

	# Obtiene la duración máxima del sonido
	var maximo: float = float(info["max"])

	# Si tiene duración máxima, lo corta pasado ese tiempo
	if maximo > 0.0:
		_cortar_despues(voz, id, maximo / voz.pitch_scale)

# Función que devuelve la duración de un efecto de sonido
func duracion_sfx(nombre: String) -> float:
	# Busca la información del sonido
	var info: Dictionary = _info_sfx(nombre)

	# Si el sonido no existe, devuelve cero
	if info.is_empty():
		return 0.0

	# Calcula la duración del archivo quitando el tiempo inicial
	var largo: float = info["stream"].get_length() - float(info["inicio"])

	# Si tiene duración máxima, usa la más corta de las dos
	if float(info["max"]) > 0.0:
		largo = min(largo, float(info["max"]))

	# Devuelve la duración final
	return max(largo, 0.0)

# Función que cambia la música del juego
func musica(nombre: String, repetir: bool = true) -> void:
	# Si ya está sonando esa música, no hace nada
	if nombre == _musica_actual:
		return

	# Guarda el nombre de la música actual
	_musica_actual = nombre

	# Guarda si la música se repite
	_repetir_musica = repetir

	# Busca la información de la música
	var info: Dictionary = _info_musica(nombre)

	# Si había un tween anterior, lo detiene
	if _tween_musica:
		_tween_musica.kill()

	# Crea un tween nuevo para cambiar la música
	_tween_musica = create_tween()

	# Si ya había música sonando, baja el volumen poco a poco
	if _musica.playing:
		_tween_musica.tween_property(_musica, "volume_db", -40.0, 0.5)

	# Cuando termina el fundido empieza la música nueva
	_tween_musica.tween_callback(_empezar_musica.bind(info))

# Función que detiene la música con un fundido
func detener_musica() -> void:
	# Borra el nombre de la música actual
	_musica_actual = ""

	# Indica que la música ya no se repite
	_repetir_musica = false

	# Deja de revisar la repetición de la música
	set_process(false)

	# Si había un tween anterior, lo detiene
	if _tween_musica:
		_tween_musica.kill()

	# Crea un tween nuevo para bajar el volumen
	_tween_musica = create_tween()

	# Baja el volumen poco a poco
	_tween_musica.tween_property(_musica, "volume_db", -40.0, 0.5)

	# Detiene la música cuando termina el fundido
	_tween_musica.tween_callback(_musica.stop)

# Función que hace temblar la cámara
func sacudir_camara(fuerza: float = 3.0, duracion: float = 0.25) -> void:
	# Obtiene la cámara 2D que está usando el juego
	var camara := get_viewport().get_camera_2d()

	# Si no hay cámara, no hace nada
	if camara == null:
		return

	# Si ya había un temblor, lo detiene
	if _tween_camara:
		_tween_camara.kill()

	# Devuelve la cámara a su posición original
	camara.offset = Vector2.ZERO

	# Crea un tween nuevo para el movimiento de la cámara
	_tween_camara = create_tween()

	# Calcula cuántos movimientos tiene el temblor
	var pasos: int = max(1, int(duracion / 0.04))

	# Repite el movimiento durante el tiempo indicado
	for i in pasos:
		# La fuerza del temblor va bajando poco a poco
		var f: float = fuerza * (1.0 - float(i) / pasos)

		# Mueve la cámara a un punto aleatorio
		_tween_camara.tween_property(camara, "offset", Vector2(randf_range(-f, f), randf_range(-f, f)), 0.04)

	# Al final devuelve la cámara a su posición original
	_tween_camara.tween_property(camara, "offset", Vector2.ZERO, 0.04)

# Función interna que empieza a reproducir una música
func _empezar_musica(info: Dictionary) -> void:
	# Detiene cualquier música que estuviera sonando
	_musica.stop()

	# Desactiva el proceso de repetición por ahora
	set_process(false)

	# Si no encontró la música, no hace nada
	if info.is_empty():
		return

	# Pone la música en el reproductor
	_musica.stream = info["stream"]

	# Pone el volumen de la música
	_musica.volume_db = volumen_musica_db + float(info["db"])

	# Guarda el segundo donde empieza
	_inicio_musica = float(info["inicio"])

	# Guarda el segundo donde termina
	_fin_musica = float(info["fin"])

	# Empieza a reproducir la música
	_musica.play(_inicio_musica)

	# Activa el proceso solo si la música tiene un punto para repetirse
	set_process(_fin_musica > 0.0 and _repetir_musica)

# Se ejecuta cuando termina una música
func _on_musica_terminada() -> void:
	# Si la música se tiene que repetir, empieza otra vez
	if _repetir_musica and _musica.stream:
		_musica.play(_inicio_musica)

# Función que corta un sonido pasado el tiempo indicado
func _cortar_despues(voz: AudioStreamPlayer, id: int, tiempo: float) -> void:
	# Espera el tiempo indicado antes de cortar el sonido
	await get_tree().create_timer(max(tiempo - 0.12, 0.0), true, false, true).timeout

	# Si el sonido ya cambió o dejó de sonar, no hace nada
	if int(_ids.get(voz, -1)) != id or not voz.playing:
		return

	# Crea un tween para bajar el volumen
	var t := create_tween()

	# Baja el volumen poco a poco
	t.tween_property(voz, "volume_db", -40.0, 0.12)

	# Detiene el sonido cuando termina el fundido
	t.tween_callback(_parar_si_es_el_mismo.bind(voz, id))

# Función que detiene un sonido solo si sigue siendo el mismo
func _parar_si_es_el_mismo(voz: AudioStreamPlayer, id: int) -> void:
	# Comprueba que el identificador sea el mismo
	if int(_ids.get(voz, -1)) == id:
		# Detiene el reproductor
		voz.stop()

# Función que busca la información de un efecto de sonido
func _info_sfx(nombre: String) -> Dictionary:
	# Si ya lo buscó antes, usa la información guardada
	if _cache_sfx.has(nombre):
		return _cache_sfx[nombre]

	# Crea un diccionario vacío para guardar la información
	var info: Dictionary = {}

	# Primero lo busca dentro de la tabla SONIDOS
	if SONIDOS.has(nombre):
		# Obtiene los datos del sonido
		var datos: Dictionary = SONIDOS[nombre]

		# Recorre las posibles rutas del archivo
		for ruta in datos["rutas"]:
			# Busca el archivo de sonido
			var hallado: Dictionary = _buscar(CARPETA_SFX + String(ruta))

			# Si lo encuentra, guarda su información
			if not hallado.is_empty():
				info = {"stream": hallado["stream"], "db": datos["db"], "inicio": datos["inicio"], "max": datos["max"]}
				break

	# Si no estaba en la tabla, busca el archivo directamente por su nombre
	if info.is_empty():
		var directo: Dictionary = _buscar(CARPETA_SFX + nombre)

		# Si lo encuentra, guarda su información
		if not directo.is_empty():
			info = {"stream": directo["stream"], "db": 0.0, "inicio": 0.0, "max": 0.0}

	# Guarda la información para no buscarla otra vez
	_cache_sfx[nombre] = info

	# Devuelve la información del sonido
	return info

# Función que busca la información de una música
func _info_musica(nombre: String) -> Dictionary:
	# Busca el archivo de música en su carpeta
	var hallado: Dictionary = _buscar(CARPETA_MUSICA + nombre)

	# Si no lo encuentra, devuelve un diccionario vacío
	if hallado.is_empty():
		return {}

	# Guarda la información básica de la música
	var info: Dictionary = {"stream": hallado["stream"], "db": 0.0, "inicio": 0.0, "fin": 0.0}

	# Si no es OGG y está en la tabla de músicas, usa su configuración
	if hallado["ext"] != "ogg" and MUSICAS.has(nombre):
		# Obtiene los datos de la música
		var datos: Dictionary = MUSICAS[nombre]

		# Guarda el volumen
		info["db"] = datos["db"]

		# Guarda el segundo donde empieza
		info["inicio"] = datos["inicio"]

		# Guarda el segundo donde termina
		info["fin"] = datos["fin"]

	# Devuelve la información de la música
	return info

# Función que busca un archivo de audio probando sus extensiones
func _buscar(ruta_sin_extension: String) -> Dictionary:
	# Recorre todas las extensiones
	for ext in EXTENSIONES:
		# Crea la ruta completa del archivo
		var ruta: String = "%s.%s" % [ruta_sin_extension, ext]

		# Comprueba si el archivo existe
		if ResourceLoader.exists(ruta):
			# Carga el archivo
			var stream = load(ruta)

			# Si se cargó bien, devuelve la información
			if stream != null:
				return {"stream": stream, "ext": ext}

	# Si no encontró nada, devuelve un diccionario vacío
	return {}

# Función que revisa qué sonidos y músicas existen
func _revisar_sonidos() -> void:
	# Efectos que no se encontraron
	var faltan_sfx: Array[String] = []

	# Recorre todos los sonidos que usa el juego
	for n in SONIDOS_USADOS:
		# Si no lo encuentra, lo agrega a la lista de faltantes
		if _info_sfx(n).is_empty():
			faltan_sfx.append(n)

	# Músicas que no se encontraron
	var faltan_musica: Array[String] = []

	# Recorre todas las músicas que usa el juego
	for n in MUSICAS_USADAS:
		# Si no la encuentra, la agrega a la lista de faltantes
		if _info_musica(n).is_empty():
			faltan_musica.append(n)

	# Muestra en la pestaña Salida cuántos efectos se encontraron
	print("Audio: %d de %d efectos encontrados." % [SONIDOS_USADOS.size() - faltan_sfx.size(), SONIDOS_USADOS.size()])

	# Muestra cuáles efectos faltan
	if faltan_sfx.size() > 0:
		print("Audio: efectos que faltan (no suenan): ", ", ".join(faltan_sfx))

	# Muestra en la pestaña Salida cuántas músicas se encontraron
	print("Audio: %d de %d musicas encontradas." % [MUSICAS_USADAS.size() - faltan_musica.size(), MUSICAS_USADAS.size()])

	# Muestra cuáles músicas faltan
	if faltan_musica.size() > 0:
		print("Audio: musicas que faltan: ", ", ".join(faltan_musica))
