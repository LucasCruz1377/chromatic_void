extends CanvasLayer

@export var verificar_automaticamente := true

@onready var fundo: ColorRect = $Fundo
@onready var centralizador: CenterContainer = $Centralizador
@onready var painel: PanelContainer = $Centralizador/Painel
@onready var titulo: Label = $Centralizador/Painel/Margem/Conteudo/Titulo
@onready var mensagem: Label = $Centralizador/Painel/Margem/Conteudo/Mensagem
@onready var versao_atual: Label = $Centralizador/Painel/Margem/Conteudo/PainelVersoes/Versoes/VersaoAtual
@onready var nova_versao: Label = $Centralizador/Painel/Margem/Conteudo/PainelVersoes/Versoes/NovaVersao
@onready var aviso_android: Label = $Centralizador/Painel/Margem/Conteudo/AvisoAndroid
@onready var progresso: ProgressBar = $Centralizador/Painel/Margem/Conteudo/Progresso
@onready var progresso_info: HBoxContainer = $Centralizador/Painel/Margem/Conteudo/ProgressoInfo
@onready var progresso_detalhes: Label = $Centralizador/Painel/Margem/Conteudo/ProgressoInfo/Detalhes
@onready var tempo_restante: Label = $Centralizador/Painel/Margem/Conteudo/ProgressoInfo/TempoRestante
@onready var status: Label = $Centralizador/Painel/Margem/Conteudo/Status
@onready var botao_atualizar: Button = $Centralizador/Painel/Margem/Conteudo/Botoes/BotaoAtualizar
@onready var botao_mais_tarde: Button = $Centralizador/Painel/Margem/Conteudo/Botoes/BotaoMaisTarde

const MAX_TENTATIVAS_VERIFICACAO := 3
const ATRASO_PRIMEIRA_VERIFICACAO := 0.8
const ATRASO_NOVA_TENTATIVA := 2.0

var inicio_download_msec := 0
var velocidade_suavizada := 0.0
var tentativas_verificacao := 0
var modo_falha_verificacao := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

	UpdateManager.update_available.connect(_mostrar_atualizacao)
	UpdateManager.update_check_failed.connect(_on_verificacao_falhou)
	UpdateManager.update_download_started.connect(_on_download_started)
	UpdateManager.update_download_progress.connect(_on_download_progress)
	UpdateManager.update_download_failed.connect(_on_download_failed)
	UpdateManager.installer_opened.connect(_on_installer_opened)

	botao_atualizar.pressed.connect(_clicou_atualizar)
	botao_mais_tarde.pressed.connect(_clicou_mais_tarde)
	get_viewport().size_changed.connect(_ajustar_ao_viewport)
	_ajustar_ao_viewport()

	if verificar_automaticamente:
		_iniciar_verificacao_automatica()


func _iniciar_verificacao_automatica() -> void:
	# Dá tempo para a rede do sistema ficar pronta, principalmente no Android.
	await get_tree().create_timer(ATRASO_PRIMEIRA_VERIFICACAO).timeout
	if not verificar_automaticamente or UpdateManager.obter_plataforma_atual().is_empty():
		return
	tentativas_verificacao = 0
	_tentar_verificar_atualizacao()


func _tentar_verificar_atualizacao() -> void:
	if UpdateManager.checking_update:
		return
	tentativas_verificacao += 1
	UpdateManager.verificar_atualizacao()


func _on_verificacao_falhou(erro: String) -> void:
	if UpdateManager.obter_plataforma_atual().is_empty():
		return
	if tentativas_verificacao < MAX_TENTATIVAS_VERIFICACAO:
		await get_tree().create_timer(ATRASO_NOVA_TENTATIVA).timeout
		_tentar_verificar_atualizacao()
		return
	_mostrar_auxilio_verificacao(erro)


func _mostrar_auxilio_verificacao(erro: String) -> void:
	modo_falha_verificacao = true
	versao_atual.text = "INSTALADA  •  v%s" % UpdateManager.current_version.trim_prefix("v")
	nova_versao.text = "VERIFICAÇÃO PENDENTE"
	titulo.text = "ATUALIZAÇÃO NÃO VERIFICADA"
	mensagem.text = (
		"Confira sua conexão e tente novamente. Seu progresso está seguro; "
		+ "não é necessário reinstalar o jogo."
	)
	status.text = erro
	aviso_android.visible = false
	progresso.hide()
	progresso_info.hide()
	botao_atualizar.text = "TENTAR NOVAMENTE"
	botao_atualizar.disabled = false
	botao_mais_tarde.text = "AGORA NÃO"
	botao_mais_tarde.disabled = false
	show()
	botao_atualizar.call_deferred("grab_focus")


