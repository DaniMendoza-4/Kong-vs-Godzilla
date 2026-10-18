# Este código controla el juego completo: los niveles, la vida de Kong y los diamantes
# También se encarga de reiniciar los niveles y pasar al siguiente cuando se recogen todos los diamantes
# Hereda de Node2D
extends Node2D

# Lista de escenas de los niveles, se asignan desde el inspector de Godot
@export var niveles: Array[PackedScene]

# Escena que se muestra al terminar el nivel 5 (la pantalla de ¡GANASTE! con sus botones)
# Si se deja vacía, solo se muestra el mensaje de texto
@export var escena_final: PackedScene

# Escena de la pantalla de inicio (se abre con "Salir al menú" en la pausa)
# Si se deja vacía, se usa la ruta de abajo
@export var escena_inicio: PackedScene
# Ruta de respaldo de la pantalla de inicio
const RUTA_INICIO_RESPALDO: String = "res://ecenas/inicio/inicio.tscn"

# Si está activado, al presionar Escape el juego se pausa y aparece el menú de pausa
@export var permitir_pausa: bool = true

# Segundos que Kong celebra (animación de victoria y rugido) antes de que aparezca la escena final
# OJO: si cambié este valor en el Inspector, ahí también tiene que decir 3
@export var segundos_celebracion: float = 3.0

# Si está activado, al empezar cada nivel aparece un letrero grande con su número y nombre
@export var mostrar_titulo_de_nivel: bool = true

# Nombre que aparece debajo del número en el letrero de cada nivel (el primero es el nivel 1)
@export var nombres_niveles: Array[String] = ["LA CIUDAD", "LA FÁBRICA", "LA ARENA", "EL BOSQUE", "EL VOLCÁN - ¡GODZILLA!"]

# Si está activado, al morir Kong vuelve al nivel 1, si no, reinicia el nivel actual
@export var volver_al_nivel_1_al_morir: bool = true

# Si está activado, al morir en un nivel que no es el 1 aparece un mensaje
# que pregunta si se quiere repetir el nivel (Sí / No)
@export var preguntar_al_morir: bool = true

# Si está activado, al responder No se cierra el juego
# Si está desactivado, al responder No se empieza otra vez desde el nivel 1
@export var cerrar_juego_al_decir_no: bool = false

# Si está activado, Kong empieza cada nivel con el 100% de vida
# Si está desactivado, conserva la vida que tenía del nivel anterior
@export var vida_al_100_en_cada_nivel: bool = true

# Cantidad de diamantes que se necesitan para completar cada nivel
# Nivel 1 = 4, nivel 2 = 8, nivel 3 = 12, nivel 4 = 16 y nivel 5 = 20
const DIAMANTES_POR_NIVEL: int = 4

# Cantidad total de niveles que tiene el juego
const NIVELES_TOTALES: int = 5

# Tiempo de espera entre niveles para que se alcance a ver el contador completo
const PAUSA_ENTRE_NIVELES: float = 0.6

# Guarda el número del nivel en el que está Kong
var _nivel_actual: int = 1

# Guarda la referencia al nivel que está cargado en la escena
var _nivel_instanciado: Node

# Guarda el mensaje de "repetir nivel" y sus botones mientras están en pantalla
var _menu_muerte: CanvasLayer
var _boton_si: Button
var _boton_no: Button

# Menú de pausa
var _menu_pausa: CanvasLayer
# Tiempo en que se cerró por última vez la pausa (evita que se reabra por accidente)
var _cierre_pausa_ms: int = 0

# En el nivel de Godzilla se necesitan DOS cosas para ganar: todos los diamantes y derrotar a Godzilla
# Estas variables recuerdan si ya se derrotó a Godzilla y si ya se mostraron los avisos de lo que falta
var _jefe_vencido: bool = false
var _aviso_jefe_mostrado: bool = false
var _aviso_diamantes_mostrado: bool = false

# Capa negra que se usa para los fundidos entre niveles
var _capa_fundido: CanvasLayer
var _negro: ColorRect
var _tween_fundido: Tween

# Guarda la vida de Kong para poder conservarla al pasar de nivel
var _vida_guardada: float = 100.0

# Guarda la cantidad total de diamantes recogidos en el juego
var _diamantes_totales: int = 0

# Indica si se está cambiando de nivel, para evitar que se repita
var _cambiando_nivel: bool = false

# Obtiene la interfaz del HUD para actualizar la información en pantalla
@onready var _hud = $HUD/Interfaz

# Se ejecuta una sola vez al iniciar la escena principal
func _ready() -> void:
	# La interfaz (vida y diamantes) no tiene botones, así que no debe bloquear los clics del mouse
	# Sin esto cubre toda la pantalla y los botones de la escena final no reciben clics
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Crea la capa negra para los fundidos (empieza en negro y se aclara al cargar el nivel)
	_crear_capa_fundido()

	# Carga el primer nivel para empezar el juego
	_crear_nivel(_nivel_actual, false)

