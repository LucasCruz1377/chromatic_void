extends RefCounted

# Chance por projétil / multiplicador final: armas rápidas têm chance menor.
const ARMAS := {
 &"a01_espingarda_lua_rosa": Vector2(0.07, 1.65),
 &"a03_alcateia_misseis": Vector2(0.10, 1.8),
 &"a04_canhao_esturjao": Vector2(0.18, 2.0),
 &"a05_minas_castor": Vector2(0.12, 1.85),
 &"a06_feixe_perielio": Vector2(0.04, 1.5),
 &"a07_foice_colheita": Vector2(0.10, 1.75),
 &"a08_torpedo_subterraneo": Vector2(0.14, 1.9),
 &"a09_morteiro_fogueira": Vector2(0.12, 1.85),
 &"a10_rajada_morango": Vector2(0.06, 1.6),
 &"a11_projetor_nevasca": Vector2(0.04, 1.5),
 &"a12_jardim_orbital": Vector2(0.07, 1.65),
 &"a13_canhao_lua_fria": Vector2(0.14, 1.9),
}
static func valores(arma: StringName, niveis: Dictionary = {}) -> Vector2:
 var base: Vector2 = ARMAS.get(arma, Vector2(0.08, 1.75))
 return Vector2(minf(base.x + int(niveis.get(&"precisao_critica", 0)) * 0.04, 0.40), minf(base.y + int(niveis.get(&"impacto_critico", 0)) * 0.15, 2.6))
