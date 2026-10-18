# Godzilla: jefe automático del nivel 5
# Se mueve solo hacia Kong, lo golpea con la cola de cerca y le lanza su rayo atómico de lejos
# Kong lo derrota golpeándolo con la tecla Z o X
# Nodo raíz: Node2D (con este script). Hijo obligatorio: AnimatedSprite2D
# El origen del nodo queda en los PIES de Godzilla (el script ajusta el sprite solo)
# Hereda de Node2D
extends Node2D

# Señal para avisar cuando Godzilla muere
signal godzilla_muerto

# Nombres de mis animaciones
@export_group("Animaciones")
# Animación de reposo
@export var anim_reposo: StringName = &"reposo"
# Animación de caminar
@export var anim_caminar: StringName = &"caminar"
# Animación del golpe de cola
@export var anim_golpe: StringName = &"golpe_cola"
# Animación del aliento atómico
@export var anim_fuego: StringName = &"aliento_atomico"
# Animación de recibir daño
@export var anim_dano: StringName = &"recibe_daño"
# Animación de muerte
@export var anim_muerte: StringName = &"derrotado_muerte"
# Número de cuadro (empieza en 0) en el que la cola realmente pega
@export var frame_golpe: int = 2
# Número de cuadro (empieza en 0) en el que sale el rayo de su boca
# La animación aliento_atomico tiene 2 cuadros (0 y 1), así que el rayo sale en el 1
@export var frame_fuego: int = 1
# Cuadros de "caminar" en los que su pie toca el piso (para sonido y temblor)
@export var frames_pasos: Array[int] = [0, 2]
# Qué tan rápido se reproduce la animación de daño (2 = el doble de rápido)
@export var velocidad_anim_dano: float = 2.0

# Vida de Godzilla
@export_group("Vida")
# Cantidad de golpes de Kong que aguanta Godzilla
@export var vida_maxima: int = 10
# Posición de la barra de vida respecto a sus pies
@export var posicion_barra: Vector2 = Vector2(-20, -48)

# Movimiento de Godzilla
@export_group("Movimiento")
# Velocidad con la que camina hacia Kong
@export var velocidad: float = 30.0
# Límites a los que puede caminar (para que no se salga del escenario)
@export var limite_izquierdo: float = -120.0
@export var limite_derecho: float = 200.0
# Pon true si el dibujo original de Godzilla mira hacia la izquierda
@export var sprite_mira_a_la_izquierda: bool = true

# Ataque de cola (cerca)
@export_group("Ataque de cola")
# Si Kong está a esta distancia o menos, Godzilla lo golpea
@export var distancia_ataque: float = 70.0
# Si Kong está más alto que esto (por ejemplo saltando), el golpe falla
@export var alcance_vertical: float = 30.0
# Vida que le quita a Kong cada golpe (Kong tiene 100)
@export var daño_golpe: float = 10.0
# Tiempo que se espera si falta la animación (respaldo)
@export var retraso_golpe: float = 0.5
# Segundos de descanso entre un golpe y otro
@export var tiempo_entre_golpes: float = 2.0
# Si está activo, Godzilla se agacha, gira de espaldas y azota a Kong con la cola
@export var giro_en_ataque: bool = true
# Segundos que se agacha antes de girar
@export var tiempo_preparacion: float = 0.25
# Segundos que tarda en dar la vuelta
@export var tiempo_giro: float = 0.14
# Si está activo, el juego se congela un instante cuando el golpe le da a Kong
@export var congelar_al_pegar: bool = true

# Salto automático
@export_group("Salto")
# Si está activo, Godzilla salta solo: hacia Kong, para subir a bloques o para aplastarlo
@export var salto_automatico: bool = true
# Nombre de la animación de salto (si todavía no existe, usa solo un estirón y no da error)
@export var anim_salto: StringName = &"salto"
# Qué tan alto salta (en unidades del nivel), tiene que ser mayor que la altura de los bloques
@export var altura_salto: float = 60.0
# Fuerza con la que cae (más alto = salto más rápido)
@export var gravedad: float = 900.0
# Velocidad máxima con la que avanza hacia los lados mientras está en el aire
@export var velocidad_salto_x: float = 110.0
# Solo salta si Kong está a esta distancia o menos
@export var distancia_salto_max: float = 220.0
# Si Kong está más alto que esto (por ejemplo en un bloque), Godzilla salta hacia él
@export var altura_para_saltar: float = 40.0
# Segundos de descanso entre un salto y otro (se le suma un poco al azar)
@export var tiempo_entre_saltos: float = 5.0
# Vida que le quita a Kong si cae encima de él (Kong tiene 100)
@export var daño_pisoton: float = 15.0
# Distancia horizontal a la que aplasta a Kong al aterrizar
@export var ancho_pisoton: float = 45.0
# Si está activo, Godzilla puede aterrizar encima de los bloques
@export var aterrizar_en_plataformas: bool = true
# Capa de colisión de los bloques y el piso (la misma que usa Kong, normalmente la 1)
@export_flags_2d_physics var mascara_suelo: int = 1
# Distancia a la que detecta un bloque enfrente para saltarlo
@export var distancia_obstaculo: float = 35.0

# Rugido
@export_group("Rugido")
# Si está activo, Godzilla ruge de vez en cuando mientras camina
@export var rugido_ocasional: bool = true
# Segundos mínimos y máximos entre un rugido y otro
@export var rugido_cada_min: float = 9.0
@export var rugido_cada_max: float = 15.0

