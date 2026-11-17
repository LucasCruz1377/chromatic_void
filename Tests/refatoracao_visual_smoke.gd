extends SceneTree

# Verificacao de importacao e heranca. Executar em Godot:
# godot --headless --path . -s res://Tests/refatoracao_visual_smoke.gd

const NOMES_INIMIGOS: Array[String] = ["CentelhaGuia","EloDourado","PrismaAmparo","SateliteBerco","PulsoSolar","FitaVioleta","NoFlutuante","EcoAmetista","LaminaIris","CasuloPrismatico","BrotoPrimaveril","SementeCanhao","PolenErrante","CipoEspiral","FrutoExplosivo","FragmentoLunar","CentelhaSolar","MeteoroJovem","EcoGravitacional","SateliteCoroa"]
const CENAS_BOSSES: Array[String] = ["res://Entities/BossPet0.tscn","res://Entities/BossFlorEquinocio.tscn","res://Entities/BossEclipseColheita.tscn","res://Entities/BossConstelacaoAmparo.tscn","res://Entities/BossNoAmetista.tscn"]

func _initialize() -> void:
	var falhas: Array[String] = []
	for nome in NOMES_INIMIGOS:
		var recurso := "res://Assets/GeometriaOriginal/Inimigos/%s.svg" % nome
		var cena := "res://Entities/Inimigo%s.tscn" % nome
		if not ResourceLoader.exists(recurso):
			falhas.append("Imagem ausente: " + recurso)
		if not ResourceLoader.exists(cena):
			falhas.append("Cena ausente: " + cena)
			continue
		var pacote := load(cena) as PackedScene
		if pacote == null:
			falhas.append("Cena nao carregou: " + cena)
			continue
		var objeto := pacote.instantiate()
		if not objeto is InimigoBase:
			falhas.append("Inimigo nao deriva de InimigoBase: " + nome)
		if not objeto.get_script().resource_path.ends_with("Inimigo%s.gd" % nome):
			falhas.append("Cena usa script errado: " + nome)
		objeto.free()
	for caminho in CENAS_BOSSES:
		if not ResourceLoader.exists(caminho):
			falhas.append("Boss ausente: " + caminho)
			continue
		var pacote := load(caminho) as PackedScene
		if pacote == null:
			falhas.append("Cena de boss nao carregou: " + caminho)
			continue
		var objeto := pacote.instantiate()
		if not objeto is BossBase:
			falhas.append("Boss nao deriva de BossBase: " + caminho)
		objeto.free()
	for caminho in [
		"res://Assets/GeometriaOriginal/Bosses/AmparoNucleo.svg",
		"res://Assets/GeometriaOriginal/Bosses/AmetistaCristal.svg"
	]:
		if not ResourceLoader.exists(caminho):
			falhas.append("Imagem do boss ausente: " + caminho)
	for erro in falhas:
		push_error(erro)
	if falhas.is_empty():
		print("OK: assets importados e cinco bosses com heranca comum")
	quit(0 if falhas.is_empty() else 1)