func _mostrar_atualizacao(version: String) -> void:
	modo_falha_verificacao = false
	tentativas_verificacao = 0
	titulo.text = "NOVA ATUALIZAÇÃO"
	botao_mais_tarde.text = "MAIS TARDE"
	versao_atual.text = "INSTALADA  •  v%s" % UpdateManager.current_version.trim_prefix("v")
	nova_versao.text = "DISPONÍVEL  •  v%s" % version.trim_prefix("v")
	status.text = ""
	progresso.hide()
	progresso_info.hide()
	botao_atualizar.disabled = false
	botao_mais_tarde.disabled = false

	var android: bool = UpdateManager.obter_plataforma_atual() == UpdateManager.PLATFORM_ANDROID
	aviso_android.visible = android
	botao_atualizar.text = "BAIXAR APK" if android else "ATUALIZAR AGORA"
	mensagem.text = (
		"Baixe o APK assinado. Ao abrir, escolha Atualizar e mantenha o jogo instalado."
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
	if modo_falha_verificacao:
		modo_falha_verificacao = false
		hide()
		tentativas_verificacao = 0
		_tentar_verificar_atualizacao()
		return
	botao_atualizar.disabled = true
	status.text = "Preparando atualização..."
	progresso.value = 0.0
	progresso.show()
	progresso_info.show()
	progresso_detalhes.text = "0%  •  preparando download"
	tempo_restante.text = "CALCULANDO TEMPO..."
	UpdateManager.iniciar_atualizacao()


func _clicou_mais_tarde() -> void:
	hide()


func _on_download_started(total_bytes: int) -> void:
	inicio_download_msec = Time.get_ticks_msec()
	velocidade_suavizada = 0.0
	progresso.show()
	progresso_info.show()
	progresso.value = 0.0
	status.text = "Baixando • %s" % _formatar_bytes(total_bytes)
	botao_mais_tarde.disabled = true


func _on_download_progress(baixado: int, total: int) -> void:
	var porcentagem := clampf(float(baixado) / float(total) * 100.0, 0.0, 100.0) if total > 0 else 0.0
	progresso.value = porcentagem
	status.text = "%s de %s" % [_formatar_bytes(baixado), _formatar_bytes(total)]
	var segundos := maxf(float(Time.get_ticks_msec() - inicio_download_msec) / 1000.0, 0.001)
	var velocidade_atual := float(baixado) / segundos
	velocidade_suavizada = (
		velocidade_atual
		if velocidade_suavizada <= 0.0
		else lerpf(velocidade_suavizada, velocidade_atual, 0.18)
	)
	progresso_detalhes.text = "%d%%  •  %s/s" % [roundi(porcentagem), _formatar_bytes(roundi(velocidade_suavizada))]
	if total > 0 and velocidade_suavizada > 1.0:
		var restante := float(maxi(total - baixado, 0)) / velocidade_suavizada
		tempo_restante.text = _formatar_tempo(restante)
	else:
		tempo_restante.text = "CALCULANDO TEMPO..."


func _on_download_failed(erro: String) -> void:
	status.text = erro
	progresso.hide()
	progresso_info.hide()
	botao_atualizar.disabled = false
	botao_mais_tarde.disabled = false


func _on_installer_opened(plataforma: String) -> void:
	if plataforma == UpdateManager.PLATFORM_ANDROID:
		status.text = "Download aberto. Ao instalar, escolha Atualizar — não desinstale o jogo."
		progresso.value = 15.0
		progresso_detalhes.text = "DOWNLOAD EXTERNO"
		tempo_restante.text = "ACOMPANHE NO NAVEGADOR"
		botao_atualizar.text = "ABRIR DOWNLOAD"
		botao_atualizar.disabled = false
		botao_mais_tarde.text = "FECHAR"
	else:
		status.text = "Aplicando atualização..."
		progresso.value = 100.0
		progresso_detalhes.text = "100%  •  download concluído"
		tempo_restante.text = "INSTALANDO..."


func _ajustar_ao_viewport() -> void:
	if not is_instance_valid(painel):
		return
	var tamanho := get_viewport().get_visible_rect().size
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centralizador.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centralizador.offset_left = 14.0
	centralizador.offset_top = 14.0
	centralizador.offset_right = -14.0
	centralizador.offset_bottom = -14.0
	painel.custom_minimum_size.x = clampf(tamanho.x - 28.0, 300.0, 620.0)
	# O CenterContainer recalcula a posição no próximo frame; zerar qualquer
	# deslocamento herdado impede a janela de reaparecer no canto superior.
	painel.position = Vector2.ZERO


func _formatar_bytes(valor: int) -> String:
	if valor <= 0:
		return "tamanho desconhecido"
	if valor >= 1024 * 1024:
		return "%.1f MB" % (float(valor) / 1048576.0)
	if valor >= 1024:
		return "%.1f KB" % (float(valor) / 1024.0)
	return "%d B" % valor


func _formatar_tempo(segundos: float) -> String:
	if segundos <= 1.0:
		return "FINALIZANDO..."
	var total := ceili(segundos)
	if total < 60:
		return "~%d s RESTANTES" % total
	var minutos := int(float(total) / 60.0)
	var resto := total % 60
	return "~%d min %02d s" % [minutos, resto]
