# Rayo atómico azul de Godzilla
# Todo su dibujo se crea por código, no necesita escena ni imágenes
# Tiene un núcleo brillante que late, estela de partículas, chispas al explotar
# y hace temblar la cámara cuando golpea a Kong
# Le da nombre de clase para poder usarlo desde otros scripts
class_name RayoAtomico
# Hereda de Area2D para detectar cuando toca a Kong
extends Area2D

# Velocidad del rayo (Godzilla se la asigna al crearlo)
var velocidad: float = 140.0
# Dirección hacia donde va (Godzilla se la asigna al crearlo)
var direccion: Vector2 = Vector2.LEFT

# Tamaño de la zona que hace daño
var radio: float = 5.0

# Guarda si ya está explotando
var _explotando: bool = false
# Guarda el tiempo para el latido del halo
var _tiempo: float = 0.0
# Halo azul grande
var _luz: Sprite2D
# Núcleo blanco brillante
var _nucleo: Sprite2D
# Estela de partículas
var _estela: CPUParticles2D

# Se ejecuta una sola vez al iniciar el nodo
func _ready() -> void:
	# Se comporta igual que las otras bolas: Kong lo detecta y se borra al cambiar de nivel
	add_to_group("bolas")
	# Capa de colisión del rayo
	collision_layer = 2
	# Hace que detecte el suelo y los bordes
	collision_mask = 1
	# Cuando choca con algo llama a la función que lo hace explotar
	body_entered.connect(_al_chocar)

	# Crea la zona de daño
	var forma := CircleShape2D.new()
	# Le pone el tamaño
	forma.radius = radio
	# Crea el nodo de colisión
	var colision := CollisionShape2D.new()
	# Le asigna la forma
	colision.shape = forma
	# Lo agrega al rayo
	add_child(colision)

	# Textura de brillo que se usa en los efectos
	var brillo := Efectos.textura_brillo()
	# Material que suma la luz
	var aditivo := Efectos.material_aditivo()

	# Estela de partículas que se queda en el aire detrás del rayo
	_estela = CPUParticles2D.new()
	# Le pone el material que suma luz
	_estela.material = aditivo
	# Le pone la textura de brillo
	_estela.texture = brillo
	# Cantidad de partículas
	_estela.amount = 36
	# Tiempo de vida de cada partícula
	_estela.lifetime = 0.45
	# Las partículas se quedan en el aire, no siguen al rayo
	_estela.local_coords = false
	# Salen hacia atrás del rayo
	_estela.direction = -direccion
	# Se abren un poco
	_estela.spread = 25.0
	# Sin gravedad
	_estela.gravity = Vector2.ZERO
	# Velocidad mínima
	_estela.initial_velocity_min = 10.0
	# Velocidad máxima
	_estela.initial_velocity_max = 35.0
	# Tamaño mínimo
	_estela.scale_amount_min = 0.12
	# Tamaño máximo
	_estela.scale_amount_max = 0.3
	# Color que va de azul claro a azul transparente
	_estela.color_ramp = Efectos.rampa(Color(0.7, 0.9, 1.0, 0.9), Color(0.1, 0.3, 1.0, 0.0))
	# Agrega la estela al rayo
	add_child(_estela)

	# Halo azul grande
	_luz = Sprite2D.new()
	# Le pone la textura de brillo
	_luz.texture = brillo
	# Le pone el material que suma luz
	_luz.material = aditivo
	# Color azul
	_luz.modulate = Color(0.3, 0.65, 1.0, 0.9)
	# Tamaño del halo
	_luz.scale = Vector2(0.55, 0.55)
	# Agrega el halo al rayo
	add_child(_luz)

	# Núcleo blanco brillante
	_nucleo = Sprite2D.new()
	# Le pone la textura de brillo
	_nucleo.texture = brillo
	# Le pone el material que suma luz
	_nucleo.material = aditivo
	# Tamaño del núcleo
	_nucleo.scale = Vector2(0.22, 0.22)
	# Agrega el núcleo al rayo
	add_child(_nucleo)

# Se ejecuta en cada frame
func _process(delta: float) -> void:
	# Si ya está explotando, no se mueve
	if _explotando:
		# Sale de la función
		return

	# Aumenta el tiempo
	_tiempo += delta

	# Avanza en línea recta hacia donde estaba Kong
	position += direccion * velocidad * delta

	# El halo late para que parezca energía viva
	var pulso: float = 1.0 + 0.15 * sin(_tiempo * 25.0)
	# Cambia el tamaño del halo
	_luz.scale = Vector2(0.55, 0.55) * pulso

	# Por seguridad, se borra si se aleja demasiado
	if abs(position.x) > 400.0 or abs(position.y) > 300.0:
		# Elimina el rayo
		queue_free()

# Función que se activa cuando Kong toca el rayo
func impactar(kong) -> void:
	# Si ya está explotando
	if _explotando:
		# No hace nada
		return
	# Kong recibe daño leve
	kong.recibir_daño_leve()
	# Hace temblar la cámara
	Audio.sacudir_camara(2.5, 0.25)
	# El rayo explota
	explotar()

# Se activa cuando el rayo choca con el piso o un borde
func _al_chocar(_cuerpo: Node2D) -> void:
	# Si ya está explotando
	if _explotando:
		# No hace nada
		return
	# El rayo explota
	explotar()

# Función que hace la explosión con destello y chispas
func explotar() -> void:
	# Indica que ya está explotando
	_explotando = true
	# Desactiva las colisiones para que ya no haga daño
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	# Deja de soltar partículas
	_estela.emitting = false
	# Sonido de la explosión
	Audio.sfx("explosion_rayo")

	# Lanza las chispas
	Efectos.chispas(self, global_position, Color(0.85, 0.95, 1.0, 1.0), Color(0.1, 0.3, 1.0, 0.0), 28, 110.0, 0.5)

	# El halo y el núcleo se agrandan y se desvanecen
	var t := create_tween().set_parallel(true)
	# Agranda el halo
	t.tween_property(_luz, "scale", Vector2(1.8, 1.8), 0.25)
	# Desvanece el halo
	t.tween_property(_luz, "modulate:a", 0.0, 0.25)
	# Agranda el núcleo
	t.tween_property(_nucleo, "scale", Vector2(0.9, 0.9), 0.15)
	# Desvanece el núcleo
	t.tween_property(_nucleo, "modulate:a", 0.0, 0.2)

	# Espera 0.7 segundos
	await get_tree().create_timer(0.7).timeout
	# Elimina el rayo
	queue_free()
