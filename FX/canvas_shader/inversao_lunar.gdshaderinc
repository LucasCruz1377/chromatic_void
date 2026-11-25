uniform bool inverter_cores = false;
uniform bool hdr_lunar = false;

// A cor equipada é escolhida em sRGB. No canvas HDR o fragmento já está em luz linear.
vec3 negativo_lunar(vec3 entrada) {
	vec3 c = clamp(entrada, vec3(0.0), vec3(1.0));
	if (!hdr_lunar) {
		return 1.0 - c;
	}
	vec3 srgb = mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
	vec3 negativo = 1.0 - srgb;
	return mix(negativo / 12.92, pow((negativo + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), negativo));
}
