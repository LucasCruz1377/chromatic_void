shader_type canvas_item;

uniform float brightness : hint_range(0.0,1.0,0.1) = 0.0;

void fragment() {
	
	vec4 col = COLOR;
	
	col.rgb = mix(col.rgb , vec3(1.0), brightness);
	
	COLOR = col;
	}