# Función que crea y muestra el nivel que le indiquemos
# conservar_vida indica si Kong mantiene la vida anterior o empieza con la vida completa
func _crear_nivel(num_nivel: int, conservar_vida: bool) -> void:
	# Revisa que exista el nivel solicitado dentro de la lista
	if niveles.is_empty() or num_nivel - 1 >= niveles.size():
		# Muestra un error en la consola
		push_error("El nivel %d no existe en el arreglo de niveles." % num_nivel)
		# Sale de la función
		return

	# Permite hacer un nuevo cambio de nivel
	_cambiando_nivel = false

	# La pantalla empieza en negro y se aclara cuando el nivel ya está listo
	_negro.color.a = 1.0

	# Empieza el nivel sin jefe derrotado
	_jefe_vencido = false
	# Y sin avisos mostrados
	_aviso_jefe_mostrado = false
	_aviso_diamantes_mostrado = false

	# Calcula los diamantes acumulados de los niveles anteriores
	_diamantes_totales = DIAMANTES_POR_NIVEL * (num_nivel - 1)

	# Actualiza el número del nivel en el HUD
	_hud.actualizar_nivel(num_nivel)
	# Y el contador de diamantes
	_hud.actualizar_diamantes(_diamantes_totales, DIAMANTES_POR_NIVEL * num_nivel)

	# Crea una copia de la escena del nivel seleccionado
	# Se resta 1 porque las posiciones de la lista empiezan en 0
	_nivel_instanciado = niveles[num_nivel - 1].instantiate()

	# Agrega el nivel a la escena principal para que aparezca en pantalla
	add_child(_nivel_instanciado)

	# Si el nivel tiene a Godzilla, esta escena se entera cuando lo derrotan
	for jefe in get_tree().get_nodes_in_group("godzilla"):
		if jefe.has_signal("godzilla_muerto") and not jefe.godzilla_muerto.is_connected(_on_jefe_derrotado):
			jefe.godzilla_muerto.connect(_on_jefe_derrotado)

	# Después del último nivel (la escena final) se esconde la interfaz y se conserva la música final
	# En los demás niveles se muestra la interfaz y se cambia la música (nivel_1, nivel_2... nivel_5)
	var es_final: bool = num_nivel > NIVELES_TOTALES
	# Muestra u oculta el HUD
	$HUD.visible = not es_final
	# Si es la escena final
	if es_final:
		# La escena final llega como un "nivel 6": aquí empieza la música final
		_cambiar_musica("musica_final", false)
	# Si no
	else:
		# Cambia la música al nivel que toca
		_cambiar_musica("nivel_%d" % num_nivel)

	# Obtiene los nodos que están directamente dentro del nivel
	var hijos := _nivel_instanciado.get_children()

	# Recorre los nodos para encontrar a Kong
	for i in hijos.size():
		# Revisa si el nodo pertenece al grupo del personaje
		if hijos[i].is_in_group("personaje"):

			# Conecta la señal de muerte de Kong con la función que reinicia el nivel
			if hijos[i].has_signal("personaje_muerto"):
				hijos[i].personaje_muerto.connect(_reiniciar_nivel)

			# Obtiene el objeto que controla la vida de Kong
			var vida = hijos[i].get("vida")

			# Si existe
			if vida:
				# Si se debe conservar la vida, le asigna la que tenía guardada
				if conservar_vida:
					vida.fijar_vida(_vida_guardada)

				# Conecta los cambios de vida con la función que actualiza el HUD
				vida.vida_cambio.connect(_on_vida_cambio)

				# Actualiza la barra de vida con el valor actual
				_on_vida_cambio(vida.vida_actual)

			# Termina la búsqueda cuando encuentra a Kong
			break

	# Aclara la pantalla (fundido desde negro) y muestra el letrero del nivel
	if es_final:
		# La escena final se encarga de su propio fundido
		_negro.color.a = 0.0
	else:
		# Aclara la pantalla
		_aclarar(0.6)
		# Muestra el letrero del nivel
		_mostrar_titulo_nivel(num_nivel)

# Se ejecuta cuando cambia la vida de Kong
func _on_vida_cambio(vida_actual: float) -> void:
	# Guarda la vida actual para usarla cuando haga falta
	_vida_guardada = vida_actual

	# Actualiza la barra de vida de la pantalla
	_hud.actualizar_vida(vida_actual)

# Se llama cuando Kong recoge un diamante
func diamante_recogido() -> void:
	# Aumenta la cantidad de diamantes recogidos
	_diamantes_totales += 1

	# Actualiza el contador del HUD con los diamantes actuales y la meta del nivel
	_hud.actualizar_diamantes(_diamantes_totales, DIAMANTES_POR_NIVEL * _nivel_actual)

# Función que elimina el nivel que está cargado
func _eliminar_nivel() -> void:
	# Comprueba que el nivel exista antes de eliminarlo
	if is_instance_valid(_nivel_instanciado):
		# Lo elimina
		_nivel_instanciado.queue_free()

