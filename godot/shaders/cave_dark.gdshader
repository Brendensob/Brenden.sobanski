shader_type canvas_item;
// Cave darkness: the screen fades to black away from the player, like the
// original in caves and the dark worlds. Distances are measured in screen
// heights, so the circle stays round at any window shape.
uniform vec2 center = vec2(0.5, 0.5); // the player, 0..1 across the screen
uniform float aspect = 1.7778;         // screen width / height
uniform float radius = 0.36;           // clear area, in screen heights
uniform float softness = 0.32;         // how gradually it fades
uniform float strength = 0.0;          // 0 = off, 1 = black at the edges
uniform vec4 tint : source_color = vec4(0.02, 0.01, 0.05, 1.0);

void fragment() {
	vec2 d = UV - center;
	d.x *= aspect;
	float dark = smoothstep(radius, radius + softness, length(d));
	COLOR = vec4(tint.rgb, dark * strength);
}
