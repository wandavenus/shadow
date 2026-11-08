shader_type canvas_item;
render_mode unshaded;

uniform sampler2D source_texture : source_color, filter_nearest, repeat_disable;
uniform float pixel_block : hint_range(1.0, 8.0) = 1.0;
uniform float color_steps : hint_range(3.0, 16.0) = 8.0;
uniform float saturation : hint_range(0.0, 1.0) = 0.8;

varying vec4 item_tint;

void vertex() {
	item_tint = COLOR;
}

void fragment() {
	vec2 source_size = 1.0 / TEXTURE_PIXEL_SIZE;
	float block = max(pixel_block, 1.0);
	vec2 source_pixel = floor(UV * source_size);
	vec2 block_origin = floor(source_pixel / block) * block;
	vec2 representative_pixel = min(block_origin + vec2(floor(block * 0.5)), source_size - vec2(1.0));
	vec2 sample_uv = (representative_pixel + vec2(0.5)) / source_size;
	vec4 source = texture(source_texture, sample_uv);

	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	vec3 muted = mix(vec3(luminance), source.rgb, saturation);
	float levels = max(color_steps, 3.0);
	vec3 palette = floor(muted * levels + vec3(0.5)) / levels;
	COLOR = vec4(palette, source.a) * item_tint;
}