# Se ejecuta cuando Kong muere
func _reiniciar_nivel() -> void:
	# Evita reiniciar el nivel varias veces al mismo tiempo
	if _cambiando_nivel:
		# Sale de la función
		return

	# En los niveles 2 al 5 pregunta si se quiere repetir el nivel
	if preguntar_al_morir and _nivel_actual > 1:
		# Marca que se está cambiando de nivel
		_cambiando_nivel = true

		# Espera a que termine el sonido de muerte de Kong antes de mostrar el mensaje
		await _esperar_sonido_muerte()

		# Muestra el mensaje con los botones
		_mostrar_menu_muerte()
		# Sale de la función
		return

	# Si está activada esta opción, vuelve al primer nivel
	if volver_al_nivel_1_al_morir:
		# Pone el nivel 1
		_nivel_actual = 1

	# Vuelve a crear el nivel con la vida completa
	_cargar_nivel_de_nuevo(_nivel_actual)

# Segundos que Kong ya esperó (animación de muerte) antes de avisar que murió, es el mismo valor que usa personaje.gd
const SEGUNDOS_ANIMACION_MUERTE: float = 1.0

# Espera lo que le falte al sonido de muerte de Kong para terminar de sonar
func _esperar_sonido_muerte() -> void:
	# Busca el Autoload Audio
	var audio = get_node_or_null("/root/Audio")
	# Si no existe
	if audio == null:
		# Sale de la función
		return
	# Calcula cuánto falta para que termine el sonido
	var falta: float = audio.duracion_sfx("kong_muerte") - SEGUNDOS_ANIMACION_MUERTE
	# Si falta tiempo
	if falta > 0.0:
		# Espera ese tiempo
		await get_tree().create_timer(falta).timeout

# Elimina el nivel actual y crea el que se indique, con Kong al 100% de vida
func _cargar_nivel_de_nuevo(num_nivel: int) -> void:
	# Elimina el nivel que estaba jugando Kong
	_eliminar_nivel()

	# Crea otra vez el nivel después de terminar el proceso actual, Kong empieza con la vida completa porque se envía false
	_crear_nivel.call_deferred(num_nivel, false)

# Muestra el mensaje con los botones Sí y No y pausa el juego
func _mostrar_menu_muerte() -> void:
	# Si el mensaje ya existe
	if is_instance_valid(_menu_muerte):
		# No hace nada
		return

	# Pausa todo el juego (Godzilla, bolas, aves...) mientras se decide
	get_tree().paused = true

	# Capa que se dibuja por encima de todo y sigue funcionando aunque el juego esté en pausa
	_menu_muerte = CanvasLayer.new()
	# Número de capa
	_menu_muerte.layer = 100
	# Que siga funcionando en pausa
	_menu_muerte.process_mode = Node.PROCESS_MODE_ALWAYS
	# La agrega a la escena
	add_child(_menu_muerte)

	# Fondo oscuro semitransparente
	var fondo := ColorRect.new()
	# Color del fondo
	fondo.color = Color(0, 0, 0, 0.65)
	# Ocupa toda la pantalla
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Lo agrega a la capa
	_menu_muerte.add_child(fondo)

	# Contenedor que centra el cuadro en la pantalla
	var centro := CenterContainer.new()
	# Ocupa toda la pantalla
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Lo agrega a la capa
	_menu_muerte.add_child(centro)

	# Cuadro del mensaje
	var panel := PanelContainer.new()
	# Estilo del cuadro
	var estilo := StyleBoxFlat.new()
	# Color de fondo
	estilo.bg_color = Color(0.1, 0.08, 0.1, 0.95)
	# Color del borde
	estilo.border_color = Color(0.9, 0.3, 0.2)
	# Grosor del borde
	estilo.set_border_width_all(3)
	# Esquinas redondeadas
	estilo.set_corner_radius_all(14)
	# Margen interior
	estilo.set_content_margin_all(28)
	# Aplica el estilo al cuadro
	panel.add_theme_stylebox_override("panel", estilo)
	# Agrega el cuadro al centro
	centro.add_child(panel)

	# Caja vertical donde van los textos y botones
	var caja := VBoxContainer.new()
	# Separación entre elementos
	caja.add_theme_constant_override("separation", 18)
	# La agrega al cuadro
	panel.add_child(caja)

	# Título
	var titulo := Label.new()
	# Texto del título
	titulo.text = "¡Kong ha caído!"
	# Lo centra
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Tamaño de la letra
	titulo.add_theme_font_size_override("font_size", 34)
	# Color de la letra
	titulo.add_theme_color_override("font_color", Color(0.95, 0.3, 0.25))
	# Lo agrega a la caja
	caja.add_child(titulo)

	# Pregunta
	var pregunta := Label.new()
	# Texto de la pregunta con el nivel actual
	pregunta.text = "¿Quieres repetir el nivel %d?" % _nivel_actual
	# La centra
	pregunta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Tamaño de la letra
	pregunta.add_theme_font_size_override("font_size", 22)
	# La agrega a la caja
	caja.add_child(pregunta)

	# Fila con los botones
	var fila := HBoxContainer.new()
	# Centra los botones
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	# Separación entre los botones
	fila.add_theme_constant_override("separation", 24)
	# La agrega a la caja
	caja.add_child(fila)

	# Crea el botón Sí
	_boton_si = _crear_boton("Sí")
	# Crea el botón No
	_boton_no = _crear_boton("No")
	# Agrega el botón Sí a la fila
	fila.add_child(_boton_si)
	# Agrega el botón No a la fila
	fila.add_child(_boton_no)

	# Conecta el botón Sí con su función
	_boton_si.pressed.connect(_on_repetir_si)
	# Conecta el botón No con su función
	_boton_no.pressed.connect(_on_repetir_no)

	# Espera un momento antes de activar los botones, para que no se
	# elija una respuesta sin querer si el jugador seguía presionando teclas
	await get_tree().create_timer(0.4, true).timeout
	# Si el mensaje ya no existe
	if not is_instance_valid(_menu_muerte):
		# Sale de la función
		return
	# Activa el botón Sí
	_boton_si.disabled = false
	# Activa el botón No
	_boton_no.disabled = false
	# El botón Sí queda seleccionado
	_boton_si.grab_focus()

