//No, this isn't a sensible way to implement such a simple feature

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float borderWidth;
vec2 iResolution;

out vec4 fragColor;

void main(void)
{
    iResolution = uSize;
    vec2 fragCoord = FlutterFragCoord();

    vec2 remap = iResolution-fragCoord;
    
    float val = 1.0-length(max((remap-(iResolution.xy-borderWidth)), 0.0))/borderWidth;
    val = smoothstep(0.0, 1.0, val);

    fragColor = vec4(val,val,val,val)*0.9;
}