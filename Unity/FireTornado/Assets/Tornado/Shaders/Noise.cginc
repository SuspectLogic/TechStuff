#if !defined(NOISE_INCLUDED)
#define NOISE_INCLUDED

float NoiseRandom(float2 uv)
{
    return frac(sin(dot(uv.xy,
                float2(12.9898,78.233)))
        * 43758.5453123);
}

float NoiseInt(float a, float b, float t)
{
    return (1.0 - t) * a + (t * b);
}

float NoiseValue(float2 uv)
{
    float2 i = floor(uv);
    float2 f = frac(uv);
    f = f * f * (3.0 - 2.0 * f);

    uv = abs(frac(uv) - 0.5);

    //four corners of 2D tile
    float a = NoiseRandom(i);
    float b = NoiseRandom(i + float2(1.0,0.0));
    float c = NoiseRandom(i + float2(0.0, 1.0));
    float d = NoiseRandom(i + float2(1.0,1.0));

    float bottomOfGrid = NoiseInt(a, b, f.x);
    float topOfGrid = NoiseInt(c, d, f.x);
    float t = NoiseInt(bottomOfGrid, topOfGrid, f.y);

    return t;
}

float NoiseOut(float2 UV, float Scale)
{
    float t = 0.0;

    float freq = pow(2.0, float(0));
    float amp = pow(0.5, float(3-0));
    t += NoiseValue(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

    freq = pow(2.0, float(1));
    amp = pow(0.5, float(3-1));
    t += NoiseValue(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

    freq = pow(2.0, float(2));
    amp = pow(0.5, float(3-2));
    t += NoiseValue(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

    return t;
}

#endif