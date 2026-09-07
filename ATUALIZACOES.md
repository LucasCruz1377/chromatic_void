# Sistema de atualização

## Polimento de pré-release desta versão

O HUD inferior usa uma única área segura responsiva para alinhar vida, XP,
nível e habilidade. A campanha agora segue um ciclo fixo de cinco bosses, com
transições automáticas e inimigos exclusivos por setor. O save recebeu somente
campos adicionais para recordes de combo, pontos e tempo sem dano; saves antigos
continuam válidos porque os valores ausentes começam em zero.

Nesta revisão, os bosses provisórios foram substituídos pela Constelação do
Amparo e pelo Nó de Ametista. Cada setor tem cinco inimigos temáticos, enquanto
os inimigos clássicos ficaram exclusivos do PET-0. Clone Enganador e Espírito
Protetor agora invocam ajudantes temporários reais. Projéteis teleguiados saem
sem alvo e só travam quando uma ameaça cruza seu raio. O antigo cosmético de
referência foi migrado para o Modelo O, uma nave formada apenas pela estrela,
com nave e rastro recoloridos pela paleta selecionada. Também foram incluídas
conquistas de combo 200 e de 1, 5, 10, 20 e 25 milhões de pontos.

O Chromatic Void consulta a versão publicada nos canais `windows` e `android` do itch.io ao abrir a tela inicial. Quando encontra uma versão mais nova, baixa o arquivo da GitHub Release que possui a mesma tag.

Por isso a ordem de publicação é importante: primeiro crie a GitHub Release e depois execute o workflow do itch.io para publicar exatamente essa tag nos dois canais.

## Fluxo por plataforma

### Windows

1. O jogo consulta a versão do canal `windows` no itch.io.
2. O ZIP correspondente é baixado da GitHub Release em `user://`.
3. O jogo cria um backup do save e inicia `Updater.exe`.
4. O updater espera o jogo fechar, valida o ZIP, substitui os arquivos e abre a nova versão.
5. Se a cópia falhar, os arquivos já substituídos são restaurados.

O `Updater.exe` é recompilado a partir de `Updater/main.py` em toda release. Não edite somente o executável antigo da raiz.

### Android

1. O jogo consulta a versão do canal `android` no itch.io.
2. O botão **Baixar APK** abre o arquivo oficial da Release no navegador.
3. O jogador abre o APK baixado e escolhe **Atualizar**.

O Android exige confirmação do usuário. O jogo não deve tentar instalar silenciosamente nem pedir que o aplicativo atual seja desinstalado.

## Por que o save permanece no Android

Uma instalação por cima preserva os dados quando todos estes requisitos são mantidos:

- mesmo identificador: `com.lucascruz1377.chromaticvoid`;
- mesmo certificado de assinatura;
- `versionCode` novo maior que o instalado;
- instalação como atualização, sem executar `adb uninstall` e sem tocar em **Desinstalar**.

Certificado oficial das versões Android:

```text
SHA-256: B1:53:F4:14:87:64:03:16:0E:BD:26:CF:19:A7:97:71:8B:97:72:1E:14:A7:87:67:0F:D0:5A:C2:01:18:A9:62
```

O pipeline bloqueia automaticamente um APK com outro identificador, certificado ou `versionCode`. A mesma keystore e senha devem ser guardadas fora do repositório.

O save e seu backup ficam em `user://save.json` e `user://save_backup.json`, dentro dos dados privados do aplicativo. Eles não ficam dentro do APK.

> `package/retain_data_on_uninstall=true` ajuda versões futuras a oferecerem retenção de dados quando o Android suportar essa opção, mas não substitui a atualização por cima. O procedimento seguro continua sendo não desinstalar.

## Usuário de uma versão sem updater

Versões antigas não precisam ter o updater para receber a próxima versão no Android:

1. Abra a página de Releases: <https://github.com/LucasCruz1377/chromatic_void/releases>.
2. Baixe `ChromaticVoid-Android.apk` da versão desejada.
3. Abra o APK baixado.
4. Se necessário, permita ao navegador instalar aplicativos desta fonte.
5. Toque em **Atualizar**, nunca em **Desinstalar**.

Foi conferido que os APKs públicos `v0.5.1` e `v0.6.2-beta.4` possuem o mesmo identificador e certificado oficial. Seus `versionCode` são, respectivamente, `7` e `22`, portanto o segundo pode substituir o primeiro como atualização. APKs de desenvolvimento assinados com outra chave não podem substituir a versão oficial sem desinstalação.

## Teste real em Android

Use um celular ou emulador que possa ser apagado depois. Guarde uma cópia da keystore antes de começar.

1. Baixe um APK oficial antigo e o APK novo.
2. Instale o antigo:

```bash
adb install ChromaticVoid-antigo.apk
```

3. Abra o jogo, altere uma configuração e modifique a quantidade de cristais para criar um save reconhecível.
4. Feche o jogo e instale o novo por cima:

```bash
adb install -r ChromaticVoid-novo.apk
```

5. O terminal deve mostrar `Success`.
6. Abra o jogo e confirme que a configuração e os cristais continuam iguais.

Para inspecionar os APKs antes da instalação:

```bash
aapt dump badging ChromaticVoid-novo.apk
apksigner verify --verbose --print-certs ChromaticVoid-novo.apk
```

O primeiro comando deve mostrar o package `com.lucascruz1377.chromaticvoid` e um `versionCode` maior. O segundo deve mostrar o SHA-256 oficial acima.

## Testes locais

```bash
python3 Tests/validar_sistema_update.py
python3 Tests/test_updater.py
godot --headless --audio-driver Dummy --path . res://Tests/update_system_smoke.tscn
```

O primeiro valida o contrato entre código, export e workflow. O segundo simula a substituição segura dos arquivos do Windows e bloqueia ZIP malicioso. O smoke test valida versões, escolha do asset e centralização da janela.

## Publicação

Cada release deve conter exatamente:

- `Windows.Desktop.zip`;
- `ChromaticVoid-Android.apk`, quando Android estiver habilitado;
- `Web.zip`;
- `SHA256SUMS.txt`.

Versões estáveis recebem apenas outras versões estáveis. Quem estiver em alpha, beta ou RC também pode receber uma pré-release mais nova.