# Rayo atómico (lejos)
@export_group("Rayo atomico")
# Si está activo usa el rayo azul con efectos (rayo_atomico.gd)
@export var usar_rayo_atomico: bool = true
# Si lo desactivo, usa esta escena (por ejemplo bola_leve.tscn)
@export var escena_bola: PackedScene
# Velocidad del rayo
@export var velocidad_bola: float = 140.0
# Segundos entre cada rayo
@export var tiempo_entre_fuegos: float = 4.0
# Tiempo que se espera si falta la animación (respaldo)
@export var retraso_fuego: float = 0.4
# Posición de su boca en PÍXELES DEL DIBUJO medida desde sus pies
# x = hacia adelante, y = altura, se ajusta hasta que el rayo salga de su hocico
@export var boca_px: Vector2 = Vector2(100, 150)

# Dónde le pega Kong
@export_group("Zona de golpe")
# Mitad del ancho y alto de Godzilla para saber si Kong lo alcanza
@export var ancho_golpeable: float = 30.0
@export var alto_golpeable: float = 50.0

# Ruta del script del rayo atómico
const RUTA_RAYO: String = "res://ecenas/godzilla/rayo_atomico.gd"

# Vida actual de Godzilla
var _vida: int
# Indica si ya murió
var _muerto: bool = false
# Indica si está haciendo una animación importante (ataque o reacción)
var _ocupado: bool = false
# Tiempos de espera restantes para poder atacar otra vez
var _espera_golpe: float = 1.5
var _espera_fuego: float = 3.0
# Referencia a Kong
var _kong: Node2D
# Barra de vida que se crea por código
var _barra: ProgressBar
# Tamaño y posición originales del sprite (para volver a ellos después del giro)
var _escala_base: Vector2
var _pos_base: Vector2
# Animación del ataque de cola (se guarda para poder cancelarla)
var _tween_ataque: Tween

# Altura del piso donde está parado Godzilla (se calcula al empezar)
var _suelo_y: float
# Velocidad vertical y horizontal del salto
var _vel_y: float = 0.0
var _vel_x: float = 0.0
# Indica si está parado sobre el piso o un bloque
var _en_suelo: bool = true
# Indica si está en medio de un salto
var _saltando: bool = false
# Tiempos de espera restantes para volver a saltar
var _espera_salto: float = 3.0
var _espera_salto_obstaculo: float = 0.0
# Tiempo que falta para el próximo rugido ocasional
var _espera_rugido: float = 8.0

# Referencia a la animación de Godzilla
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Se ejecuta una sola vez al iniciar el nodo
func _ready() -> void:
	# Agrega a Godzilla al grupo "godzilla"
	add_to_group("godzilla")
	# Empieza con la vida completa
	_vida = vida_maxima
	# Guarda la escala original del sprite
	_escala_base = sprite.scale
	# Guarda la posición original del sprite
	_pos_base = sprite.position

	# Guarda la altura del piso donde lo puse y la afina con el piso real
	_suelo_y = global_position.y
	# Busca el piso real cuando termine el frame
	call_deferred("_buscar_suelo")
	# Crea la barra de vida
	_crear_barra()

	# Pone el origen del nodo en los pies de Godzilla
	if _tiene(anim_reposo):
		# Obtiene la textura del primer cuadro del reposo
		var textura := sprite.sprite_frames.get_frame_texture(anim_reposo, 0)
		# Si existe
		if textura:
			# Sube el sprite la mitad de su altura
			sprite.offset = Vector2(0, -textura.get_height() / 2.0)

	# Las animaciones de un solo uso no se repiten
	for nombre in [anim_golpe, anim_fuego, anim_dano, anim_muerte, anim_salto]:
		# Si la animación existe
		if _tiene(nombre):
			# La pone sin repetición
			sprite.sprite_frames.set_animation_loop(nombre, false)
	# Caminar y reposo sí se repiten
	for nombre in [anim_reposo, anim_caminar]:
		# Si la animación existe
		if _tiene(nombre):
			# La pone con repetición
			sprite.sprite_frames.set_animation_loop(nombre, true)

	# Avisa si falta alguna animación
	_avisar_animaciones_faltantes()

	# Conecta el cambio de cuadro con la función de los pasos
	sprite.frame_changed.connect(_on_frame_changed)
	# Empieza con la animación de reposo
	_jugar(anim_reposo)

