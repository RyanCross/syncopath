shader_type canvas_item;

// lots taken from this vid, which was a huge help in translating audio data into shader
// https://www.youtube.com/watch?v=2LHljiWIx3w

const int VU_COUNT = 30; // same val as script
const float segment_count = 40.0; // number of "led lights" in the column

uniform float[VU_COUNT] freq_data;

void fragment() {
	vec2 uv = UV;
	uv.y = 1.0 - uv.y; // flip the y so equalizer displays bottom to top
	float vu_count = float(VU_COUNT);
	vec2 pos = vec2(floor(uv.x * vu_count) / vu_count, floor(uv.y * segment_count) / segment_count);
	float fft = freq_data[int(uv.x * vu_count)];
	// spectrum analyzers usually display in green and red
	// mix = linear interpolation
	vec3 color = mix(vec3(0.0, 2.0, 1.0), vec3(2.0, 0.0, 0.0), sqrt(uv.y));
	// make shine if greater than fft, otherwise keep dark
	float mask = pos.y < fft ? 1.0 : 0.1; 
	vec2 dist = fract((uv - pos) * vec2(vu_count, segment_count)) - 0.5;
	float led = smoothstep(0.5, 0.35, abs(dist.x)) * smoothstep(0.5, 0.35, abs(dist.y));
	COLOR = vec4(led * color * mask, 1.0);
}
