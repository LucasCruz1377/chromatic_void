shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {
    vec2 uv = SCREEN_UV;

    // leve curvatura (efeito tubo)
    vec2 center = uv - 0.5;
    uv += center * length(center) * 0.2;

    // pega cor da tela
    vec3 col = texture(screen_texture, uv).rgb;

    // scanlines (linhas horizontais)
    float scan = sin(uv.y * 800.0) * 0.04;
    col -= scan;

    // flicker leve
    float flicker = sin(TIME * 10.0) * 0.02;
    col += flicker;

    // leve perda de qualidade (lavado)
    col *= 0.9;

    COLOR = vec4(col, 1.0);
}