# Crea un botón con el estilo del mensaje (por defecto empieza desactivado)
func _crear_boton(texto: String, desactivado: bool = true) -> Button:
	# Crea el botón
	var boton := Button.new()
	# Le pone el texto
	boton.text = texto
	# Tamaño mínimo
	boton.custom_minimum_size = Vector2(140, 50)
	# Tamaño de la letra
	boton.add_theme_font_size_override("font_size", 24)
	# Lo activa o desactiva
	boton.disabled = desactivado
	# Devuelve el botón
	return boton

# El jugador responde Sí: repite el mismo nivel
func _on_repetir_si() -> void:
	# Cierra el mensaje
	_cerrar_menu_muerte()
	# Carga el mismo nivel de nuevo
	_cargar_nivel_de_nuevo(_nivel_actual)

# El jugador responde No: cierra el juego o empieza desde el nivel 1
func _on_repetir_no() -> void:
	# Cierra el mensaje
	_cerrar_menu_muerte()
	# Si está activado cerrar el juego
	if cerrar_juego_al_decir_no:
		# Cierra el juego
		get_tree().quit()
		# Sale de la función
		return
	# Si no, vuelve al nivel 1
	_nivel_actual = 1
	# Carga el nivel 1
	_cargar_nivel_de_nuevo(1)

# Quita el mensaje y reanuda el juego
func _cerrar_menu_muerte() -> void:
	# Quita la pausa
	get_tree().paused = false
	# Si el mensaje existe
	if is_instance_valid(_menu_muerte):
		# Lo elimina
		_menu_muerte.queue_free()
	# Lo borra de la variable
	_menu_muerte = null

# Cambia la música solo si el Autoload Audio está registrado (si no, no hace nada)
func _cambiar_musica(nombre: String, repetir: bool = true) -> void:
	# Busca el Autoload Audio
	var audio = get_node_or_null("/root/Audio")
	# Si existe
	if audio:
		# Cambia la música
		audio.musica(nombre, repetir)

# Detiene la música con un fundido (solo si el Autoload Audio está registrado)
func _detener_musica() -> void:
	# Busca el Autoload Audio
	var audio = get_node_or_null("/root/Audio")
	# Si existe
	if audio:
		# Detiene la música
		audio.detener_musica()

# Reproduce un efecto de sonido solo si el Autoload Audio está registrado
func _sfx(nombre: String) -> void:
	# Busca el Autoload Audio
	var audio = get_node_or_null("/root/Audio")
	# Si existe
	if audio:
		# Reproduce el sonido
		audio.sfx(nombre)

# Muestra la escena final (¡GANASTE! con los botones Jugar de nuevo y Ver créditos)
func _mostrar_final() -> void:
	# Empieza la música de la escena final (cambia a true si quieres que se repita en bucle)
	_cambiar_musica("musica_final", false)

	# Si no hay escena final asignada, muestra el mensaje de texto
	if escena_final == null:
		# Muestra el mensaje
		_hud.mostrar_mensaje("¡GANASTE!")
		# Sale de la función
		return

	# La pantalla se oscurece antes de mostrar la escena final
	await _fundir_a_negro(0.5)

	# Quita el último nivel
	_eliminar_nivel()
	# Y esconde la interfaz de vida y diamantes
	$HUD.visible = false

	# Crea la escena final
	_nivel_instanciado = escena_final.instantiate()
	# La agrega a la pantalla
	add_child(_nivel_instanciado)

	# La escena final se encarga de su propio fundido desde negro
	_negro.color.a = 0.0

