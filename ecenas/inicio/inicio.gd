# Pantalla de inicio: KONG VS GODZILLA
# La imagen del título queda centrada y el botón JUGAR debajo
# Hereda de Control
extends Control

# Escena del juego que se abre al presionar JUGAR
@export var escena_juego: PackedScene

# Ruta de respaldo de la escena del juego
const RUTA_JUEGO_RESPALDO: String = "res://ecenas/ecena-principal/ecena_principal.tscn"

# Configuración del título
# Indica si se muestra el título
@export var mostrar_titulo: bool = true
# Imagen del título
@export var imagen_titulo: Texture2D
# Ruta de respaldo de la imagen del título
const RUTA_TITULO_RESPALDO: String = "res://ecenas/inicio/titulo_kong_vs_godzilla.png"

# Altura de la imagen del título
@export var titulo_alto: float = 200.0

# Separación entre el título y el botón
@export var titulo_separacion: float = 25.0

# Título alternativo si no se encuentra la imagen
@export_multiline var texto_titulo: String = "[center][color=#e8731a]KONG[/color]\n[color=#ffffff]VS[/color]\n[color=#4a90c8]GODZILLA[/color][/center]"

# Fuente para el título y los botones
@export var fuente: Font

# Ayuda de controles
@export_multiline var texto_controles: String = "Flechas: mover      Espacio: saltar      Z / X: golpear"

# Indica si se muestra el botón SALIR
@export var mostrar_salir: bool = false

# Efectos de la pantalla de inicio
@export_group("Efectos")
# La pantalla aparece poco a poco desde negro
@export var aparecer_desde_negro: bool = true
# Suben brasas desde abajo
@export var brasas: bool = true
# El título late
@export var titulo_late: bool = true

# Variables internas
# Botón JUGAR
var _boton_jugar: Button
# Título del juego
var _titulo: Control
# Caja donde están los botones
var _caja_botones: VBoxContainer
# Contenedor que centra el menú
var _centro_menu: CenterContainer
# Evita que se presione JUGAR varias veces
var _iniciando: bool = false
# Indica si ya pueden sonar los sonidos de los botones
var _sonido_listo: bool = false

# Se ejecuta una sola vez al iniciar el nodo
func _ready() -> void:
	# Restablece el estado del juego, quita la pausa
	get_tree().paused = false
	# Y la cámara lenta
	Engine.time_scale = 1.0

	# Ocupa toda la pantalla
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Crea el fondo si falta
	_crear_fondo_si_falta()

	# Si están activadas las brasas
	if brasas:
		# Las crea
		_crear_brasas()

	# Crea el menú con el botón JUGAR
	_crear_menu()

	# Si se muestra el título
	if mostrar_titulo:
		# Lo crea
		_crear_titulo()

	# Si aparece desde negro
	if aparecer_desde_negro:
		# Hace el efecto
		_aparecer_desde_negro()

	# Empieza la música de inicio
	_musica("musica_inicio")

	# El botón JUGAR queda seleccionado
	_boton_jugar.grab_focus.call_deferred()

	# Espera un momento antes de activar los sonidos de los botones
	await get_tree().create_timer(0.4).timeout
	# Ya pueden sonar
	_sonido_listo = true

# Crea un fondo oscuro si no existe uno
func _crear_fondo_si_falta() -> void:
	# Si ya existe un fondo
	if get_node_or_null("Fondo") != null:
		# No hace nada
		return

	# Crea el fondo
	var fondo := ColorRect.new()
	# Le pone nombre
	fondo.name = "Fondo"
	# Le pone el color
	fondo.color = Color(0.07, 0.03, 0.04)
	# Hace que ocupe toda la pantalla
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Lo agrega a la escena
	add_child(fondo)
	# Lo manda al fondo para que quede detrás de todo
	move_child(fondo, 0)

