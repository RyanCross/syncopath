shader_type canvas_item;
// ported from https://www.shadertoy.com/view/XlBBDt

#define NB_BARS		32
#define NB_SAMPLES	16
// WARNING : NB_BARS x NB_SAMPLES must be 512

// space between bars (relative to bar width)
#define SPACE		0.15

// space without bars, left and right (relative to window size)
#define SIDE_SPACE  0.04

// from here: www.shadertoy.com/view/XtjBzG
vec3 heatColorMap(float t)
{
    t *= 4.;
    return clamp(vec3(min(t-1.5, 4.5-t), 
                      min(t-0.5, 3.5-t), 
                      min(t+0.5, 2.5-t)), 
                 0., 1.);
}

// void mainImage( out vec4 O, in vec2 I ) {
void fragment() {
	vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 uv = FRAGCOORD.xy/iResolution.xy;
    
    //vec2 uv = UV;
    
    uv.x = (uv.x-SIDE_SPACE)/(1.-2.*SIDE_SPACE);
    
    if(uv.x<0. || uv.x > 1.)
    {
    	COLOR = vec4(0.);
    }
    
    float NB_BARS_F = float(NB_BARS);
    int bar = int(floor(uv.x * NB_BARS_F));
    
    float f = 0.;
    f = 0.;
    
    for(int t=0; t<NB_SAMPLES; t++)
    {
    	f += texelFetch(TEXTURE, ivec2(bar*NB_SAMPLES+t, 0), 0).r;
    }
    f /= float(NB_SAMPLES);
    
    f *= 0.85;
    f += 0.02;
    
    vec3 c = heatColorMap(f);
    

    float bar_f = float(bar)/NB_BARS_F;
    
    //c *= 1.-step(f, uv.y);
    //c *= 1.-step(1.-SPACE*.5, (uv.x-bar_f)*NB_BARS);
    //c *= 1.-step(1.-SPACE*.5, 1.-(uv.x-bar_f)*NB_BARS);
    
    c *= mix(1.,0., clamp((uv.y-f)*iResolution.y,0.,1.));
    c *= clamp((min((uv.x-bar_f)*NB_BARS_F, 1.-(uv.x-bar_f)*NB_BARS_F)-SPACE*.5)/NB_BARS_F*iResolution.x, 0., 1.);
    
    COLOR = vec4(c, 1.0);
}