# Se llama cuando Kong recoge todos los diamantes del nivel
# En el nivel de Godzilla no basta con eso: también hay que derrotarlo
func siguiente_nivel() -> void:
	# Si es el último nivel y hay jefe
	if _nivel_actual >= NIVELES_TOTALES and _hay_jefe():
		# Revisa si se cumplen las dos condiciones
		_revisar_victoria()
		# Sale de la función
		return
	# Si no, pasa de nivel
	_pasar_de_nivel()

# Indica si el nivel actual tiene a Godzilla
func _hay_jefe() -> bool:
	# Devuelve verdadero si hay algún Godzilla
	return get_tree().get_nodes_in_group("godzilla").size() > 0

# Indica si Godzilla ya se quedó sin vida y está en su animación de muerte
func _jefe_muriendo() -> bool:
	# Recorre los Godzilla del nivel
	for jefe in get_tree().get_nodes_in_group("godzilla"):
		# Si alguno está muerto
		if jefe.get("_muerto") == true:
			# Devuelve verdadero
			return true
	# Si no, devuelve falso
	return false

# Godzilla acaba de ser derrotado (lo avisa su propia señal)
func _on_jefe_derrotado() -> void:
	# Marca al jefe como vencido
	_jefe_vencido = true
	# Revisa si ya se ganó
	_revisar_victoria()

# Revisa las dos condiciones para ganar: todos los diamantes recogidos Y Godzilla derrotado
func _revisar_victoria() -> void:
	# Diamantes que se necesitan en total
	var meta: int = DIAMANTES_POR_NIVEL * _nivel_actual
	# Indica si ya se recogieron todos
	var diamantes_listos: bool = _diamantes_totales >= meta

	# Si Godzilla está en su animación de muerte, espera a que termine (su señal volverá a revisar)
	if _jefe_muriendo() and not _jefe_vencido:
		# Sale de la función
		return

	# Se cumplieron las dos condiciones: se gana
	if diamantes_listos and _jefe_vencido:
		# Pasa de nivel
		_pasar_de_nivel()
		# Sale de la función
		return

	# Godzilla cayó pero faltan diamantes
	if _jefe_vencido and not diamantes_listos:
		# Si todavía no se mostró el aviso
		if not _aviso_jefe_mostrado:
			# Marca el aviso como mostrado
			_aviso_jefe_mostrado = true
			# Calcula cuántos diamantes faltan
			var faltan: int = meta - _diamantes_totales
			# Prepara el texto según si falta uno o varios
			var texto: String = "Falta 1 diamante" if faltan == 1 else "Faltan %d diamantes" % faltan
			# Muestra el aviso
			_mostrar_aviso("¡GODZILLA DERROTADO!", texto)
		# Sale de la función
		return

	# Están todos los diamantes pero Godzilla sigue vivo
	if diamantes_listos and not _jefe_vencido:
		# Si todavía no se mostró el aviso
		if not _aviso_diamantes_mostrado:
			# Marca el aviso como mostrado
			_aviso_diamantes_mostrado = true
			# Muestra el aviso
			_mostrar_aviso("¡DIAMANTES COMPLETOS!", "Ahora derrota a Godzilla")

# Kong hace su animación de victoria y se espera unos segundos antes de seguir
func _celebrar_victoria() -> void:
	# Muestra el aviso de victoria
	_mostrar_aviso("¡VICTORIA!", "¡Kong es el verdadero rey!")

	# Busca a Kong (el Area2D de Kong también está en el grupo, por eso se busca el que sabe celebrar)
	for nodo in get_tree().get_nodes_in_group("personaje"):
		# Si el nodo tiene la función celebrar
		if nodo.has_method("celebrar"):
			# Kong celebra
			nodo.celebrar()
			# Termina la búsqueda
			break

	# Espera los segundos de la celebración
	await get_tree().create_timer(segundos_celebracion).timeout