# Crea el botón JUGAR y el botón SALIR opcional
func _crear_menu() -> void:
	# Crea la caja de los botones
	_caja_botones = VBoxContainer.new()
	# Le pone nombre
	_caja_botones.name = "CajaBotones"
	# Centra los botones
	_caja_botones.alignment = BoxContainer.ALIGNMENT_CENTER
	# Separación entre botones
	_caja_botones.add_theme_constant_override("separation", 18)

	# El contenedor ocupa toda la pantalla
	_centro_menu = CenterContainer.new()
	# Le pone nombre
	_centro_menu.name = "CentroMenu"
	# Hace que ocupe toda la pantalla
	_centro_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Lo agrega a la escena
	add_child(_centro_menu)
	# Agrega la caja de botones dentro del contenedor
	_centro_menu.add_child(_caja_botones)

	# Botón JUGAR
	_boton_jugar = _crear_boton(
		"JUGAR",
		Color(0.95, 0.68, 0.1),
		Color(0.08, 0.05, 0.02)
	)

	# Conecta el botón con la función de jugar
	_boton_jugar.pressed.connect(_jugar)
	# Agrega el botón a la caja
	_caja_botones.add_child(_boton_jugar)

	# Botón SALIR opcional
	if mostrar_salir:
		var boton_salir := _crear_boton(
			"SALIR",
			Color(0.2, 0.45, 0.65),
			Color.WHITE
		)

		# Conecta el botón con la función de salir
		boton_salir.pressed.connect(_salir)
		# Agrega el botón a la caja
		_caja_botones.add_child(boton_salir)

	# Ayuda de controles en la parte de abajo
	var ayuda := Label.new()
	# Le pone nombre
	ayuda.name = "AyudaControles"
	# Le pone el texto de controles
	ayuda.text = texto_controles
	# Centra el texto en horizontal
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Y en vertical
	ayuda.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Tamaño de la letra
	ayuda.add_theme_font_size_override("font_size", 20)
	# Color de la letra
	ayuda.add_theme_color_override(
		"font_color",
		Color(1, 1, 1, 0.8)
	)
	# Color del borde de la letra
	ayuda.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)
	# Grosor del borde de la letra
	ayuda.add_theme_constant_override("outline_size", 6)
	# La coloca abajo de la pantalla
	ayuda.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	# Margen de arriba
	ayuda.offset_top = -64
	# Margen de abajo
	ayuda.offset_bottom = -24
	# La agrega a la escena
	add_child(ayuda)

# Carga la imagen del título o crea un título de texto
func _crear_titulo() -> void:
	# Usa la imagen asignada
	var textura: Texture2D = imagen_titulo

	# Si no hay imagen asignada, prueba con la ruta de respaldo
	if textura == null and ResourceLoader.exists(RUTA_TITULO_RESPALDO):
		# La carga
		textura = load(RUTA_TITULO_RESPALDO) as Texture2D

	# Si hay una imagen, la usa
	if textura != null:
		# Crea el nodo de la imagen
		var imagen := TextureRect.new()
		# Le pone nombre
		imagen.name = "ImagenTitulo"
		# Le asigna la textura
		imagen.texture = textura
		# Permite cambiar el tamaño de la imagen
		imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		# Mantiene las proporciones y la centra
		imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# Filtro de la textura
		imagen.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

		# Calcula el ancho para mantener las proporciones de la imagen
		var ancho: float = (
			titulo_alto
			* float(textura.get_width())
			/ float(textura.get_height())
		)

		# Le pone el tamaño
		imagen.size = Vector2(ancho, titulo_alto)
		# Guarda la imagen como título
		_titulo = imagen

	# Si no hay imagen, usa un título de texto
	else:
		# Crea el texto
		var texto := RichTextLabel.new()
		# Le pone nombre
		texto.name = "TituloTexto"
		# Activa el formato BBCode para los colores
		texto.bbcode_enabled = true
		# Se ajusta al contenido
		texto.fit_content = true
		# Sin barra de desplazamiento
		texto.scroll_active = false
		# Sin salto de línea automático
		texto.autowrap_mode = TextServer.AUTOWRAP_OFF
		# Tamaño mínimo
		texto.custom_minimum_size = Vector2(700, 0)
		# Le pone el texto del título
		texto.text = texto_titulo

		# Tamaño de la letra
		texto.add_theme_font_size_override("normal_font_size", 52)
		# Grosor del borde
		texto.add_theme_constant_override("outline_size", 10)
		# Color del borde
		texto.add_theme_color_override(
			"font_outline_color",
			Color.BLACK
		)

		# Si hay una fuente asignada
		if fuente != null:
			# La aplica al texto
			texto.add_theme_font_override("normal_font", fuente)

		# Guarda el texto como título
		_titulo = texto

	# El título no debe bloquear los clics
	_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Empieza invisible hasta que se coloque
	_titulo.visible = false
	# Lo agrega a la escena
	add_child(_titulo)

	# Espera dos frames para que Godot calcule los tamaños
	await get_tree().process_frame
	await get_tree().process_frame

	# Coloca el título
	_colocar_titulo()