# Se ejecuta en cada frame de física
func _physics_process(delta: float) -> void:
	# Gravedad y salto (también cuando ya murió, para que caiga al piso)
	_aplicar_fisica(delta)

	# Si ya murió, no hace nada más
	if _muerto:
		# Sale de la función
		return

	# Busca a Kong (el CharacterBody2D del grupo jugador)
	if not is_instance_valid(_kong):
		# Lo busca
		_kong = _buscar_kong()
		# Si no lo encuentra
		if _kong == null:
			# Sale de la función
			return

	# Resta el tiempo de espera del golpe
	_espera_golpe -= delta
	# Del fuego
	_espera_fuego -= delta
	# Del salto
	_espera_salto -= delta
	# Del salto sobre un obstáculo
	_espera_salto_obstaculo -= delta
	# Y del rugido
	_espera_rugido -= delta

	# Distancia horizontal hacia Kong (positiva = Kong está a la derecha)
	var dx: float = _kong.global_position.x - global_position.x

	# Godzilla siempre mira hacia Kong
	if sprite_mira_a_la_izquierda:
		# Voltea el sprite
		sprite.flip_h = dx > 0.0
	# Si el dibujo mira hacia el otro lado
	else:
		# Voltea el sprite al revés
		sprite.flip_h = dx < 0.0

	# Si está atacando, reaccionando o en el aire, no decide nada nuevo
	if _ocupado or not _en_suelo:
		# Sale de la función
		return

	# Distancia sin signo
	var distancia: float = abs(dx)
	# Hacia qué lado está Kong
	var lado: float = sign(dx)

	# Kong está más arriba que Godzilla (por ejemplo parado en un bloque)
	var kong_arriba: bool = _kong.global_position.y < global_position.y - altura_para_saltar
	# Indica si puede saltar
	var puede_saltar: bool = salto_automatico and _espera_salto <= 0.0

	# Si puede saltar, Kong está arriba y cerca
	if puede_saltar and kong_arriba and distancia <= distancia_salto_max:
		# Kong está en un bloque alto: salta hacia él
		_saltar()
	# Si Kong está cerca, el golpe está listo y no está arriba
	elif distancia <= distancia_ataque and _espera_golpe <= 0.0 and not kong_arriba:
		# Kong está cerca: lo golpea con la cola
		_ataque_cuerpo()
	# Si Kong está lejos y el fuego está listo
	elif distancia > distancia_ataque * 1.5 and _espera_fuego <= 0.0:
		# Kong está lejos: le lanza el rayo
		_lanzar_fuego()
	# Si puede saltar y Kong está a media distancia
	elif puede_saltar and distancia > distancia_ataque * 1.2 and distancia <= distancia_salto_max:
		# Kong está a media distancia: salta para caerle encima
		_saltar()
	# Si todavía está lejos de Kong
	elif distancia > distancia_ataque * 0.8:
		# Si hay un bloque enfrente
		if salto_automatico and _espera_salto_obstaculo <= 0.0 and _hay_obstaculo(lado):
			# Hay un bloque enfrente: lo salta
			_saltar()
		# Si no hay bloque
		else:
			# Camina hacia Kong sin salirse de los límites
			var nueva_x: float = clamp(position.x + lado * velocidad * delta, limite_izquierdo, limite_derecho)
			# Si se movió
			if nueva_x != position.x:
				# Actualiza su posición
				position.x = nueva_x
				# Animación de caminar
				_jugar(anim_caminar)
				# De vez en cuando ruge mientras camina (sin detenerse)
				if rugido_ocasional and _espera_rugido <= 0.0:
					# Ruge
					_rugir_caminando()
			# Si no se movió
			else:
				# Animación de reposo
				_jugar(anim_reposo)
	# Si ya está cerca de Kong
	else:
		# Animación de reposo
		_jugar(anim_reposo)

# Busca el cuerpo de Kong (el Area2D de Kong también está en el grupo "jugador")
func _buscar_kong() -> Node2D:
	# Recorre los nodos del grupo
	for nodo in get_tree().get_nodes_in_group("jugador"):
		# Si es el CharacterBody2D
		if nodo is CharacterBody2D:
			# Lo devuelve
			return nodo
	# Si no lo encuentra, devuelve nada
	return null

# Golpe de cola: se agacha, gira de espaldas, azota con la cola y vuelve a girar
func _ataque_cuerpo() -> void:
	# Marca que está ocupado
	_ocupado = true
	# Reinicia el tiempo de espera del golpe
	_espera_golpe = tiempo_entre_golpes

	# Lado hacia donde está Kong (1 = derecha, -1 = izquierda)
	var lado: float = 1.0
	# Si Kong está a la izquierda
	if is_instance_valid(_kong) and _kong.global_position.x < global_position.x:
		# Cambia el lado
		lado = -1.0

	# 1) Preparación: se agacha y se echa un poco hacia atrás
	_tween_ataque = create_tween().set_parallel(true)
	_tween_ataque.tween_property(sprite, "position:x", _pos_base.x - lado * 6.0, tiempo_preparacion)
	_tween_ataque.tween_property(sprite, "scale:y", _escala_base.y * 0.94, tiempo_preparacion)
	# Espera a que termine
	await _tween_ataque.finished
	# Si murió mientras tanto
	if _muerto:
		# Sale de la función
		return

	# 2) Empieza la animación y, al mismo tiempo, da la vuelta (queda de espaldas a Kong)
	_jugar(anim_golpe, true)
	# Sonido del giro
	_sfx("godzilla_giro")
	# Si el giro está activado
	if giro_en_ataque:
		# Crea un tween nuevo
		_tween_ataque = create_tween()
		# Gira el sprite
		_tween_ataque.tween_method(_aplicar_giro, 1.0, -1.0, tiempo_giro)
		# Y recupera la altura
		_tween_ataque.parallel().tween_property(sprite, "scale:y", _escala_base.y, tiempo_giro)
		# Y la posición
		_tween_ataque.parallel().tween_property(sprite, "position:x", _pos_base.x, tiempo_giro)
		# Espera a que termine
		await _tween_ataque.finished
		# Si murió mientras tanto
		if _muerto:
			# Sale de la función
			return

	# 3) Espera el cuadro donde se ve el latigazo
	await _esperar_frame(anim_golpe, frame_golpe, retraso_golpe)
	# Si murió mientras tanto
	if _muerto:
		# Sale de la función
		return

	# Efectos del latigazo: arco de energía, polvo y temblor
	_efecto_latigazo(lado)
	# Polvo
	_polvo(lado)
	# Temblor de cámara
	_sacudir(1.5, 0.15)
	# Sonido del golpe de cola
	_sfx("godzilla_cola")

	# Si Kong se alejó o saltó, el golpe falla
	if is_instance_valid(_kong):
		# Revisa si está cerca en horizontal
		var cerca_x: bool = abs(_kong.global_position.x - global_position.x) <= distancia_ataque + 10.0
		# Y en vertical
		var cerca_y: bool = abs(_kong.global_position.y - global_position.y) <= alcance_vertical
		# Si está cerca y puede recibir el golpe
		if cerca_x and cerca_y and _kong.has_method("recibir_golpe_godzilla"):
			# Le quita vida a Kong
			_kong.recibir_golpe_godzilla(daño_golpe)
			# Sonido del impacto
			_sfx("impacto_fuerte")
			# Temblor fuerte
			_sacudir(4.0, 0.3)
			# Si está activado congelar al pegar
			if congelar_al_pegar:
				# Congela el juego un instante
				_congelar(0.08)

	# 4) Termina la animación y vuelve a girar hacia Kong
	await _esperar_fin(anim_golpe, 0.4)
	# Si murió mientras tanto
	if _muerto:
		# Sale de la función
		return

	# Si el giro está activado
	if giro_en_ataque:
		# Crea un tween nuevo
		_tween_ataque = create_tween()
		# Vuelve a girar de frente
		_tween_ataque.tween_method(_aplicar_giro, -1.0, 1.0, tiempo_giro)
		# Espera a que termine
		await _tween_ataque.finished
		# Si murió mientras tanto
		if _muerto:
			# Sale de la función
			return

	# Ya puede decidir otra cosa
	_ocupado = false

