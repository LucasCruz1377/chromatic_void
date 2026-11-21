# Correções do log e da estrutura — 17/11/2026

Base analisada: branch `fix/errors`, commit `ea1085c608c91931ef42722645d0f663cb03d038`, incluindo o histórico recente de replicação, conversão visual e reversão. Log fornecido: `godot.log`, Godot 4.7.2 Steam, Windows, renderer Mobile/D3D12 em Radeon integrada.

## Diagnóstico e alterações

| Evidência | Diagnóstico | Tratamento |
| --- | --- | --- |
| Erros de mipmaps, framebuffer, pipelines e uniform sets | Cascata do backend D3D12; não corresponde a um erro de sintaxe GDScript | Preservada a seleção Vulkan no Windows já feita em `ea1085c`. Não houve validação de GPU Windows neste ambiente. |
| Save temporário inválido e leitura UTF-8 incompleta | O log é anterior à correção de fechamento de arquivos; um temporário compartilhado e cópia sobre o principal ainda permitiam disputa entre instâncias e leitura parcial | Temporário por PID, validação após fechar o arquivo e substituição por rename. Falhas preservam o principal; backup válido continua recuperável. Duas sessões ainda podem substituir o progresso uma da outra: não foi criado um sistema de mesclagem entre partidas. |
| `Couldn't create an ENet host` | Criação de socket falhou; porta ocupada é uma causa possível, não demonstrada exclusivamente pelo log | Preservada a mensagem de diagnóstico já implementada e adicionadas suas traduções. A porta permanece 24567 para manter o protocolo de conexão. |
| Delta inválido, despawn não autorizado e nome de spawn duplicado | Remoção local de entidades replicadas pode invalidar o registro do MultiplayerSpawner | Limpeza de inimigos e morte/dano compartilhado na base ficam restritos ao host. Réplicas manuais de projéteis não criam um sincronizador sem correspondente no servidor. |
| Visual de chefe congelado | `ae09f5f` descartava todos os filhos e animações quando o JSON passava de 950 bytes. A física desativada no cliente impede que ele reconstrua sozinho essas animações | Captura completa em `ChefeBase`, compressão DEFLATE, partes de até 900 bytes e reconstrução por sequência. Canal não ordenado permite partes fora de ordem; quadros antigos/duplicados são rejeitados e um quadro novo substitui o incompleto. |
| Snapshots de mundo crescentes | A lista inteira de inimigos podia ultrapassar o MTU mesmo com poucos jogadores | Divisão por tamanho binário, mantendo todos os inimigos; partes da mesma sequência são aceitas independentemente. |
| Estado de entrada reenviado depois de aplicado | O segundo quadro podia restaurar posição, vida e progressão antigas | Entrada aplicada uma vez; removido o reenvio na confirmação. |
| 25 scripts setoriais repetiam enum, campos, inicialização, carga, movimento e utilitários | A separação anterior copiou a estrutura comum para cada espécie | `InimigoSetorialBase` concentra o ciclo comum e os utilitários de tiro/vínculos. Filhos conservam seus ataques, movimentos específicos e desenhos. |
| Propriedade `custom_maximum_size` da barra de vida | Falha em Godot 4.6.3 interrompia a criação do nickname e da barra multiplayer | Removida a propriedade redundante; dimensão mínima e tamanho explícito mantêm a barra sob o pai Node2D. |
| Foco adiado em interface removida | Um controle podia sair da árvore antes de receber foco | A tela inicial verifica instância, árvore e visibilidade antes de focar. |

## Estrutura resultante

| Base | Classes derivadas |
| --- | --- |
| `InimigoBase` | `ChefeBase`, `InimigoSetorialBase`, inimigos clássicos e fragmentos |
| `ChefeBase` | `BossPet0`, `BossCaosPrimaveril`, `BossSizigiaEterna`, `BossMensal` |
| `BossMensal` | `BossConstelacaoAmparo`, `BossNoAmetista` |
| `InimigoSetorialBase` | 25 espécies setoriais |

