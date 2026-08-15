extends CanvasLayer


@onready var material_filtro := $Filtro.material as ShaderMaterial

var tween: Tween


func _ready() -> void:
	definir_intensidade(0.0)


func iniciar() -> void:
	interpolar_intensidade(1.0, 0.12, false)


func finalizar() -> void:
	interpolar_intensidade(0.0, 0.22, true)


func interpolar_intensidade(
	valor_final: float,
	duracao: float,
	liberar_ao_final: bool
) -> void:
	if tween and tween.is_valid():
		tween.kill()

	var valor_inicial := float(
		material_filtro.get_shader_parameter("intensidade")
	)

	tween = create_tween()
	tween.tween_method(
		definir_intensidade,
		valor_inicial,
		valor_final,
		duracao
	)

	if liberar_ao_final:
		tween.tween_callback(queue_free)


func definir_intensidade(valor: float) -> void:
	material_filtro.set_shader_parameter("intensidade", valor)