# Rayo atómico: sale de su boca en el cuadro donde abre el hocico
func _lanzar_fuego() -> void:
	# Marca que está ocupado
	_ocupado = true
	# Reinicia el tiempo de espera del fuego
	_espera_fuego = tiempo_entre_fuegos
	# Animación del aliento atómico
	_jugar(anim_fuego, true)
	# Sonido de carga
	_sfx("godzilla_carga")

	# Espera el cuadro donde sale el rayo
	await _esperar_frame(anim_fuego, frame_fuego, retraso_fuego)
	# Si murió mientras tanto
	if _muerto:
		# Sale de la función
		return

	# Dispara el rayo
	_disparar()

	# Espera a que termine la animación
	await _esperar_fin(anim_fuego, 0.5)
	# Ya puede decidir otra cosa
	_ocupado = false

# Crea el rayo y lo manda hacia donde está Kong en este momento
func _disparar() -> void:
	# Si Kong no existe
	if not is_instance_valid(_kong):
		# Sale de la función
		return

	# Indica si Kong está a la derecha
	var hacia_derecha: bool = _kong.global_position.x > global_position.x
	# Calcula dónde está su boca
	var boca_global: Vector2 = _posicion_boca(hacia_derecha)
	# Calcula la dirección hacia Kong
	var direccion: Vector2 = (_kong.global_position - boca_global)
	# Si está casi en el mismo punto
	if direccion.length() < 1.0:
		# Usa derecha o izquierda
		direccion = Vector2.RIGHT if hacia_derecha else Vector2.LEFT
	# Normaliza la dirección
	direccion = direccion.normalized()

	# Sonido del rayo
	_sfx("godzilla_rayo")

	# Crea el rayo atómico
	var rayo = _crear_rayo()
	# Si se pudo crear
	if rayo != null:
		# Le asigna la velocidad
		rayo.velocidad = velocidad_bola
		# Le asigna la dirección
		rayo.direccion = direccion
		# Lo agrega al nivel
		get_parent().add_child(rayo)
		# Lo coloca en su boca
		rayo.global_position = boca_global
	# Si no, usa la bola normal
	elif escena_bola:
		# Crea la bola
		var bola = escena_bola.instantiate()
		# Le asigna la velocidad
		bola.velocidad = velocidad_bola
		# Le asigna la dirección
		bola.direccion = Vector2.RIGHT if hacia_derecha else Vector2.LEFT
		# La agrega al nivel
		get_parent().add_child(bola)
		# La coloca en su boca
		bola.global_position = boca_global
		# Voltea la imagen de la bola
		bola.get_node("Sprite2D").flip_h = hacia_derecha

# Calcula dónde está su boca en el mundo (toma en cuenta la escala y hacia dónde mira)
func _posicion_boca(hacia_derecha: bool) -> Vector2:
	# Lado hacia donde mira
	var lado: float = 1.0 if hacia_derecha else -1.0
	# Calcula el desplazamiento de la boca
	var desplazamiento := Vector2(
		boca_px.x * lado * sprite.scale.x * scale.x,
		-boca_px.y * sprite.scale.y * scale.y
	)
	# Devuelve la posición de la boca
	return global_position + desplazamiento

# Kong llama a esta función para saber si su golpe alcanza a Godzilla
func esta_en_alcance(pos_kong: Vector2, alcance_kong: float) -> bool:
	# Revisa si está cerca en horizontal
	var cerca_x: bool = abs(pos_kong.x - global_position.x) <= alcance_kong + ancho_golpeable
	# Positivo = Kong está arriba de los pies de Godzilla
	var altura: float = global_position.y - pos_kong.y
	# Devuelve verdadero si lo alcanza
	return cerca_x and altura >= -20.0 and altura <= alto_golpeable

# Kong llama a esta función cuando le acierta un golpe
func recibir_golpe(cantidad: int = 1) -> void:
	# Si ya murió
	if _muerto:
		# No hace nada
		return

	# Le resta vida
	_vida = max(_vida - cantidad, 0)
	# Actualiza la barra
	_barra.value = _vida
	# Sonido de daño
	_sfx("godzilla_daño")

	# Parpadeo rojo para que se note el golpe
	sprite.modulate = Color(1.0, 0.3, 0.3)
	# Vuelve poco a poco al color normal
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.25)

	# Si se quedó sin vida
	if _vida <= 0:
		# Muere
		_morir()
	# Si no está ocupado
	elif not _ocupado:
		# Muestra la animación de daño
		_reaccion_dano()

