shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float intensidade : hint_range(0.0, 1.0) = 0.0;
uniform float separacao_cromatica : hint_range(0.0, 5.0) = 1.5;


void fragment() {
	vec2 deslocamento = vec2(
		SCREEN_PIXEL_SIZE.x * separacao_cromatica * intensidade,
		0.0
	);

	vec4 original = texture(screen_texture, SCREEN_UV);
	float vermelho = texture(screen_texture, SCREEN_UV + deslocamento).r;
	float verde = original.g;
	float azul = texture(screen_texture, SCREEN_UV - deslocamento).b;

	vec3 cromatico = vec3(vermelho, verde, azul);
	vec3 negativo = vec3(1.0) - cromatico;
	vec3 cor_final = mix(original.rgb, negativo, intensidade * 0.85);

	float linha = sin(
		(SCREEN_UV.y / SCREEN_PIXEL_SIZE.y) * 0.65 + TIME * 10.0
	) * 0.035 * intensidade;

	vec2 centro = SCREEN_UV * 2.0 - 1.0;
	float borda = smoothstep(0.35, 1.35, length(centro));

	cor_final += linha;
	cor_final *= 1.0 - borda * 0.18 * intensidade;

	COLOR = vec4(cor_final, 1.0);
}

