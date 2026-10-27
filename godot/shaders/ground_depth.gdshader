shader_type canvas_item;
// The ground darkens smoothly the deeper it is under the surface. The surface row
// of each column comes from a one-pixel-high picture (row / 255 in red).
uniform sampler2D surface : filter_nearest, repeat_disable;
uniform float columns = 64.0;
uniform float strength = 0.26;
varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float col = clamp(floor(world.x / 16.0), 0.0, columns - 1.0);
	float surf = texture(surface, vec2((col + 0.5) / columns, 0.5)).r * 255.0 * 16.0;
	// starts two tiles down, full strength 22 tiles down; whole pixels keep it crisp
	float d = clamp((floor(world.y) - surf - 32.0) / 352.0, 0.0, 1.0);
	COLOR.rgb *= 1.0 - strength * d;
}