# Muestra la animación de daño (solo si no está atacando)
func _reaccion_dano() -> void:
	# Marca que está ocupado
	_ocupado = true
	# Reproduce la animación de daño
	_jugar(anim_dano, true, velocidad_anim_dano)
	# Espera a que termine
	await _esperar_fin(anim_dano, 0.3)
	# Si no murió
	if not _muerto:
		# Ya puede decidir otra cosa
		_ocupado = false

# Función que se ejecuta cuando Godzilla muere
func _morir() -> void:
	# Marca que murió
	_muerto = true
	# Marca que está ocupado
	_ocupado = true
	# Esconde la barra de vida
	_barra.hide()

	# Cancela cualquier ataque a medias y deja el sprite en su posición normal
	if _tween_ataque:
		# Detiene el tween
		_tween_ataque.kill()
	# Restablece la escala
	sprite.scale = _escala_base
	# Restablece la posición
	sprite.position = _pos_base
	# Velocidad normal del juego
	Engine.time_scale = 1.0
	# Detiene el salto horizontal
	_vel_x = 0.0

	# Detiene los generadores de bolas
	# get_tree().call_group("spawner", "detener")
	# Y borra las que quedan en pantalla
	get_tree().call_group("bolas", "queue_free")

	# Sonido de muerte
	_sfx("godzilla_muerte")
	# Temblor de cámara
	_sacudir(4.0, 0.6)
	# Animación de muerte
	_jugar(anim_muerte, true)
	# Espera a que termine la animación
	await _esperar_fin(anim_muerte, 1.0)

	# Deja ver el cuerpo caído un momento y luego se desvanece
	await get_tree().create_timer(1.0).timeout
	# Lo desvanece
	create_tween().tween_property(sprite, "modulate:a", 0.0, 1.0)
	# Espera a que se desvanezca
	await get_tree().create_timer(1.0).timeout

	# Emite la señal de que murió
	godzilla_muerto.emit()

	# Avisa a la escena principal, ella decide si ya se ganó (también hacen falta todos los diamantes)
	var principal := get_tree().current_scene
	# Si existe la función siguiente_nivel
	if principal and principal.has_method("siguiente_nivel"):
		# La ejecuta
		principal.siguiente_nivel()

# Sonido y temblor cuando su pie toca el piso al caminar
func _on_frame_changed() -> void:
	# Si está caminando y está en un cuadro de paso
	if sprite.animation == anim_caminar and sprite.frame in frames_pasos:
		# Sonido del paso
		_sfx("godzilla_paso", 1.0, -4.0)
		# Temblor de cámara
		_sacudir(0.8, 0.12)

# Indica si existe una animación con ese nombre
func _tiene(nombre: StringName) -> bool:
	# Devuelve verdadero si existe
	return sprite.sprite_frames != null and sprite.sprite_frames.has_animation(nombre)

# Reproduce una animación si existe
func _jugar(nombre: StringName, desde_inicio: bool = false, velocidad_anim: float = 1.0) -> void:
	# Si no existe
	if not _tiene(nombre):
		# Sale de la función
		return
	# Si hay que empezar desde el inicio o es otra animación
	if desde_inicio or sprite.animation != nombre or not sprite.is_playing():
		# La reproduce
		sprite.play(nombre, velocidad_anim)
		# Si hay que empezar desde el inicio
		if desde_inicio:
			# Pone el primer cuadro
			sprite.frame = 0

# Espera hasta que la animación llegue a un cuadro (o un tiempo si la animación no existe)
func _esperar_frame(nombre: StringName, indice: int, respaldo: float) -> void:
	# Si la animación existe
	if _tiene(nombre):
		# Si se pide un cuadro que no existe, se usa el último cuadro
		# Así Godzilla nunca se queda esperando para siempre
		# Calcula el último cuadro
		var ultimo: int = sprite.sprite_frames.get_frame_count(nombre) - 1
		# Elige el cuadro objetivo
		var objetivo: int = min(indice, ultimo)
		# Mientras no llegue al cuadro
		while sprite.animation == nombre and sprite.frame < objetivo and sprite.is_playing():
			# Espera el siguiente cambio de cuadro
			await sprite.frame_changed
	# Si la animación no existe
	else:
		# Espera el tiempo de respaldo
		await get_tree().create_timer(respaldo).timeout

# Espera hasta que termine la animación (o un tiempo si la animación no existe)
func _esperar_fin(nombre: StringName, respaldo: float) -> void:
	# Si la animación existe y se está reproduciendo
	if _tiene(nombre) and sprite.animation == nombre and sprite.is_playing():
		# Espera a que termine
		await sprite.animation_finished
	# Si no
	else:
		# Espera el tiempo de respaldo
		await get_tree().create_timer(respaldo).timeout

