extends Node
var falhas:Array[String]=[]
func checar(ok:bool,msg:String)->void:
	if not ok:falhas.append(msg);push_error("REWORK: "+msg)
func _ready()->void:
	var batalha:Node=(load("res://Rooms/Battle_area.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(batalha);await get_tree().process_frame;get_tree().current_scene=batalha;await get_tree().process_frame
	batalha.tutorial_ativo=false
	var pet:Array=load("res://Scripts/SectorData.gd").obter(&"vazio_inicial").get("inimigos",[])
	var antigos:=[&"seguidor",&"melee",&"investida",&"tanque",&"atirador"]
	for entrada in pet:checar(StringName(entrada[0]) in antigos,"PET-0 misturou inimigo novo")
	for caminho in ["res://Entities/BossConstelacaoAmparo.tscn","res://Entities/BossNoAmetista.tscn"]:
		var boss=(load(caminho) as PackedScene).instantiate();batalha.add_child(boss);boss.global_position=Vector2(480,180);boss.player=batalha.player
		checar(boss.get_script().resource_path!="res://Scripts/BossMensal.gd","boss ainda usa modelo genérico")
		if boss is BossNoAmetista:
			checar(boss.Dano >= 38.0 and boss.Velocidade >= 120.0,"Nó de Ametista não ficou mais forte")
			boss.amarras.assign([0.0,0.0,0.0,0.0]);boss.rompidas=4
			checar(boss.obter_velocidade_maxima() > boss.Velocidade,"Ametista sem defesa não ficou mais agressivo")
			boss._lacos_perseguidores();await get_tree().process_frame
			var travou_antes:=false
			for faixa in get_tree().get_nodes_in_group("perigo_boss_dinamico"):
				if faixa is FaixaEnergiaBoss and is_equal_approx(faixa.antecedencia_trava,0.3):travou_antes=true
			checar(travou_antes,"lasers do Ametista não travam 0,3 s antes de atirar")
		for ataque in 4:boss.executar_ataque(ataque)
		boss.queue_free()
	await get_tree().process_frame
	for audio in batalha.find_children("*","AudioStreamPlayer",true,false):(audio as AudioStreamPlayer).stop()
	for audio in batalha.find_children("*","AudioStreamPlayer2D",true,false):(audio as AudioStreamPlayer2D).stop()
	batalha.queue_free();await get_tree().process_frame
	if falhas.is_empty():print("TESTE OK: PET-0 clássico e oito padrões dos bosses");get_tree().quit(0)
	else:get_tree().quit(1)
