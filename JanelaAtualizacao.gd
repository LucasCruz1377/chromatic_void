extends CanvasLayer

@export var verificar_automaticamente := true

@onready var fundo: ColorRect = $Fundo
@onready var centralizador: CenterContainer = $Centralizador
@onready var painel: PanelContainer = $Centralizador/Painel
@onready var titulo: Label = $Centralizador/Painel/Margem/Conteudo/Titulo
@onready var mensagem: Label = $Centralizador/Painel/Margem/Conteudo/Mensagem
@onready var versao_atual: Label = $Centralizador/Painel/Margem/Conteudo/Versoes/VersaoAtual
@onready var nova_versao: Label = $Centralizador/Painel/Margem/Conteudo/Versoes/NovaVersao
@onready var aviso_android: Label = $Centralizador/Painel/Margem/Conteudo/AvisoAndroid
@onready var progresso: ProgressBar = $Centralizador/Painel/Margem/Conteudo/Progresso
@onready var status: Label = $Centralizador/Painel/Margem/Conteudo/Status
@onready var botao_atualizar: Button = $Centralizador/Painel/Margem/Conteudo/Botoes/BotaoAtualizar
@onready var botao_mais_tarde: Button = $Centralizador/Painel/Margem/Conteudo/Botoes/BotaoMaisTarde


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

	UpdateManager.update_available.connect(_mostrar_atualizacao)
	UpdateManager.update_download_started.connect(_on_download_started)
	UpdateManager.update_download_progress.connect(_on_download_progress)
	UpdateManager.update_download_failed.connect(_on_download_failed)
	UpdateManager.installer_opened.connect(_on_installer_opened)

	botao_atualizar.pressed.connect(_clicou_atualizar)
	botao_mais_tarde.pressed.connect(_clicou_mais_tarde)
	get_viewport().size_changed.connect(_ajustar_ao_viewport)
	_ajustar_ao_viewport()

	if verificar_automaticamente:
		UpdateManager.verificar_atualizacao()


func _mostrar_atualizacao(version: String) -> void:
	versao_atual.text = "INSTALADA  •  v%s" % UpdateManager.current_version.trim_prefix("v")
	nova_versao.text = "DISPONÍVEL  •  v%s" % version.trim_prefix("v")
	status.text = ""
	progresso.hide()
	botao_atualizar.disabled = false
	botao_mais_tarde.disabled = false

	var android: bool = UpdateManager.obter_plataforma_atual() == UpdateManager.PLATFORM_ANDROID
	aviso_android.visible = android
	botao_atualizar.text = "BAIXAR APK" if android else "ATUALIZAR AGORA"
	mensagem.text = (
		"Baixe o novo APK e instale por cima desta versão."
		if android
		else
		"Uma nova jornada pelo vazio já está pronta para você."
	)

	show()
	fundo.modulate.a = 0.0
	painel.modulate = Color(1, 1, 1, 0)
	painel.scale = Vector2(0.94, 0.94)
	painel.pivot_offset = painel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(fundo, "modulate:a", 1.0, 0.2)
	tween.tween_property(painel, "modulate:a", 1.0, 0.25)
	tween.tween_property(painel, "scale", Vector2.ONE, 0.25)
	botao_atualizar.call_deferred("grab_focus")


func _clicou_atualizar() -> void:
	botao_atualizar.disabled = true
	status.text = "Preparando atualização..."
	UpdateManager.iniciar_atualizacao()


func _clicou_mais_tarde() -> void:
	hide()


func _on_download_started(total_bytes: int) -> void:
	progresso.show()
	progresso.value = 0.0
	status.text = "Baixando • %s" % _formatar_bytes(total_bytes)
	botao_mais_tarde.disabled = true


func _on_download_progress(baixado: int, total: int) -> void:
	progresso.value = clampf(float(baixado) / float(total) * 100.0, 0.0, 100.0) if total > 0 else 0.0
	status.text = "%s de %s" % [_formatar_bytes(baixado), _formatar_bytes(total)]


func _on_download_failed(erro: String) -> void:
	status.text = erro
	progresso.hide()
	botao_atualizar.disabled = false
	botao_mais_tarde.disabled = false


func _on_installer_opened(plataforma: String) -> void:
	if plataforma == UpdateManager.PLATFORM_ANDROID:
		status.text = "Download aberto. Ao instalar, escolha Atualizar — não desinstale o jogo."
		botao_atualizar.text = "ABRIR DOWNLOAD"
		botao_atualizar.disabled = false
		botao_mais_tarde.text = "FECHAR"
	else:
		status.text = "Aplicando atualização..."


func _ajustar_ao_viewport() -> void:
	if not is_instance_valid(painel):
		return
	var largura := get_viewport().get_visible_rect().size.x
	painel.custom_minimum_size.x = clampf(largura - 32.0, 320.0, 580.0)


func _formatar_bytes(valor: int) -> String:
	if valor <= 0:
		return "tamanho desconhecido"
	if valor >= 1024 * 1024:
		return "%.1f MB" % (float(valor) / 1048576.0)
	if valor >= 1024:
		return "%.1f KB" % (float(valor) / 1024.0)
	return "%d B" % valor
