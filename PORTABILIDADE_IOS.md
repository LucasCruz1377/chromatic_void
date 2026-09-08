# Portabilidade iOS

O projeto já trata iOS como mobile: controles por toque, perfil de partículas,
limite de FPS e cursor nativo/personalizado oculto. O preset **iOS Xcode Project**
gera um projeto Xcode ARM64 para iPhone e iPad, com iOS 13 como versão mínima.

## Antes da primeira exportação

1. Use macOS com Xcode e os templates de exportação do Godot 4.7 instalados.
2. Em `export_presets.cfg`, troque `XXXXXXXXXX` pelo Apple Team ID de 10 caracteres.
3. Confirme que `com.lucascruz1377.chromaticvoid` está cadastrado na conta Apple.
4. No Godot, exporte o preset **iOS Xcode Project** para uma pasta vazia.
5. Abra o `.xcodeproj`, selecione a equipe de assinatura e gere o Archive no Xcode.

O preset usa `application/export_project_only=true`: o Godot prepara o projeto,
mas certificados, provisioning profile e publicação continuam sob responsabilidade
do Xcode/Apple Developer. O placeholder impede que credenciais pessoais sejam
gravadas no repositório.