# Crea la barra de vida arriba de Godzilla
func _crear_barra() -> void:
	# Crea la barra
	_barra = ProgressBar.new()
	# Valor mínimo
	_barra.min_value = 0
	# Valor máximo
	_barra.max_value = vida_maxima
	# Empieza llena
	_barra.value = vida_maxima
	# Oculta el porcentaje
	_barra.show_percentage = false
	# Tamaño mínimo
	_barra.custom_minimum_size = Vector2(40, 5)
	# Tamaño
	_barra.size = Vector2(40, 5)
	# Posición
	_barra.position = posicion_barra

	# Estilo del relleno
	var relleno := StyleBoxFlat.new()
	# Color del relleno
	relleno.bg_color = Color(0.9, 0.15, 0.15)
	# Estilo del fondo
	var fondo := StyleBoxFlat.new()
	# Color del fondo
	fondo.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	# Aplica el estilo del relleno
	_barra.add_theme_stylebox_override("fill", relleno)

	# Nombre del jefe sobre su barra de vida (se esconde junto con la barra)
	var nombre := Label.new()
	# Texto
	nombre.text = "GODZILLA"
	# Lo centra
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Tamaño
	nombre.size = Vector2(40, 10)
	# Posición
	nombre.position = Vector2(0, -11)
	# Tamaño de la letra
	nombre.add_theme_font_size_override("font_size", 7)
	# Color de la letra
	nombre.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	# Color del borde
	nombre.add_theme_color_override("font_outline_color", Color.BLACK)
	# Grosor del borde
	nombre.add_theme_constant_override("outline_size", 3)
	# Lo agrega a la barra
	_barra.add_child(nombre)
	# Aplica el estilo del fondo
	_barra.add_theme_stylebox_override("background", fondo)

	# Agrega la barra a Godzilla
	add_child(_barra)

# Revisa los nombres de las animaciones y avisa en la pestaña Salida si alguno no existe
func _avisar_animaciones_faltantes() -> void:
	# Si no hay SpriteFrames asignado
	if sprite.sprite_frames == null:
		# Aviso en la consola
		push_warning("Godzilla: el AnimatedSprite2D no tiene SpriteFrames asignado.")
		# Sale de la función
		return
	# Lista de animaciones que faltan
	var faltan: Array[String] = []
	# Recorre las animaciones que necesita
	for nombre in [anim_reposo, anim_caminar, anim_golpe, anim_fuego, anim_dano, anim_muerte]:
		# Si no existe
		if not sprite.sprite_frames.has_animation(nombre):
			# La agrega a la lista
			faltan.append(str(nombre))
	# Si falta alguna
	if faltan.size() > 0:
		# Aviso en la consola con las que faltan y las que sí existen
		push_warning("Godzilla: no existen estas animaciones: %s. Las que si existen son: %s. Cambia los nombres en el Inspector (grupo Animaciones)." % [", ".join(faltan), ", ".join(sprite.sprite_frames.get_animation_names())])

# Crea el rayo atómico si el script existe y funciona, si no, devuelve null
func _crear_rayo():
	# Si el rayo atómico está desactivado
	if not usar_rayo_atomico:
		# Devuelve null
		return null
	# Carga el script del rayo
	var script = load(RUTA_RAYO)
	# Si no se pudo cargar o no se puede crear
	if script == null or not script.can_instantiate():
		# Aviso en la consola
		push_warning("Godzilla: no se pudo usar rayo_atomico.gd, se usa la bola normal.")
		# Devuelve null
		return null
	# Crea el rayo
	return script.new()

# Reproduce un efecto de sonido solo si el Autoload Audio está registrado
func _sfx(nombre: String, pitch: float = 1.0, volumen_db: float = 0.0) -> void:
	# Busca el Autoload Audio
	var audio = get_node_or_null("/root/Audio")
	# Si existe
	if audio:
		# Reproduce el sonido
		audio.sfx(nombre, pitch, volumen_db)

# Hace temblar la cámara solo si el Autoload Audio está registrado
func _sacudir(fuerza: float, duracion: float) -> void:
	# Busca el Autoload Audio
	var audio = get_node_or_null("/root/Audio")
	# Si existe
	if audio:
		# Hace temblar la cámara
		audio.sacudir_camara(fuerza, duracion)

# Cambia la música solo si el Autoload Audio está registrado
func _musica(nombre: String, repetir: bool = true) -> void:
	# Busca el Autoload Audio
	var audio = get_node_or_null("/root/Audio")
	# Si existe
	if audio:
		# Cambia la música
		audio.musica(nombre, repetir)

# Por seguridad, si Godzilla desaparece mientras el juego está congelado, vuelve a la velocidad normal
func _exit_tree() -> void:
	# Velocidad normal del juego
	Engine.time_scale = 1.0

# Gira el sprite de lado a lado (1 = de frente, 0 = de canto, -1 = de espaldas)
func _aplicar_giro(valor: float) -> void:
	# Cambia la escala horizontal
	sprite.scale.x = _escala_base.x * valor

# Congela el juego un instante para que el golpe se sienta pesado
func _congelar(duracion: float) -> void:
	# Casi detiene el tiempo
	Engine.time_scale = 0.05
	# Espera la duración indicada
	await get_tree().create_timer(duracion, true, false, true).timeout
	# Velocidad normal del juego
	Engine.time_scale = 1.0

