shader_type canvas_item;
render_mode blend_mul, unshaded;

uniform float dusk_strength : hint_range(0.0, 1.0) = 0.0;
uniform float night_strength : hint_range(0.0, 1.0) = 0.0;
uniform float cloudiness : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 grade = mix(vec3(1.0), vec3(0.48, 0.43, 0.42), dusk_strength);
	grade = mix(grade, vec3(0.20, 0.24, 0.37), night_strength);
	grade = mix(grade, grade * vec3(0.80, 0.84, 0.92), cloudiness * 0.42);
	COLOR = vec4(grade, 1.0);
}