# Centra el título y coloca JUGAR debajo
func _colocar_titulo() -> void:
	# Si falta el título o la caja de botones
	if _titulo == null or _caja_botones == null:
		# Sale de la función
		return

	# Centra el título en horizontal
	_titulo.position.x = (size.x - _titulo.size.x) / 2.0

	# Centra el título en vertical
	_titulo.position.y = (size.y - _titulo.size.y) / 2.0

	# Pone el punto de giro en el centro
	_titulo.pivot_offset = _titulo.size / 2.0
	# Muestra el título
	_titulo.visible = true

	# Calcula la altura del grupo formado por el título y el botón
	var altura_grupo: float = (
		_titulo.size.y
		+ titulo_separacion
		+ _caja_botones.size.y
	)

	# Calcula dónde empieza el grupo para que quede centrado
	var inicio_y: float = (size.y - altura_grupo) / 2.0

	# Coloca el título arriba
	_titulo.position.y = inicio_y

	# Mueve la caja del botón debajo del título
	_caja_botones.position = Vector2(
		(size.x - _caja_botones.size.x) / 2.0,
		inicio_y + _titulo.size.y + titulo_separacion
	)

	# Si el título late
	if titulo_late:
		# Crea un tween que se repite siempre
		var t := create_tween().set_loops()

		# El título crece un poco
		t.tween_property(
			_titulo,
			"scale",
			Vector2(1.025, 1.025),
			1.6
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		# Y vuelve a su tamaño normal
		t.tween_property(
			_titulo,
			"scale",
			Vector2.ONE,
			1.6
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# Crea un botón con estilo dorado o azul
func _crear_boton(
	texto: String,
	color: Color,
	color_texto: Color
) -> Button:
	# Crea el botón
	var boton := Button.new()
	# Le pone el texto
	boton.text = texto
	# Tamaño mínimo
	boton.custom_minimum_size = Vector2(320, 78)
	# Lo centra
	boton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# Tamaño de la letra
	boton.add_theme_font_size_override("font_size", 36)

	# Si hay una fuente asignada
	if fuente != null:
		# La aplica
		boton.add_theme_font_override("font", fuente)

	# Aplica el color del texto en todos los estados del botón
	for nombre in [
		"font_color",
		"font_hover_color",
		"font_pressed_color",
		"font_focus_color"
	]:
		boton.add_theme_color_override(nombre, color_texto)

	# Crea los estilos del botón
	var normal := _estilo(color)
	# Estilo cuando se pasa el mouse
	var resaltado := _estilo(color.lightened(0.2))
	# Estilo cuando se presiona
	var presionado := _estilo(color.darkened(0.2))

	# Estilo normal
	boton.add_theme_stylebox_override("normal", normal)
	# Estilo con el mouse encima
	boton.add_theme_stylebox_override("hover", resaltado)
	# Estilo presionado
	boton.add_theme_stylebox_override("pressed", presionado)
	# Estilo con el foco
	boton.add_theme_stylebox_override("focus", resaltado)

	# Escala desde el centro
	boton.resized.connect(
		func():
			boton.pivot_offset = boton.size / 2.0
	)

	# Al pasar el mouse, el botón queda seleccionado
	boton.mouse_entered.connect(boton.grab_focus)
	# Cuando se selecciona, se resalta
	boton.focus_entered.connect(_resaltar.bind(boton, true))
	# Cuando se deja de seleccionar, vuelve a su estado normal
	boton.focus_exited.connect(_resaltar.bind(boton, false))

	# Devuelve el botón
	return boton

# Estilo visual de los botones
func _estilo(color: Color) -> StyleBoxFlat:
	# Crea el estilo
	var estilo := StyleBoxFlat.new()
	# Color de fondo
	estilo.bg_color = color
	# Color del borde
	estilo.border_color = Color.BLACK
	# Grosor del borde
	estilo.set_border_width_all(4)
	# Esquinas redondeadas
	estilo.set_corner_radius_all(12)
	# Color de la sombra
	estilo.shadow_color = Color(0, 0, 0, 0.5)
	# Tamaño de la sombra
	estilo.shadow_size = 8
	# Posición de la sombra
	estilo.shadow_offset = Vector2(0, 4)

	# Devuelve el estilo
	return estilo

# Animación cuando se selecciona un botón
func _resaltar(boton: Button, activo: bool) -> void:
	# El botón crece un poco si está seleccionado
	var destino: Vector2 = (
		Vector2(1.07, 1.07)
		if activo
		else Vector2.ONE
	)

	# Anima el cambio de tamaño
	create_tween().tween_property(
		boton,
		"scale",
		destino,
		0.12
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Si está seleccionado y ya pueden sonar los sonidos
	if activo and _sonido_listo:
		# Sonido al pasar por el botón
		_sfx("boton_hover")

# Inicia el juego con una transición a negro
func _jugar() -> void:
	# Si ya se está iniciando
	if _iniciando:
		# No hace nada
		return

	# Marca que ya se está iniciando
	_iniciando = true
	# Desactiva el botón
	_boton_jugar.disabled = true
	# Sonido del clic
	_sfx("boton_click")

	# Crea la capa para el fundido
	var capa := CanvasLayer.new()
	# La pone por encima de todo
	capa.layer = 90
	# La agrega a la escena
	add_child(capa)

	# Crea el rectángulo negro
	var negro := ColorRect.new()
	# Empieza transparente
	negro.color = Color(0, 0, 0, 0)
	# Ocupa toda la pantalla
	negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	# No bloquea los clics
	negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Lo agrega a la capa
	capa.add_child(negro)

	# Crea el tween
	var t := create_tween()
	# La pantalla se oscurece poco a poco
	t.tween_property(negro, "color:a", 1.0, 0.45)

	# Espera a que termine el fundido
	await t.finished

	# Si hay una escena de juego asignada, la abre
	if escena_juego != null:
		# Cambia a esa escena
		get_tree().change_scene_to_packed(escena_juego)
	# Si no, prueba con la ruta de respaldo
	elif ResourceLoader.exists(RUTA_JUEGO_RESPALDO):
		# Cambia a la escena de respaldo
		get_tree().change_scene_to_file(RUTA_JUEGO_RESPALDO)
	# Si tampoco existe
	else:
		# Muestra un error en la consola
		push_error(
			"No se encontro la escena del juego: "
			+ RUTA_JUEGO_RESPALDO
		)

# Función que cierra el juego
func _salir() -> void:
	# Cierra el juego
	get_tree().quit()

# Muestra la pantalla poco a poco desde negro
func _aparecer_desde_negro() -> void:
	# Crea la capa para el fundido
	var capa := CanvasLayer.new()
	# La pone por encima de todo
	capa.layer = 90
	# La agrega a la escena
	add_child(capa)

	# Crea el rectángulo negro
	var negro := ColorRect.new()
	# Empieza totalmente negro
	negro.color = Color(0, 0, 0, 1)
	# Ocupa toda la pantalla
	negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	# No bloquea los clics
	negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Lo agrega a la capa
	capa.add_child(negro)

	# Crea el tween
	var t := create_tween()
	# La pantalla se aclara poco a poco
	t.tween_property(negro, "color:a", 0.0, 1.2)
	# Al terminar, elimina la capa
	t.tween_callback(capa.queue_free)

# Crea las brasas que suben desde abajo
func _crear_brasas() -> void:
	# Obtiene el tamaño de la pantalla
	var pantalla: Vector2 = get_viewport_rect().size

	# Crea las partículas
	var p := CPUParticles2D.new()
	# Les pone nombre
	p.name = "Brasas"
	# Las coloca abajo de la pantalla
	p.position = Vector2(
		pantalla.x / 2.0,
		pantalla.y + 10.0
	)

	# Cantidad de brasas
	p.amount = 80
	# Tiempo de vida
	p.lifetime = 5.0
	# Hace que ya haya brasas desde el primer momento
	p.preprocess = 5.0
	# Salen en una línea horizontal
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	# Ancho de la línea
	p.emission_rect_extents = Vector2(pantalla.x / 2.0, 2.0)
	# Suben hacia arriba
	p.direction = Vector2(0, -1)
	# Se abren un poco
	p.spread = 20.0
	# Gravedad hacia arriba
	p.gravity = Vector2(0, -15)
	# Velocidad mínima
	p.initial_velocity_min = 40.0
	# Velocidad máxima
	p.initial_velocity_max = 110.0
	# Tamaño mínimo
	p.scale_amount_min = 2.5
	# Tamaño máximo
	p.scale_amount_max = 6.0

	# Degradado de amarillo a rojo transparente
	var degradado := Gradient.new()
	degradado.set_color(0, Color(1.0, 0.75, 0.25, 1.0))
	degradado.set_color(1, Color(1.0, 0.2, 0.0, 0.0))
	# Se lo aplica a las partículas
	p.color_ramp = degradado

	# Brillo aditivo
	var aditivo := CanvasItemMaterial.new()
	aditivo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	# Se lo aplica a las partículas
	p.material = aditivo

	# Las agrega a la escena
	add_child(p)

# Reproduce efectos de sonido si existe el Autoload Audio
func _sfx(nombre: String) -> void:
	# Busca el Autoload Audio
	var audio = get_node_or_null("/root/Audio")

	# Si existe
	if audio != null:
		# Reproduce el sonido
		audio.sfx(nombre)

# Reproduce música si existe el Autoload Audio
func _musica(nombre: String) -> void:
	# Busca el Autoload Audio
	var audio = get_node_or_null("/root/Audio")

	# Si existe
	if audio != null:
		# Reproduce la música
		audio.musica(nombre)