# Dibuja un arco brillante que representa el latigazo de la cola y se desvanece
func _efecto_latigazo(lado: float) -> void:
	# Radio del arco
	var radio: float = distancia_ataque * 0.9

	# Crea la línea
	var arco := Line2D.new()
	# Recorre 13 puntos
	for i in 13:
		# Avance de 0 a 1
		var avance: float = i / 12.0
		# Ángulo del punto
		var angulo: float = lerp(deg_to_rad(150.0), deg_to_rad(10.0), avance)
		# Agrega el punto al arco
		arco.add_point(Vector2(lado * cos(angulo) * radio, -sin(angulo) * radio * 0.45 - 8.0))

	# Delgado al empezar y grueso al final, como un latigazo
	var grosor := Curve.new()
	grosor.add_point(Vector2(0.0, 0.1))
	grosor.add_point(Vector2(1.0, 1.0))
	# Aplica la curva de grosor
	arco.width_curve = grosor
	# Grosor máximo
	arco.width = 9.0

	# De transparente a blanco brillante
	var degradado := Gradient.new()
	degradado.set_color(0, Color(0.5, 0.75, 1.0, 0.0))
	degradado.set_color(1, Color(1.0, 1.0, 1.0, 1.0))
	# Aplica el degradado
	arco.gradient = degradado

	# Material que suma luz para que brille
	var aditivo := CanvasItemMaterial.new()
	aditivo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	# Aplica el material
	arco.material = aditivo
	# Lo dibuja por encima
	arco.z_index = 5

	# Lo agrega al nivel
	get_parent().add_child(arco)
	# Lo coloca en la posición de Godzilla
	arco.global_position = global_position
	# Tamaño inicial
	arco.scale = Vector2(0.85, 0.85)

	# Crea un tween en paralelo
	var t := create_tween().set_parallel(true)
	# Agranda el arco
	t.tween_property(arco, "scale", Vector2(1.1, 1.1), 0.22)
	# Lo desvanece
	t.tween_property(arco, "modulate:a", 0.0, 0.22)
	# Al terminar, lo elimina
	t.chain().tween_callback(arco.queue_free)

# Polvo que sale del piso cuando la cola golpea
func _polvo(lado: float) -> void:
	# Crea las partículas
	var p := CPUParticles2D.new()
	# Salen una sola vez
	p.one_shot = true
	# Salen casi todas al mismo tiempo
	p.explosiveness = 0.9
	# Cantidad
	p.amount = 14
	# Tiempo de vida
	p.lifetime = 0.45
	# Dirección
	p.direction = Vector2(lado, -0.6)
	# Se abren un poco
	p.spread = 35.0
	# Gravedad
	p.gravity = Vector2(0, 150)
	# Velocidad mínima
	p.initial_velocity_min = 25.0
	# Velocidad máxima
	p.initial_velocity_max = 70.0
	# Tamaño mínimo
	p.scale_amount_min = 2.0
	# Tamaño máximo
	p.scale_amount_max = 4.0
	# Color del polvo
	p.color = Color(0.8, 0.75, 0.65)

	# Se desvanece al final de su vida
	var degradado := Gradient.new()
	degradado.set_color(0, Color(1, 1, 1, 1))
	degradado.set_color(1, Color(1, 1, 1, 0))
	# Aplica el degradado
	p.color_ramp = degradado

	# Las agrega al nivel
	get_parent().add_child(p)
	# Las coloca delante de Godzilla
	p.global_position = global_position + Vector2(lado * distancia_ataque * 0.5, -2.0)
	# Empiezan a salir
	p.emitting = true
	# Cuando pasa el tiempo, las elimina
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)

# Empieza un salto hacia donde está Kong
func _saltar() -> void:
	# Marca que está ocupado
	_ocupado = true
	# Marca que está saltando
	_saltando = true
	# Ya no está en el suelo
	_en_suelo = false
	# Reinicia el tiempo de espera del salto con un poco de azar
	_espera_salto = tiempo_entre_saltos + randf() * 2.0
	# Reinicia el tiempo de espera del salto sobre obstáculo
	_espera_salto_obstaculo = 1.5

	# Velocidad inicial para llegar a la altura deseada
	var velocidad_subida: float = sqrt(2.0 * gravedad * altura_salto)
	# Velocidad vertical hacia arriba
	_vel_y = -velocidad_subida

	# Calcula cuánto avanza hacia los lados para caer cerca de Kong
	var tiempo_aire: float = 2.0 * velocidad_subida / gravedad
	# Distancia horizontal hacia Kong
	var distancia_x: float = 0.0
	# Si Kong existe
	if is_instance_valid(_kong):
		# Calcula la distancia
		distancia_x = _kong.global_position.x - global_position.x
	# Velocidad horizontal limitada
	_vel_x = clamp(distancia_x / tiempo_aire, -velocidad_salto_x, velocidad_salto_x)

	# Animación de salto
	_jugar(anim_salto, true)
	# Sonido del salto
	_sfx("godzilla_salto")
	# Lo estira un instante
	_deformar(Vector2(0.9, 1.12), 0.12)

# Aplica la gravedad, mueve el salto y detecta cuándo toca el piso o un bloque
func _aplicar_fisica(delta: float) -> void:
	# Avance horizontal mientras está en el aire
	if _saltando:
		# Mueve a Godzilla sin salirse de los límites
		position.x = clamp(position.x + _vel_x * delta, limite_izquierdo, limite_derecho)

	# Aplica la gravedad
	_vel_y += gravedad * delta
	# Altura actual
	var y_actual: float = global_position.y
	# Altura nueva
	var y_nueva: float = y_actual + _vel_y * delta

	# Altura final
	var y_final: float = y_nueva
	# Indica si tocó el suelo
	var toco_suelo: bool = false

	# Solo busca suelo cuando va cayendo (si va subiendo atraviesa los bloques)
	if _vel_y >= 0.0:
		# Suelo por defecto
		var suelo: float = _suelo_y
		# Si puede aterrizar en los bloques
		if aterrizar_en_plataformas:
			# Punto de inicio del rayo
			var desde := Vector2(global_position.x, y_actual - 12.0)
			# Punto final del rayo
			var hasta := Vector2(global_position.x, y_nueva + 1.0)
			# Busca un bloque
			var golpe: Dictionary = _rayo(desde, hasta)
			# Si encontró uno
			if not golpe.is_empty():
				# Altura del bloque
				var y_bloque: float = golpe["position"].y
				# Usa el suelo más alto
				suelo = min(suelo, y_bloque)
		# Si llega al suelo
		if y_nueva >= suelo - 1.0:
			# Se queda en el suelo
			y_final = suelo
			# Marca que tocó el suelo
			toco_suelo = true

	# Aplica la altura final
	global_position.y = y_final
	# Si tocó el suelo
	if toco_suelo:
		# Detiene la caída
		_vel_y = 0.0

	# Guarda si antes estaba en el suelo
	var estaba_en_suelo: bool = _en_suelo
	# Actualiza si está en el suelo
	_en_suelo = toco_suelo
	# Si acaba de tocar el suelo
	if toco_suelo and not estaba_en_suelo:
		# Aterriza
		_aterrizar()

