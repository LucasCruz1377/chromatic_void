# Melhoria v0.7.3 — pacote cumulativo

Base: main, commit 52b4271ffc8c7d340407a5d8ef9144c5417caa75.
Este ZIP contém o projeto-fonte completo dessa base com as melhorias abaixo; não é um APK nem um executável.

## Substituição e envio
1. Faça uma cópia de segurança do projeto local, especialmente alterações ainda não enviadas.
2. Atualize sua main e extraia este ZIP na raiz que contém project.godot, aceitando substituir arquivos. Não apague músicas ou outros arquivos locais que não estejam no ZIP.
3. Abra o projeto no Godot 4.7 e aguarde a importação. Teste uma partida e os novos efeitos no aparelho.
4. Na pasta do repositório, confira e envie:
   git status
   git add .
   git commit -m "Melhoria v0.7.3: audio, criticos e balanceamento"
   git push origin main
5. Depois de conferir o CI, crie uma tag ainda não usada:
   git tag v0.7.3
   git push origin v0.7.3
Não recrie nem force uma tag existente. O pacote preserva os workflows da base e não publica nada automaticamente.
Os arquivos de save não são incluídos nem apagados. Mantenha a identidade do aplicativo e a mesma chave Android nas exportações.

## Alterações
- Cinco WAVs em sounds/SFX: retrocesso, pétalas, investida, Hiperdash e cura.
- Pétalas: um som por lançamento, compartilhado por todos os bumerangues.
- Cura: som ao recuperar vida; intervalo de 1,5 s evita sobreposição em cura contínua.
- Lua/Eclipse: removidos da rotação os ataques de círculos que fecham. Ondas expansivas continuam.
- Flor: vulnerabilidade de 3 / 2,25 / 1,5 segundos nas fases 1 / 2 / 3. O retorno antecipado das pétalas não cancela a janela restante. Dano possível depende da arma/build; não há dano automático nem garantia de meia fase.
- Inimigos comuns: vida +18%, dano +6%, velocidade +2,5% por setor avançado, relativos à base, sem multiplicação exponencial. No último setor: +72%, +24%, +10%. Bosses não recebem essa escala.
- Crítico sorteado por projétil de arma, chance e multiplicador por arma. Acertos críticos têm número dourado; fragmentos herdam o resultado sem novo sorteio. Habilidades não recebem crítico de arma.
- Precisão Crítica: +4 pontos percentuais de chance por nível, até 3.
- Impacto Crítico: +15 pontos percentuais de multiplicador por nível, até 3; requer Precisão Crítica.
- Valores-base aparecem nas descrições das armas da loja.
- Capacitor Cinético removido das ofertas e desativado; identificação legada tolerada.
- Modelos setoriais com núcleos, detalhes geométricos, partículas de preparação e feedback de execução. Perigos lineares mostram largura real; áreas mostram contagem visual e desaparecem suavemente.
- Melee e investida do PET-0 olham continuamente para o jogador; a direção do golpe continua travada para permitir esquiva.

## Validação
Godot 4.7: importação, compilação de todos os scripts e testes de flor, Sizígia, upgrades, conteúdo novo, bosses e setor inicial.
Teste adicional melhoria073_smoke: críticos/feedback, escala de vida por setor, emissão de áudio sem duplicação e tempos da flor.
290 referências res:// verificadas.
Alguns testes legados reportam recursos ainda em uso ao encerrar; não houve erro de parse.
Validação headless: não substitui teste visual/sonoro e de desempenho no celular.
