shader_type canvas_item;

uniform float velocidade : hint_range(0.05, 1.0) = 0.18;
uniform float brilho : hint_range(0.5, 2.0) = 1.25;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float fase = TIME * velocidade + UV.y * 1.35 + UV.x * 0.35;
	vec3 rgb = 0.58 + 0.42 * cos(6.2831853 * (fase + vec3(0.0, 0.3333, 0.6666)));
	COLOR = vec4(rgb * brilho, base.a * COLOR.a);
}