# Muestra un aviso grande en la parte de arriba de la pantalla y lo desvanece solo
func _mostrar_aviso(titulo: String, subtitulo: String) -> void:
	# Crea la capa
	var capa := CanvasLayer.new()
	# Número de capa
	capa.layer = 80
	# La agrega a la escena
	add_child(capa)

	# Contenedor del aviso
	var contenedor := Control.new()
	# Lo coloca arriba y a lo ancho
	contenedor.set_anchors_preset(Control.PRESET_TOP_WIDE)
	# Margen de arriba
	contenedor.offset_top = 110.0
	# Margen de abajo
	contenedor.offset_bottom = 300.0
	# No bloquea los clics
	contenedor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Empieza invisible
	contenedor.modulate.a = 0.0
	# Lo agrega a la capa
	capa.add_child(contenedor)

	# Caja vertical para los dos textos
	var caja := VBoxContainer.new()
	# Ocupa todo el contenedor
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	# No bloquea los clics
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Separación entre los textos
	caja.add_theme_constant_override("separation", 6)
	# La agrega al contenedor
	contenedor.add_child(caja)

	# Primera línea (título)
	var linea1 := Label.new()
	# Texto del título
	linea1.text = titulo
	# Lo centra
	linea1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Tamaño de la letra
	linea1.add_theme_font_size_override("font_size", 52)
	# Color de la letra
	linea1.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2))
	# Color del borde
	linea1.add_theme_color_override("font_outline_color", Color.BLACK)
	# Grosor del borde
	linea1.add_theme_constant_override("outline_size", 12)
	# La agrega a la caja
	caja.add_child(linea1)

	# Segunda línea (subtítulo)
	var linea2 := Label.new()
	# Texto del subtítulo
	linea2.text = subtitulo
	# Lo centra
	linea2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Tamaño de la letra
	linea2.add_theme_font_size_override("font_size", 30)
	# Color de la letra
	linea2.add_theme_color_override("font_color", Color.WHITE)
	# Color del borde
	linea2.add_theme_color_override("font_outline_color", Color.BLACK)
	# Grosor del borde
	linea2.add_theme_constant_override("outline_size", 9)
	# La agrega a la caja
	caja.add_child(linea2)

	# Crea el tween
	var t := create_tween()
	# El aviso aparece poco a poco
	t.tween_property(contenedor, "modulate:a", 1.0, 0.3)
	# Se queda un momento
	t.tween_interval(2.4)
	# Se desvanece
	t.tween_property(contenedor, "modulate:a", 0.0, 0.5)
	# Al terminar, elimina la capa
	t.tween_callback(capa.queue_free)

# Pasa al siguiente nivel (o a la escena final si era el último)
func _pasar_de_nivel() -> void:
	# Evita que se inicie el cambio de nivel más de una vez
	if _cambiando_nivel:
		# Sale de la función
		return

	# Indica que se está cambiando de nivel
	_cambiando_nivel = true

	# Detiene los generadores de fuego
	get_tree().call_group("spawner", "detener")
	# Y elimina las bolas que siguen en pantalla
	get_tree().call_group("bolas", "queue_free")

	# Si es el último nivel
	if _nivel_actual >= NIVELES_TOTALES:
		# Se calla la música del nivel, suena el rugido y Kong celebra antes de la escena final
		# Detiene la música
		_detener_musica()
		# Sonido del rugido de victoria
		_sfx("rugido_victoria")
		# Espera a que termine la celebración
		await _celebrar_victoria()
	# Si no
	else:
		# Espera un momento para que se pueda ver el contador completo
		await get_tree().create_timer(PAUSA_ENTRE_NIVELES).timeout

	# Comprueba si ya se llegó al último nivel disponible
	if _nivel_actual >= niveles.size():

		# Si se completaron los cinco niveles, muestra la escena final
		if _nivel_actual >= NIVELES_TOTALES:
			# Muestra la escena final
			_mostrar_final()

		# Si faltan niveles por crear, muestra un aviso
		else:
			# Aviso en la consola
			push_warning("Falta crear el nivel %d (solo hay %d niveles)." % [_nivel_actual + 1, niveles.size()])
			# Aviso en pantalla
			_hud.mostrar_mensaje("FALTA NIVEL %d" % (_nivel_actual + 1))

		# Sale de la función
		return

	# Aumenta el número para pasar al siguiente nivel
	_nivel_actual += 1

	# La pantalla se oscurece antes de cambiar de nivel
	await _fundir_a_negro(0.4)

	# Elimina el nivel que acaba de completarse
	_eliminar_nivel()

	# Crea el siguiente nivel y decide si Kong conserva su vida
	_crear_nivel.call_deferred(_nivel_actual, not vida_al_100_en_cada_nivel)

# Crea la capa negra que cubre la pantalla (empieza totalmente negra)
func _crear_capa_fundido() -> void:
	# Crea la capa
	_capa_fundido = CanvasLayer.new()
	# Número de capa
	_capa_fundido.layer = 70
	# La agrega a la escena
	add_child(_capa_fundido)

	# Crea el rectángulo negro
	_negro = ColorRect.new()
	# Color negro
	_negro.color = Color(0, 0, 0, 1)
	# Ocupa toda la pantalla
	_negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	# No bloquea los clics
	_negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Lo agrega a la capa
	_capa_fundido.add_child(_negro)

# La pantalla se oscurece poco a poco y espera a que termine
func _fundir_a_negro(duracion: float) -> void:
	# Si ya había un tween
	if _tween_fundido:
		# Lo detiene
		_tween_fundido.kill()
	# Crea un tween nuevo
	_tween_fundido = create_tween()
	# Sube la opacidad del negro
	_tween_fundido.tween_property(_negro, "color:a", 1.0, duracion)
	# Espera a que termine
	await _tween_fundido.finished

