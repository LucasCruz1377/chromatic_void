shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec2 centro = vec2(0.5, 0.5);
uniform float progresso : hint_range(0.0, 1.0) = 0.0;
uniform float escuridao : hint_range(0.0, 1.0) = 0.0;
uniform float intensidade : hint_range(0.0, 2.0) = 1.0;
uniform float silhueta : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 delta_uv = uv - centro;
	vec2 delta_corrigido = delta_uv;
	delta_corrigido.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float distancia = length(delta_corrigido);
	float raio_onda = progresso * 0.92;
	float onda = 1.0 - smoothstep(0.006, 0.032, abs(distancia - raio_onda));
	vec2 normal = normalize(delta_uv + vec2(0.0001));
	vec2 deslocamento = normal * onda * 0.021 * intensidade * (1.0 - progresso * 0.28);
	vec4 tela = texture(screen_texture, uv - deslocamento);
	vec3 cor_final = mix(tela.rgb, tela.rgb * vec3(0.07, 0.075, 0.13), escuridao);

	float raio_eclipse = 0.112 * silhueta;
	float disco = 1.0 - smoothstep(raio_eclipse - 0.004, raio_eclipse + 0.002, distancia);
	float contorno = 1.0 - smoothstep(0.003, 0.014, abs(distancia - raio_eclipse));
	vec3 neon = mix(vec3(1.0, 0.34, 0.08), vec3(0.74, 0.38, 1.0), smoothstep(-0.08, 0.08, delta_corrigido.y));
	cor_final = mix(cor_final, vec3(0.002, 0.004, 0.014), disco * silhueta);
	cor_final += neon * contorno * silhueta * 1.45;
	cor_final += vec3(0.46, 0.7, 1.0) * onda * 0.07;
	COLOR = vec4(cor_final, 1.0);
}
