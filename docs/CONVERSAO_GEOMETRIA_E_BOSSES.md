# Conversão conservadora de geometria e organização dos bosses

**Branch:** `fix/errors`. Nenhuma alteração foi dirigida a `main`.

## Assets adicionados

- `Assets/GeometriaOriginal/Inimigos/`: 20 imagens SVG transparentes, uma para cada espécie setorial ativa: CentelhaGuia, EloDourado, PrismaAmparo, SateliteBerco, PulsoSolar, FitaVioleta, NoFlutuante, EcoAmetista, LaminaIris, CasuloPrismatico, BrotoPrimaveril, SementeCanhao, PolenErrante, CipoEspiral, FrutoExplosivo, FragmentoLunar, CentelhaSolar, MeteoroJovem, EcoGravitacional, SateliteCoroa.
- `Assets/GeometriaOriginal/Bosses/AmparoNucleo.svg`: máscara hexagonal estática do núcleo do Amparo.
- `Assets/GeometriaOriginal/Bosses/AmetistaCristal.svg`: máscara geométrica estática do cristal da Ametista.

SVG é um **arquivo de imagem**, importado pelo Godot como textura e exibido via `Sprite2D`. As cores, vértices e linhas dessas imagens foram derivados dos comandos de desenho existentes, sem geração artística. Higgsfield **não foi usado**: a conta não estava conectada.

## Implementação

Os vinte scripts `Scripts/Inimigo*.gd` carregam suas texturas, criam um filho `FormaPreRenderizada` e mantêm os desenhos dinâmicos, incluindo núcleo, orientação do alvo, carga, vínculos entre aliados e geometria variável. Três silhuetas que giram mantêm essa rotação por `Sprite2D.rotation`. Não foram alteradas colisões, velocidade ou dano.

`BossConstelacaoAmparo.gd` e `BossNoAmetista.gd` carregam os dois assets de núcleo por `Sprite2D`; cores, dimensões e orientação continuam guiadas pelo estado existente do boss. Satélites, amarras, órbitas, ondas, projéteis e feixes continuam dinâmicos: transformá-los em imagens fixas causaria perda de funcionalidade.

Os cinco chefes agora derivam da classe intermediária **`Scripts/BossBase.gd`**, que herda `InimigoBase`. PET-0, Caos Primaveril e Sizígia Eterna derivam diretamente de `BossBase`; Amparo e Ametista herdam de `BossMensal`, que agora deriva de `BossBase`. Cada chefe manteve seu próprio script e sua própria cena, sem reescrever padrões de ataque.

## Fidelidade e desempenho

A aparência **não foi deliberadamente redesenhada**, mas **não é possível garantir identidade pixel a pixel** sem renderizar e comparar cada cena no Godot. SVG rasterizado e desenho CanvasItem podem diferir ligeiramente em suavização de linhas, intensidade e bordas; alguns contornos móveis continuam procedurais. A melhora de FPS **não foi medida** e não é garantida. O objetivo implementado é reduzir geometria estática recalculada em `_draw()`, mantendo renderização dinâmica onde necessária.

## Validação

Executar `godot --headless --path . -s res://Tests/refatoracao_visual_smoke.gd` em uma instalação Godot compatível. Depois comparar screenshots host/cliente, tempos de frame e estatísticas de desenho em cada setor. A verificação estática não substitui teste em execução.