# La pantalla se aclara poco a poco desde negro
func _aclarar(duracion: float) -> void:
	# Si ya había un tween
	if _tween_fundido:
		# Lo detiene
		_tween_fundido.kill()
	# Crea un tween nuevo
	_tween_fundido = create_tween()
	# Baja la opacidad del negro
	_tween_fundido.tween_property(_negro, "color:a", 0.0, duracion)

# Muestra un letrero grande con el número y el nombre del nivel, y se desvanece solo
func _mostrar_titulo_nivel(num_nivel: int) -> void:
	# Si el letrero está desactivado
	if not mostrar_titulo_de_nivel:
		# Sale de la función
		return

	# Crea la capa
	var capa := CanvasLayer.new()
	# Número de capa
	capa.layer = 80
	# La agrega a la escena
	add_child(capa)

	# Todo el letrero cuelga de este contenedor para poder desvanecerlo junto
	var contenedor := Control.new()
	# Ocupa toda la pantalla
	contenedor.set_anchors_preset(Control.PRESET_FULL_RECT)
	# No bloquea los clics
	contenedor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Empieza invisible
	contenedor.modulate.a = 0.0
	# Lo agrega a la capa
	capa.add_child(contenedor)

	# Contenedor que centra el letrero
	var centro := CenterContainer.new()
	# Ocupa toda la pantalla
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	# No bloquea los clics
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Lo agrega al contenedor
	contenedor.add_child(centro)

	# Caja vertical para los textos
	var caja := VBoxContainer.new()
	# Separación entre los textos
	caja.add_theme_constant_override("separation", 8)
	# No bloquea los clics
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# La agrega al centro
	centro.add_child(caja)

	# Número del nivel
	var titulo := Label.new()
	# Texto del número
	titulo.text = "NIVEL %d" % num_nivel
	# Lo centra
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Tamaño de la letra
	titulo.add_theme_font_size_override("font_size", 72)
	# Color de la letra
	titulo.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2))
	# Color del borde
	titulo.add_theme_color_override("font_outline_color", Color.BLACK)
	# Grosor del borde
	titulo.add_theme_constant_override("outline_size", 14)
	# Lo agrega a la caja
	caja.add_child(titulo)

	# Nombre del nivel (si hay uno escrito para este número)
	if num_nivel - 1 < nombres_niveles.size():
		# Crea el texto del nombre
		var subtitulo := Label.new()
		# Le pone el nombre del nivel
		subtitulo.text = nombres_niveles[num_nivel - 1]
		# Lo centra
		subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# Tamaño de la letra
		subtitulo.add_theme_font_size_override("font_size", 34)
		# Color de la letra
		subtitulo.add_theme_color_override("font_color", Color.WHITE)
		# Color del borde
		subtitulo.add_theme_color_override("font_outline_color", Color.BLACK)
		# Grosor del borde
		subtitulo.add_theme_constant_override("outline_size", 10)
		# Lo agrega a la caja
		caja.add_child(subtitulo)

	# Crea el tween
	var t := create_tween()
	# Espera un momento
	t.tween_interval(0.3)
	# Aparece
	t.tween_property(contenedor, "modulate:a", 1.0, 0.35)
	# Se queda un momento
	t.tween_interval(1.1)
	# Se desvanece
	t.tween_property(contenedor, "modulate:a", 0.0, 0.45)
	# Al terminar, elimina la capa
	t.tween_callback(capa.queue_free)

# Con la tecla Escape se abre el menú de pausa
func _unhandled_input(event: InputEvent) -> void:
	# Si se presionó Escape y se puede pausar
	if event.is_action_pressed("ui_cancel") and _se_puede_pausar():
		# Marca la tecla como usada
		get_viewport().set_input_as_handled()
		# Muestra el menú de pausa
		_mostrar_menu_pausa()

# Indica si en este momento se puede pausar (no durante cambios de nivel, mensajes ni la escena final)
func _se_puede_pausar() -> bool:
	# Si la pausa está desactivada, el juego ya está en pausa o se está cambiando de nivel
	if not permitir_pausa or get_tree().paused or _cambiando_nivel:
		# No se puede pausar
		return false
	# Si el HUD no se ve (escena final)
	if not $HUD.visible:
		# No se puede pausar
		return false
	# Si ya hay un menú en pantalla
	if is_instance_valid(_menu_muerte) or is_instance_valid(_menu_pausa):
		# No se puede pausar
		return false
	# Solo se puede si pasaron más de 250 ms desde que se cerró la pausa
	return Time.get_ticks_msec() - _cierre_pausa_ms > 250

