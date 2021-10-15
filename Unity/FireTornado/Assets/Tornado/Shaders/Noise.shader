Shader "Unlit/Noise"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _noiseScale ("Noise Scale", float) = 1.0
        _Speed ("Noise Speed", float) = 1.0
        _Contrast ("Contrast", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Noise.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _noiseScale;
            float _Scale;
            float _Speed;
            float _Contrast;
                                  
            v2f vert (appdata v)
            {
                v2f o;                
                v.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float2 tex1UV = v.uv * (float2(_noiseScale, _noiseScale) );
                o.uv = tex1UV + frac(_Time.y * float2(_Speed, _Speed));
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            float NoiseContrast(float In, float Contrast)
            {
                float midPoint = pow(0.5, 2.2);
                return (In - midPoint) * Contrast + midPoint;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float col = NoiseOut(i.uv, _noiseScale);
                col.r = NoiseContrast(col.r, _Contrast);
                
                // col *= col;

                return col;
            }
            ENDCG
        }
    }
}