# Cuando toca el piso después de un salto: polvo, temblor y pisotón
func _aterrizar() -> void:
	# Si murió
	if _muerto:
		# Sale de la función
		return

	# Guarda si venía saltando
	var venia_saltando: bool = _saltando
	# Ya no está saltando
	_saltando = false
	# Detiene el movimiento horizontal
	_vel_x = 0.0
	# Lo aplasta un instante
	_deformar(Vector2(1.12, 0.88), 0.1)

	# Si solo se cayó de un bloque, no hace pisotón
	if not venia_saltando:
		# Sale de la función
		return

	# Polvo a la derecha
	_polvo(1.0)
	# Polvo a la izquierda
	_polvo(-1.0)
	# Sonido del aterrizaje
	_sfx("godzilla_aterriza")
	# Temblor de cámara
	_sacudir(3.0, 0.25)

	# Si Kong está debajo, lo aplasta (Kong lo esquiva saltando o alejándose)
	if is_instance_valid(_kong) and _kong.has_method("recibir_golpe_godzilla"):
		# Revisa si está cerca en horizontal
		var cerca_x: bool = abs(_kong.global_position.x - global_position.x) <= ancho_pisoton
		# Y en vertical
		var cerca_y: bool = abs(_kong.global_position.y - global_position.y) <= alcance_vertical
		# Si está cerca
		if cerca_x and cerca_y:
			# Le quita vida a Kong
			_kong.recibir_golpe_godzilla(daño_pisoton)

	# Animación de reposo
	_jugar(anim_reposo, true)
	# Espera un momento
	await get_tree().create_timer(0.35).timeout
	# Si no murió
	if not _muerto:
		# Ya puede decidir otra cosa
		_ocupado = false

# Busca el piso que hay debajo de Godzilla al empezar el nivel
func _buscar_suelo() -> void:
	# Espera un frame de física
	await get_tree().physics_frame
	# Lanza una línea hacia abajo
	var golpe: Dictionary = _rayo(global_position + Vector2(0, -20), global_position + Vector2(0, 400))
	# Si encontró algo
	if not golpe.is_empty():
		# Guarda la altura del piso
		_suelo_y = golpe["position"].y

# Lanza una línea invisible y devuelve lo primero que toca (o vacío si no toca nada)
func _rayo(desde: Vector2, hasta: Vector2) -> Dictionary:
	# Crea la consulta de la línea
	var consulta := PhysicsRayQueryParameters2D.create(desde, hasta, mascara_suelo)
	# Devuelve lo que toca
	return get_world_2d().direct_space_state.intersect_ray(consulta)

# Indica si hay un bloque justo enfrente (los bordes del nivel no cuentan)
func _hay_obstaculo(lado: float) -> bool:
	# Punto de inicio
	var desde: Vector2 = global_position + Vector2(0, -10)
	# Punto final
	var hasta: Vector2 = desde + Vector2(lado * distancia_obstaculo, 0)
	# Lanza la línea
	var golpe: Dictionary = _rayo(desde, hasta)
	# Si no toca nada
	if golpe.is_empty():
		# No hay obstáculo
		return false
	# Obtiene lo que tocó
	var cuerpo = golpe["collider"]
	# Si es un borde del nivel
	if cuerpo is Node and cuerpo.name.begins_with("borde"):
		# No cuenta como obstáculo
		return false
	# Si no, hay obstáculo
	return true

# Estira o aplasta el sprite un instante (da sensación de peso al saltar y caer)
func _deformar(factor: Vector2, tiempo: float) -> void:
	# Si murió
	if _muerto:
		# Sale de la función
		return
	# Obtiene hacia qué lado está volteado
	var signo: float = sign(sprite.scale.x)
	# Si no tiene signo
	if signo == 0.0:
		# Usa positivo
		signo = 1.0
	# Crea un tween
	var t := create_tween()
	# Deforma el sprite
	t.tween_property(sprite, "scale", Vector2(_escala_base.x * signo * factor.x, _escala_base.y * factor.y), tiempo)
	# Lo devuelve a su forma normal
	t.tween_property(sprite, "scale", Vector2(_escala_base.x * signo, _escala_base.y), tiempo)

# Rugido mientras camina: suena el rugido, tiembla la pantalla y Godzilla sigue avanzando
func _rugir_caminando() -> void:
	# Elige cuándo será el próximo rugido
	_espera_rugido = randf_range(rugido_cada_min, rugido_cada_max)
	# Sonido del rugido
	_sfx("godzilla_rugido")
	# Lo agranda un poco
	_deformar(Vector2(1.04, 1.04), 0.3)
	# Temblor de cámara
	_sacudir(1.5, 2.0)
