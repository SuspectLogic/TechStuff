Shader "Unlit/Tornado"
{
    Properties
    {
        [HDR] _ColorA ("Color A", Color) = (1,1,1,1)
        // [HDR] _ColorB ("Color B", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _clipThresh ("Clip threshold", range(0,1)) = 1.0
        _flameMultiplier ("Mask Multiplier", float) = 1.0

        [Header(Texture Settings)]
        [Space(20)]

        _texScale1X("Tex 1 Scale X", float) = 1.0
        _texScale1Y("Tex 1 Scale Y", float) = 1.0
        _texScale2X("Tex 2 Scale X", float) = 1.0
        _texScale2Y("Tex 2 Scale Y", float) = 1.0
        _scrollSpeed1X ("Tex 1, Scroll Speed X", float) = 0
        _scrollSpeed1Y ("Tex 1, Scroll Speed Y", float) = 0
        _scrollSpeed2X ("Tex 2, Scroll Speed X", float) = 0
        _scrollSpeed2Y ("Tex 2, Scroll Speed Y", float) = 0      

        [Header(Displacement Settings)]
        [Space(20)]

        _Displacement ("Displacement Power", float) = 0
        _noiseAmount ("Noise Amount", float ) = 0.0
        _noiseSpeedX ("Noise Speed X", float ) = 0
        _noiseSpeedY ("Noise Speed Y", float) = 0
        _scaleNoiseX ("Noise scale X", float) = 1.0
        _scaleNoiseY ("Noise Scale Y", float) = 1.0

        [Header(Pulse Settings)]
        [Space(20)]

        _pulseSpeed ("Pulse Speed (Very sensitive)", float) = 0.0
        _pulseForce ("Pulse Force", float) = 0.0

        [Header(Mask Settings)]
        [Space(20)]
        _maskOpacity ("mask opacity", float) = 1.0
        _maskTop ("Mask Top", float) = 5.0
        _maskBottom ("Mask Bottom", float) = 1.0
        _sideMask ("Side Mask", float) = 0.0

    }
    SubShader
    {
        Blend SrcAlpha OneMinusSrcAlpha
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        ZWrite On
        // Cull OFF
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv1 : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv1 : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float4 color : COLOR;
                UNITY_FOG_COORDS(0)
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
            };

            sampler2D _MainTex;

            float4 _MainTex_ST, _ColorA, _ColorB;

            //UV Speed
            float _scrollSpeed1X, _scrollSpeed1Y, _scrollSpeed2X, 
            _scrollSpeed2Y, _colMult, _noiseSpeedX, _noiseSpeedY, 
            _Displacement, _clipThresh, _scaleNoiseX, _scaleNoiseY, 
            _pulseSpeed, _pulseForce, _texScale1X, _texScale1Y, _texScale2X, 
            _texScale2Y, _noiseAmount, _maskOpacity, _maskTop, _maskBottom, _sideMask, 
            _flameMultiplier; 
                                   
//// Transforms 2D UV by scale/bias property
// #define TRANSFORM_TEX(tex,name) (tex.xy * name##_ST.xy + name##_ST.zw)

            v2f vert (appdata v)
            {
                v2f o;
                //Pulse Settings. this creates scrolling uvs and passes them into the sampled gradient texture.
                float2 pulseUV = float2(v.uv1.x, 1 - (v.uv1.y - 0.5)) + frac(_Time.y * float2(_pulseSpeed, _pulseSpeed));
                float pulseCol = tex2Dlod(_MainTex, float4(float2(pulseUV),0,0)).b;//tex2Dlod is a function used to sample the texture in the vertex shader. passing in the pulseUV.
                float pulseOut = pulseCol / _pulseForce;
                
                //Noise
                float2 noiseUV = v.uv1.xy + frac(_Time.y * float2(_noiseSpeedX, _noiseSpeedY)); //setup uv's to scroll with time multiplier
                float3 noiseTex = tex2Dlod(_MainTex, float4(noiseUV * float2(_scaleNoiseX, _scaleNoiseY), 0,0)); //sample Another texture using tex2Dlod, this time passing in noiseUV as the primary uvs.
                float2 noiseOut = lerp(v.uv1.xy, float2(noiseTex.g, noiseTex.g), _noiseAmount);//output of the noise to later be used to distort uvs for textures in the frag shader.

                //Two sets of uvs multiplied by the noise out.
                float2 tex1UV = noiseOut * (float2(_texScale1X, _texScale1Y) );
                float2 tex2UV = noiseOut * (float2(_texScale2X, _texScale2Y));

                //these uvs are output 
                o.uv1 = tex1UV + frac(_Time.y * float2(_scrollSpeed1X, _scrollSpeed1Y));
                o.uv2 = tex2UV + frac(_Time.y * float2(_scrollSpeed2X, _scrollSpeed2Y));

                //Masks for the top, bottom and sides of the textures.
                float vertMask = ((pow(1 - v.uv2.y, _maskTop) * (pow( v.uv2.y, _maskBottom))) * _maskOpacity);
                float sideMask = ((pow(1 - v.uv2.x, _sideMask) * (pow(v.uv2.x, _sideMask))) * _maskOpacity);
                o.color = vertMask * sideMask;



                //Multiply displacement last
                v.vertex.xyz +=  ((noiseTex.g - pulseOut) * v.normal) * _Displacement;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.vertex = UnityObjectToClipPos(v.vertex);

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 colA = tex2D(_MainTex, i.uv1);
                float4 colB = tex2D(_MainTex, i.uv2);
                float flameMask = (colA.r * colB.r) * _flameMultiplier;
                float4 col = _ColorA;
                // col.rgb = lerp(_ColorA, _ColorB, flameMask); //Color version 2. This version is better if you don't want to rely on HDR colors for flames.
                col.a = flameMask * i.color.r;          
                clip(col.a - _clipThresh);
                
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                // col = i.color;
                return col;
            }
            ENDCG
        }
    }
}