# Pausa el juego y muestra los botones Continuar, Reiniciar nivel y Salir al menú
func _mostrar_menu_pausa() -> void:
	# Pausa el juego
	get_tree().paused = true

	# Crea la capa del menú
	_menu_pausa = CanvasLayer.new()
	# Número de capa
	_menu_pausa.layer = 100
	# Que siga funcionando en pausa
	_menu_pausa.process_mode = Node.PROCESS_MODE_ALWAYS
	# La agrega a la escena
	add_child(_menu_pausa)

	# Crea el panel y obtiene la caja donde van los botones
	var caja := _crear_panel_menu(_menu_pausa, "PAUSA", Color(0.95, 0.8, 0.2))

	# Botón CONTINUAR
	var continuar := _crear_boton("CONTINUAR", false)
	# Botón REINICIAR NIVEL
	var reiniciar := _crear_boton("REINICIAR NIVEL", false)
	# Botón SALIR AL MENÚ
	var salir := _crear_boton("SALIR AL MENÚ", false)
	# Recorre los tres botones
	for boton in [continuar, reiniciar, salir]:
		# Les pone el tamaño
		boton.custom_minimum_size = Vector2(320, 54)
		# Los agrega a la caja
		caja.add_child(boton)

	# La tecla Escape también activa el botón Continuar
	var atajo := Shortcut.new()
	# Crea la tecla
	var tecla := InputEventKey.new()
	# Le asigna Escape
	tecla.keycode = KEY_ESCAPE
	# Agrega la tecla al atajo
	atajo.events = [tecla]
	# Asigna el atajo al botón
	continuar.shortcut = atajo

	# Conecta el botón Continuar
	continuar.pressed.connect(_cerrar_menu_pausa)
	# Conecta el botón Reiniciar
	reiniciar.pressed.connect(_on_pausa_reiniciar)
	# Conecta el botón Salir
	salir.pressed.connect(_on_pausa_salir)
	# El botón Continuar queda seleccionado
	continuar.grab_focus()

# Crea el fondo oscuro y el cuadro de un menú, devuelve la caja donde se ponen los botones
func _crear_panel_menu(capa: CanvasLayer, titulo: String, color_titulo: Color) -> VBoxContainer:
	# Fondo oscuro
	var fondo := ColorRect.new()
	# Color del fondo
	fondo.color = Color(0, 0, 0, 0.65)
	# Ocupa toda la pantalla
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Lo agrega a la capa
	capa.add_child(fondo)

	# Contenedor que centra el cuadro
	var centro := CenterContainer.new()
	# Ocupa toda la pantalla
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Lo agrega a la capa
	capa.add_child(centro)

	# Cuadro del menú
	var panel := PanelContainer.new()
	# Estilo del cuadro
	var estilo := StyleBoxFlat.new()
	# Color de fondo
	estilo.bg_color = Color(0.1, 0.08, 0.1, 0.95)
	# Color del borde
	estilo.border_color = Color(0.9, 0.3, 0.2)
	# Grosor del borde
	estilo.set_border_width_all(3)
	# Esquinas redondeadas
	estilo.set_corner_radius_all(14)
	# Margen interior
	estilo.set_content_margin_all(28)
	# Aplica el estilo al cuadro
	panel.add_theme_stylebox_override("panel", estilo)
	# Agrega el cuadro al centro
	centro.add_child(panel)

	# Caja vertical para los botones
	var caja := VBoxContainer.new()
	# Separación entre elementos
	caja.add_theme_constant_override("separation", 14)
	# La agrega al cuadro
	panel.add_child(caja)

	# Título del menú
	var etiqueta := Label.new()
	# Texto del título
	etiqueta.text = titulo
	# Lo centra
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Tamaño de la letra
	etiqueta.add_theme_font_size_override("font_size", 38)
	# Color de la letra
	etiqueta.add_theme_color_override("font_color", color_titulo)
	# Lo agrega a la caja
	caja.add_child(etiqueta)
	# Devuelve la caja
	return caja

# Quita el menú de pausa y reanuda el juego
func _cerrar_menu_pausa() -> void:
	# Quita la pausa
	get_tree().paused = false
	# Guarda el momento en que se cerró
	_cierre_pausa_ms = Time.get_ticks_msec()
	# Si el menú existe
	if is_instance_valid(_menu_pausa):
		# Lo elimina
		_menu_pausa.queue_free()
	# Lo borra de la variable
	_menu_pausa = null

# REINICIAR NIVEL: vuelve a empezar el nivel actual
func _on_pausa_reiniciar() -> void:
	# Cierra el menú de pausa
	_cerrar_menu_pausa()
	# Carga el nivel actual de nuevo
	_cargar_nivel_de_nuevo(_nivel_actual)

# SALIR AL MENÚ: oscurece la pantalla y abre la pantalla de inicio
func _on_pausa_salir() -> void:
	# Cierra el menú de pausa
	_cerrar_menu_pausa()
	# Marca que se está cambiando de escena
	_cambiando_nivel = true
	# Oscurece la pantalla
	await _fundir_a_negro(0.35)
	# Si hay una escena de inicio asignada
	if escena_inicio:
		# Cambia a esa escena
		get_tree().change_scene_to_packed(escena_inicio)
	# Si no
	else:
		# Cambia a la escena de respaldo
		get_tree().change_scene_to_file(RUTA_INICIO_RESPALDO)
