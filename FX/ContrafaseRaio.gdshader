shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 tinta : source_color = vec4(1.0);
uniform float relogio = 0.0;
uniform float intensidade = 1.0;
uniform float frequencia = 15.0;

void fragment() {
	float eixo = abs(UV.y * 2.0 - 1.0);
	float nucleo = 1.0 - smoothstep(0.05, 0.32, eixo);
	float halo = pow(max(0.0, 1.0 - eixo), 2.2);
	float pulso = sin(UV.x * frequencia * 6.283 - relogio * 13.0);
	float corda = abs(eixo - 0.40 - 0.07 * pulso);
	float harmonico = 1.0 - smoothstep(0.0, 0.11, corda);
	vec3 cor = mix(tinta.rgb, vec3(1.0), nucleo * 0.86);
	float alfa = nucleo + halo * 0.72 + harmonico * 0.32;
	COLOR = vec4(cor, clamp(alfa * intensidade, 0.0, 1.0));
}