- `Scripts/InimigoBase.gd`: vida, movimento físico, estados, contato, recompensas e sincronização comum.
- `Scripts/ChefeBase.gd`: estados e visuais de chefes, animações, shaders, texturas de fase e transporte fragmentado.
- `Scripts/InimigoSetorialBase.gd`: ciclo preparar/executar/recarga, movimento por gancho, tiros, vínculos e estado do desenho procedural. Parceiros e protegidos são transmitidos por NodePath, sem tentar serializar objetos Node.
- `Scripts/BossMensal.gd`: mecânicas mensais e protocolo confiável das defesas do Amparo/Ametista, preservados.
- Herança das novas bases por caminho explícito, reduzindo dependência do cache de classes durante a importação.

Não foram substituídos assets, silhuetas, cores, ataques ou progressão. O desenho procedural foi preservado. As mudanças visíveis esperadas são a recuperação de animações, avisos, vínculos e transformações que faltavam no cliente.

## Verificação

Ambiente local: **Godot 4.6.3 oficial, Linux, headless**. A versão difere da 4.7.2 do log e da 4.7 usada pela CI.

- Importação e compilação dos **160 scripts**.
- **30 cenas de smoke test** concluídas com código zero.
- Sete validadores Python e o teste do atualizador concluídos com sucesso.
- Integração ENet com dois processos: posições, loadouts, compra validada de upgrade, XP, cristais, partículas, ataques visuais, HUD, morte e renascimento.
- Integração ampliada: envio visual dos cinco chefes e remoção pelo host, sem erros de spawn/despawn/delta nos logs dessa execução.
- Regressão de fragmentação: rotação de filho, linha com 256 pontos, partes invertidas/duplicadas, quadro parcial e proteção contra morte/dano no cliente.
- Regressão de mundo: quatro pilotos e 100 inimigos preservados em pacotes abaixo do limite.
- Regressão de save: caracteres UTF-8, campos aninhados, manutenção de campos anteriores, recuperação de principal corrompido e preservação de backup válido.

Alguns testes existentes ainda emitem avisos de ObjectDB/recursos em uso no encerramento do processo headless, embora concluam suas verificações. Não se afirma ausência de vazamentos com base nesses testes.

Ainda exigem validação no equipamento real: renderização Vulkan/driver Radeon no Windows, comportamento do filesystem Windows sob bloqueio por outro programa e partidas em máquinas distintas com latência/perda de pacotes. O teste local de rede usa loopback; quatro jogadores foram cobertos no dimensionamento dos pacotes, não numa sessão de quatro processos.


## Complemento: log do bumerangue e saida multiplayer

O segundo anexo (`Texto colado(1).txt`) trouxe 831 consultas de sobreposicao com monitoramento desligado, tres despawns sem registro, dois deltas para sincronizador invalido e uma chamada de `is_server()` em MultiplayerAPI nula.

- `fireball.gd`: bumerangues visuais nao consultam sobreposicoes nem aplicam dano; tiros reais preservam um acerto por alvo em cada fase, ida e volta. O tiro subterraneo visual tambem permanece sem monitoramento quando emerge.
- `battle_area.gd`: callbacks de fim de disparo verificam arvore, exclusao pendente, API e conexao. O cliente deixa o despawn das naves desconectadas a cargo do host.
- `gui.gd` e arena: retorno ao menu encerra o peer antes de remover a cena, evitando pacotes para sincronizadores ja removidos.
- Os overrides de morte dos chefes tambem verificam autoridade antes de executar limpezas; a Flor nao pode remover espinhos replicados por uma chamada local de morte.
- Barra de vida multiplayer: dimensao efetiva restaurada para **86 x 3 pixels**, aplicada depois de ocultar a porcentagem e instalar os estilos. Isso impede que o tamanho minimo inicial do tema mantenha a barra alta. Posicao e cores foram preservadas.

Regressoes adicionadas: `log_multiplayer_smoke` testa repeticao da consulta, ausencia de dano na replica, dano real de ida/volta e callback em arena fora da arvore. `lifecycle_peer_integration` executa tres processos, remove um cliente enquanto os outros continuam e valida despawns de tres espinhos da Flor. Seu runner rejeita erros de replicacao mesmo quando a engine termina com codigo zero. A integracao existente de dois jogadores tambem verifica `ProgressBar.size == Vector2(86, 3)`.

Validacao local: compilacao de 162 scripts; regressao do log; testes de estrutura, Flor, chefes e progressao; sete validadores Python; integracoes de dois e tres peers aprovadas. Persistem os avisos de recursos em uso no encerramento headless ja descritos acima. O ambiente local continua sendo Godot 4.6.3/Linux; a CI executa Godot 4.7.
