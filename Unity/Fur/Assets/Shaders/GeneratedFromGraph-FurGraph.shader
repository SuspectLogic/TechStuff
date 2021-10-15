Shader "Fur"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 0)
        _Multiply("Multiply", Range(0, 1)) = 0
        [NoScaleOffset]_MainTex("Fur Texture", 2D) = "white" {}
        _MainTex_ST("Tiling", Vector) = (1, 1, 0, 0)
        _RimPower("Rim Power", Float) = 4
        [NoScaleOffset]_MaskTex("Mask Texture", 2D) = "white" {}
        [NoScaleOffset]_ColorTex("Color Texture", 2D) = "white" {}
        _NoiseScale("Noise Scale", Float) = 50
        _LenthVar("Length Variation", Range(0, 1)) = 0
        _NoiseContrast("Mask Contrast", Range(0, 2)) = 1
        _WindStrength("WindStrength", Float) = 0
        _WindSettings("Wind Tiling and Speed", Vector) = (1, 1, 0.1, 0.1)
        _ClipThreshold("Alpha Clip Threshold", Range(0, 1)) = 1
        _HairOccCol("Hair occlusion color", Color) = (1, 1, 1, 0)
        [NoScaleOffset]_FlowTex("Flow Map", 2D) = "black" {}
        _FlowStrength("Flow map strength", Range(0, 1)) = 0
        [ToggleUI]_DEBUGVERTEXCOLORS_ON("Debug vertex colors", Float) = 0
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "UniversalMaterialType" = "Lit"
            "Queue"="AlphaTest"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_COLOR
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_COLOR
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_FORWARD
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv0 : TEXCOORD0;
            float4 uv1 : TEXCOORD1;
            float4 color : COLOR;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float4 texCoord0;
            float4 color;
            float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            float2 lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 sh;
            #endif
            float4 fogFactorAndVertexLight;
            float4 shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 TangentSpaceNormal;
            float4 uv0;
            float4 VertexColor;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float4 uv0;
            float4 VertexColor;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float4 interp3 : TEXCOORD3;
            float4 interp4 : TEXCOORD4;
            float3 interp5 : TEXCOORD5;
            #if defined(LIGHTMAP_ON)
            float2 interp6 : TEXCOORD6;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 interp7 : TEXCOORD7;
            #endif
            float4 interp8 : TEXCOORD8;
            float4 interp9 : TEXCOORD9;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyzw =  input.texCoord0;
            output.interp4.xyzw =  input.color;
            output.interp5.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp6.xy =  input.lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp7.xyz =  input.sh;
            #endif
            output.interp8.xyzw =  input.fogFactorAndVertexLight;
            output.interp9.xyzw =  input.shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.texCoord0 = input.interp3.xyzw;
            output.color = input.interp4.xyzw;
            output.viewDirectionWS = input.interp5.xyz;
            #if defined(LIGHTMAP_ON)
            output.lightmapUV = input.interp6.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp7.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp8.xyzw;
            output.shadowCoord = input.interp9.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        half4 _Color;
        half _Multiply;
        float4 _MainTex_TexelSize;
        half4 _MainTex_ST;
        half _RimPower;
        float4 _MaskTex_TexelSize;
        float4 _ColorTex_TexelSize;
        half _NoiseScale;
        half _LenthVar;
        half _NoiseContrast;
        half _WindStrength;
        half4 _WindSettings;
        half _ClipThreshold;
        half4 _HairOccCol;
        float4 _FlowTex_TexelSize;
        half _FlowStrength;
        half _DEBUGVERTEXCOLORS_ON;
        CBUFFER_END

        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_MaskTex);
        SAMPLER(sampler_MaskTex);
        TEXTURE2D(_ColorTex);
        SAMPLER(sampler_ColorTex);
        TEXTURE2D(_FlowTex);
        SAMPLER(sampler_FlowTex);

            // Graph Functions
            
        void Unity_Combine_half(half R, half G, half B, half A, out half4 RGBA, out half3 RGB, out half2 RG)
        {
            RGBA = half4(R, G, B, A);
            RGB = half3(R, G, B);
            RG = half2(R, G);
        }

        void Unity_Multiply_half(half A, half B, out half Out)
        {
            Out = A * B;
        }

        void Unity_Add_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A + B;
        }

        void Unity_TilingAndOffset_half(half2 UV, half2 Tiling, half2 Offset, out half2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        half2 Unity_GradientNoise_Dir_half(half2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(half2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_half(half2 UV, half Scale, out half Out)
        { 
            half2 p = UV * Scale;
            half2 ip = floor(p);
            half2 fp = frac(p);
            half d00 = dot(Unity_GradientNoise_Dir_half(ip), fp);
            half d01 = dot(Unity_GradientNoise_Dir_half(ip + half2(0, 1)), fp - half2(0, 1));
            half d10 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 0)), fp - half2(1, 0));
            half d11 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 1)), fp - half2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_half4(half4 A, half4 B, half4 T, out half4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Multiply_half(half2 A, half2 B, out half2 Out)
        {
            Out = A * B;
        }

        void Unity_Subtract_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A - B;
        }

        void Unity_Step_half(half Edge, half In, out half Out)
        {
            Out = step(Edge, In);
        }


        inline half Unity_SimpleNoise_RandomValue_half (half2 uv)
        {
            return frac(sin(dot(uv, half2(12.9898, 78.233)))*43758.5453);
        }

        inline half Unity_SimpleNnoise_Interpolate_half (half a, half b, half t)
        {
            return (1.0-t)*a + (t*b);
        }


        inline half Unity_SimpleNoise_ValueNoise_half (half2 uv)
        {
            half2 i = floor(uv);
            half2 f = frac(uv);
            f = f * f * (3.0 - 2.0 * f);

            uv = abs(frac(uv) - 0.5);
            half2 c0 = i + half2(0.0, 0.0);
            half2 c1 = i + half2(1.0, 0.0);
            half2 c2 = i + half2(0.0, 1.0);
            half2 c3 = i + half2(1.0, 1.0);
            half r0 = Unity_SimpleNoise_RandomValue_half(c0);
            half r1 = Unity_SimpleNoise_RandomValue_half(c1);
            half r2 = Unity_SimpleNoise_RandomValue_half(c2);
            half r3 = Unity_SimpleNoise_RandomValue_half(c3);

            half bottomOfGrid = Unity_SimpleNnoise_Interpolate_half(r0, r1, f.x);
            half topOfGrid = Unity_SimpleNnoise_Interpolate_half(r2, r3, f.x);
            half t = Unity_SimpleNnoise_Interpolate_half(bottomOfGrid, topOfGrid, f.y);
            return t;
        }
        void Unity_SimpleNoise_half(half2 UV, half Scale, out half Out)
        {
            half t = 0.0;

            half freq = pow(2.0, half(0));
            half amp = pow(0.5, half(3-0));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(1));
            amp = pow(0.5, half(3-1));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(2));
            amp = pow(0.5, half(3-2));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            Out = t;
        }

        void Unity_Smoothstep_half(half Edge1, half Edge2, half In, out half Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Lerp_half(half A, half B, half T, out half Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Subtract_half(half A, half B, out half Out)
        {
            Out = A - B;
        }

        void Unity_Saturate_half(half In, out half Out)
        {
            Out = saturate(In);
        }

        void Unity_Multiply_half(half4 A, half4 B, out half4 Out)
        {
            Out = A * B;
        }

        void Unity_Branch_half4(half Predicate, half4 True, half4 False, out half4 Out)
        {
            Out = Predicate ? True : False;
        }

        void Unity_NormalUnpack_half(half4 In, out half3 Out)
        {
                        Out = UnpackNormal(In);
                    }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            half3 Normal;
            half3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            half4 _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0 = _WindSettings;
            half _Split_bb70b739a797490d880162edc7afee6f_R_1 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[0];
            half _Split_bb70b739a797490d880162edc7afee6f_G_2 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[1];
            half _Split_bb70b739a797490d880162edc7afee6f_B_3 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[2];
            half _Split_bb70b739a797490d880162edc7afee6f_A_4 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[3];
            half4 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4;
            half3 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5;
            half2 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6;
            Unity_Combine_half(_Split_bb70b739a797490d880162edc7afee6f_R_1, _Split_bb70b739a797490d880162edc7afee6f_G_2, 0, 0, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6);
            half2 _Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0 = half2(_Split_bb70b739a797490d880162edc7afee6f_B_3, _Split_bb70b739a797490d880162edc7afee6f_A_4);
            half _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_B_3, IN.TimeParameters.x, _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2);
            half _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_A_4, IN.TimeParameters.x, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2);
            half4 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4;
            half3 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5;
            half2 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6;
            Unity_Combine_half(_Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2, 0, 0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6);
            half2 _Add_090b4851a1384ca09f399033bea33b52_Out_2;
            Unity_Add_half2(_Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2);
            half2 _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2, _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3);
            half _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2;
            Unity_GradientNoise_half(_TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3, 16, _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2);
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2;
            Unity_Multiply_half(_GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_80222ead6749415082b7f9c461e2b035_Out_2);
            half _Property_00bf319b767845e7851dfff509e4690f_Out_0 = _WindStrength;
            half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
            Unity_Multiply_half(_Multiply_80222ead6749415082b7f9c461e2b035_Out_2, _Property_00bf319b767845e7851dfff509e4690f_Out_0, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2);
            half _Multiply_6235c90d381c4045880e54b9359ca466_Out_2;
            Unity_Multiply_half(0.05, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2, _Multiply_6235c90d381c4045880e54b9359ca466_Out_2);
            float3 _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            Unity_Add_float3((_Multiply_6235c90d381c4045880e54b9359ca466_Out_2.xxx), IN.ObjectSpacePosition, _Add_49510769758a45d69ae0fdcacecba70d_Out_2);
            description.Position = _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            half3 BaseColor;
            half3 NormalTS;
            half3 Emission;
            half Metallic;
            half Smoothness;
            half Occlusion;
            half Alpha;
            half AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            half4 _Property_2228b5aed348428da10b9296f9ebc494_Out_0 = _Color;
            half _Property_38318a489f9a4408a735e7c400d44b9a_Out_0 = _DEBUGVERTEXCOLORS_ON;
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half4 _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0 = _HairOccCol;
            half4 _Lerp_266d46ff80174903a133109b2f8086e1_Out_3;
            Unity_Lerp_half4(_Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0, half4(1, 1, 1, 1), (_Split_32e455b4db934124814f28147e62dda0_R_1.xxxx), _Lerp_266d46ff80174903a133109b2f8086e1_Out_3);
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_R_1 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[0];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_G_2 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[1];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_B_3 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[2];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_A_4 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[3];
            half4 _Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3;
            Unity_Lerp_half4(half4(1, 1, 1, 1), _Lerp_266d46ff80174903a133109b2f8086e1_Out_3, (_Split_9b0b84b2dbbd49d3b86865c028aa1936_A_4.xxxx), _Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3);
            UnityTexture2D _Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0 = UnityBuildTexture2DStructNoScale(_ColorTex);
            half4 _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0 = _WindSettings;
            half _Split_bb70b739a797490d880162edc7afee6f_R_1 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[0];
            half _Split_bb70b739a797490d880162edc7afee6f_G_2 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[1];
            half _Split_bb70b739a797490d880162edc7afee6f_B_3 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[2];
            half _Split_bb70b739a797490d880162edc7afee6f_A_4 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[3];
            half4 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4;
            half3 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5;
            half2 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6;
            Unity_Combine_half(_Split_bb70b739a797490d880162edc7afee6f_R_1, _Split_bb70b739a797490d880162edc7afee6f_G_2, 0, 0, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6);
            half2 _Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0 = half2(_Split_bb70b739a797490d880162edc7afee6f_B_3, _Split_bb70b739a797490d880162edc7afee6f_A_4);
            half _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_B_3, IN.TimeParameters.x, _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2);
            half _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_A_4, IN.TimeParameters.x, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2);
            half4 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4;
            half3 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5;
            half2 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6;
            Unity_Combine_half(_Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2, 0, 0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6);
            half2 _Add_090b4851a1384ca09f399033bea33b52_Out_2;
            Unity_Add_half2(_Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2);
            half2 _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2, _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3);
            half _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2;
            Unity_GradientNoise_half(_TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3, 16, _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2);
            half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2;
            Unity_Multiply_half(_GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_80222ead6749415082b7f9c461e2b035_Out_2);
            half _Property_00bf319b767845e7851dfff509e4690f_Out_0 = _WindStrength;
            half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
            Unity_Multiply_half(_Multiply_80222ead6749415082b7f9c461e2b035_Out_2, _Property_00bf319b767845e7851dfff509e4690f_Out_0, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2);
            half4 _Property_7104b0921e324793aecf6f4aef29ed10_Out_0 = _MainTex_ST;
            half _Split_602db811c686494894895d6489ac1a93_R_1 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[0];
            half _Split_602db811c686494894895d6489ac1a93_G_2 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[1];
            half _Split_602db811c686494894895d6489ac1a93_B_3 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[2];
            half _Split_602db811c686494894895d6489ac1a93_A_4 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[3];
            half4 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGBA_4;
            half3 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGB_5;
            half2 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6;
            Unity_Combine_half(_Split_602db811c686494894895d6489ac1a93_B_3, _Split_602db811c686494894895d6489ac1a93_A_4, 0, 0, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGBA_4, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGB_5, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6);
            half2 _Add_5ecadbcbe14847e18d526011c7679f8c_Out_2;
            Unity_Add_half2((_Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2.xx), _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6, _Add_5ecadbcbe14847e18d526011c7679f8c_Out_2);
            UnityTexture2D _Property_525a14b76350460487a0235960d53ada_Out_0 = UnityBuildTexture2DStructNoScale(_MainTex);
            half4 _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4;
            half3 _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5;
            half2 _Combine_f7a96a985f594d6cae0daad764b71498_RG_6;
            Unity_Combine_half(_Split_602db811c686494894895d6489ac1a93_R_1, _Split_602db811c686494894895d6489ac1a93_G_2, 0, 0, _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4, _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6);
            half2 _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6, half2 (0, 0), _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3);
            UnityTexture2D _Property_6f42653dd834439da6b2995d25abd852_Out_0 = UnityBuildTexture2DStructNoScale(_FlowTex);
            half4 _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6f42653dd834439da6b2995d25abd852_Out_0.tex, _Property_6f42653dd834439da6b2995d25abd852_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_R_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.r;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_G_5 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.g;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_B_6 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.b;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_A_7 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.a;
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_R_1 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[0];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[1];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_B_3 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[2];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_A_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[3];
            half4 _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4;
            half3 _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5;
            half2 _Combine_00997931f0e1429d9a936bab82c990fc_RG_6;
            Unity_Combine_half(_Split_5c07383c9bd542b5bb228ba55a4bf822_R_1, _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2, 0, 0, _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4, _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5, _Combine_00997931f0e1429d9a936bab82c990fc_RG_6);
            half2 _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2;
            Unity_Multiply_half(_Combine_00997931f0e1429d9a936bab82c990fc_RG_6, half2(2, 2), _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2);
            half2 _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2;
            Unity_Subtract_half2(_Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2, half2(1, 1), _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2);
            half2 _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2;
            Unity_Multiply_half(_Subtract_528e92e261ff4ce082329f42aaede8de_Out_2, (_Split_32e455b4db934124814f28147e62dda0_R_1.xx), _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2);
            half _Property_24307526768d44f09f9614d06af9462e_Out_0 = _FlowStrength;
            half2 _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2;
            Unity_Multiply_half(_Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2, (_Property_24307526768d44f09f9614d06af9462e_Out_0.xx), _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2);
            half2 _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2;
            Unity_Add_half2(_TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3, _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half4 _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0 = SAMPLE_TEXTURE2D(_Property_525a14b76350460487a0235960d53ada_Out_0.tex, _Property_525a14b76350460487a0235960d53ada_Out_0.samplerstate, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_R_4 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.r;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_G_5 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.g;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_B_6 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.b;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.a;
            half _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2;
            Unity_Step_half(_Split_32e455b4db934124814f28147e62dda0_R_1, _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7, _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2);
            UnityTexture2D _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0 = UnityBuildTexture2DStructNoScale(_MaskTex);
            half4 _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.tex, _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.r;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_G_5 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.g;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_B_6 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.b;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_A_7 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.a;
            half _Property_d805ba1e888840a1b721ba4757ff7653_Out_0 = _NoiseScale;
            half _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2;
            Unity_SimpleNoise_half(IN.uv0.xy, _Property_d805ba1e888840a1b721ba4757ff7653_Out_0, _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2);
            half _Multiply_2301638808af49f1b094a9bc30731680_Out_2;
            Unity_Multiply_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, 4, _Multiply_2301638808af49f1b094a9bc30731680_Out_2);
            half _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0 = _NoiseContrast;
            half _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3;
            Unity_Smoothstep_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, _Multiply_2301638808af49f1b094a9bc30731680_Out_2, _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0, _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3);
            half _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2;
            Unity_Multiply_half(_Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2);
            half _Property_15657d2187234f36bee94093c3e87cfc_Out_0 = _LenthVar;
            half _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3;
            Unity_Lerp_half(0, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2, _Property_15657d2187234f36bee94093c3e87cfc_Out_0, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3);
            half _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2;
            Unity_Subtract_half(_SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3, _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2);
            half _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1;
            Unity_Saturate_half(_Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1);
            half _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            Unity_Multiply_half(_Step_a0e808c6281d4f1e906e97dc26931de5_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1, _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2);
            half2 _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2;
            Unity_Multiply_half(_Add_5ecadbcbe14847e18d526011c7679f8c_Out_2, (_Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2.xx), _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2);
            half2 _Multiply_9a843867bc00497ebdabd88255642899_Out_2;
            Unity_Multiply_half(half2(0.1, 0.1), _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2, _Multiply_9a843867bc00497ebdabd88255642899_Out_2);
            half2 _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, half2 (1, 1), _Multiply_9a843867bc00497ebdabd88255642899_Out_2, _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3);
            half4 _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0 = SAMPLE_TEXTURE2D(_Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0.tex, _Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0.samplerstate, _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3);
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_R_4 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.r;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_G_5 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.g;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_B_6 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.b;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_A_7 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.a;
            half4 _Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2;
            Unity_Multiply_half(_Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3, _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0, _Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2);
            half _Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2;
            Unity_Multiply_half(_SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7, 1, _Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2);
            half4 _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2;
            Unity_Multiply_half(_Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2, (_Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2.xxxx), _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2);
            half4 _Branch_1de247f9645e44088172ca18ab7005fc_Out_3;
            Unity_Branch_half4(_Property_38318a489f9a4408a735e7c400d44b9a_Out_0, (_Split_32e455b4db934124814f28147e62dda0_R_1.xxxx), _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2, _Branch_1de247f9645e44088172ca18ab7005fc_Out_3);
            half4 _Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2;
            Unity_Multiply_half(_Property_2228b5aed348428da10b9296f9ebc494_Out_0, _Branch_1de247f9645e44088172ca18ab7005fc_Out_3, _Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2);
            half3 _NormalUnpack_a1ec2fa45e3a4b338f038233d42da4b0_Out_1;
            Unity_NormalUnpack_half(_SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0, _NormalUnpack_a1ec2fa45e3a4b338f038233d42da4b0_Out_1);
            half _Property_eb141db1cd544ea2adf973c512527d1f_Out_0 = _ClipThreshold;
            surface.BaseColor = (_Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2.xyz);
            surface.NormalTS = _NormalUnpack_a1ec2fa45e3a4b338f038233d42da4b0_Out_1;
            surface.Emission = half3(0, 0, 0);
            surface.Metallic = 0;
            surface.Smoothness = 0;
            surface.Occlusion = 1;
            surface.Alpha = _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            surface.AlphaClipThreshold = _Property_eb141db1cd544ea2adf973c512527d1f_Out_0;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.uv0 =                         input.uv0;
            output.VertexColor =                 input.color;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);



            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);


            output.uv0 =                         input.texCoord0;
            output.VertexColor =                 input.color;
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "GBuffer"
            Tags
            {
                "LightMode" = "UniversalGBuffer"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
        #pragma multi_compile _ _GBUFFER_NORMALS_OCT
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_COLOR
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_COLOR
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_GBUFFER
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv0 : TEXCOORD0;
            float4 uv1 : TEXCOORD1;
            float4 color : COLOR;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float4 texCoord0;
            float4 color;
            float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            float2 lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 sh;
            #endif
            float4 fogFactorAndVertexLight;
            float4 shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 TangentSpaceNormal;
            float4 uv0;
            float4 VertexColor;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float4 uv0;
            float4 VertexColor;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float4 interp3 : TEXCOORD3;
            float4 interp4 : TEXCOORD4;
            float3 interp5 : TEXCOORD5;
            #if defined(LIGHTMAP_ON)
            float2 interp6 : TEXCOORD6;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 interp7 : TEXCOORD7;
            #endif
            float4 interp8 : TEXCOORD8;
            float4 interp9 : TEXCOORD9;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyzw =  input.texCoord0;
            output.interp4.xyzw =  input.color;
            output.interp5.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp6.xy =  input.lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp7.xyz =  input.sh;
            #endif
            output.interp8.xyzw =  input.fogFactorAndVertexLight;
            output.interp9.xyzw =  input.shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.texCoord0 = input.interp3.xyzw;
            output.color = input.interp4.xyzw;
            output.viewDirectionWS = input.interp5.xyz;
            #if defined(LIGHTMAP_ON)
            output.lightmapUV = input.interp6.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp7.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp8.xyzw;
            output.shadowCoord = input.interp9.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        half4 _Color;
        half _Multiply;
        float4 _MainTex_TexelSize;
        half4 _MainTex_ST;
        half _RimPower;
        float4 _MaskTex_TexelSize;
        float4 _ColorTex_TexelSize;
        half _NoiseScale;
        half _LenthVar;
        half _NoiseContrast;
        half _WindStrength;
        half4 _WindSettings;
        half _ClipThreshold;
        half4 _HairOccCol;
        float4 _FlowTex_TexelSize;
        half _FlowStrength;
        half _DEBUGVERTEXCOLORS_ON;
        CBUFFER_END

        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_MaskTex);
        SAMPLER(sampler_MaskTex);
        TEXTURE2D(_ColorTex);
        SAMPLER(sampler_ColorTex);
        TEXTURE2D(_FlowTex);
        SAMPLER(sampler_FlowTex);

            // Graph Functions
            
        void Unity_Combine_half(half R, half G, half B, half A, out half4 RGBA, out half3 RGB, out half2 RG)
        {
            RGBA = half4(R, G, B, A);
            RGB = half3(R, G, B);
            RG = half2(R, G);
        }

        void Unity_Multiply_half(half A, half B, out half Out)
        {
            Out = A * B;
        }

        void Unity_Add_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A + B;
        }

        void Unity_TilingAndOffset_half(half2 UV, half2 Tiling, half2 Offset, out half2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        half2 Unity_GradientNoise_Dir_half(half2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(half2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_half(half2 UV, half Scale, out half Out)
        { 
            half2 p = UV * Scale;
            half2 ip = floor(p);
            half2 fp = frac(p);
            half d00 = dot(Unity_GradientNoise_Dir_half(ip), fp);
            half d01 = dot(Unity_GradientNoise_Dir_half(ip + half2(0, 1)), fp - half2(0, 1));
            half d10 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 0)), fp - half2(1, 0));
            half d11 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 1)), fp - half2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_half4(half4 A, half4 B, half4 T, out half4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Multiply_half(half2 A, half2 B, out half2 Out)
        {
            Out = A * B;
        }

        void Unity_Subtract_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A - B;
        }

        void Unity_Step_half(half Edge, half In, out half Out)
        {
            Out = step(Edge, In);
        }


        inline half Unity_SimpleNoise_RandomValue_half (half2 uv)
        {
            return frac(sin(dot(uv, half2(12.9898, 78.233)))*43758.5453);
        }

        inline half Unity_SimpleNnoise_Interpolate_half (half a, half b, half t)
        {
            return (1.0-t)*a + (t*b);
        }


        inline half Unity_SimpleNoise_ValueNoise_half (half2 uv)
        {
            half2 i = floor(uv);
            half2 f = frac(uv);
            f = f * f * (3.0 - 2.0 * f);

            uv = abs(frac(uv) - 0.5);
            half2 c0 = i + half2(0.0, 0.0);
            half2 c1 = i + half2(1.0, 0.0);
            half2 c2 = i + half2(0.0, 1.0);
            half2 c3 = i + half2(1.0, 1.0);
            half r0 = Unity_SimpleNoise_RandomValue_half(c0);
            half r1 = Unity_SimpleNoise_RandomValue_half(c1);
            half r2 = Unity_SimpleNoise_RandomValue_half(c2);
            half r3 = Unity_SimpleNoise_RandomValue_half(c3);

            half bottomOfGrid = Unity_SimpleNnoise_Interpolate_half(r0, r1, f.x);
            half topOfGrid = Unity_SimpleNnoise_Interpolate_half(r2, r3, f.x);
            half t = Unity_SimpleNnoise_Interpolate_half(bottomOfGrid, topOfGrid, f.y);
            return t;
        }
        void Unity_SimpleNoise_half(half2 UV, half Scale, out half Out)
        {
            half t = 0.0;

            half freq = pow(2.0, half(0));
            half amp = pow(0.5, half(3-0));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(1));
            amp = pow(0.5, half(3-1));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(2));
            amp = pow(0.5, half(3-2));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            Out = t;
        }

        void Unity_Smoothstep_half(half Edge1, half Edge2, half In, out half Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Lerp_half(half A, half B, half T, out half Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Subtract_half(half A, half B, out half Out)
        {
            Out = A - B;
        }

        void Unity_Saturate_half(half In, out half Out)
        {
            Out = saturate(In);
        }

        void Unity_Multiply_half(half4 A, half4 B, out half4 Out)
        {
            Out = A * B;
        }

        void Unity_Branch_half4(half Predicate, half4 True, half4 False, out half4 Out)
        {
            Out = Predicate ? True : False;
        }

        void Unity_NormalUnpack_half(half4 In, out half3 Out)
        {
                        Out = UnpackNormal(In);
                    }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            half3 Normal;
            half3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            half4 _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0 = _WindSettings;
            half _Split_bb70b739a797490d880162edc7afee6f_R_1 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[0];
            half _Split_bb70b739a797490d880162edc7afee6f_G_2 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[1];
            half _Split_bb70b739a797490d880162edc7afee6f_B_3 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[2];
            half _Split_bb70b739a797490d880162edc7afee6f_A_4 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[3];
            half4 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4;
            half3 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5;
            half2 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6;
            Unity_Combine_half(_Split_bb70b739a797490d880162edc7afee6f_R_1, _Split_bb70b739a797490d880162edc7afee6f_G_2, 0, 0, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6);
            half2 _Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0 = half2(_Split_bb70b739a797490d880162edc7afee6f_B_3, _Split_bb70b739a797490d880162edc7afee6f_A_4);
            half _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_B_3, IN.TimeParameters.x, _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2);
            half _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_A_4, IN.TimeParameters.x, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2);
            half4 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4;
            half3 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5;
            half2 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6;
            Unity_Combine_half(_Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2, 0, 0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6);
            half2 _Add_090b4851a1384ca09f399033bea33b52_Out_2;
            Unity_Add_half2(_Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2);
            half2 _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2, _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3);
            half _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2;
            Unity_GradientNoise_half(_TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3, 16, _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2);
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2;
            Unity_Multiply_half(_GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_80222ead6749415082b7f9c461e2b035_Out_2);
            half _Property_00bf319b767845e7851dfff509e4690f_Out_0 = _WindStrength;
            half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
            Unity_Multiply_half(_Multiply_80222ead6749415082b7f9c461e2b035_Out_2, _Property_00bf319b767845e7851dfff509e4690f_Out_0, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2);
            half _Multiply_6235c90d381c4045880e54b9359ca466_Out_2;
            Unity_Multiply_half(0.05, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2, _Multiply_6235c90d381c4045880e54b9359ca466_Out_2);
            float3 _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            Unity_Add_float3((_Multiply_6235c90d381c4045880e54b9359ca466_Out_2.xxx), IN.ObjectSpacePosition, _Add_49510769758a45d69ae0fdcacecba70d_Out_2);
            description.Position = _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            half3 BaseColor;
            half3 NormalTS;
            half3 Emission;
            half Metallic;
            half Smoothness;
            half Occlusion;
            half Alpha;
            half AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            half4 _Property_2228b5aed348428da10b9296f9ebc494_Out_0 = _Color;
            half _Property_38318a489f9a4408a735e7c400d44b9a_Out_0 = _DEBUGVERTEXCOLORS_ON;
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half4 _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0 = _HairOccCol;
            half4 _Lerp_266d46ff80174903a133109b2f8086e1_Out_3;
            Unity_Lerp_half4(_Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0, half4(1, 1, 1, 1), (_Split_32e455b4db934124814f28147e62dda0_R_1.xxxx), _Lerp_266d46ff80174903a133109b2f8086e1_Out_3);
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_R_1 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[0];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_G_2 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[1];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_B_3 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[2];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_A_4 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[3];
            half4 _Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3;
            Unity_Lerp_half4(half4(1, 1, 1, 1), _Lerp_266d46ff80174903a133109b2f8086e1_Out_3, (_Split_9b0b84b2dbbd49d3b86865c028aa1936_A_4.xxxx), _Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3);
            UnityTexture2D _Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0 = UnityBuildTexture2DStructNoScale(_ColorTex);
            half4 _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0 = _WindSettings;
            half _Split_bb70b739a797490d880162edc7afee6f_R_1 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[0];
            half _Split_bb70b739a797490d880162edc7afee6f_G_2 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[1];
            half _Split_bb70b739a797490d880162edc7afee6f_B_3 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[2];
            half _Split_bb70b739a797490d880162edc7afee6f_A_4 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[3];
            half4 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4;
            half3 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5;
            half2 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6;
            Unity_Combine_half(_Split_bb70b739a797490d880162edc7afee6f_R_1, _Split_bb70b739a797490d880162edc7afee6f_G_2, 0, 0, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6);
            half2 _Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0 = half2(_Split_bb70b739a797490d880162edc7afee6f_B_3, _Split_bb70b739a797490d880162edc7afee6f_A_4);
            half _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_B_3, IN.TimeParameters.x, _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2);
            half _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_A_4, IN.TimeParameters.x, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2);
            half4 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4;
            half3 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5;
            half2 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6;
            Unity_Combine_half(_Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2, 0, 0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6);
            half2 _Add_090b4851a1384ca09f399033bea33b52_Out_2;
            Unity_Add_half2(_Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2);
            half2 _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2, _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3);
            half _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2;
            Unity_GradientNoise_half(_TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3, 16, _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2);
            half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2;
            Unity_Multiply_half(_GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_80222ead6749415082b7f9c461e2b035_Out_2);
            half _Property_00bf319b767845e7851dfff509e4690f_Out_0 = _WindStrength;
            half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
            Unity_Multiply_half(_Multiply_80222ead6749415082b7f9c461e2b035_Out_2, _Property_00bf319b767845e7851dfff509e4690f_Out_0, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2);
            half4 _Property_7104b0921e324793aecf6f4aef29ed10_Out_0 = _MainTex_ST;
            half _Split_602db811c686494894895d6489ac1a93_R_1 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[0];
            half _Split_602db811c686494894895d6489ac1a93_G_2 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[1];
            half _Split_602db811c686494894895d6489ac1a93_B_3 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[2];
            half _Split_602db811c686494894895d6489ac1a93_A_4 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[3];
            half4 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGBA_4;
            half3 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGB_5;
            half2 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6;
            Unity_Combine_half(_Split_602db811c686494894895d6489ac1a93_B_3, _Split_602db811c686494894895d6489ac1a93_A_4, 0, 0, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGBA_4, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGB_5, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6);
            half2 _Add_5ecadbcbe14847e18d526011c7679f8c_Out_2;
            Unity_Add_half2((_Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2.xx), _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6, _Add_5ecadbcbe14847e18d526011c7679f8c_Out_2);
            UnityTexture2D _Property_525a14b76350460487a0235960d53ada_Out_0 = UnityBuildTexture2DStructNoScale(_MainTex);
            half4 _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4;
            half3 _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5;
            half2 _Combine_f7a96a985f594d6cae0daad764b71498_RG_6;
            Unity_Combine_half(_Split_602db811c686494894895d6489ac1a93_R_1, _Split_602db811c686494894895d6489ac1a93_G_2, 0, 0, _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4, _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6);
            half2 _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6, half2 (0, 0), _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3);
            UnityTexture2D _Property_6f42653dd834439da6b2995d25abd852_Out_0 = UnityBuildTexture2DStructNoScale(_FlowTex);
            half4 _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6f42653dd834439da6b2995d25abd852_Out_0.tex, _Property_6f42653dd834439da6b2995d25abd852_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_R_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.r;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_G_5 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.g;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_B_6 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.b;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_A_7 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.a;
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_R_1 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[0];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[1];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_B_3 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[2];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_A_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[3];
            half4 _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4;
            half3 _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5;
            half2 _Combine_00997931f0e1429d9a936bab82c990fc_RG_6;
            Unity_Combine_half(_Split_5c07383c9bd542b5bb228ba55a4bf822_R_1, _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2, 0, 0, _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4, _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5, _Combine_00997931f0e1429d9a936bab82c990fc_RG_6);
            half2 _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2;
            Unity_Multiply_half(_Combine_00997931f0e1429d9a936bab82c990fc_RG_6, half2(2, 2), _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2);
            half2 _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2;
            Unity_Subtract_half2(_Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2, half2(1, 1), _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2);
            half2 _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2;
            Unity_Multiply_half(_Subtract_528e92e261ff4ce082329f42aaede8de_Out_2, (_Split_32e455b4db934124814f28147e62dda0_R_1.xx), _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2);
            half _Property_24307526768d44f09f9614d06af9462e_Out_0 = _FlowStrength;
            half2 _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2;
            Unity_Multiply_half(_Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2, (_Property_24307526768d44f09f9614d06af9462e_Out_0.xx), _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2);
            half2 _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2;
            Unity_Add_half2(_TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3, _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half4 _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0 = SAMPLE_TEXTURE2D(_Property_525a14b76350460487a0235960d53ada_Out_0.tex, _Property_525a14b76350460487a0235960d53ada_Out_0.samplerstate, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_R_4 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.r;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_G_5 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.g;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_B_6 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.b;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.a;
            half _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2;
            Unity_Step_half(_Split_32e455b4db934124814f28147e62dda0_R_1, _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7, _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2);
            UnityTexture2D _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0 = UnityBuildTexture2DStructNoScale(_MaskTex);
            half4 _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.tex, _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.r;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_G_5 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.g;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_B_6 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.b;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_A_7 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.a;
            half _Property_d805ba1e888840a1b721ba4757ff7653_Out_0 = _NoiseScale;
            half _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2;
            Unity_SimpleNoise_half(IN.uv0.xy, _Property_d805ba1e888840a1b721ba4757ff7653_Out_0, _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2);
            half _Multiply_2301638808af49f1b094a9bc30731680_Out_2;
            Unity_Multiply_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, 4, _Multiply_2301638808af49f1b094a9bc30731680_Out_2);
            half _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0 = _NoiseContrast;
            half _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3;
            Unity_Smoothstep_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, _Multiply_2301638808af49f1b094a9bc30731680_Out_2, _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0, _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3);
            half _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2;
            Unity_Multiply_half(_Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2);
            half _Property_15657d2187234f36bee94093c3e87cfc_Out_0 = _LenthVar;
            half _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3;
            Unity_Lerp_half(0, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2, _Property_15657d2187234f36bee94093c3e87cfc_Out_0, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3);
            half _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2;
            Unity_Subtract_half(_SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3, _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2);
            half _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1;
            Unity_Saturate_half(_Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1);
            half _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            Unity_Multiply_half(_Step_a0e808c6281d4f1e906e97dc26931de5_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1, _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2);
            half2 _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2;
            Unity_Multiply_half(_Add_5ecadbcbe14847e18d526011c7679f8c_Out_2, (_Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2.xx), _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2);
            half2 _Multiply_9a843867bc00497ebdabd88255642899_Out_2;
            Unity_Multiply_half(half2(0.1, 0.1), _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2, _Multiply_9a843867bc00497ebdabd88255642899_Out_2);
            half2 _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, half2 (1, 1), _Multiply_9a843867bc00497ebdabd88255642899_Out_2, _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3);
            half4 _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0 = SAMPLE_TEXTURE2D(_Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0.tex, _Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0.samplerstate, _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3);
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_R_4 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.r;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_G_5 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.g;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_B_6 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.b;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_A_7 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.a;
            half4 _Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2;
            Unity_Multiply_half(_Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3, _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0, _Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2);
            half _Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2;
            Unity_Multiply_half(_SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7, 1, _Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2);
            half4 _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2;
            Unity_Multiply_half(_Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2, (_Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2.xxxx), _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2);
            half4 _Branch_1de247f9645e44088172ca18ab7005fc_Out_3;
            Unity_Branch_half4(_Property_38318a489f9a4408a735e7c400d44b9a_Out_0, (_Split_32e455b4db934124814f28147e62dda0_R_1.xxxx), _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2, _Branch_1de247f9645e44088172ca18ab7005fc_Out_3);
            half4 _Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2;
            Unity_Multiply_half(_Property_2228b5aed348428da10b9296f9ebc494_Out_0, _Branch_1de247f9645e44088172ca18ab7005fc_Out_3, _Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2);
            half3 _NormalUnpack_a1ec2fa45e3a4b338f038233d42da4b0_Out_1;
            Unity_NormalUnpack_half(_SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0, _NormalUnpack_a1ec2fa45e3a4b338f038233d42da4b0_Out_1);
            half _Property_eb141db1cd544ea2adf973c512527d1f_Out_0 = _ClipThreshold;
            surface.BaseColor = (_Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2.xyz);
            surface.NormalTS = _NormalUnpack_a1ec2fa45e3a4b338f038233d42da4b0_Out_1;
            surface.Emission = half3(0, 0, 0);
            surface.Metallic = 0;
            surface.Smoothness = 0;
            surface.Occlusion = 1;
            surface.Alpha = _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            surface.AlphaClipThreshold = _Property_eb141db1cd544ea2adf973c512527d1f_Out_0;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.uv0 =                         input.uv0;
            output.VertexColor =                 input.color;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);



            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);


            output.uv0 =                         input.texCoord0;
            output.VertexColor =                 input.color;
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRGBufferPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_COLOR
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_COLOR
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_SHADOWCASTER
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv0 : TEXCOORD0;
            float4 color : COLOR;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float4 texCoord0;
            float4 color;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float4 uv0;
            float4 VertexColor;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float4 uv0;
            float4 VertexColor;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float4 interp0 : TEXCOORD0;
            float4 interp1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyzw =  input.texCoord0;
            output.interp1.xyzw =  input.color;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.interp0.xyzw;
            output.color = input.interp1.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        half4 _Color;
        half _Multiply;
        float4 _MainTex_TexelSize;
        half4 _MainTex_ST;
        half _RimPower;
        float4 _MaskTex_TexelSize;
        float4 _ColorTex_TexelSize;
        half _NoiseScale;
        half _LenthVar;
        half _NoiseContrast;
        half _WindStrength;
        half4 _WindSettings;
        half _ClipThreshold;
        half4 _HairOccCol;
        float4 _FlowTex_TexelSize;
        half _FlowStrength;
        half _DEBUGVERTEXCOLORS_ON;
        CBUFFER_END

        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_MaskTex);
        SAMPLER(sampler_MaskTex);
        TEXTURE2D(_ColorTex);
        SAMPLER(sampler_ColorTex);
        TEXTURE2D(_FlowTex);
        SAMPLER(sampler_FlowTex);

            // Graph Functions
            
        void Unity_Combine_half(half R, half G, half B, half A, out half4 RGBA, out half3 RGB, out half2 RG)
        {
            RGBA = half4(R, G, B, A);
            RGB = half3(R, G, B);
            RG = half2(R, G);
        }

        void Unity_Multiply_half(half A, half B, out half Out)
        {
            Out = A * B;
        }

        void Unity_Add_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A + B;
        }

        void Unity_TilingAndOffset_half(half2 UV, half2 Tiling, half2 Offset, out half2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        half2 Unity_GradientNoise_Dir_half(half2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(half2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_half(half2 UV, half Scale, out half Out)
        { 
            half2 p = UV * Scale;
            half2 ip = floor(p);
            half2 fp = frac(p);
            half d00 = dot(Unity_GradientNoise_Dir_half(ip), fp);
            half d01 = dot(Unity_GradientNoise_Dir_half(ip + half2(0, 1)), fp - half2(0, 1));
            half d10 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 0)), fp - half2(1, 0));
            half d11 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 1)), fp - half2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Multiply_half(half2 A, half2 B, out half2 Out)
        {
            Out = A * B;
        }

        void Unity_Subtract_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A - B;
        }

        void Unity_Step_half(half Edge, half In, out half Out)
        {
            Out = step(Edge, In);
        }


        inline half Unity_SimpleNoise_RandomValue_half (half2 uv)
        {
            return frac(sin(dot(uv, half2(12.9898, 78.233)))*43758.5453);
        }

        inline half Unity_SimpleNnoise_Interpolate_half (half a, half b, half t)
        {
            return (1.0-t)*a + (t*b);
        }


        inline half Unity_SimpleNoise_ValueNoise_half (half2 uv)
        {
            half2 i = floor(uv);
            half2 f = frac(uv);
            f = f * f * (3.0 - 2.0 * f);

            uv = abs(frac(uv) - 0.5);
            half2 c0 = i + half2(0.0, 0.0);
            half2 c1 = i + half2(1.0, 0.0);
            half2 c2 = i + half2(0.0, 1.0);
            half2 c3 = i + half2(1.0, 1.0);
            half r0 = Unity_SimpleNoise_RandomValue_half(c0);
            half r1 = Unity_SimpleNoise_RandomValue_half(c1);
            half r2 = Unity_SimpleNoise_RandomValue_half(c2);
            half r3 = Unity_SimpleNoise_RandomValue_half(c3);

            half bottomOfGrid = Unity_SimpleNnoise_Interpolate_half(r0, r1, f.x);
            half topOfGrid = Unity_SimpleNnoise_Interpolate_half(r2, r3, f.x);
            half t = Unity_SimpleNnoise_Interpolate_half(bottomOfGrid, topOfGrid, f.y);
            return t;
        }
        void Unity_SimpleNoise_half(half2 UV, half Scale, out half Out)
        {
            half t = 0.0;

            half freq = pow(2.0, half(0));
            half amp = pow(0.5, half(3-0));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(1));
            amp = pow(0.5, half(3-1));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(2));
            amp = pow(0.5, half(3-2));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            Out = t;
        }

        void Unity_Smoothstep_half(half Edge1, half Edge2, half In, out half Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Lerp_half(half A, half B, half T, out half Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Subtract_half(half A, half B, out half Out)
        {
            Out = A - B;
        }

        void Unity_Saturate_half(half In, out half Out)
        {
            Out = saturate(In);
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            half3 Normal;
            half3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            half4 _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0 = _WindSettings;
            half _Split_bb70b739a797490d880162edc7afee6f_R_1 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[0];
            half _Split_bb70b739a797490d880162edc7afee6f_G_2 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[1];
            half _Split_bb70b739a797490d880162edc7afee6f_B_3 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[2];
            half _Split_bb70b739a797490d880162edc7afee6f_A_4 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[3];
            half4 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4;
            half3 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5;
            half2 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6;
            Unity_Combine_half(_Split_bb70b739a797490d880162edc7afee6f_R_1, _Split_bb70b739a797490d880162edc7afee6f_G_2, 0, 0, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6);
            half2 _Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0 = half2(_Split_bb70b739a797490d880162edc7afee6f_B_3, _Split_bb70b739a797490d880162edc7afee6f_A_4);
            half _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_B_3, IN.TimeParameters.x, _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2);
            half _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_A_4, IN.TimeParameters.x, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2);
            half4 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4;
            half3 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5;
            half2 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6;
            Unity_Combine_half(_Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2, 0, 0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6);
            half2 _Add_090b4851a1384ca09f399033bea33b52_Out_2;
            Unity_Add_half2(_Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2);
            half2 _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2, _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3);
            half _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2;
            Unity_GradientNoise_half(_TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3, 16, _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2);
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2;
            Unity_Multiply_half(_GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_80222ead6749415082b7f9c461e2b035_Out_2);
            half _Property_00bf319b767845e7851dfff509e4690f_Out_0 = _WindStrength;
            half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
            Unity_Multiply_half(_Multiply_80222ead6749415082b7f9c461e2b035_Out_2, _Property_00bf319b767845e7851dfff509e4690f_Out_0, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2);
            half _Multiply_6235c90d381c4045880e54b9359ca466_Out_2;
            Unity_Multiply_half(0.05, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2, _Multiply_6235c90d381c4045880e54b9359ca466_Out_2);
            float3 _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            Unity_Add_float3((_Multiply_6235c90d381c4045880e54b9359ca466_Out_2.xxx), IN.ObjectSpacePosition, _Add_49510769758a45d69ae0fdcacecba70d_Out_2);
            description.Position = _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            half Alpha;
            half AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            UnityTexture2D _Property_525a14b76350460487a0235960d53ada_Out_0 = UnityBuildTexture2DStructNoScale(_MainTex);
            half4 _Property_7104b0921e324793aecf6f4aef29ed10_Out_0 = _MainTex_ST;
            half _Split_602db811c686494894895d6489ac1a93_R_1 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[0];
            half _Split_602db811c686494894895d6489ac1a93_G_2 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[1];
            half _Split_602db811c686494894895d6489ac1a93_B_3 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[2];
            half _Split_602db811c686494894895d6489ac1a93_A_4 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[3];
            half4 _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4;
            half3 _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5;
            half2 _Combine_f7a96a985f594d6cae0daad764b71498_RG_6;
            Unity_Combine_half(_Split_602db811c686494894895d6489ac1a93_R_1, _Split_602db811c686494894895d6489ac1a93_G_2, 0, 0, _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4, _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6);
            half2 _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6, half2 (0, 0), _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3);
            UnityTexture2D _Property_6f42653dd834439da6b2995d25abd852_Out_0 = UnityBuildTexture2DStructNoScale(_FlowTex);
            half4 _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6f42653dd834439da6b2995d25abd852_Out_0.tex, _Property_6f42653dd834439da6b2995d25abd852_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_R_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.r;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_G_5 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.g;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_B_6 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.b;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_A_7 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.a;
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_R_1 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[0];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[1];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_B_3 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[2];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_A_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[3];
            half4 _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4;
            half3 _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5;
            half2 _Combine_00997931f0e1429d9a936bab82c990fc_RG_6;
            Unity_Combine_half(_Split_5c07383c9bd542b5bb228ba55a4bf822_R_1, _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2, 0, 0, _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4, _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5, _Combine_00997931f0e1429d9a936bab82c990fc_RG_6);
            half2 _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2;
            Unity_Multiply_half(_Combine_00997931f0e1429d9a936bab82c990fc_RG_6, half2(2, 2), _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2);
            half2 _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2;
            Unity_Subtract_half2(_Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2, half2(1, 1), _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2);
            half2 _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2;
            Unity_Multiply_half(_Subtract_528e92e261ff4ce082329f42aaede8de_Out_2, (_Split_32e455b4db934124814f28147e62dda0_R_1.xx), _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2);
            half _Property_24307526768d44f09f9614d06af9462e_Out_0 = _FlowStrength;
            half2 _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2;
            Unity_Multiply_half(_Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2, (_Property_24307526768d44f09f9614d06af9462e_Out_0.xx), _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2);
            half2 _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2;
            Unity_Add_half2(_TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3, _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half4 _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0 = SAMPLE_TEXTURE2D(_Property_525a14b76350460487a0235960d53ada_Out_0.tex, _Property_525a14b76350460487a0235960d53ada_Out_0.samplerstate, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_R_4 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.r;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_G_5 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.g;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_B_6 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.b;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.a;
            half _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2;
            Unity_Step_half(_Split_32e455b4db934124814f28147e62dda0_R_1, _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7, _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2);
            UnityTexture2D _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0 = UnityBuildTexture2DStructNoScale(_MaskTex);
            half4 _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.tex, _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.r;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_G_5 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.g;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_B_6 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.b;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_A_7 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.a;
            half _Property_d805ba1e888840a1b721ba4757ff7653_Out_0 = _NoiseScale;
            half _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2;
            Unity_SimpleNoise_half(IN.uv0.xy, _Property_d805ba1e888840a1b721ba4757ff7653_Out_0, _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2);
            half _Multiply_2301638808af49f1b094a9bc30731680_Out_2;
            Unity_Multiply_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, 4, _Multiply_2301638808af49f1b094a9bc30731680_Out_2);
            half _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0 = _NoiseContrast;
            half _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3;
            Unity_Smoothstep_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, _Multiply_2301638808af49f1b094a9bc30731680_Out_2, _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0, _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3);
            half _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2;
            Unity_Multiply_half(_Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2);
            half _Property_15657d2187234f36bee94093c3e87cfc_Out_0 = _LenthVar;
            half _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3;
            Unity_Lerp_half(0, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2, _Property_15657d2187234f36bee94093c3e87cfc_Out_0, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3);
            half _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2;
            Unity_Subtract_half(_SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3, _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2);
            half _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1;
            Unity_Saturate_half(_Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1);
            half _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            Unity_Multiply_half(_Step_a0e808c6281d4f1e906e97dc26931de5_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1, _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2);
            half _Property_eb141db1cd544ea2adf973c512527d1f_Out_0 = _ClipThreshold;
            surface.Alpha = _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            surface.AlphaClipThreshold = _Property_eb141db1cd544ea2adf973c512527d1f_Out_0;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.uv0 =                         input.uv0;
            output.VertexColor =                 input.color;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





            output.uv0 =                         input.texCoord0;
            output.VertexColor =                 input.color;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_COLOR
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_COLOR
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHONLY
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv0 : TEXCOORD0;
            float4 color : COLOR;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float4 texCoord0;
            float4 color;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float4 uv0;
            float4 VertexColor;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float4 uv0;
            float4 VertexColor;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float4 interp0 : TEXCOORD0;
            float4 interp1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyzw =  input.texCoord0;
            output.interp1.xyzw =  input.color;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.interp0.xyzw;
            output.color = input.interp1.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        half4 _Color;
        half _Multiply;
        float4 _MainTex_TexelSize;
        half4 _MainTex_ST;
        half _RimPower;
        float4 _MaskTex_TexelSize;
        float4 _ColorTex_TexelSize;
        half _NoiseScale;
        half _LenthVar;
        half _NoiseContrast;
        half _WindStrength;
        half4 _WindSettings;
        half _ClipThreshold;
        half4 _HairOccCol;
        float4 _FlowTex_TexelSize;
        half _FlowStrength;
        half _DEBUGVERTEXCOLORS_ON;
        CBUFFER_END

        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_MaskTex);
        SAMPLER(sampler_MaskTex);
        TEXTURE2D(_ColorTex);
        SAMPLER(sampler_ColorTex);
        TEXTURE2D(_FlowTex);
        SAMPLER(sampler_FlowTex);

            // Graph Functions
            
        void Unity_Combine_half(half R, half G, half B, half A, out half4 RGBA, out half3 RGB, out half2 RG)
        {
            RGBA = half4(R, G, B, A);
            RGB = half3(R, G, B);
            RG = half2(R, G);
        }

        void Unity_Multiply_half(half A, half B, out half Out)
        {
            Out = A * B;
        }

        void Unity_Add_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A + B;
        }

        void Unity_TilingAndOffset_half(half2 UV, half2 Tiling, half2 Offset, out half2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        half2 Unity_GradientNoise_Dir_half(half2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(half2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_half(half2 UV, half Scale, out half Out)
        { 
            half2 p = UV * Scale;
            half2 ip = floor(p);
            half2 fp = frac(p);
            half d00 = dot(Unity_GradientNoise_Dir_half(ip), fp);
            half d01 = dot(Unity_GradientNoise_Dir_half(ip + half2(0, 1)), fp - half2(0, 1));
            half d10 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 0)), fp - half2(1, 0));
            half d11 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 1)), fp - half2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Multiply_half(half2 A, half2 B, out half2 Out)
        {
            Out = A * B;
        }

        void Unity_Subtract_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A - B;
        }

        void Unity_Step_half(half Edge, half In, out half Out)
        {
            Out = step(Edge, In);
        }


        inline half Unity_SimpleNoise_RandomValue_half (half2 uv)
        {
            return frac(sin(dot(uv, half2(12.9898, 78.233)))*43758.5453);
        }

        inline half Unity_SimpleNnoise_Interpolate_half (half a, half b, half t)
        {
            return (1.0-t)*a + (t*b);
        }


        inline half Unity_SimpleNoise_ValueNoise_half (half2 uv)
        {
            half2 i = floor(uv);
            half2 f = frac(uv);
            f = f * f * (3.0 - 2.0 * f);

            uv = abs(frac(uv) - 0.5);
            half2 c0 = i + half2(0.0, 0.0);
            half2 c1 = i + half2(1.0, 0.0);
            half2 c2 = i + half2(0.0, 1.0);
            half2 c3 = i + half2(1.0, 1.0);
            half r0 = Unity_SimpleNoise_RandomValue_half(c0);
            half r1 = Unity_SimpleNoise_RandomValue_half(c1);
            half r2 = Unity_SimpleNoise_RandomValue_half(c2);
            half r3 = Unity_SimpleNoise_RandomValue_half(c3);

            half bottomOfGrid = Unity_SimpleNnoise_Interpolate_half(r0, r1, f.x);
            half topOfGrid = Unity_SimpleNnoise_Interpolate_half(r2, r3, f.x);
            half t = Unity_SimpleNnoise_Interpolate_half(bottomOfGrid, topOfGrid, f.y);
            return t;
        }
        void Unity_SimpleNoise_half(half2 UV, half Scale, out half Out)
        {
            half t = 0.0;

            half freq = pow(2.0, half(0));
            half amp = pow(0.5, half(3-0));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(1));
            amp = pow(0.5, half(3-1));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(2));
            amp = pow(0.5, half(3-2));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            Out = t;
        }

        void Unity_Smoothstep_half(half Edge1, half Edge2, half In, out half Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Lerp_half(half A, half B, half T, out half Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Subtract_half(half A, half B, out half Out)
        {
            Out = A - B;
        }

        void Unity_Saturate_half(half In, out half Out)
        {
            Out = saturate(In);
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            half3 Normal;
            half3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            half4 _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0 = _WindSettings;
            half _Split_bb70b739a797490d880162edc7afee6f_R_1 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[0];
            half _Split_bb70b739a797490d880162edc7afee6f_G_2 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[1];
            half _Split_bb70b739a797490d880162edc7afee6f_B_3 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[2];
            half _Split_bb70b739a797490d880162edc7afee6f_A_4 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[3];
            half4 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4;
            half3 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5;
            half2 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6;
            Unity_Combine_half(_Split_bb70b739a797490d880162edc7afee6f_R_1, _Split_bb70b739a797490d880162edc7afee6f_G_2, 0, 0, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6);
            half2 _Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0 = half2(_Split_bb70b739a797490d880162edc7afee6f_B_3, _Split_bb70b739a797490d880162edc7afee6f_A_4);
            half _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_B_3, IN.TimeParameters.x, _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2);
            half _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_A_4, IN.TimeParameters.x, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2);
            half4 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4;
            half3 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5;
            half2 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6;
            Unity_Combine_half(_Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2, 0, 0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6);
            half2 _Add_090b4851a1384ca09f399033bea33b52_Out_2;
            Unity_Add_half2(_Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2);
            half2 _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2, _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3);
            half _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2;
            Unity_GradientNoise_half(_TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3, 16, _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2);
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2;
            Unity_Multiply_half(_GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_80222ead6749415082b7f9c461e2b035_Out_2);
            half _Property_00bf319b767845e7851dfff509e4690f_Out_0 = _WindStrength;
            half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
            Unity_Multiply_half(_Multiply_80222ead6749415082b7f9c461e2b035_Out_2, _Property_00bf319b767845e7851dfff509e4690f_Out_0, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2);
            half _Multiply_6235c90d381c4045880e54b9359ca466_Out_2;
            Unity_Multiply_half(0.05, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2, _Multiply_6235c90d381c4045880e54b9359ca466_Out_2);
            float3 _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            Unity_Add_float3((_Multiply_6235c90d381c4045880e54b9359ca466_Out_2.xxx), IN.ObjectSpacePosition, _Add_49510769758a45d69ae0fdcacecba70d_Out_2);
            description.Position = _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            half Alpha;
            half AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            UnityTexture2D _Property_525a14b76350460487a0235960d53ada_Out_0 = UnityBuildTexture2DStructNoScale(_MainTex);
            half4 _Property_7104b0921e324793aecf6f4aef29ed10_Out_0 = _MainTex_ST;
            half _Split_602db811c686494894895d6489ac1a93_R_1 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[0];
            half _Split_602db811c686494894895d6489ac1a93_G_2 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[1];
            half _Split_602db811c686494894895d6489ac1a93_B_3 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[2];
            half _Split_602db811c686494894895d6489ac1a93_A_4 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[3];
            half4 _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4;
            half3 _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5;
            half2 _Combine_f7a96a985f594d6cae0daad764b71498_RG_6;
            Unity_Combine_half(_Split_602db811c686494894895d6489ac1a93_R_1, _Split_602db811c686494894895d6489ac1a93_G_2, 0, 0, _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4, _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6);
            half2 _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6, half2 (0, 0), _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3);
            UnityTexture2D _Property_6f42653dd834439da6b2995d25abd852_Out_0 = UnityBuildTexture2DStructNoScale(_FlowTex);
            half4 _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6f42653dd834439da6b2995d25abd852_Out_0.tex, _Property_6f42653dd834439da6b2995d25abd852_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_R_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.r;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_G_5 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.g;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_B_6 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.b;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_A_7 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.a;
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_R_1 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[0];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[1];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_B_3 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[2];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_A_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[3];
            half4 _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4;
            half3 _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5;
            half2 _Combine_00997931f0e1429d9a936bab82c990fc_RG_6;
            Unity_Combine_half(_Split_5c07383c9bd542b5bb228ba55a4bf822_R_1, _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2, 0, 0, _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4, _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5, _Combine_00997931f0e1429d9a936bab82c990fc_RG_6);
            half2 _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2;
            Unity_Multiply_half(_Combine_00997931f0e1429d9a936bab82c990fc_RG_6, half2(2, 2), _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2);
            half2 _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2;
            Unity_Subtract_half2(_Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2, half2(1, 1), _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2);
            half2 _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2;
            Unity_Multiply_half(_Subtract_528e92e261ff4ce082329f42aaede8de_Out_2, (_Split_32e455b4db934124814f28147e62dda0_R_1.xx), _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2);
            half _Property_24307526768d44f09f9614d06af9462e_Out_0 = _FlowStrength;
            half2 _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2;
            Unity_Multiply_half(_Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2, (_Property_24307526768d44f09f9614d06af9462e_Out_0.xx), _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2);
            half2 _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2;
            Unity_Add_half2(_TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3, _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half4 _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0 = SAMPLE_TEXTURE2D(_Property_525a14b76350460487a0235960d53ada_Out_0.tex, _Property_525a14b76350460487a0235960d53ada_Out_0.samplerstate, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_R_4 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.r;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_G_5 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.g;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_B_6 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.b;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.a;
            half _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2;
            Unity_Step_half(_Split_32e455b4db934124814f28147e62dda0_R_1, _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7, _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2);
            UnityTexture2D _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0 = UnityBuildTexture2DStructNoScale(_MaskTex);
            half4 _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.tex, _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.r;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_G_5 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.g;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_B_6 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.b;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_A_7 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.a;
            half _Property_d805ba1e888840a1b721ba4757ff7653_Out_0 = _NoiseScale;
            half _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2;
            Unity_SimpleNoise_half(IN.uv0.xy, _Property_d805ba1e888840a1b721ba4757ff7653_Out_0, _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2);
            half _Multiply_2301638808af49f1b094a9bc30731680_Out_2;
            Unity_Multiply_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, 4, _Multiply_2301638808af49f1b094a9bc30731680_Out_2);
            half _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0 = _NoiseContrast;
            half _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3;
            Unity_Smoothstep_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, _Multiply_2301638808af49f1b094a9bc30731680_Out_2, _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0, _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3);
            half _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2;
            Unity_Multiply_half(_Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2);
            half _Property_15657d2187234f36bee94093c3e87cfc_Out_0 = _LenthVar;
            half _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3;
            Unity_Lerp_half(0, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2, _Property_15657d2187234f36bee94093c3e87cfc_Out_0, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3);
            half _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2;
            Unity_Subtract_half(_SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3, _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2);
            half _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1;
            Unity_Saturate_half(_Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1);
            half _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            Unity_Multiply_half(_Step_a0e808c6281d4f1e906e97dc26931de5_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1, _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2);
            half _Property_eb141db1cd544ea2adf973c512527d1f_Out_0 = _ClipThreshold;
            surface.Alpha = _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            surface.AlphaClipThreshold = _Property_eb141db1cd544ea2adf973c512527d1f_Out_0;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.uv0 =                         input.uv0;
            output.VertexColor =                 input.color;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





            output.uv0 =                         input.texCoord0;
            output.VertexColor =                 input.color;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_COLOR
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_COLOR
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv0 : TEXCOORD0;
            float4 uv1 : TEXCOORD1;
            float4 color : COLOR;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 normalWS;
            float4 tangentWS;
            float4 texCoord0;
            float4 color;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 TangentSpaceNormal;
            float4 uv0;
            float4 VertexColor;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float4 uv0;
            float4 VertexColor;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float4 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float4 interp3 : TEXCOORD3;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.normalWS;
            output.interp1.xyzw =  input.tangentWS;
            output.interp2.xyzw =  input.texCoord0;
            output.interp3.xyzw =  input.color;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.normalWS = input.interp0.xyz;
            output.tangentWS = input.interp1.xyzw;
            output.texCoord0 = input.interp2.xyzw;
            output.color = input.interp3.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        half4 _Color;
        half _Multiply;
        float4 _MainTex_TexelSize;
        half4 _MainTex_ST;
        half _RimPower;
        float4 _MaskTex_TexelSize;
        float4 _ColorTex_TexelSize;
        half _NoiseScale;
        half _LenthVar;
        half _NoiseContrast;
        half _WindStrength;
        half4 _WindSettings;
        half _ClipThreshold;
        half4 _HairOccCol;
        float4 _FlowTex_TexelSize;
        half _FlowStrength;
        half _DEBUGVERTEXCOLORS_ON;
        CBUFFER_END

        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_MaskTex);
        SAMPLER(sampler_MaskTex);
        TEXTURE2D(_ColorTex);
        SAMPLER(sampler_ColorTex);
        TEXTURE2D(_FlowTex);
        SAMPLER(sampler_FlowTex);

            // Graph Functions
            
        void Unity_Combine_half(half R, half G, half B, half A, out half4 RGBA, out half3 RGB, out half2 RG)
        {
            RGBA = half4(R, G, B, A);
            RGB = half3(R, G, B);
            RG = half2(R, G);
        }

        void Unity_Multiply_half(half A, half B, out half Out)
        {
            Out = A * B;
        }

        void Unity_Add_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A + B;
        }

        void Unity_TilingAndOffset_half(half2 UV, half2 Tiling, half2 Offset, out half2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        half2 Unity_GradientNoise_Dir_half(half2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(half2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_half(half2 UV, half Scale, out half Out)
        { 
            half2 p = UV * Scale;
            half2 ip = floor(p);
            half2 fp = frac(p);
            half d00 = dot(Unity_GradientNoise_Dir_half(ip), fp);
            half d01 = dot(Unity_GradientNoise_Dir_half(ip + half2(0, 1)), fp - half2(0, 1));
            half d10 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 0)), fp - half2(1, 0));
            half d11 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 1)), fp - half2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Multiply_half(half2 A, half2 B, out half2 Out)
        {
            Out = A * B;
        }

        void Unity_Subtract_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A - B;
        }

        void Unity_NormalUnpack_half(half4 In, out half3 Out)
        {
                        Out = UnpackNormal(In);
                    }

        void Unity_Step_half(half Edge, half In, out half Out)
        {
            Out = step(Edge, In);
        }


        inline half Unity_SimpleNoise_RandomValue_half (half2 uv)
        {
            return frac(sin(dot(uv, half2(12.9898, 78.233)))*43758.5453);
        }

        inline half Unity_SimpleNnoise_Interpolate_half (half a, half b, half t)
        {
            return (1.0-t)*a + (t*b);
        }


        inline half Unity_SimpleNoise_ValueNoise_half (half2 uv)
        {
            half2 i = floor(uv);
            half2 f = frac(uv);
            f = f * f * (3.0 - 2.0 * f);

            uv = abs(frac(uv) - 0.5);
            half2 c0 = i + half2(0.0, 0.0);
            half2 c1 = i + half2(1.0, 0.0);
            half2 c2 = i + half2(0.0, 1.0);
            half2 c3 = i + half2(1.0, 1.0);
            half r0 = Unity_SimpleNoise_RandomValue_half(c0);
            half r1 = Unity_SimpleNoise_RandomValue_half(c1);
            half r2 = Unity_SimpleNoise_RandomValue_half(c2);
            half r3 = Unity_SimpleNoise_RandomValue_half(c3);

            half bottomOfGrid = Unity_SimpleNnoise_Interpolate_half(r0, r1, f.x);
            half topOfGrid = Unity_SimpleNnoise_Interpolate_half(r2, r3, f.x);
            half t = Unity_SimpleNnoise_Interpolate_half(bottomOfGrid, topOfGrid, f.y);
            return t;
        }
        void Unity_SimpleNoise_half(half2 UV, half Scale, out half Out)
        {
            half t = 0.0;

            half freq = pow(2.0, half(0));
            half amp = pow(0.5, half(3-0));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(1));
            amp = pow(0.5, half(3-1));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(2));
            amp = pow(0.5, half(3-2));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            Out = t;
        }

        void Unity_Smoothstep_half(half Edge1, half Edge2, half In, out half Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Lerp_half(half A, half B, half T, out half Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Subtract_half(half A, half B, out half Out)
        {
            Out = A - B;
        }

        void Unity_Saturate_half(half In, out half Out)
        {
            Out = saturate(In);
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            half3 Normal;
            half3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            half4 _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0 = _WindSettings;
            half _Split_bb70b739a797490d880162edc7afee6f_R_1 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[0];
            half _Split_bb70b739a797490d880162edc7afee6f_G_2 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[1];
            half _Split_bb70b739a797490d880162edc7afee6f_B_3 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[2];
            half _Split_bb70b739a797490d880162edc7afee6f_A_4 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[3];
            half4 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4;
            half3 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5;
            half2 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6;
            Unity_Combine_half(_Split_bb70b739a797490d880162edc7afee6f_R_1, _Split_bb70b739a797490d880162edc7afee6f_G_2, 0, 0, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6);
            half2 _Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0 = half2(_Split_bb70b739a797490d880162edc7afee6f_B_3, _Split_bb70b739a797490d880162edc7afee6f_A_4);
            half _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_B_3, IN.TimeParameters.x, _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2);
            half _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_A_4, IN.TimeParameters.x, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2);
            half4 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4;
            half3 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5;
            half2 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6;
            Unity_Combine_half(_Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2, 0, 0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6);
            half2 _Add_090b4851a1384ca09f399033bea33b52_Out_2;
            Unity_Add_half2(_Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2);
            half2 _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2, _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3);
            half _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2;
            Unity_GradientNoise_half(_TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3, 16, _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2);
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2;
            Unity_Multiply_half(_GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_80222ead6749415082b7f9c461e2b035_Out_2);
            half _Property_00bf319b767845e7851dfff509e4690f_Out_0 = _WindStrength;
            half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
            Unity_Multiply_half(_Multiply_80222ead6749415082b7f9c461e2b035_Out_2, _Property_00bf319b767845e7851dfff509e4690f_Out_0, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2);
            half _Multiply_6235c90d381c4045880e54b9359ca466_Out_2;
            Unity_Multiply_half(0.05, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2, _Multiply_6235c90d381c4045880e54b9359ca466_Out_2);
            float3 _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            Unity_Add_float3((_Multiply_6235c90d381c4045880e54b9359ca466_Out_2.xxx), IN.ObjectSpacePosition, _Add_49510769758a45d69ae0fdcacecba70d_Out_2);
            description.Position = _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            half3 NormalTS;
            half Alpha;
            half AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_525a14b76350460487a0235960d53ada_Out_0 = UnityBuildTexture2DStructNoScale(_MainTex);
            half4 _Property_7104b0921e324793aecf6f4aef29ed10_Out_0 = _MainTex_ST;
            half _Split_602db811c686494894895d6489ac1a93_R_1 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[0];
            half _Split_602db811c686494894895d6489ac1a93_G_2 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[1];
            half _Split_602db811c686494894895d6489ac1a93_B_3 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[2];
            half _Split_602db811c686494894895d6489ac1a93_A_4 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[3];
            half4 _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4;
            half3 _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5;
            half2 _Combine_f7a96a985f594d6cae0daad764b71498_RG_6;
            Unity_Combine_half(_Split_602db811c686494894895d6489ac1a93_R_1, _Split_602db811c686494894895d6489ac1a93_G_2, 0, 0, _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4, _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6);
            half2 _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6, half2 (0, 0), _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3);
            UnityTexture2D _Property_6f42653dd834439da6b2995d25abd852_Out_0 = UnityBuildTexture2DStructNoScale(_FlowTex);
            half4 _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6f42653dd834439da6b2995d25abd852_Out_0.tex, _Property_6f42653dd834439da6b2995d25abd852_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_R_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.r;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_G_5 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.g;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_B_6 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.b;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_A_7 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.a;
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_R_1 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[0];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[1];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_B_3 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[2];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_A_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[3];
            half4 _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4;
            half3 _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5;
            half2 _Combine_00997931f0e1429d9a936bab82c990fc_RG_6;
            Unity_Combine_half(_Split_5c07383c9bd542b5bb228ba55a4bf822_R_1, _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2, 0, 0, _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4, _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5, _Combine_00997931f0e1429d9a936bab82c990fc_RG_6);
            half2 _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2;
            Unity_Multiply_half(_Combine_00997931f0e1429d9a936bab82c990fc_RG_6, half2(2, 2), _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2);
            half2 _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2;
            Unity_Subtract_half2(_Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2, half2(1, 1), _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2);
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half2 _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2;
            Unity_Multiply_half(_Subtract_528e92e261ff4ce082329f42aaede8de_Out_2, (_Split_32e455b4db934124814f28147e62dda0_R_1.xx), _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2);
            half _Property_24307526768d44f09f9614d06af9462e_Out_0 = _FlowStrength;
            half2 _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2;
            Unity_Multiply_half(_Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2, (_Property_24307526768d44f09f9614d06af9462e_Out_0.xx), _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2);
            half2 _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2;
            Unity_Add_half2(_TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3, _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half4 _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0 = SAMPLE_TEXTURE2D(_Property_525a14b76350460487a0235960d53ada_Out_0.tex, _Property_525a14b76350460487a0235960d53ada_Out_0.samplerstate, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_R_4 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.r;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_G_5 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.g;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_B_6 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.b;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.a;
            half3 _NormalUnpack_a1ec2fa45e3a4b338f038233d42da4b0_Out_1;
            Unity_NormalUnpack_half(_SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0, _NormalUnpack_a1ec2fa45e3a4b338f038233d42da4b0_Out_1);
            half _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2;
            Unity_Step_half(_Split_32e455b4db934124814f28147e62dda0_R_1, _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7, _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2);
            UnityTexture2D _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0 = UnityBuildTexture2DStructNoScale(_MaskTex);
            half4 _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.tex, _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.r;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_G_5 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.g;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_B_6 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.b;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_A_7 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.a;
            half _Property_d805ba1e888840a1b721ba4757ff7653_Out_0 = _NoiseScale;
            half _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2;
            Unity_SimpleNoise_half(IN.uv0.xy, _Property_d805ba1e888840a1b721ba4757ff7653_Out_0, _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2);
            half _Multiply_2301638808af49f1b094a9bc30731680_Out_2;
            Unity_Multiply_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, 4, _Multiply_2301638808af49f1b094a9bc30731680_Out_2);
            half _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0 = _NoiseContrast;
            half _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3;
            Unity_Smoothstep_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, _Multiply_2301638808af49f1b094a9bc30731680_Out_2, _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0, _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3);
            half _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2;
            Unity_Multiply_half(_Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2);
            half _Property_15657d2187234f36bee94093c3e87cfc_Out_0 = _LenthVar;
            half _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3;
            Unity_Lerp_half(0, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2, _Property_15657d2187234f36bee94093c3e87cfc_Out_0, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3);
            half _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2;
            Unity_Subtract_half(_SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3, _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2);
            half _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1;
            Unity_Saturate_half(_Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1);
            half _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            Unity_Multiply_half(_Step_a0e808c6281d4f1e906e97dc26931de5_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1, _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2);
            half _Property_eb141db1cd544ea2adf973c512527d1f_Out_0 = _ClipThreshold;
            surface.NormalTS = _NormalUnpack_a1ec2fa45e3a4b338f038233d42da4b0_Out_1;
            surface.Alpha = _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            surface.AlphaClipThreshold = _Property_eb141db1cd544ea2adf973c512527d1f_Out_0;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.uv0 =                         input.uv0;
            output.VertexColor =                 input.color;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);



            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);


            output.uv0 =                         input.texCoord0;
            output.VertexColor =                 input.color;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            // Render State
            Cull Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            #define ATTRIBUTES_NEED_COLOR
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_COLOR
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_META
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv0 : TEXCOORD0;
            float4 uv1 : TEXCOORD1;
            float4 uv2 : TEXCOORD2;
            float4 color : COLOR;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float4 texCoord0;
            float4 color;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float4 uv0;
            float4 VertexColor;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float4 uv0;
            float4 VertexColor;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float4 interp0 : TEXCOORD0;
            float4 interp1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyzw =  input.texCoord0;
            output.interp1.xyzw =  input.color;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.interp0.xyzw;
            output.color = input.interp1.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        half4 _Color;
        half _Multiply;
        float4 _MainTex_TexelSize;
        half4 _MainTex_ST;
        half _RimPower;
        float4 _MaskTex_TexelSize;
        float4 _ColorTex_TexelSize;
        half _NoiseScale;
        half _LenthVar;
        half _NoiseContrast;
        half _WindStrength;
        half4 _WindSettings;
        half _ClipThreshold;
        half4 _HairOccCol;
        float4 _FlowTex_TexelSize;
        half _FlowStrength;
        half _DEBUGVERTEXCOLORS_ON;
        CBUFFER_END

        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_MaskTex);
        SAMPLER(sampler_MaskTex);
        TEXTURE2D(_ColorTex);
        SAMPLER(sampler_ColorTex);
        TEXTURE2D(_FlowTex);
        SAMPLER(sampler_FlowTex);

            // Graph Functions
            
        void Unity_Combine_half(half R, half G, half B, half A, out half4 RGBA, out half3 RGB, out half2 RG)
        {
            RGBA = half4(R, G, B, A);
            RGB = half3(R, G, B);
            RG = half2(R, G);
        }

        void Unity_Multiply_half(half A, half B, out half Out)
        {
            Out = A * B;
        }

        void Unity_Add_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A + B;
        }

        void Unity_TilingAndOffset_half(half2 UV, half2 Tiling, half2 Offset, out half2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        half2 Unity_GradientNoise_Dir_half(half2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(half2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_half(half2 UV, half Scale, out half Out)
        { 
            half2 p = UV * Scale;
            half2 ip = floor(p);
            half2 fp = frac(p);
            half d00 = dot(Unity_GradientNoise_Dir_half(ip), fp);
            half d01 = dot(Unity_GradientNoise_Dir_half(ip + half2(0, 1)), fp - half2(0, 1));
            half d10 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 0)), fp - half2(1, 0));
            half d11 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 1)), fp - half2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_half4(half4 A, half4 B, half4 T, out half4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Multiply_half(half2 A, half2 B, out half2 Out)
        {
            Out = A * B;
        }

        void Unity_Subtract_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A - B;
        }

        void Unity_Step_half(half Edge, half In, out half Out)
        {
            Out = step(Edge, In);
        }


        inline half Unity_SimpleNoise_RandomValue_half (half2 uv)
        {
            return frac(sin(dot(uv, half2(12.9898, 78.233)))*43758.5453);
        }

        inline half Unity_SimpleNnoise_Interpolate_half (half a, half b, half t)
        {
            return (1.0-t)*a + (t*b);
        }


        inline half Unity_SimpleNoise_ValueNoise_half (half2 uv)
        {
            half2 i = floor(uv);
            half2 f = frac(uv);
            f = f * f * (3.0 - 2.0 * f);

            uv = abs(frac(uv) - 0.5);
            half2 c0 = i + half2(0.0, 0.0);
            half2 c1 = i + half2(1.0, 0.0);
            half2 c2 = i + half2(0.0, 1.0);
            half2 c3 = i + half2(1.0, 1.0);
            half r0 = Unity_SimpleNoise_RandomValue_half(c0);
            half r1 = Unity_SimpleNoise_RandomValue_half(c1);
            half r2 = Unity_SimpleNoise_RandomValue_half(c2);
            half r3 = Unity_SimpleNoise_RandomValue_half(c3);

            half bottomOfGrid = Unity_SimpleNnoise_Interpolate_half(r0, r1, f.x);
            half topOfGrid = Unity_SimpleNnoise_Interpolate_half(r2, r3, f.x);
            half t = Unity_SimpleNnoise_Interpolate_half(bottomOfGrid, topOfGrid, f.y);
            return t;
        }
        void Unity_SimpleNoise_half(half2 UV, half Scale, out half Out)
        {
            half t = 0.0;

            half freq = pow(2.0, half(0));
            half amp = pow(0.5, half(3-0));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(1));
            amp = pow(0.5, half(3-1));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(2));
            amp = pow(0.5, half(3-2));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            Out = t;
        }

        void Unity_Smoothstep_half(half Edge1, half Edge2, half In, out half Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Lerp_half(half A, half B, half T, out half Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Subtract_half(half A, half B, out half Out)
        {
            Out = A - B;
        }

        void Unity_Saturate_half(half In, out half Out)
        {
            Out = saturate(In);
        }

        void Unity_Multiply_half(half4 A, half4 B, out half4 Out)
        {
            Out = A * B;
        }

        void Unity_Branch_half4(half Predicate, half4 True, half4 False, out half4 Out)
        {
            Out = Predicate ? True : False;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            half3 Normal;
            half3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            half4 _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0 = _WindSettings;
            half _Split_bb70b739a797490d880162edc7afee6f_R_1 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[0];
            half _Split_bb70b739a797490d880162edc7afee6f_G_2 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[1];
            half _Split_bb70b739a797490d880162edc7afee6f_B_3 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[2];
            half _Split_bb70b739a797490d880162edc7afee6f_A_4 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[3];
            half4 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4;
            half3 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5;
            half2 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6;
            Unity_Combine_half(_Split_bb70b739a797490d880162edc7afee6f_R_1, _Split_bb70b739a797490d880162edc7afee6f_G_2, 0, 0, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6);
            half2 _Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0 = half2(_Split_bb70b739a797490d880162edc7afee6f_B_3, _Split_bb70b739a797490d880162edc7afee6f_A_4);
            half _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_B_3, IN.TimeParameters.x, _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2);
            half _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_A_4, IN.TimeParameters.x, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2);
            half4 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4;
            half3 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5;
            half2 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6;
            Unity_Combine_half(_Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2, 0, 0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6);
            half2 _Add_090b4851a1384ca09f399033bea33b52_Out_2;
            Unity_Add_half2(_Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2);
            half2 _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2, _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3);
            half _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2;
            Unity_GradientNoise_half(_TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3, 16, _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2);
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2;
            Unity_Multiply_half(_GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_80222ead6749415082b7f9c461e2b035_Out_2);
            half _Property_00bf319b767845e7851dfff509e4690f_Out_0 = _WindStrength;
            half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
            Unity_Multiply_half(_Multiply_80222ead6749415082b7f9c461e2b035_Out_2, _Property_00bf319b767845e7851dfff509e4690f_Out_0, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2);
            half _Multiply_6235c90d381c4045880e54b9359ca466_Out_2;
            Unity_Multiply_half(0.05, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2, _Multiply_6235c90d381c4045880e54b9359ca466_Out_2);
            float3 _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            Unity_Add_float3((_Multiply_6235c90d381c4045880e54b9359ca466_Out_2.xxx), IN.ObjectSpacePosition, _Add_49510769758a45d69ae0fdcacecba70d_Out_2);
            description.Position = _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            half3 BaseColor;
            half3 Emission;
            half Alpha;
            half AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            half4 _Property_2228b5aed348428da10b9296f9ebc494_Out_0 = _Color;
            half _Property_38318a489f9a4408a735e7c400d44b9a_Out_0 = _DEBUGVERTEXCOLORS_ON;
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half4 _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0 = _HairOccCol;
            half4 _Lerp_266d46ff80174903a133109b2f8086e1_Out_3;
            Unity_Lerp_half4(_Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0, half4(1, 1, 1, 1), (_Split_32e455b4db934124814f28147e62dda0_R_1.xxxx), _Lerp_266d46ff80174903a133109b2f8086e1_Out_3);
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_R_1 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[0];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_G_2 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[1];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_B_3 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[2];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_A_4 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[3];
            half4 _Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3;
            Unity_Lerp_half4(half4(1, 1, 1, 1), _Lerp_266d46ff80174903a133109b2f8086e1_Out_3, (_Split_9b0b84b2dbbd49d3b86865c028aa1936_A_4.xxxx), _Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3);
            UnityTexture2D _Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0 = UnityBuildTexture2DStructNoScale(_ColorTex);
            half4 _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0 = _WindSettings;
            half _Split_bb70b739a797490d880162edc7afee6f_R_1 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[0];
            half _Split_bb70b739a797490d880162edc7afee6f_G_2 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[1];
            half _Split_bb70b739a797490d880162edc7afee6f_B_3 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[2];
            half _Split_bb70b739a797490d880162edc7afee6f_A_4 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[3];
            half4 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4;
            half3 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5;
            half2 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6;
            Unity_Combine_half(_Split_bb70b739a797490d880162edc7afee6f_R_1, _Split_bb70b739a797490d880162edc7afee6f_G_2, 0, 0, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6);
            half2 _Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0 = half2(_Split_bb70b739a797490d880162edc7afee6f_B_3, _Split_bb70b739a797490d880162edc7afee6f_A_4);
            half _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_B_3, IN.TimeParameters.x, _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2);
            half _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_A_4, IN.TimeParameters.x, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2);
            half4 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4;
            half3 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5;
            half2 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6;
            Unity_Combine_half(_Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2, 0, 0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6);
            half2 _Add_090b4851a1384ca09f399033bea33b52_Out_2;
            Unity_Add_half2(_Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2);
            half2 _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2, _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3);
            half _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2;
            Unity_GradientNoise_half(_TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3, 16, _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2);
            half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2;
            Unity_Multiply_half(_GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_80222ead6749415082b7f9c461e2b035_Out_2);
            half _Property_00bf319b767845e7851dfff509e4690f_Out_0 = _WindStrength;
            half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
            Unity_Multiply_half(_Multiply_80222ead6749415082b7f9c461e2b035_Out_2, _Property_00bf319b767845e7851dfff509e4690f_Out_0, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2);
            half4 _Property_7104b0921e324793aecf6f4aef29ed10_Out_0 = _MainTex_ST;
            half _Split_602db811c686494894895d6489ac1a93_R_1 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[0];
            half _Split_602db811c686494894895d6489ac1a93_G_2 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[1];
            half _Split_602db811c686494894895d6489ac1a93_B_3 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[2];
            half _Split_602db811c686494894895d6489ac1a93_A_4 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[3];
            half4 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGBA_4;
            half3 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGB_5;
            half2 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6;
            Unity_Combine_half(_Split_602db811c686494894895d6489ac1a93_B_3, _Split_602db811c686494894895d6489ac1a93_A_4, 0, 0, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGBA_4, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGB_5, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6);
            half2 _Add_5ecadbcbe14847e18d526011c7679f8c_Out_2;
            Unity_Add_half2((_Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2.xx), _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6, _Add_5ecadbcbe14847e18d526011c7679f8c_Out_2);
            UnityTexture2D _Property_525a14b76350460487a0235960d53ada_Out_0 = UnityBuildTexture2DStructNoScale(_MainTex);
            half4 _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4;
            half3 _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5;
            half2 _Combine_f7a96a985f594d6cae0daad764b71498_RG_6;
            Unity_Combine_half(_Split_602db811c686494894895d6489ac1a93_R_1, _Split_602db811c686494894895d6489ac1a93_G_2, 0, 0, _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4, _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6);
            half2 _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6, half2 (0, 0), _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3);
            UnityTexture2D _Property_6f42653dd834439da6b2995d25abd852_Out_0 = UnityBuildTexture2DStructNoScale(_FlowTex);
            half4 _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6f42653dd834439da6b2995d25abd852_Out_0.tex, _Property_6f42653dd834439da6b2995d25abd852_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_R_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.r;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_G_5 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.g;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_B_6 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.b;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_A_7 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.a;
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_R_1 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[0];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[1];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_B_3 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[2];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_A_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[3];
            half4 _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4;
            half3 _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5;
            half2 _Combine_00997931f0e1429d9a936bab82c990fc_RG_6;
            Unity_Combine_half(_Split_5c07383c9bd542b5bb228ba55a4bf822_R_1, _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2, 0, 0, _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4, _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5, _Combine_00997931f0e1429d9a936bab82c990fc_RG_6);
            half2 _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2;
            Unity_Multiply_half(_Combine_00997931f0e1429d9a936bab82c990fc_RG_6, half2(2, 2), _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2);
            half2 _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2;
            Unity_Subtract_half2(_Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2, half2(1, 1), _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2);
            half2 _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2;
            Unity_Multiply_half(_Subtract_528e92e261ff4ce082329f42aaede8de_Out_2, (_Split_32e455b4db934124814f28147e62dda0_R_1.xx), _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2);
            half _Property_24307526768d44f09f9614d06af9462e_Out_0 = _FlowStrength;
            half2 _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2;
            Unity_Multiply_half(_Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2, (_Property_24307526768d44f09f9614d06af9462e_Out_0.xx), _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2);
            half2 _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2;
            Unity_Add_half2(_TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3, _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half4 _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0 = SAMPLE_TEXTURE2D(_Property_525a14b76350460487a0235960d53ada_Out_0.tex, _Property_525a14b76350460487a0235960d53ada_Out_0.samplerstate, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_R_4 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.r;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_G_5 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.g;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_B_6 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.b;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.a;
            half _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2;
            Unity_Step_half(_Split_32e455b4db934124814f28147e62dda0_R_1, _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7, _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2);
            UnityTexture2D _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0 = UnityBuildTexture2DStructNoScale(_MaskTex);
            half4 _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.tex, _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.r;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_G_5 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.g;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_B_6 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.b;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_A_7 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.a;
            half _Property_d805ba1e888840a1b721ba4757ff7653_Out_0 = _NoiseScale;
            half _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2;
            Unity_SimpleNoise_half(IN.uv0.xy, _Property_d805ba1e888840a1b721ba4757ff7653_Out_0, _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2);
            half _Multiply_2301638808af49f1b094a9bc30731680_Out_2;
            Unity_Multiply_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, 4, _Multiply_2301638808af49f1b094a9bc30731680_Out_2);
            half _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0 = _NoiseContrast;
            half _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3;
            Unity_Smoothstep_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, _Multiply_2301638808af49f1b094a9bc30731680_Out_2, _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0, _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3);
            half _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2;
            Unity_Multiply_half(_Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2);
            half _Property_15657d2187234f36bee94093c3e87cfc_Out_0 = _LenthVar;
            half _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3;
            Unity_Lerp_half(0, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2, _Property_15657d2187234f36bee94093c3e87cfc_Out_0, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3);
            half _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2;
            Unity_Subtract_half(_SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3, _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2);
            half _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1;
            Unity_Saturate_half(_Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1);
            half _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            Unity_Multiply_half(_Step_a0e808c6281d4f1e906e97dc26931de5_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1, _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2);
            half2 _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2;
            Unity_Multiply_half(_Add_5ecadbcbe14847e18d526011c7679f8c_Out_2, (_Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2.xx), _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2);
            half2 _Multiply_9a843867bc00497ebdabd88255642899_Out_2;
            Unity_Multiply_half(half2(0.1, 0.1), _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2, _Multiply_9a843867bc00497ebdabd88255642899_Out_2);
            half2 _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, half2 (1, 1), _Multiply_9a843867bc00497ebdabd88255642899_Out_2, _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3);
            half4 _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0 = SAMPLE_TEXTURE2D(_Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0.tex, _Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0.samplerstate, _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3);
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_R_4 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.r;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_G_5 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.g;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_B_6 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.b;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_A_7 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.a;
            half4 _Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2;
            Unity_Multiply_half(_Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3, _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0, _Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2);
            half _Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2;
            Unity_Multiply_half(_SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7, 1, _Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2);
            half4 _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2;
            Unity_Multiply_half(_Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2, (_Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2.xxxx), _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2);
            half4 _Branch_1de247f9645e44088172ca18ab7005fc_Out_3;
            Unity_Branch_half4(_Property_38318a489f9a4408a735e7c400d44b9a_Out_0, (_Split_32e455b4db934124814f28147e62dda0_R_1.xxxx), _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2, _Branch_1de247f9645e44088172ca18ab7005fc_Out_3);
            half4 _Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2;
            Unity_Multiply_half(_Property_2228b5aed348428da10b9296f9ebc494_Out_0, _Branch_1de247f9645e44088172ca18ab7005fc_Out_3, _Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2);
            half _Property_eb141db1cd544ea2adf973c512527d1f_Out_0 = _ClipThreshold;
            surface.BaseColor = (_Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2.xyz);
            surface.Emission = half3(0, 0, 0);
            surface.Alpha = _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            surface.AlphaClipThreshold = _Property_eb141db1cd544ea2adf973c512527d1f_Out_0;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.uv0 =                         input.uv0;
            output.VertexColor =                 input.color;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





            output.uv0 =                         input.texCoord0;
            output.VertexColor =                 input.color;
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            // Name: <None>
            Tags
            {
                "LightMode" = "Universal2D"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_COLOR
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_COLOR
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_2D
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv0 : TEXCOORD0;
            float4 color : COLOR;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float4 texCoord0;
            float4 color;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float4 uv0;
            float4 VertexColor;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float4 uv0;
            float4 VertexColor;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float4 interp0 : TEXCOORD0;
            float4 interp1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyzw =  input.texCoord0;
            output.interp1.xyzw =  input.color;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.interp0.xyzw;
            output.color = input.interp1.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        half4 _Color;
        half _Multiply;
        float4 _MainTex_TexelSize;
        half4 _MainTex_ST;
        half _RimPower;
        float4 _MaskTex_TexelSize;
        float4 _ColorTex_TexelSize;
        half _NoiseScale;
        half _LenthVar;
        half _NoiseContrast;
        half _WindStrength;
        half4 _WindSettings;
        half _ClipThreshold;
        half4 _HairOccCol;
        float4 _FlowTex_TexelSize;
        half _FlowStrength;
        half _DEBUGVERTEXCOLORS_ON;
        CBUFFER_END

        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_MaskTex);
        SAMPLER(sampler_MaskTex);
        TEXTURE2D(_ColorTex);
        SAMPLER(sampler_ColorTex);
        TEXTURE2D(_FlowTex);
        SAMPLER(sampler_FlowTex);

            // Graph Functions
            
        void Unity_Combine_half(half R, half G, half B, half A, out half4 RGBA, out half3 RGB, out half2 RG)
        {
            RGBA = half4(R, G, B, A);
            RGB = half3(R, G, B);
            RG = half2(R, G);
        }

        void Unity_Multiply_half(half A, half B, out half Out)
        {
            Out = A * B;
        }

        void Unity_Add_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A + B;
        }

        void Unity_TilingAndOffset_half(half2 UV, half2 Tiling, half2 Offset, out half2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        half2 Unity_GradientNoise_Dir_half(half2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(half2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_half(half2 UV, half Scale, out half Out)
        { 
            half2 p = UV * Scale;
            half2 ip = floor(p);
            half2 fp = frac(p);
            half d00 = dot(Unity_GradientNoise_Dir_half(ip), fp);
            half d01 = dot(Unity_GradientNoise_Dir_half(ip + half2(0, 1)), fp - half2(0, 1));
            half d10 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 0)), fp - half2(1, 0));
            half d11 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 1)), fp - half2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_half4(half4 A, half4 B, half4 T, out half4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Multiply_half(half2 A, half2 B, out half2 Out)
        {
            Out = A * B;
        }

        void Unity_Subtract_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A - B;
        }

        void Unity_Step_half(half Edge, half In, out half Out)
        {
            Out = step(Edge, In);
        }


        inline half Unity_SimpleNoise_RandomValue_half (half2 uv)
        {
            return frac(sin(dot(uv, half2(12.9898, 78.233)))*43758.5453);
        }

        inline half Unity_SimpleNnoise_Interpolate_half (half a, half b, half t)
        {
            return (1.0-t)*a + (t*b);
        }


        inline half Unity_SimpleNoise_ValueNoise_half (half2 uv)
        {
            half2 i = floor(uv);
            half2 f = frac(uv);
            f = f * f * (3.0 - 2.0 * f);

            uv = abs(frac(uv) - 0.5);
            half2 c0 = i + half2(0.0, 0.0);
            half2 c1 = i + half2(1.0, 0.0);
            half2 c2 = i + half2(0.0, 1.0);
            half2 c3 = i + half2(1.0, 1.0);
            half r0 = Unity_SimpleNoise_RandomValue_half(c0);
            half r1 = Unity_SimpleNoise_RandomValue_half(c1);
            half r2 = Unity_SimpleNoise_RandomValue_half(c2);
            half r3 = Unity_SimpleNoise_RandomValue_half(c3);

            half bottomOfGrid = Unity_SimpleNnoise_Interpolate_half(r0, r1, f.x);
            half topOfGrid = Unity_SimpleNnoise_Interpolate_half(r2, r3, f.x);
            half t = Unity_SimpleNnoise_Interpolate_half(bottomOfGrid, topOfGrid, f.y);
            return t;
        }
        void Unity_SimpleNoise_half(half2 UV, half Scale, out half Out)
        {
            half t = 0.0;

            half freq = pow(2.0, half(0));
            half amp = pow(0.5, half(3-0));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(1));
            amp = pow(0.5, half(3-1));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(2));
            amp = pow(0.5, half(3-2));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            Out = t;
        }

        void Unity_Smoothstep_half(half Edge1, half Edge2, half In, out half Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Lerp_half(half A, half B, half T, out half Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Subtract_half(half A, half B, out half Out)
        {
            Out = A - B;
        }

        void Unity_Saturate_half(half In, out half Out)
        {
            Out = saturate(In);
        }

        void Unity_Multiply_half(half4 A, half4 B, out half4 Out)
        {
            Out = A * B;
        }

        void Unity_Branch_half4(half Predicate, half4 True, half4 False, out half4 Out)
        {
            Out = Predicate ? True : False;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            half3 Normal;
            half3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            half4 _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0 = _WindSettings;
            half _Split_bb70b739a797490d880162edc7afee6f_R_1 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[0];
            half _Split_bb70b739a797490d880162edc7afee6f_G_2 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[1];
            half _Split_bb70b739a797490d880162edc7afee6f_B_3 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[2];
            half _Split_bb70b739a797490d880162edc7afee6f_A_4 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[3];
            half4 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4;
            half3 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5;
            half2 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6;
            Unity_Combine_half(_Split_bb70b739a797490d880162edc7afee6f_R_1, _Split_bb70b739a797490d880162edc7afee6f_G_2, 0, 0, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6);
            half2 _Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0 = half2(_Split_bb70b739a797490d880162edc7afee6f_B_3, _Split_bb70b739a797490d880162edc7afee6f_A_4);
            half _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_B_3, IN.TimeParameters.x, _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2);
            half _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_A_4, IN.TimeParameters.x, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2);
            half4 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4;
            half3 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5;
            half2 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6;
            Unity_Combine_half(_Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2, 0, 0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6);
            half2 _Add_090b4851a1384ca09f399033bea33b52_Out_2;
            Unity_Add_half2(_Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2);
            half2 _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2, _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3);
            half _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2;
            Unity_GradientNoise_half(_TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3, 16, _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2);
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2;
            Unity_Multiply_half(_GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_80222ead6749415082b7f9c461e2b035_Out_2);
            half _Property_00bf319b767845e7851dfff509e4690f_Out_0 = _WindStrength;
            half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
            Unity_Multiply_half(_Multiply_80222ead6749415082b7f9c461e2b035_Out_2, _Property_00bf319b767845e7851dfff509e4690f_Out_0, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2);
            half _Multiply_6235c90d381c4045880e54b9359ca466_Out_2;
            Unity_Multiply_half(0.05, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2, _Multiply_6235c90d381c4045880e54b9359ca466_Out_2);
            float3 _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            Unity_Add_float3((_Multiply_6235c90d381c4045880e54b9359ca466_Out_2.xxx), IN.ObjectSpacePosition, _Add_49510769758a45d69ae0fdcacecba70d_Out_2);
            description.Position = _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            half3 BaseColor;
            half Alpha;
            half AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            half4 _Property_2228b5aed348428da10b9296f9ebc494_Out_0 = _Color;
            half _Property_38318a489f9a4408a735e7c400d44b9a_Out_0 = _DEBUGVERTEXCOLORS_ON;
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half4 _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0 = _HairOccCol;
            half4 _Lerp_266d46ff80174903a133109b2f8086e1_Out_3;
            Unity_Lerp_half4(_Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0, half4(1, 1, 1, 1), (_Split_32e455b4db934124814f28147e62dda0_R_1.xxxx), _Lerp_266d46ff80174903a133109b2f8086e1_Out_3);
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_R_1 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[0];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_G_2 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[1];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_B_3 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[2];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_A_4 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[3];
            half4 _Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3;
            Unity_Lerp_half4(half4(1, 1, 1, 1), _Lerp_266d46ff80174903a133109b2f8086e1_Out_3, (_Split_9b0b84b2dbbd49d3b86865c028aa1936_A_4.xxxx), _Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3);
            UnityTexture2D _Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0 = UnityBuildTexture2DStructNoScale(_ColorTex);
            half4 _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0 = _WindSettings;
            half _Split_bb70b739a797490d880162edc7afee6f_R_1 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[0];
            half _Split_bb70b739a797490d880162edc7afee6f_G_2 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[1];
            half _Split_bb70b739a797490d880162edc7afee6f_B_3 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[2];
            half _Split_bb70b739a797490d880162edc7afee6f_A_4 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[3];
            half4 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4;
            half3 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5;
            half2 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6;
            Unity_Combine_half(_Split_bb70b739a797490d880162edc7afee6f_R_1, _Split_bb70b739a797490d880162edc7afee6f_G_2, 0, 0, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6);
            half2 _Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0 = half2(_Split_bb70b739a797490d880162edc7afee6f_B_3, _Split_bb70b739a797490d880162edc7afee6f_A_4);
            half _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_B_3, IN.TimeParameters.x, _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2);
            half _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_A_4, IN.TimeParameters.x, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2);
            half4 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4;
            half3 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5;
            half2 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6;
            Unity_Combine_half(_Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2, 0, 0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6);
            half2 _Add_090b4851a1384ca09f399033bea33b52_Out_2;
            Unity_Add_half2(_Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2);
            half2 _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2, _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3);
            half _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2;
            Unity_GradientNoise_half(_TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3, 16, _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2);
            half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2;
            Unity_Multiply_half(_GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_80222ead6749415082b7f9c461e2b035_Out_2);
            half _Property_00bf319b767845e7851dfff509e4690f_Out_0 = _WindStrength;
            half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
            Unity_Multiply_half(_Multiply_80222ead6749415082b7f9c461e2b035_Out_2, _Property_00bf319b767845e7851dfff509e4690f_Out_0, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2);
            half4 _Property_7104b0921e324793aecf6f4aef29ed10_Out_0 = _MainTex_ST;
            half _Split_602db811c686494894895d6489ac1a93_R_1 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[0];
            half _Split_602db811c686494894895d6489ac1a93_G_2 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[1];
            half _Split_602db811c686494894895d6489ac1a93_B_3 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[2];
            half _Split_602db811c686494894895d6489ac1a93_A_4 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[3];
            half4 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGBA_4;
            half3 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGB_5;
            half2 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6;
            Unity_Combine_half(_Split_602db811c686494894895d6489ac1a93_B_3, _Split_602db811c686494894895d6489ac1a93_A_4, 0, 0, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGBA_4, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGB_5, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6);
            half2 _Add_5ecadbcbe14847e18d526011c7679f8c_Out_2;
            Unity_Add_half2((_Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2.xx), _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6, _Add_5ecadbcbe14847e18d526011c7679f8c_Out_2);
            UnityTexture2D _Property_525a14b76350460487a0235960d53ada_Out_0 = UnityBuildTexture2DStructNoScale(_MainTex);
            half4 _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4;
            half3 _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5;
            half2 _Combine_f7a96a985f594d6cae0daad764b71498_RG_6;
            Unity_Combine_half(_Split_602db811c686494894895d6489ac1a93_R_1, _Split_602db811c686494894895d6489ac1a93_G_2, 0, 0, _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4, _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6);
            half2 _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6, half2 (0, 0), _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3);
            UnityTexture2D _Property_6f42653dd834439da6b2995d25abd852_Out_0 = UnityBuildTexture2DStructNoScale(_FlowTex);
            half4 _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6f42653dd834439da6b2995d25abd852_Out_0.tex, _Property_6f42653dd834439da6b2995d25abd852_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_R_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.r;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_G_5 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.g;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_B_6 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.b;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_A_7 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.a;
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_R_1 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[0];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[1];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_B_3 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[2];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_A_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[3];
            half4 _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4;
            half3 _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5;
            half2 _Combine_00997931f0e1429d9a936bab82c990fc_RG_6;
            Unity_Combine_half(_Split_5c07383c9bd542b5bb228ba55a4bf822_R_1, _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2, 0, 0, _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4, _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5, _Combine_00997931f0e1429d9a936bab82c990fc_RG_6);
            half2 _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2;
            Unity_Multiply_half(_Combine_00997931f0e1429d9a936bab82c990fc_RG_6, half2(2, 2), _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2);
            half2 _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2;
            Unity_Subtract_half2(_Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2, half2(1, 1), _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2);
            half2 _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2;
            Unity_Multiply_half(_Subtract_528e92e261ff4ce082329f42aaede8de_Out_2, (_Split_32e455b4db934124814f28147e62dda0_R_1.xx), _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2);
            half _Property_24307526768d44f09f9614d06af9462e_Out_0 = _FlowStrength;
            half2 _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2;
            Unity_Multiply_half(_Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2, (_Property_24307526768d44f09f9614d06af9462e_Out_0.xx), _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2);
            half2 _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2;
            Unity_Add_half2(_TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3, _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half4 _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0 = SAMPLE_TEXTURE2D(_Property_525a14b76350460487a0235960d53ada_Out_0.tex, _Property_525a14b76350460487a0235960d53ada_Out_0.samplerstate, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_R_4 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.r;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_G_5 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.g;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_B_6 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.b;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.a;
            half _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2;
            Unity_Step_half(_Split_32e455b4db934124814f28147e62dda0_R_1, _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7, _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2);
            UnityTexture2D _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0 = UnityBuildTexture2DStructNoScale(_MaskTex);
            half4 _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.tex, _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.r;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_G_5 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.g;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_B_6 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.b;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_A_7 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.a;
            half _Property_d805ba1e888840a1b721ba4757ff7653_Out_0 = _NoiseScale;
            half _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2;
            Unity_SimpleNoise_half(IN.uv0.xy, _Property_d805ba1e888840a1b721ba4757ff7653_Out_0, _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2);
            half _Multiply_2301638808af49f1b094a9bc30731680_Out_2;
            Unity_Multiply_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, 4, _Multiply_2301638808af49f1b094a9bc30731680_Out_2);
            half _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0 = _NoiseContrast;
            half _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3;
            Unity_Smoothstep_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, _Multiply_2301638808af49f1b094a9bc30731680_Out_2, _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0, _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3);
            half _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2;
            Unity_Multiply_half(_Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2);
            half _Property_15657d2187234f36bee94093c3e87cfc_Out_0 = _LenthVar;
            half _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3;
            Unity_Lerp_half(0, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2, _Property_15657d2187234f36bee94093c3e87cfc_Out_0, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3);
            half _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2;
            Unity_Subtract_half(_SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3, _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2);
            half _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1;
            Unity_Saturate_half(_Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1);
            half _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            Unity_Multiply_half(_Step_a0e808c6281d4f1e906e97dc26931de5_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1, _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2);
            half2 _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2;
            Unity_Multiply_half(_Add_5ecadbcbe14847e18d526011c7679f8c_Out_2, (_Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2.xx), _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2);
            half2 _Multiply_9a843867bc00497ebdabd88255642899_Out_2;
            Unity_Multiply_half(half2(0.1, 0.1), _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2, _Multiply_9a843867bc00497ebdabd88255642899_Out_2);
            half2 _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, half2 (1, 1), _Multiply_9a843867bc00497ebdabd88255642899_Out_2, _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3);
            half4 _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0 = SAMPLE_TEXTURE2D(_Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0.tex, _Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0.samplerstate, _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3);
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_R_4 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.r;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_G_5 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.g;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_B_6 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.b;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_A_7 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.a;
            half4 _Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2;
            Unity_Multiply_half(_Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3, _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0, _Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2);
            half _Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2;
            Unity_Multiply_half(_SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7, 1, _Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2);
            half4 _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2;
            Unity_Multiply_half(_Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2, (_Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2.xxxx), _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2);
            half4 _Branch_1de247f9645e44088172ca18ab7005fc_Out_3;
            Unity_Branch_half4(_Property_38318a489f9a4408a735e7c400d44b9a_Out_0, (_Split_32e455b4db934124814f28147e62dda0_R_1.xxxx), _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2, _Branch_1de247f9645e44088172ca18ab7005fc_Out_3);
            half4 _Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2;
            Unity_Multiply_half(_Property_2228b5aed348428da10b9296f9ebc494_Out_0, _Branch_1de247f9645e44088172ca18ab7005fc_Out_3, _Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2);
            half _Property_eb141db1cd544ea2adf973c512527d1f_Out_0 = _ClipThreshold;
            surface.BaseColor = (_Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2.xyz);
            surface.Alpha = _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            surface.AlphaClipThreshold = _Property_eb141db1cd544ea2adf973c512527d1f_Out_0;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.uv0 =                         input.uv0;
            output.VertexColor =                 input.color;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





            output.uv0 =                         input.texCoord0;
            output.VertexColor =                 input.color;
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"

            ENDHLSL
        }
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "UniversalMaterialType" = "Lit"
            "Queue"="AlphaTest"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_COLOR
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_COLOR
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_FORWARD
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv0 : TEXCOORD0;
            float4 uv1 : TEXCOORD1;
            float4 color : COLOR;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float4 texCoord0;
            float4 color;
            float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            float2 lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 sh;
            #endif
            float4 fogFactorAndVertexLight;
            float4 shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 TangentSpaceNormal;
            float4 uv0;
            float4 VertexColor;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float4 uv0;
            float4 VertexColor;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float4 interp3 : TEXCOORD3;
            float4 interp4 : TEXCOORD4;
            float3 interp5 : TEXCOORD5;
            #if defined(LIGHTMAP_ON)
            float2 interp6 : TEXCOORD6;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 interp7 : TEXCOORD7;
            #endif
            float4 interp8 : TEXCOORD8;
            float4 interp9 : TEXCOORD9;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyzw =  input.texCoord0;
            output.interp4.xyzw =  input.color;
            output.interp5.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp6.xy =  input.lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp7.xyz =  input.sh;
            #endif
            output.interp8.xyzw =  input.fogFactorAndVertexLight;
            output.interp9.xyzw =  input.shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.texCoord0 = input.interp3.xyzw;
            output.color = input.interp4.xyzw;
            output.viewDirectionWS = input.interp5.xyz;
            #if defined(LIGHTMAP_ON)
            output.lightmapUV = input.interp6.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp7.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp8.xyzw;
            output.shadowCoord = input.interp9.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        half4 _Color;
        half _Multiply;
        float4 _MainTex_TexelSize;
        half4 _MainTex_ST;
        half _RimPower;
        float4 _MaskTex_TexelSize;
        float4 _ColorTex_TexelSize;
        half _NoiseScale;
        half _LenthVar;
        half _NoiseContrast;
        half _WindStrength;
        half4 _WindSettings;
        half _ClipThreshold;
        half4 _HairOccCol;
        float4 _FlowTex_TexelSize;
        half _FlowStrength;
        half _DEBUGVERTEXCOLORS_ON;
        CBUFFER_END

        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_MaskTex);
        SAMPLER(sampler_MaskTex);
        TEXTURE2D(_ColorTex);
        SAMPLER(sampler_ColorTex);
        TEXTURE2D(_FlowTex);
        SAMPLER(sampler_FlowTex);

            // Graph Functions
            
        void Unity_Combine_half(half R, half G, half B, half A, out half4 RGBA, out half3 RGB, out half2 RG)
        {
            RGBA = half4(R, G, B, A);
            RGB = half3(R, G, B);
            RG = half2(R, G);
        }

        void Unity_Multiply_half(half A, half B, out half Out)
        {
            Out = A * B;
        }

        void Unity_Add_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A + B;
        }

        void Unity_TilingAndOffset_half(half2 UV, half2 Tiling, half2 Offset, out half2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        half2 Unity_GradientNoise_Dir_half(half2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(half2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_half(half2 UV, half Scale, out half Out)
        { 
            half2 p = UV * Scale;
            half2 ip = floor(p);
            half2 fp = frac(p);
            half d00 = dot(Unity_GradientNoise_Dir_half(ip), fp);
            half d01 = dot(Unity_GradientNoise_Dir_half(ip + half2(0, 1)), fp - half2(0, 1));
            half d10 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 0)), fp - half2(1, 0));
            half d11 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 1)), fp - half2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_half4(half4 A, half4 B, half4 T, out half4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Multiply_half(half2 A, half2 B, out half2 Out)
        {
            Out = A * B;
        }

        void Unity_Subtract_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A - B;
        }

        void Unity_Step_half(half Edge, half In, out half Out)
        {
            Out = step(Edge, In);
        }


        inline half Unity_SimpleNoise_RandomValue_half (half2 uv)
        {
            return frac(sin(dot(uv, half2(12.9898, 78.233)))*43758.5453);
        }

        inline half Unity_SimpleNnoise_Interpolate_half (half a, half b, half t)
        {
            return (1.0-t)*a + (t*b);
        }


        inline half Unity_SimpleNoise_ValueNoise_half (half2 uv)
        {
            half2 i = floor(uv);
            half2 f = frac(uv);
            f = f * f * (3.0 - 2.0 * f);

            uv = abs(frac(uv) - 0.5);
            half2 c0 = i + half2(0.0, 0.0);
            half2 c1 = i + half2(1.0, 0.0);
            half2 c2 = i + half2(0.0, 1.0);
            half2 c3 = i + half2(1.0, 1.0);
            half r0 = Unity_SimpleNoise_RandomValue_half(c0);
            half r1 = Unity_SimpleNoise_RandomValue_half(c1);
            half r2 = Unity_SimpleNoise_RandomValue_half(c2);
            half r3 = Unity_SimpleNoise_RandomValue_half(c3);

            half bottomOfGrid = Unity_SimpleNnoise_Interpolate_half(r0, r1, f.x);
            half topOfGrid = Unity_SimpleNnoise_Interpolate_half(r2, r3, f.x);
            half t = Unity_SimpleNnoise_Interpolate_half(bottomOfGrid, topOfGrid, f.y);
            return t;
        }
        void Unity_SimpleNoise_half(half2 UV, half Scale, out half Out)
        {
            half t = 0.0;

            half freq = pow(2.0, half(0));
            half amp = pow(0.5, half(3-0));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(1));
            amp = pow(0.5, half(3-1));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(2));
            amp = pow(0.5, half(3-2));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            Out = t;
        }

        void Unity_Smoothstep_half(half Edge1, half Edge2, half In, out half Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Lerp_half(half A, half B, half T, out half Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Subtract_half(half A, half B, out half Out)
        {
            Out = A - B;
        }

        void Unity_Saturate_half(half In, out half Out)
        {
            Out = saturate(In);
        }

        void Unity_Multiply_half(half4 A, half4 B, out half4 Out)
        {
            Out = A * B;
        }

        void Unity_Branch_half4(half Predicate, half4 True, half4 False, out half4 Out)
        {
            Out = Predicate ? True : False;
        }

        void Unity_NormalUnpack_half(half4 In, out half3 Out)
        {
                        Out = UnpackNormal(In);
                    }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            half3 Normal;
            half3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            half4 _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0 = _WindSettings;
            half _Split_bb70b739a797490d880162edc7afee6f_R_1 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[0];
            half _Split_bb70b739a797490d880162edc7afee6f_G_2 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[1];
            half _Split_bb70b739a797490d880162edc7afee6f_B_3 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[2];
            half _Split_bb70b739a797490d880162edc7afee6f_A_4 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[3];
            half4 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4;
            half3 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5;
            half2 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6;
            Unity_Combine_half(_Split_bb70b739a797490d880162edc7afee6f_R_1, _Split_bb70b739a797490d880162edc7afee6f_G_2, 0, 0, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6);
            half2 _Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0 = half2(_Split_bb70b739a797490d880162edc7afee6f_B_3, _Split_bb70b739a797490d880162edc7afee6f_A_4);
            half _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_B_3, IN.TimeParameters.x, _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2);
            half _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_A_4, IN.TimeParameters.x, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2);
            half4 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4;
            half3 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5;
            half2 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6;
            Unity_Combine_half(_Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2, 0, 0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6);
            half2 _Add_090b4851a1384ca09f399033bea33b52_Out_2;
            Unity_Add_half2(_Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2);
            half2 _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2, _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3);
            half _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2;
            Unity_GradientNoise_half(_TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3, 16, _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2);
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2;
            Unity_Multiply_half(_GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_80222ead6749415082b7f9c461e2b035_Out_2);
            half _Property_00bf319b767845e7851dfff509e4690f_Out_0 = _WindStrength;
            half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
            Unity_Multiply_half(_Multiply_80222ead6749415082b7f9c461e2b035_Out_2, _Property_00bf319b767845e7851dfff509e4690f_Out_0, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2);
            half _Multiply_6235c90d381c4045880e54b9359ca466_Out_2;
            Unity_Multiply_half(0.05, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2, _Multiply_6235c90d381c4045880e54b9359ca466_Out_2);
            float3 _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            Unity_Add_float3((_Multiply_6235c90d381c4045880e54b9359ca466_Out_2.xxx), IN.ObjectSpacePosition, _Add_49510769758a45d69ae0fdcacecba70d_Out_2);
            description.Position = _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            half3 BaseColor;
            half3 NormalTS;
            half3 Emission;
            half Metallic;
            half Smoothness;
            half Occlusion;
            half Alpha;
            half AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            half4 _Property_2228b5aed348428da10b9296f9ebc494_Out_0 = _Color;
            half _Property_38318a489f9a4408a735e7c400d44b9a_Out_0 = _DEBUGVERTEXCOLORS_ON;
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half4 _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0 = _HairOccCol;
            half4 _Lerp_266d46ff80174903a133109b2f8086e1_Out_3;
            Unity_Lerp_half4(_Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0, half4(1, 1, 1, 1), (_Split_32e455b4db934124814f28147e62dda0_R_1.xxxx), _Lerp_266d46ff80174903a133109b2f8086e1_Out_3);
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_R_1 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[0];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_G_2 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[1];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_B_3 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[2];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_A_4 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[3];
            half4 _Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3;
            Unity_Lerp_half4(half4(1, 1, 1, 1), _Lerp_266d46ff80174903a133109b2f8086e1_Out_3, (_Split_9b0b84b2dbbd49d3b86865c028aa1936_A_4.xxxx), _Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3);
            UnityTexture2D _Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0 = UnityBuildTexture2DStructNoScale(_ColorTex);
            half4 _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0 = _WindSettings;
            half _Split_bb70b739a797490d880162edc7afee6f_R_1 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[0];
            half _Split_bb70b739a797490d880162edc7afee6f_G_2 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[1];
            half _Split_bb70b739a797490d880162edc7afee6f_B_3 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[2];
            half _Split_bb70b739a797490d880162edc7afee6f_A_4 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[3];
            half4 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4;
            half3 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5;
            half2 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6;
            Unity_Combine_half(_Split_bb70b739a797490d880162edc7afee6f_R_1, _Split_bb70b739a797490d880162edc7afee6f_G_2, 0, 0, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6);
            half2 _Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0 = half2(_Split_bb70b739a797490d880162edc7afee6f_B_3, _Split_bb70b739a797490d880162edc7afee6f_A_4);
            half _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_B_3, IN.TimeParameters.x, _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2);
            half _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_A_4, IN.TimeParameters.x, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2);
            half4 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4;
            half3 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5;
            half2 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6;
            Unity_Combine_half(_Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2, 0, 0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6);
            half2 _Add_090b4851a1384ca09f399033bea33b52_Out_2;
            Unity_Add_half2(_Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2);
            half2 _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2, _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3);
            half _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2;
            Unity_GradientNoise_half(_TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3, 16, _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2);
            half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2;
            Unity_Multiply_half(_GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_80222ead6749415082b7f9c461e2b035_Out_2);
            half _Property_00bf319b767845e7851dfff509e4690f_Out_0 = _WindStrength;
            half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
            Unity_Multiply_half(_Multiply_80222ead6749415082b7f9c461e2b035_Out_2, _Property_00bf319b767845e7851dfff509e4690f_Out_0, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2);
            half4 _Property_7104b0921e324793aecf6f4aef29ed10_Out_0 = _MainTex_ST;
            half _Split_602db811c686494894895d6489ac1a93_R_1 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[0];
            half _Split_602db811c686494894895d6489ac1a93_G_2 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[1];
            half _Split_602db811c686494894895d6489ac1a93_B_3 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[2];
            half _Split_602db811c686494894895d6489ac1a93_A_4 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[3];
            half4 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGBA_4;
            half3 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGB_5;
            half2 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6;
            Unity_Combine_half(_Split_602db811c686494894895d6489ac1a93_B_3, _Split_602db811c686494894895d6489ac1a93_A_4, 0, 0, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGBA_4, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGB_5, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6);
            half2 _Add_5ecadbcbe14847e18d526011c7679f8c_Out_2;
            Unity_Add_half2((_Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2.xx), _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6, _Add_5ecadbcbe14847e18d526011c7679f8c_Out_2);
            UnityTexture2D _Property_525a14b76350460487a0235960d53ada_Out_0 = UnityBuildTexture2DStructNoScale(_MainTex);
            half4 _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4;
            half3 _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5;
            half2 _Combine_f7a96a985f594d6cae0daad764b71498_RG_6;
            Unity_Combine_half(_Split_602db811c686494894895d6489ac1a93_R_1, _Split_602db811c686494894895d6489ac1a93_G_2, 0, 0, _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4, _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6);
            half2 _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6, half2 (0, 0), _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3);
            UnityTexture2D _Property_6f42653dd834439da6b2995d25abd852_Out_0 = UnityBuildTexture2DStructNoScale(_FlowTex);
            half4 _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6f42653dd834439da6b2995d25abd852_Out_0.tex, _Property_6f42653dd834439da6b2995d25abd852_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_R_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.r;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_G_5 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.g;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_B_6 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.b;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_A_7 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.a;
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_R_1 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[0];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[1];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_B_3 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[2];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_A_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[3];
            half4 _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4;
            half3 _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5;
            half2 _Combine_00997931f0e1429d9a936bab82c990fc_RG_6;
            Unity_Combine_half(_Split_5c07383c9bd542b5bb228ba55a4bf822_R_1, _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2, 0, 0, _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4, _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5, _Combine_00997931f0e1429d9a936bab82c990fc_RG_6);
            half2 _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2;
            Unity_Multiply_half(_Combine_00997931f0e1429d9a936bab82c990fc_RG_6, half2(2, 2), _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2);
            half2 _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2;
            Unity_Subtract_half2(_Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2, half2(1, 1), _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2);
            half2 _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2;
            Unity_Multiply_half(_Subtract_528e92e261ff4ce082329f42aaede8de_Out_2, (_Split_32e455b4db934124814f28147e62dda0_R_1.xx), _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2);
            half _Property_24307526768d44f09f9614d06af9462e_Out_0 = _FlowStrength;
            half2 _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2;
            Unity_Multiply_half(_Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2, (_Property_24307526768d44f09f9614d06af9462e_Out_0.xx), _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2);
            half2 _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2;
            Unity_Add_half2(_TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3, _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half4 _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0 = SAMPLE_TEXTURE2D(_Property_525a14b76350460487a0235960d53ada_Out_0.tex, _Property_525a14b76350460487a0235960d53ada_Out_0.samplerstate, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_R_4 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.r;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_G_5 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.g;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_B_6 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.b;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.a;
            half _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2;
            Unity_Step_half(_Split_32e455b4db934124814f28147e62dda0_R_1, _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7, _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2);
            UnityTexture2D _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0 = UnityBuildTexture2DStructNoScale(_MaskTex);
            half4 _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.tex, _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.r;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_G_5 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.g;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_B_6 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.b;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_A_7 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.a;
            half _Property_d805ba1e888840a1b721ba4757ff7653_Out_0 = _NoiseScale;
            half _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2;
            Unity_SimpleNoise_half(IN.uv0.xy, _Property_d805ba1e888840a1b721ba4757ff7653_Out_0, _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2);
            half _Multiply_2301638808af49f1b094a9bc30731680_Out_2;
            Unity_Multiply_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, 4, _Multiply_2301638808af49f1b094a9bc30731680_Out_2);
            half _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0 = _NoiseContrast;
            half _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3;
            Unity_Smoothstep_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, _Multiply_2301638808af49f1b094a9bc30731680_Out_2, _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0, _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3);
            half _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2;
            Unity_Multiply_half(_Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2);
            half _Property_15657d2187234f36bee94093c3e87cfc_Out_0 = _LenthVar;
            half _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3;
            Unity_Lerp_half(0, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2, _Property_15657d2187234f36bee94093c3e87cfc_Out_0, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3);
            half _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2;
            Unity_Subtract_half(_SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3, _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2);
            half _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1;
            Unity_Saturate_half(_Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1);
            half _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            Unity_Multiply_half(_Step_a0e808c6281d4f1e906e97dc26931de5_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1, _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2);
            half2 _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2;
            Unity_Multiply_half(_Add_5ecadbcbe14847e18d526011c7679f8c_Out_2, (_Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2.xx), _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2);
            half2 _Multiply_9a843867bc00497ebdabd88255642899_Out_2;
            Unity_Multiply_half(half2(0.1, 0.1), _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2, _Multiply_9a843867bc00497ebdabd88255642899_Out_2);
            half2 _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, half2 (1, 1), _Multiply_9a843867bc00497ebdabd88255642899_Out_2, _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3);
            half4 _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0 = SAMPLE_TEXTURE2D(_Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0.tex, _Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0.samplerstate, _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3);
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_R_4 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.r;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_G_5 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.g;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_B_6 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.b;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_A_7 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.a;
            half4 _Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2;
            Unity_Multiply_half(_Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3, _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0, _Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2);
            half _Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2;
            Unity_Multiply_half(_SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7, 1, _Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2);
            half4 _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2;
            Unity_Multiply_half(_Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2, (_Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2.xxxx), _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2);
            half4 _Branch_1de247f9645e44088172ca18ab7005fc_Out_3;
            Unity_Branch_half4(_Property_38318a489f9a4408a735e7c400d44b9a_Out_0, (_Split_32e455b4db934124814f28147e62dda0_R_1.xxxx), _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2, _Branch_1de247f9645e44088172ca18ab7005fc_Out_3);
            half4 _Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2;
            Unity_Multiply_half(_Property_2228b5aed348428da10b9296f9ebc494_Out_0, _Branch_1de247f9645e44088172ca18ab7005fc_Out_3, _Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2);
            half3 _NormalUnpack_a1ec2fa45e3a4b338f038233d42da4b0_Out_1;
            Unity_NormalUnpack_half(_SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0, _NormalUnpack_a1ec2fa45e3a4b338f038233d42da4b0_Out_1);
            half _Property_eb141db1cd544ea2adf973c512527d1f_Out_0 = _ClipThreshold;
            surface.BaseColor = (_Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2.xyz);
            surface.NormalTS = _NormalUnpack_a1ec2fa45e3a4b338f038233d42da4b0_Out_1;
            surface.Emission = half3(0, 0, 0);
            surface.Metallic = 0;
            surface.Smoothness = 0;
            surface.Occlusion = 1;
            surface.Alpha = _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            surface.AlphaClipThreshold = _Property_eb141db1cd544ea2adf973c512527d1f_Out_0;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.uv0 =                         input.uv0;
            output.VertexColor =                 input.color;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);



            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);


            output.uv0 =                         input.texCoord0;
            output.VertexColor =                 input.color;
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_COLOR
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_COLOR
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_SHADOWCASTER
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv0 : TEXCOORD0;
            float4 color : COLOR;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float4 texCoord0;
            float4 color;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float4 uv0;
            float4 VertexColor;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float4 uv0;
            float4 VertexColor;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float4 interp0 : TEXCOORD0;
            float4 interp1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyzw =  input.texCoord0;
            output.interp1.xyzw =  input.color;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.interp0.xyzw;
            output.color = input.interp1.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        half4 _Color;
        half _Multiply;
        float4 _MainTex_TexelSize;
        half4 _MainTex_ST;
        half _RimPower;
        float4 _MaskTex_TexelSize;
        float4 _ColorTex_TexelSize;
        half _NoiseScale;
        half _LenthVar;
        half _NoiseContrast;
        half _WindStrength;
        half4 _WindSettings;
        half _ClipThreshold;
        half4 _HairOccCol;
        float4 _FlowTex_TexelSize;
        half _FlowStrength;
        half _DEBUGVERTEXCOLORS_ON;
        CBUFFER_END

        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_MaskTex);
        SAMPLER(sampler_MaskTex);
        TEXTURE2D(_ColorTex);
        SAMPLER(sampler_ColorTex);
        TEXTURE2D(_FlowTex);
        SAMPLER(sampler_FlowTex);

            // Graph Functions
            
        void Unity_Combine_half(half R, half G, half B, half A, out half4 RGBA, out half3 RGB, out half2 RG)
        {
            RGBA = half4(R, G, B, A);
            RGB = half3(R, G, B);
            RG = half2(R, G);
        }

        void Unity_Multiply_half(half A, half B, out half Out)
        {
            Out = A * B;
        }

        void Unity_Add_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A + B;
        }

        void Unity_TilingAndOffset_half(half2 UV, half2 Tiling, half2 Offset, out half2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        half2 Unity_GradientNoise_Dir_half(half2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(half2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_half(half2 UV, half Scale, out half Out)
        { 
            half2 p = UV * Scale;
            half2 ip = floor(p);
            half2 fp = frac(p);
            half d00 = dot(Unity_GradientNoise_Dir_half(ip), fp);
            half d01 = dot(Unity_GradientNoise_Dir_half(ip + half2(0, 1)), fp - half2(0, 1));
            half d10 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 0)), fp - half2(1, 0));
            half d11 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 1)), fp - half2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Multiply_half(half2 A, half2 B, out half2 Out)
        {
            Out = A * B;
        }

        void Unity_Subtract_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A - B;
        }

        void Unity_Step_half(half Edge, half In, out half Out)
        {
            Out = step(Edge, In);
        }


        inline half Unity_SimpleNoise_RandomValue_half (half2 uv)
        {
            return frac(sin(dot(uv, half2(12.9898, 78.233)))*43758.5453);
        }

        inline half Unity_SimpleNnoise_Interpolate_half (half a, half b, half t)
        {
            return (1.0-t)*a + (t*b);
        }


        inline half Unity_SimpleNoise_ValueNoise_half (half2 uv)
        {
            half2 i = floor(uv);
            half2 f = frac(uv);
            f = f * f * (3.0 - 2.0 * f);

            uv = abs(frac(uv) - 0.5);
            half2 c0 = i + half2(0.0, 0.0);
            half2 c1 = i + half2(1.0, 0.0);
            half2 c2 = i + half2(0.0, 1.0);
            half2 c3 = i + half2(1.0, 1.0);
            half r0 = Unity_SimpleNoise_RandomValue_half(c0);
            half r1 = Unity_SimpleNoise_RandomValue_half(c1);
            half r2 = Unity_SimpleNoise_RandomValue_half(c2);
            half r3 = Unity_SimpleNoise_RandomValue_half(c3);

            half bottomOfGrid = Unity_SimpleNnoise_Interpolate_half(r0, r1, f.x);
            half topOfGrid = Unity_SimpleNnoise_Interpolate_half(r2, r3, f.x);
            half t = Unity_SimpleNnoise_Interpolate_half(bottomOfGrid, topOfGrid, f.y);
            return t;
        }
        void Unity_SimpleNoise_half(half2 UV, half Scale, out half Out)
        {
            half t = 0.0;

            half freq = pow(2.0, half(0));
            half amp = pow(0.5, half(3-0));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(1));
            amp = pow(0.5, half(3-1));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(2));
            amp = pow(0.5, half(3-2));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            Out = t;
        }

        void Unity_Smoothstep_half(half Edge1, half Edge2, half In, out half Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Lerp_half(half A, half B, half T, out half Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Subtract_half(half A, half B, out half Out)
        {
            Out = A - B;
        }

        void Unity_Saturate_half(half In, out half Out)
        {
            Out = saturate(In);
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            half3 Normal;
            half3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            half4 _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0 = _WindSettings;
            half _Split_bb70b739a797490d880162edc7afee6f_R_1 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[0];
            half _Split_bb70b739a797490d880162edc7afee6f_G_2 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[1];
            half _Split_bb70b739a797490d880162edc7afee6f_B_3 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[2];
            half _Split_bb70b739a797490d880162edc7afee6f_A_4 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[3];
            half4 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4;
            half3 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5;
            half2 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6;
            Unity_Combine_half(_Split_bb70b739a797490d880162edc7afee6f_R_1, _Split_bb70b739a797490d880162edc7afee6f_G_2, 0, 0, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6);
            half2 _Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0 = half2(_Split_bb70b739a797490d880162edc7afee6f_B_3, _Split_bb70b739a797490d880162edc7afee6f_A_4);
            half _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_B_3, IN.TimeParameters.x, _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2);
            half _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_A_4, IN.TimeParameters.x, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2);
            half4 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4;
            half3 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5;
            half2 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6;
            Unity_Combine_half(_Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2, 0, 0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6);
            half2 _Add_090b4851a1384ca09f399033bea33b52_Out_2;
            Unity_Add_half2(_Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2);
            half2 _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2, _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3);
            half _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2;
            Unity_GradientNoise_half(_TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3, 16, _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2);
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2;
            Unity_Multiply_half(_GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_80222ead6749415082b7f9c461e2b035_Out_2);
            half _Property_00bf319b767845e7851dfff509e4690f_Out_0 = _WindStrength;
            half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
            Unity_Multiply_half(_Multiply_80222ead6749415082b7f9c461e2b035_Out_2, _Property_00bf319b767845e7851dfff509e4690f_Out_0, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2);
            half _Multiply_6235c90d381c4045880e54b9359ca466_Out_2;
            Unity_Multiply_half(0.05, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2, _Multiply_6235c90d381c4045880e54b9359ca466_Out_2);
            float3 _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            Unity_Add_float3((_Multiply_6235c90d381c4045880e54b9359ca466_Out_2.xxx), IN.ObjectSpacePosition, _Add_49510769758a45d69ae0fdcacecba70d_Out_2);
            description.Position = _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            half Alpha;
            half AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            UnityTexture2D _Property_525a14b76350460487a0235960d53ada_Out_0 = UnityBuildTexture2DStructNoScale(_MainTex);
            half4 _Property_7104b0921e324793aecf6f4aef29ed10_Out_0 = _MainTex_ST;
            half _Split_602db811c686494894895d6489ac1a93_R_1 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[0];
            half _Split_602db811c686494894895d6489ac1a93_G_2 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[1];
            half _Split_602db811c686494894895d6489ac1a93_B_3 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[2];
            half _Split_602db811c686494894895d6489ac1a93_A_4 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[3];
            half4 _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4;
            half3 _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5;
            half2 _Combine_f7a96a985f594d6cae0daad764b71498_RG_6;
            Unity_Combine_half(_Split_602db811c686494894895d6489ac1a93_R_1, _Split_602db811c686494894895d6489ac1a93_G_2, 0, 0, _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4, _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6);
            half2 _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6, half2 (0, 0), _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3);
            UnityTexture2D _Property_6f42653dd834439da6b2995d25abd852_Out_0 = UnityBuildTexture2DStructNoScale(_FlowTex);
            half4 _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6f42653dd834439da6b2995d25abd852_Out_0.tex, _Property_6f42653dd834439da6b2995d25abd852_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_R_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.r;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_G_5 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.g;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_B_6 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.b;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_A_7 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.a;
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_R_1 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[0];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[1];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_B_3 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[2];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_A_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[3];
            half4 _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4;
            half3 _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5;
            half2 _Combine_00997931f0e1429d9a936bab82c990fc_RG_6;
            Unity_Combine_half(_Split_5c07383c9bd542b5bb228ba55a4bf822_R_1, _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2, 0, 0, _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4, _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5, _Combine_00997931f0e1429d9a936bab82c990fc_RG_6);
            half2 _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2;
            Unity_Multiply_half(_Combine_00997931f0e1429d9a936bab82c990fc_RG_6, half2(2, 2), _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2);
            half2 _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2;
            Unity_Subtract_half2(_Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2, half2(1, 1), _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2);
            half2 _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2;
            Unity_Multiply_half(_Subtract_528e92e261ff4ce082329f42aaede8de_Out_2, (_Split_32e455b4db934124814f28147e62dda0_R_1.xx), _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2);
            half _Property_24307526768d44f09f9614d06af9462e_Out_0 = _FlowStrength;
            half2 _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2;
            Unity_Multiply_half(_Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2, (_Property_24307526768d44f09f9614d06af9462e_Out_0.xx), _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2);
            half2 _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2;
            Unity_Add_half2(_TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3, _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half4 _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0 = SAMPLE_TEXTURE2D(_Property_525a14b76350460487a0235960d53ada_Out_0.tex, _Property_525a14b76350460487a0235960d53ada_Out_0.samplerstate, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_R_4 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.r;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_G_5 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.g;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_B_6 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.b;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.a;
            half _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2;
            Unity_Step_half(_Split_32e455b4db934124814f28147e62dda0_R_1, _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7, _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2);
            UnityTexture2D _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0 = UnityBuildTexture2DStructNoScale(_MaskTex);
            half4 _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.tex, _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.r;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_G_5 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.g;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_B_6 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.b;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_A_7 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.a;
            half _Property_d805ba1e888840a1b721ba4757ff7653_Out_0 = _NoiseScale;
            half _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2;
            Unity_SimpleNoise_half(IN.uv0.xy, _Property_d805ba1e888840a1b721ba4757ff7653_Out_0, _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2);
            half _Multiply_2301638808af49f1b094a9bc30731680_Out_2;
            Unity_Multiply_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, 4, _Multiply_2301638808af49f1b094a9bc30731680_Out_2);
            half _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0 = _NoiseContrast;
            half _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3;
            Unity_Smoothstep_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, _Multiply_2301638808af49f1b094a9bc30731680_Out_2, _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0, _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3);
            half _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2;
            Unity_Multiply_half(_Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2);
            half _Property_15657d2187234f36bee94093c3e87cfc_Out_0 = _LenthVar;
            half _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3;
            Unity_Lerp_half(0, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2, _Property_15657d2187234f36bee94093c3e87cfc_Out_0, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3);
            half _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2;
            Unity_Subtract_half(_SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3, _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2);
            half _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1;
            Unity_Saturate_half(_Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1);
            half _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            Unity_Multiply_half(_Step_a0e808c6281d4f1e906e97dc26931de5_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1, _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2);
            half _Property_eb141db1cd544ea2adf973c512527d1f_Out_0 = _ClipThreshold;
            surface.Alpha = _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            surface.AlphaClipThreshold = _Property_eb141db1cd544ea2adf973c512527d1f_Out_0;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.uv0 =                         input.uv0;
            output.VertexColor =                 input.color;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





            output.uv0 =                         input.texCoord0;
            output.VertexColor =                 input.color;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_COLOR
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_COLOR
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHONLY
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv0 : TEXCOORD0;
            float4 color : COLOR;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float4 texCoord0;
            float4 color;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float4 uv0;
            float4 VertexColor;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float4 uv0;
            float4 VertexColor;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float4 interp0 : TEXCOORD0;
            float4 interp1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyzw =  input.texCoord0;
            output.interp1.xyzw =  input.color;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.interp0.xyzw;
            output.color = input.interp1.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        half4 _Color;
        half _Multiply;
        float4 _MainTex_TexelSize;
        half4 _MainTex_ST;
        half _RimPower;
        float4 _MaskTex_TexelSize;
        float4 _ColorTex_TexelSize;
        half _NoiseScale;
        half _LenthVar;
        half _NoiseContrast;
        half _WindStrength;
        half4 _WindSettings;
        half _ClipThreshold;
        half4 _HairOccCol;
        float4 _FlowTex_TexelSize;
        half _FlowStrength;
        half _DEBUGVERTEXCOLORS_ON;
        CBUFFER_END

        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_MaskTex);
        SAMPLER(sampler_MaskTex);
        TEXTURE2D(_ColorTex);
        SAMPLER(sampler_ColorTex);
        TEXTURE2D(_FlowTex);
        SAMPLER(sampler_FlowTex);

            // Graph Functions
            
        void Unity_Combine_half(half R, half G, half B, half A, out half4 RGBA, out half3 RGB, out half2 RG)
        {
            RGBA = half4(R, G, B, A);
            RGB = half3(R, G, B);
            RG = half2(R, G);
        }

        void Unity_Multiply_half(half A, half B, out half Out)
        {
            Out = A * B;
        }

        void Unity_Add_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A + B;
        }

        void Unity_TilingAndOffset_half(half2 UV, half2 Tiling, half2 Offset, out half2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        half2 Unity_GradientNoise_Dir_half(half2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(half2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_half(half2 UV, half Scale, out half Out)
        { 
            half2 p = UV * Scale;
            half2 ip = floor(p);
            half2 fp = frac(p);
            half d00 = dot(Unity_GradientNoise_Dir_half(ip), fp);
            half d01 = dot(Unity_GradientNoise_Dir_half(ip + half2(0, 1)), fp - half2(0, 1));
            half d10 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 0)), fp - half2(1, 0));
            half d11 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 1)), fp - half2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Multiply_half(half2 A, half2 B, out half2 Out)
        {
            Out = A * B;
        }

        void Unity_Subtract_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A - B;
        }

        void Unity_Step_half(half Edge, half In, out half Out)
        {
            Out = step(Edge, In);
        }


        inline half Unity_SimpleNoise_RandomValue_half (half2 uv)
        {
            return frac(sin(dot(uv, half2(12.9898, 78.233)))*43758.5453);
        }

        inline half Unity_SimpleNnoise_Interpolate_half (half a, half b, half t)
        {
            return (1.0-t)*a + (t*b);
        }


        inline half Unity_SimpleNoise_ValueNoise_half (half2 uv)
        {
            half2 i = floor(uv);
            half2 f = frac(uv);
            f = f * f * (3.0 - 2.0 * f);

            uv = abs(frac(uv) - 0.5);
            half2 c0 = i + half2(0.0, 0.0);
            half2 c1 = i + half2(1.0, 0.0);
            half2 c2 = i + half2(0.0, 1.0);
            half2 c3 = i + half2(1.0, 1.0);
            half r0 = Unity_SimpleNoise_RandomValue_half(c0);
            half r1 = Unity_SimpleNoise_RandomValue_half(c1);
            half r2 = Unity_SimpleNoise_RandomValue_half(c2);
            half r3 = Unity_SimpleNoise_RandomValue_half(c3);

            half bottomOfGrid = Unity_SimpleNnoise_Interpolate_half(r0, r1, f.x);
            half topOfGrid = Unity_SimpleNnoise_Interpolate_half(r2, r3, f.x);
            half t = Unity_SimpleNnoise_Interpolate_half(bottomOfGrid, topOfGrid, f.y);
            return t;
        }
        void Unity_SimpleNoise_half(half2 UV, half Scale, out half Out)
        {
            half t = 0.0;

            half freq = pow(2.0, half(0));
            half amp = pow(0.5, half(3-0));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(1));
            amp = pow(0.5, half(3-1));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(2));
            amp = pow(0.5, half(3-2));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            Out = t;
        }

        void Unity_Smoothstep_half(half Edge1, half Edge2, half In, out half Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Lerp_half(half A, half B, half T, out half Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Subtract_half(half A, half B, out half Out)
        {
            Out = A - B;
        }

        void Unity_Saturate_half(half In, out half Out)
        {
            Out = saturate(In);
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            half3 Normal;
            half3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            half4 _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0 = _WindSettings;
            half _Split_bb70b739a797490d880162edc7afee6f_R_1 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[0];
            half _Split_bb70b739a797490d880162edc7afee6f_G_2 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[1];
            half _Split_bb70b739a797490d880162edc7afee6f_B_3 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[2];
            half _Split_bb70b739a797490d880162edc7afee6f_A_4 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[3];
            half4 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4;
            half3 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5;
            half2 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6;
            Unity_Combine_half(_Split_bb70b739a797490d880162edc7afee6f_R_1, _Split_bb70b739a797490d880162edc7afee6f_G_2, 0, 0, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6);
            half2 _Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0 = half2(_Split_bb70b739a797490d880162edc7afee6f_B_3, _Split_bb70b739a797490d880162edc7afee6f_A_4);
            half _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_B_3, IN.TimeParameters.x, _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2);
            half _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_A_4, IN.TimeParameters.x, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2);
            half4 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4;
            half3 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5;
            half2 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6;
            Unity_Combine_half(_Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2, 0, 0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6);
            half2 _Add_090b4851a1384ca09f399033bea33b52_Out_2;
            Unity_Add_half2(_Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2);
            half2 _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2, _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3);
            half _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2;
            Unity_GradientNoise_half(_TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3, 16, _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2);
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2;
            Unity_Multiply_half(_GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_80222ead6749415082b7f9c461e2b035_Out_2);
            half _Property_00bf319b767845e7851dfff509e4690f_Out_0 = _WindStrength;
            half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
            Unity_Multiply_half(_Multiply_80222ead6749415082b7f9c461e2b035_Out_2, _Property_00bf319b767845e7851dfff509e4690f_Out_0, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2);
            half _Multiply_6235c90d381c4045880e54b9359ca466_Out_2;
            Unity_Multiply_half(0.05, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2, _Multiply_6235c90d381c4045880e54b9359ca466_Out_2);
            float3 _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            Unity_Add_float3((_Multiply_6235c90d381c4045880e54b9359ca466_Out_2.xxx), IN.ObjectSpacePosition, _Add_49510769758a45d69ae0fdcacecba70d_Out_2);
            description.Position = _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            half Alpha;
            half AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            UnityTexture2D _Property_525a14b76350460487a0235960d53ada_Out_0 = UnityBuildTexture2DStructNoScale(_MainTex);
            half4 _Property_7104b0921e324793aecf6f4aef29ed10_Out_0 = _MainTex_ST;
            half _Split_602db811c686494894895d6489ac1a93_R_1 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[0];
            half _Split_602db811c686494894895d6489ac1a93_G_2 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[1];
            half _Split_602db811c686494894895d6489ac1a93_B_3 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[2];
            half _Split_602db811c686494894895d6489ac1a93_A_4 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[3];
            half4 _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4;
            half3 _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5;
            half2 _Combine_f7a96a985f594d6cae0daad764b71498_RG_6;
            Unity_Combine_half(_Split_602db811c686494894895d6489ac1a93_R_1, _Split_602db811c686494894895d6489ac1a93_G_2, 0, 0, _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4, _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6);
            half2 _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6, half2 (0, 0), _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3);
            UnityTexture2D _Property_6f42653dd834439da6b2995d25abd852_Out_0 = UnityBuildTexture2DStructNoScale(_FlowTex);
            half4 _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6f42653dd834439da6b2995d25abd852_Out_0.tex, _Property_6f42653dd834439da6b2995d25abd852_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_R_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.r;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_G_5 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.g;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_B_6 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.b;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_A_7 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.a;
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_R_1 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[0];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[1];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_B_3 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[2];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_A_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[3];
            half4 _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4;
            half3 _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5;
            half2 _Combine_00997931f0e1429d9a936bab82c990fc_RG_6;
            Unity_Combine_half(_Split_5c07383c9bd542b5bb228ba55a4bf822_R_1, _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2, 0, 0, _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4, _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5, _Combine_00997931f0e1429d9a936bab82c990fc_RG_6);
            half2 _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2;
            Unity_Multiply_half(_Combine_00997931f0e1429d9a936bab82c990fc_RG_6, half2(2, 2), _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2);
            half2 _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2;
            Unity_Subtract_half2(_Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2, half2(1, 1), _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2);
            half2 _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2;
            Unity_Multiply_half(_Subtract_528e92e261ff4ce082329f42aaede8de_Out_2, (_Split_32e455b4db934124814f28147e62dda0_R_1.xx), _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2);
            half _Property_24307526768d44f09f9614d06af9462e_Out_0 = _FlowStrength;
            half2 _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2;
            Unity_Multiply_half(_Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2, (_Property_24307526768d44f09f9614d06af9462e_Out_0.xx), _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2);
            half2 _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2;
            Unity_Add_half2(_TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3, _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half4 _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0 = SAMPLE_TEXTURE2D(_Property_525a14b76350460487a0235960d53ada_Out_0.tex, _Property_525a14b76350460487a0235960d53ada_Out_0.samplerstate, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_R_4 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.r;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_G_5 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.g;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_B_6 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.b;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.a;
            half _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2;
            Unity_Step_half(_Split_32e455b4db934124814f28147e62dda0_R_1, _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7, _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2);
            UnityTexture2D _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0 = UnityBuildTexture2DStructNoScale(_MaskTex);
            half4 _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.tex, _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.r;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_G_5 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.g;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_B_6 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.b;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_A_7 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.a;
            half _Property_d805ba1e888840a1b721ba4757ff7653_Out_0 = _NoiseScale;
            half _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2;
            Unity_SimpleNoise_half(IN.uv0.xy, _Property_d805ba1e888840a1b721ba4757ff7653_Out_0, _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2);
            half _Multiply_2301638808af49f1b094a9bc30731680_Out_2;
            Unity_Multiply_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, 4, _Multiply_2301638808af49f1b094a9bc30731680_Out_2);
            half _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0 = _NoiseContrast;
            half _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3;
            Unity_Smoothstep_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, _Multiply_2301638808af49f1b094a9bc30731680_Out_2, _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0, _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3);
            half _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2;
            Unity_Multiply_half(_Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2);
            half _Property_15657d2187234f36bee94093c3e87cfc_Out_0 = _LenthVar;
            half _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3;
            Unity_Lerp_half(0, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2, _Property_15657d2187234f36bee94093c3e87cfc_Out_0, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3);
            half _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2;
            Unity_Subtract_half(_SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3, _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2);
            half _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1;
            Unity_Saturate_half(_Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1);
            half _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            Unity_Multiply_half(_Step_a0e808c6281d4f1e906e97dc26931de5_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1, _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2);
            half _Property_eb141db1cd544ea2adf973c512527d1f_Out_0 = _ClipThreshold;
            surface.Alpha = _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            surface.AlphaClipThreshold = _Property_eb141db1cd544ea2adf973c512527d1f_Out_0;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.uv0 =                         input.uv0;
            output.VertexColor =                 input.color;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





            output.uv0 =                         input.texCoord0;
            output.VertexColor =                 input.color;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_COLOR
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_COLOR
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv0 : TEXCOORD0;
            float4 uv1 : TEXCOORD1;
            float4 color : COLOR;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 normalWS;
            float4 tangentWS;
            float4 texCoord0;
            float4 color;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 TangentSpaceNormal;
            float4 uv0;
            float4 VertexColor;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float4 uv0;
            float4 VertexColor;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float4 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float4 interp3 : TEXCOORD3;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.normalWS;
            output.interp1.xyzw =  input.tangentWS;
            output.interp2.xyzw =  input.texCoord0;
            output.interp3.xyzw =  input.color;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.normalWS = input.interp0.xyz;
            output.tangentWS = input.interp1.xyzw;
            output.texCoord0 = input.interp2.xyzw;
            output.color = input.interp3.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        half4 _Color;
        half _Multiply;
        float4 _MainTex_TexelSize;
        half4 _MainTex_ST;
        half _RimPower;
        float4 _MaskTex_TexelSize;
        float4 _ColorTex_TexelSize;
        half _NoiseScale;
        half _LenthVar;
        half _NoiseContrast;
        half _WindStrength;
        half4 _WindSettings;
        half _ClipThreshold;
        half4 _HairOccCol;
        float4 _FlowTex_TexelSize;
        half _FlowStrength;
        half _DEBUGVERTEXCOLORS_ON;
        CBUFFER_END

        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_MaskTex);
        SAMPLER(sampler_MaskTex);
        TEXTURE2D(_ColorTex);
        SAMPLER(sampler_ColorTex);
        TEXTURE2D(_FlowTex);
        SAMPLER(sampler_FlowTex);

            // Graph Functions
            
        void Unity_Combine_half(half R, half G, half B, half A, out half4 RGBA, out half3 RGB, out half2 RG)
        {
            RGBA = half4(R, G, B, A);
            RGB = half3(R, G, B);
            RG = half2(R, G);
        }

        void Unity_Multiply_half(half A, half B, out half Out)
        {
            Out = A * B;
        }

        void Unity_Add_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A + B;
        }

        void Unity_TilingAndOffset_half(half2 UV, half2 Tiling, half2 Offset, out half2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        half2 Unity_GradientNoise_Dir_half(half2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(half2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_half(half2 UV, half Scale, out half Out)
        { 
            half2 p = UV * Scale;
            half2 ip = floor(p);
            half2 fp = frac(p);
            half d00 = dot(Unity_GradientNoise_Dir_half(ip), fp);
            half d01 = dot(Unity_GradientNoise_Dir_half(ip + half2(0, 1)), fp - half2(0, 1));
            half d10 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 0)), fp - half2(1, 0));
            half d11 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 1)), fp - half2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Multiply_half(half2 A, half2 B, out half2 Out)
        {
            Out = A * B;
        }

        void Unity_Subtract_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A - B;
        }

        void Unity_NormalUnpack_half(half4 In, out half3 Out)
        {
                        Out = UnpackNormal(In);
                    }

        void Unity_Step_half(half Edge, half In, out half Out)
        {
            Out = step(Edge, In);
        }


        inline half Unity_SimpleNoise_RandomValue_half (half2 uv)
        {
            return frac(sin(dot(uv, half2(12.9898, 78.233)))*43758.5453);
        }

        inline half Unity_SimpleNnoise_Interpolate_half (half a, half b, half t)
        {
            return (1.0-t)*a + (t*b);
        }


        inline half Unity_SimpleNoise_ValueNoise_half (half2 uv)
        {
            half2 i = floor(uv);
            half2 f = frac(uv);
            f = f * f * (3.0 - 2.0 * f);

            uv = abs(frac(uv) - 0.5);
            half2 c0 = i + half2(0.0, 0.0);
            half2 c1 = i + half2(1.0, 0.0);
            half2 c2 = i + half2(0.0, 1.0);
            half2 c3 = i + half2(1.0, 1.0);
            half r0 = Unity_SimpleNoise_RandomValue_half(c0);
            half r1 = Unity_SimpleNoise_RandomValue_half(c1);
            half r2 = Unity_SimpleNoise_RandomValue_half(c2);
            half r3 = Unity_SimpleNoise_RandomValue_half(c3);

            half bottomOfGrid = Unity_SimpleNnoise_Interpolate_half(r0, r1, f.x);
            half topOfGrid = Unity_SimpleNnoise_Interpolate_half(r2, r3, f.x);
            half t = Unity_SimpleNnoise_Interpolate_half(bottomOfGrid, topOfGrid, f.y);
            return t;
        }
        void Unity_SimpleNoise_half(half2 UV, half Scale, out half Out)
        {
            half t = 0.0;

            half freq = pow(2.0, half(0));
            half amp = pow(0.5, half(3-0));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(1));
            amp = pow(0.5, half(3-1));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(2));
            amp = pow(0.5, half(3-2));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            Out = t;
        }

        void Unity_Smoothstep_half(half Edge1, half Edge2, half In, out half Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Lerp_half(half A, half B, half T, out half Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Subtract_half(half A, half B, out half Out)
        {
            Out = A - B;
        }

        void Unity_Saturate_half(half In, out half Out)
        {
            Out = saturate(In);
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            half3 Normal;
            half3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            half4 _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0 = _WindSettings;
            half _Split_bb70b739a797490d880162edc7afee6f_R_1 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[0];
            half _Split_bb70b739a797490d880162edc7afee6f_G_2 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[1];
            half _Split_bb70b739a797490d880162edc7afee6f_B_3 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[2];
            half _Split_bb70b739a797490d880162edc7afee6f_A_4 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[3];
            half4 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4;
            half3 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5;
            half2 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6;
            Unity_Combine_half(_Split_bb70b739a797490d880162edc7afee6f_R_1, _Split_bb70b739a797490d880162edc7afee6f_G_2, 0, 0, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6);
            half2 _Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0 = half2(_Split_bb70b739a797490d880162edc7afee6f_B_3, _Split_bb70b739a797490d880162edc7afee6f_A_4);
            half _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_B_3, IN.TimeParameters.x, _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2);
            half _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_A_4, IN.TimeParameters.x, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2);
            half4 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4;
            half3 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5;
            half2 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6;
            Unity_Combine_half(_Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2, 0, 0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6);
            half2 _Add_090b4851a1384ca09f399033bea33b52_Out_2;
            Unity_Add_half2(_Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2);
            half2 _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2, _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3);
            half _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2;
            Unity_GradientNoise_half(_TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3, 16, _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2);
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2;
            Unity_Multiply_half(_GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_80222ead6749415082b7f9c461e2b035_Out_2);
            half _Property_00bf319b767845e7851dfff509e4690f_Out_0 = _WindStrength;
            half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
            Unity_Multiply_half(_Multiply_80222ead6749415082b7f9c461e2b035_Out_2, _Property_00bf319b767845e7851dfff509e4690f_Out_0, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2);
            half _Multiply_6235c90d381c4045880e54b9359ca466_Out_2;
            Unity_Multiply_half(0.05, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2, _Multiply_6235c90d381c4045880e54b9359ca466_Out_2);
            float3 _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            Unity_Add_float3((_Multiply_6235c90d381c4045880e54b9359ca466_Out_2.xxx), IN.ObjectSpacePosition, _Add_49510769758a45d69ae0fdcacecba70d_Out_2);
            description.Position = _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            half3 NormalTS;
            half Alpha;
            half AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_525a14b76350460487a0235960d53ada_Out_0 = UnityBuildTexture2DStructNoScale(_MainTex);
            half4 _Property_7104b0921e324793aecf6f4aef29ed10_Out_0 = _MainTex_ST;
            half _Split_602db811c686494894895d6489ac1a93_R_1 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[0];
            half _Split_602db811c686494894895d6489ac1a93_G_2 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[1];
            half _Split_602db811c686494894895d6489ac1a93_B_3 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[2];
            half _Split_602db811c686494894895d6489ac1a93_A_4 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[3];
            half4 _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4;
            half3 _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5;
            half2 _Combine_f7a96a985f594d6cae0daad764b71498_RG_6;
            Unity_Combine_half(_Split_602db811c686494894895d6489ac1a93_R_1, _Split_602db811c686494894895d6489ac1a93_G_2, 0, 0, _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4, _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6);
            half2 _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6, half2 (0, 0), _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3);
            UnityTexture2D _Property_6f42653dd834439da6b2995d25abd852_Out_0 = UnityBuildTexture2DStructNoScale(_FlowTex);
            half4 _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6f42653dd834439da6b2995d25abd852_Out_0.tex, _Property_6f42653dd834439da6b2995d25abd852_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_R_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.r;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_G_5 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.g;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_B_6 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.b;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_A_7 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.a;
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_R_1 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[0];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[1];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_B_3 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[2];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_A_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[3];
            half4 _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4;
            half3 _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5;
            half2 _Combine_00997931f0e1429d9a936bab82c990fc_RG_6;
            Unity_Combine_half(_Split_5c07383c9bd542b5bb228ba55a4bf822_R_1, _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2, 0, 0, _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4, _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5, _Combine_00997931f0e1429d9a936bab82c990fc_RG_6);
            half2 _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2;
            Unity_Multiply_half(_Combine_00997931f0e1429d9a936bab82c990fc_RG_6, half2(2, 2), _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2);
            half2 _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2;
            Unity_Subtract_half2(_Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2, half2(1, 1), _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2);
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half2 _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2;
            Unity_Multiply_half(_Subtract_528e92e261ff4ce082329f42aaede8de_Out_2, (_Split_32e455b4db934124814f28147e62dda0_R_1.xx), _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2);
            half _Property_24307526768d44f09f9614d06af9462e_Out_0 = _FlowStrength;
            half2 _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2;
            Unity_Multiply_half(_Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2, (_Property_24307526768d44f09f9614d06af9462e_Out_0.xx), _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2);
            half2 _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2;
            Unity_Add_half2(_TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3, _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half4 _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0 = SAMPLE_TEXTURE2D(_Property_525a14b76350460487a0235960d53ada_Out_0.tex, _Property_525a14b76350460487a0235960d53ada_Out_0.samplerstate, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_R_4 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.r;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_G_5 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.g;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_B_6 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.b;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.a;
            half3 _NormalUnpack_a1ec2fa45e3a4b338f038233d42da4b0_Out_1;
            Unity_NormalUnpack_half(_SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0, _NormalUnpack_a1ec2fa45e3a4b338f038233d42da4b0_Out_1);
            half _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2;
            Unity_Step_half(_Split_32e455b4db934124814f28147e62dda0_R_1, _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7, _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2);
            UnityTexture2D _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0 = UnityBuildTexture2DStructNoScale(_MaskTex);
            half4 _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.tex, _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.r;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_G_5 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.g;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_B_6 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.b;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_A_7 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.a;
            half _Property_d805ba1e888840a1b721ba4757ff7653_Out_0 = _NoiseScale;
            half _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2;
            Unity_SimpleNoise_half(IN.uv0.xy, _Property_d805ba1e888840a1b721ba4757ff7653_Out_0, _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2);
            half _Multiply_2301638808af49f1b094a9bc30731680_Out_2;
            Unity_Multiply_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, 4, _Multiply_2301638808af49f1b094a9bc30731680_Out_2);
            half _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0 = _NoiseContrast;
            half _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3;
            Unity_Smoothstep_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, _Multiply_2301638808af49f1b094a9bc30731680_Out_2, _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0, _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3);
            half _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2;
            Unity_Multiply_half(_Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2);
            half _Property_15657d2187234f36bee94093c3e87cfc_Out_0 = _LenthVar;
            half _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3;
            Unity_Lerp_half(0, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2, _Property_15657d2187234f36bee94093c3e87cfc_Out_0, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3);
            half _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2;
            Unity_Subtract_half(_SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3, _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2);
            half _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1;
            Unity_Saturate_half(_Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1);
            half _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            Unity_Multiply_half(_Step_a0e808c6281d4f1e906e97dc26931de5_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1, _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2);
            half _Property_eb141db1cd544ea2adf973c512527d1f_Out_0 = _ClipThreshold;
            surface.NormalTS = _NormalUnpack_a1ec2fa45e3a4b338f038233d42da4b0_Out_1;
            surface.Alpha = _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            surface.AlphaClipThreshold = _Property_eb141db1cd544ea2adf973c512527d1f_Out_0;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.uv0 =                         input.uv0;
            output.VertexColor =                 input.color;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);



            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);


            output.uv0 =                         input.texCoord0;
            output.VertexColor =                 input.color;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            // Render State
            Cull Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            #define ATTRIBUTES_NEED_COLOR
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_COLOR
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_META
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv0 : TEXCOORD0;
            float4 uv1 : TEXCOORD1;
            float4 uv2 : TEXCOORD2;
            float4 color : COLOR;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float4 texCoord0;
            float4 color;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float4 uv0;
            float4 VertexColor;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float4 uv0;
            float4 VertexColor;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float4 interp0 : TEXCOORD0;
            float4 interp1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyzw =  input.texCoord0;
            output.interp1.xyzw =  input.color;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.interp0.xyzw;
            output.color = input.interp1.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        half4 _Color;
        half _Multiply;
        float4 _MainTex_TexelSize;
        half4 _MainTex_ST;
        half _RimPower;
        float4 _MaskTex_TexelSize;
        float4 _ColorTex_TexelSize;
        half _NoiseScale;
        half _LenthVar;
        half _NoiseContrast;
        half _WindStrength;
        half4 _WindSettings;
        half _ClipThreshold;
        half4 _HairOccCol;
        float4 _FlowTex_TexelSize;
        half _FlowStrength;
        half _DEBUGVERTEXCOLORS_ON;
        CBUFFER_END

        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_MaskTex);
        SAMPLER(sampler_MaskTex);
        TEXTURE2D(_ColorTex);
        SAMPLER(sampler_ColorTex);
        TEXTURE2D(_FlowTex);
        SAMPLER(sampler_FlowTex);

            // Graph Functions
            
        void Unity_Combine_half(half R, half G, half B, half A, out half4 RGBA, out half3 RGB, out half2 RG)
        {
            RGBA = half4(R, G, B, A);
            RGB = half3(R, G, B);
            RG = half2(R, G);
        }

        void Unity_Multiply_half(half A, half B, out half Out)
        {
            Out = A * B;
        }

        void Unity_Add_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A + B;
        }

        void Unity_TilingAndOffset_half(half2 UV, half2 Tiling, half2 Offset, out half2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        half2 Unity_GradientNoise_Dir_half(half2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(half2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_half(half2 UV, half Scale, out half Out)
        { 
            half2 p = UV * Scale;
            half2 ip = floor(p);
            half2 fp = frac(p);
            half d00 = dot(Unity_GradientNoise_Dir_half(ip), fp);
            half d01 = dot(Unity_GradientNoise_Dir_half(ip + half2(0, 1)), fp - half2(0, 1));
            half d10 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 0)), fp - half2(1, 0));
            half d11 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 1)), fp - half2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_half4(half4 A, half4 B, half4 T, out half4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Multiply_half(half2 A, half2 B, out half2 Out)
        {
            Out = A * B;
        }

        void Unity_Subtract_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A - B;
        }

        void Unity_Step_half(half Edge, half In, out half Out)
        {
            Out = step(Edge, In);
        }


        inline half Unity_SimpleNoise_RandomValue_half (half2 uv)
        {
            return frac(sin(dot(uv, half2(12.9898, 78.233)))*43758.5453);
        }

        inline half Unity_SimpleNnoise_Interpolate_half (half a, half b, half t)
        {
            return (1.0-t)*a + (t*b);
        }


        inline half Unity_SimpleNoise_ValueNoise_half (half2 uv)
        {
            half2 i = floor(uv);
            half2 f = frac(uv);
            f = f * f * (3.0 - 2.0 * f);

            uv = abs(frac(uv) - 0.5);
            half2 c0 = i + half2(0.0, 0.0);
            half2 c1 = i + half2(1.0, 0.0);
            half2 c2 = i + half2(0.0, 1.0);
            half2 c3 = i + half2(1.0, 1.0);
            half r0 = Unity_SimpleNoise_RandomValue_half(c0);
            half r1 = Unity_SimpleNoise_RandomValue_half(c1);
            half r2 = Unity_SimpleNoise_RandomValue_half(c2);
            half r3 = Unity_SimpleNoise_RandomValue_half(c3);

            half bottomOfGrid = Unity_SimpleNnoise_Interpolate_half(r0, r1, f.x);
            half topOfGrid = Unity_SimpleNnoise_Interpolate_half(r2, r3, f.x);
            half t = Unity_SimpleNnoise_Interpolate_half(bottomOfGrid, topOfGrid, f.y);
            return t;
        }
        void Unity_SimpleNoise_half(half2 UV, half Scale, out half Out)
        {
            half t = 0.0;

            half freq = pow(2.0, half(0));
            half amp = pow(0.5, half(3-0));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(1));
            amp = pow(0.5, half(3-1));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(2));
            amp = pow(0.5, half(3-2));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            Out = t;
        }

        void Unity_Smoothstep_half(half Edge1, half Edge2, half In, out half Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Lerp_half(half A, half B, half T, out half Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Subtract_half(half A, half B, out half Out)
        {
            Out = A - B;
        }

        void Unity_Saturate_half(half In, out half Out)
        {
            Out = saturate(In);
        }

        void Unity_Multiply_half(half4 A, half4 B, out half4 Out)
        {
            Out = A * B;
        }

        void Unity_Branch_half4(half Predicate, half4 True, half4 False, out half4 Out)
        {
            Out = Predicate ? True : False;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            half3 Normal;
            half3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            half4 _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0 = _WindSettings;
            half _Split_bb70b739a797490d880162edc7afee6f_R_1 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[0];
            half _Split_bb70b739a797490d880162edc7afee6f_G_2 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[1];
            half _Split_bb70b739a797490d880162edc7afee6f_B_3 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[2];
            half _Split_bb70b739a797490d880162edc7afee6f_A_4 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[3];
            half4 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4;
            half3 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5;
            half2 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6;
            Unity_Combine_half(_Split_bb70b739a797490d880162edc7afee6f_R_1, _Split_bb70b739a797490d880162edc7afee6f_G_2, 0, 0, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6);
            half2 _Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0 = half2(_Split_bb70b739a797490d880162edc7afee6f_B_3, _Split_bb70b739a797490d880162edc7afee6f_A_4);
            half _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_B_3, IN.TimeParameters.x, _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2);
            half _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_A_4, IN.TimeParameters.x, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2);
            half4 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4;
            half3 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5;
            half2 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6;
            Unity_Combine_half(_Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2, 0, 0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6);
            half2 _Add_090b4851a1384ca09f399033bea33b52_Out_2;
            Unity_Add_half2(_Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2);
            half2 _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2, _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3);
            half _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2;
            Unity_GradientNoise_half(_TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3, 16, _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2);
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2;
            Unity_Multiply_half(_GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_80222ead6749415082b7f9c461e2b035_Out_2);
            half _Property_00bf319b767845e7851dfff509e4690f_Out_0 = _WindStrength;
            half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
            Unity_Multiply_half(_Multiply_80222ead6749415082b7f9c461e2b035_Out_2, _Property_00bf319b767845e7851dfff509e4690f_Out_0, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2);
            half _Multiply_6235c90d381c4045880e54b9359ca466_Out_2;
            Unity_Multiply_half(0.05, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2, _Multiply_6235c90d381c4045880e54b9359ca466_Out_2);
            float3 _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            Unity_Add_float3((_Multiply_6235c90d381c4045880e54b9359ca466_Out_2.xxx), IN.ObjectSpacePosition, _Add_49510769758a45d69ae0fdcacecba70d_Out_2);
            description.Position = _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            half3 BaseColor;
            half3 Emission;
            half Alpha;
            half AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            half4 _Property_2228b5aed348428da10b9296f9ebc494_Out_0 = _Color;
            half _Property_38318a489f9a4408a735e7c400d44b9a_Out_0 = _DEBUGVERTEXCOLORS_ON;
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half4 _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0 = _HairOccCol;
            half4 _Lerp_266d46ff80174903a133109b2f8086e1_Out_3;
            Unity_Lerp_half4(_Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0, half4(1, 1, 1, 1), (_Split_32e455b4db934124814f28147e62dda0_R_1.xxxx), _Lerp_266d46ff80174903a133109b2f8086e1_Out_3);
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_R_1 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[0];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_G_2 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[1];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_B_3 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[2];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_A_4 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[3];
            half4 _Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3;
            Unity_Lerp_half4(half4(1, 1, 1, 1), _Lerp_266d46ff80174903a133109b2f8086e1_Out_3, (_Split_9b0b84b2dbbd49d3b86865c028aa1936_A_4.xxxx), _Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3);
            UnityTexture2D _Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0 = UnityBuildTexture2DStructNoScale(_ColorTex);
            half4 _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0 = _WindSettings;
            half _Split_bb70b739a797490d880162edc7afee6f_R_1 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[0];
            half _Split_bb70b739a797490d880162edc7afee6f_G_2 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[1];
            half _Split_bb70b739a797490d880162edc7afee6f_B_3 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[2];
            half _Split_bb70b739a797490d880162edc7afee6f_A_4 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[3];
            half4 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4;
            half3 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5;
            half2 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6;
            Unity_Combine_half(_Split_bb70b739a797490d880162edc7afee6f_R_1, _Split_bb70b739a797490d880162edc7afee6f_G_2, 0, 0, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6);
            half2 _Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0 = half2(_Split_bb70b739a797490d880162edc7afee6f_B_3, _Split_bb70b739a797490d880162edc7afee6f_A_4);
            half _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_B_3, IN.TimeParameters.x, _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2);
            half _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_A_4, IN.TimeParameters.x, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2);
            half4 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4;
            half3 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5;
            half2 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6;
            Unity_Combine_half(_Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2, 0, 0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6);
            half2 _Add_090b4851a1384ca09f399033bea33b52_Out_2;
            Unity_Add_half2(_Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2);
            half2 _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2, _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3);
            half _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2;
            Unity_GradientNoise_half(_TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3, 16, _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2);
            half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2;
            Unity_Multiply_half(_GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_80222ead6749415082b7f9c461e2b035_Out_2);
            half _Property_00bf319b767845e7851dfff509e4690f_Out_0 = _WindStrength;
            half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
            Unity_Multiply_half(_Multiply_80222ead6749415082b7f9c461e2b035_Out_2, _Property_00bf319b767845e7851dfff509e4690f_Out_0, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2);
            half4 _Property_7104b0921e324793aecf6f4aef29ed10_Out_0 = _MainTex_ST;
            half _Split_602db811c686494894895d6489ac1a93_R_1 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[0];
            half _Split_602db811c686494894895d6489ac1a93_G_2 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[1];
            half _Split_602db811c686494894895d6489ac1a93_B_3 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[2];
            half _Split_602db811c686494894895d6489ac1a93_A_4 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[3];
            half4 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGBA_4;
            half3 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGB_5;
            half2 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6;
            Unity_Combine_half(_Split_602db811c686494894895d6489ac1a93_B_3, _Split_602db811c686494894895d6489ac1a93_A_4, 0, 0, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGBA_4, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGB_5, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6);
            half2 _Add_5ecadbcbe14847e18d526011c7679f8c_Out_2;
            Unity_Add_half2((_Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2.xx), _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6, _Add_5ecadbcbe14847e18d526011c7679f8c_Out_2);
            UnityTexture2D _Property_525a14b76350460487a0235960d53ada_Out_0 = UnityBuildTexture2DStructNoScale(_MainTex);
            half4 _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4;
            half3 _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5;
            half2 _Combine_f7a96a985f594d6cae0daad764b71498_RG_6;
            Unity_Combine_half(_Split_602db811c686494894895d6489ac1a93_R_1, _Split_602db811c686494894895d6489ac1a93_G_2, 0, 0, _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4, _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6);
            half2 _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6, half2 (0, 0), _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3);
            UnityTexture2D _Property_6f42653dd834439da6b2995d25abd852_Out_0 = UnityBuildTexture2DStructNoScale(_FlowTex);
            half4 _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6f42653dd834439da6b2995d25abd852_Out_0.tex, _Property_6f42653dd834439da6b2995d25abd852_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_R_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.r;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_G_5 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.g;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_B_6 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.b;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_A_7 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.a;
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_R_1 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[0];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[1];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_B_3 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[2];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_A_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[3];
            half4 _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4;
            half3 _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5;
            half2 _Combine_00997931f0e1429d9a936bab82c990fc_RG_6;
            Unity_Combine_half(_Split_5c07383c9bd542b5bb228ba55a4bf822_R_1, _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2, 0, 0, _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4, _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5, _Combine_00997931f0e1429d9a936bab82c990fc_RG_6);
            half2 _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2;
            Unity_Multiply_half(_Combine_00997931f0e1429d9a936bab82c990fc_RG_6, half2(2, 2), _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2);
            half2 _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2;
            Unity_Subtract_half2(_Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2, half2(1, 1), _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2);
            half2 _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2;
            Unity_Multiply_half(_Subtract_528e92e261ff4ce082329f42aaede8de_Out_2, (_Split_32e455b4db934124814f28147e62dda0_R_1.xx), _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2);
            half _Property_24307526768d44f09f9614d06af9462e_Out_0 = _FlowStrength;
            half2 _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2;
            Unity_Multiply_half(_Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2, (_Property_24307526768d44f09f9614d06af9462e_Out_0.xx), _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2);
            half2 _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2;
            Unity_Add_half2(_TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3, _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half4 _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0 = SAMPLE_TEXTURE2D(_Property_525a14b76350460487a0235960d53ada_Out_0.tex, _Property_525a14b76350460487a0235960d53ada_Out_0.samplerstate, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_R_4 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.r;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_G_5 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.g;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_B_6 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.b;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.a;
            half _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2;
            Unity_Step_half(_Split_32e455b4db934124814f28147e62dda0_R_1, _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7, _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2);
            UnityTexture2D _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0 = UnityBuildTexture2DStructNoScale(_MaskTex);
            half4 _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.tex, _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.r;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_G_5 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.g;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_B_6 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.b;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_A_7 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.a;
            half _Property_d805ba1e888840a1b721ba4757ff7653_Out_0 = _NoiseScale;
            half _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2;
            Unity_SimpleNoise_half(IN.uv0.xy, _Property_d805ba1e888840a1b721ba4757ff7653_Out_0, _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2);
            half _Multiply_2301638808af49f1b094a9bc30731680_Out_2;
            Unity_Multiply_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, 4, _Multiply_2301638808af49f1b094a9bc30731680_Out_2);
            half _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0 = _NoiseContrast;
            half _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3;
            Unity_Smoothstep_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, _Multiply_2301638808af49f1b094a9bc30731680_Out_2, _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0, _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3);
            half _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2;
            Unity_Multiply_half(_Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2);
            half _Property_15657d2187234f36bee94093c3e87cfc_Out_0 = _LenthVar;
            half _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3;
            Unity_Lerp_half(0, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2, _Property_15657d2187234f36bee94093c3e87cfc_Out_0, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3);
            half _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2;
            Unity_Subtract_half(_SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3, _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2);
            half _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1;
            Unity_Saturate_half(_Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1);
            half _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            Unity_Multiply_half(_Step_a0e808c6281d4f1e906e97dc26931de5_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1, _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2);
            half2 _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2;
            Unity_Multiply_half(_Add_5ecadbcbe14847e18d526011c7679f8c_Out_2, (_Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2.xx), _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2);
            half2 _Multiply_9a843867bc00497ebdabd88255642899_Out_2;
            Unity_Multiply_half(half2(0.1, 0.1), _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2, _Multiply_9a843867bc00497ebdabd88255642899_Out_2);
            half2 _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, half2 (1, 1), _Multiply_9a843867bc00497ebdabd88255642899_Out_2, _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3);
            half4 _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0 = SAMPLE_TEXTURE2D(_Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0.tex, _Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0.samplerstate, _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3);
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_R_4 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.r;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_G_5 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.g;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_B_6 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.b;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_A_7 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.a;
            half4 _Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2;
            Unity_Multiply_half(_Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3, _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0, _Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2);
            half _Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2;
            Unity_Multiply_half(_SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7, 1, _Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2);
            half4 _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2;
            Unity_Multiply_half(_Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2, (_Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2.xxxx), _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2);
            half4 _Branch_1de247f9645e44088172ca18ab7005fc_Out_3;
            Unity_Branch_half4(_Property_38318a489f9a4408a735e7c400d44b9a_Out_0, (_Split_32e455b4db934124814f28147e62dda0_R_1.xxxx), _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2, _Branch_1de247f9645e44088172ca18ab7005fc_Out_3);
            half4 _Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2;
            Unity_Multiply_half(_Property_2228b5aed348428da10b9296f9ebc494_Out_0, _Branch_1de247f9645e44088172ca18ab7005fc_Out_3, _Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2);
            half _Property_eb141db1cd544ea2adf973c512527d1f_Out_0 = _ClipThreshold;
            surface.BaseColor = (_Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2.xyz);
            surface.Emission = half3(0, 0, 0);
            surface.Alpha = _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            surface.AlphaClipThreshold = _Property_eb141db1cd544ea2adf973c512527d1f_Out_0;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.uv0 =                         input.uv0;
            output.VertexColor =                 input.color;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





            output.uv0 =                         input.texCoord0;
            output.VertexColor =                 input.color;
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            // Name: <None>
            Tags
            {
                "LightMode" = "Universal2D"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_COLOR
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_COLOR
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_2D
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv0 : TEXCOORD0;
            float4 color : COLOR;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float4 texCoord0;
            float4 color;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float4 uv0;
            float4 VertexColor;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float4 uv0;
            float4 VertexColor;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float4 interp0 : TEXCOORD0;
            float4 interp1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyzw =  input.texCoord0;
            output.interp1.xyzw =  input.color;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.interp0.xyzw;
            output.color = input.interp1.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        half4 _Color;
        half _Multiply;
        float4 _MainTex_TexelSize;
        half4 _MainTex_ST;
        half _RimPower;
        float4 _MaskTex_TexelSize;
        float4 _ColorTex_TexelSize;
        half _NoiseScale;
        half _LenthVar;
        half _NoiseContrast;
        half _WindStrength;
        half4 _WindSettings;
        half _ClipThreshold;
        half4 _HairOccCol;
        float4 _FlowTex_TexelSize;
        half _FlowStrength;
        half _DEBUGVERTEXCOLORS_ON;
        CBUFFER_END

        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_MaskTex);
        SAMPLER(sampler_MaskTex);
        TEXTURE2D(_ColorTex);
        SAMPLER(sampler_ColorTex);
        TEXTURE2D(_FlowTex);
        SAMPLER(sampler_FlowTex);

            // Graph Functions
            
        void Unity_Combine_half(half R, half G, half B, half A, out half4 RGBA, out half3 RGB, out half2 RG)
        {
            RGBA = half4(R, G, B, A);
            RGB = half3(R, G, B);
            RG = half2(R, G);
        }

        void Unity_Multiply_half(half A, half B, out half Out)
        {
            Out = A * B;
        }

        void Unity_Add_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A + B;
        }

        void Unity_TilingAndOffset_half(half2 UV, half2 Tiling, half2 Offset, out half2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        half2 Unity_GradientNoise_Dir_half(half2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(half2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_half(half2 UV, half Scale, out half Out)
        { 
            half2 p = UV * Scale;
            half2 ip = floor(p);
            half2 fp = frac(p);
            half d00 = dot(Unity_GradientNoise_Dir_half(ip), fp);
            half d01 = dot(Unity_GradientNoise_Dir_half(ip + half2(0, 1)), fp - half2(0, 1));
            half d10 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 0)), fp - half2(1, 0));
            half d11 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 1)), fp - half2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_half4(half4 A, half4 B, half4 T, out half4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Multiply_half(half2 A, half2 B, out half2 Out)
        {
            Out = A * B;
        }

        void Unity_Subtract_half2(half2 A, half2 B, out half2 Out)
        {
            Out = A - B;
        }

        void Unity_Step_half(half Edge, half In, out half Out)
        {
            Out = step(Edge, In);
        }


        inline half Unity_SimpleNoise_RandomValue_half (half2 uv)
        {
            return frac(sin(dot(uv, half2(12.9898, 78.233)))*43758.5453);
        }

        inline half Unity_SimpleNnoise_Interpolate_half (half a, half b, half t)
        {
            return (1.0-t)*a + (t*b);
        }


        inline half Unity_SimpleNoise_ValueNoise_half (half2 uv)
        {
            half2 i = floor(uv);
            half2 f = frac(uv);
            f = f * f * (3.0 - 2.0 * f);

            uv = abs(frac(uv) - 0.5);
            half2 c0 = i + half2(0.0, 0.0);
            half2 c1 = i + half2(1.0, 0.0);
            half2 c2 = i + half2(0.0, 1.0);
            half2 c3 = i + half2(1.0, 1.0);
            half r0 = Unity_SimpleNoise_RandomValue_half(c0);
            half r1 = Unity_SimpleNoise_RandomValue_half(c1);
            half r2 = Unity_SimpleNoise_RandomValue_half(c2);
            half r3 = Unity_SimpleNoise_RandomValue_half(c3);

            half bottomOfGrid = Unity_SimpleNnoise_Interpolate_half(r0, r1, f.x);
            half topOfGrid = Unity_SimpleNnoise_Interpolate_half(r2, r3, f.x);
            half t = Unity_SimpleNnoise_Interpolate_half(bottomOfGrid, topOfGrid, f.y);
            return t;
        }
        void Unity_SimpleNoise_half(half2 UV, half Scale, out half Out)
        {
            half t = 0.0;

            half freq = pow(2.0, half(0));
            half amp = pow(0.5, half(3-0));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(1));
            amp = pow(0.5, half(3-1));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, half(2));
            amp = pow(0.5, half(3-2));
            t += Unity_SimpleNoise_ValueNoise_half(half2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            Out = t;
        }

        void Unity_Smoothstep_half(half Edge1, half Edge2, half In, out half Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Lerp_half(half A, half B, half T, out half Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Subtract_half(half A, half B, out half Out)
        {
            Out = A - B;
        }

        void Unity_Saturate_half(half In, out half Out)
        {
            Out = saturate(In);
        }

        void Unity_Multiply_half(half4 A, half4 B, out half4 Out)
        {
            Out = A * B;
        }

        void Unity_Branch_half4(half Predicate, half4 True, half4 False, out half4 Out)
        {
            Out = Predicate ? True : False;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            half3 Normal;
            half3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            half4 _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0 = _WindSettings;
            half _Split_bb70b739a797490d880162edc7afee6f_R_1 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[0];
            half _Split_bb70b739a797490d880162edc7afee6f_G_2 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[1];
            half _Split_bb70b739a797490d880162edc7afee6f_B_3 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[2];
            half _Split_bb70b739a797490d880162edc7afee6f_A_4 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[3];
            half4 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4;
            half3 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5;
            half2 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6;
            Unity_Combine_half(_Split_bb70b739a797490d880162edc7afee6f_R_1, _Split_bb70b739a797490d880162edc7afee6f_G_2, 0, 0, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6);
            half2 _Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0 = half2(_Split_bb70b739a797490d880162edc7afee6f_B_3, _Split_bb70b739a797490d880162edc7afee6f_A_4);
            half _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_B_3, IN.TimeParameters.x, _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2);
            half _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_A_4, IN.TimeParameters.x, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2);
            half4 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4;
            half3 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5;
            half2 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6;
            Unity_Combine_half(_Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2, 0, 0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6);
            half2 _Add_090b4851a1384ca09f399033bea33b52_Out_2;
            Unity_Add_half2(_Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2);
            half2 _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2, _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3);
            half _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2;
            Unity_GradientNoise_half(_TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3, 16, _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2);
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2;
            Unity_Multiply_half(_GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_80222ead6749415082b7f9c461e2b035_Out_2);
            half _Property_00bf319b767845e7851dfff509e4690f_Out_0 = _WindStrength;
            half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
            Unity_Multiply_half(_Multiply_80222ead6749415082b7f9c461e2b035_Out_2, _Property_00bf319b767845e7851dfff509e4690f_Out_0, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2);
            half _Multiply_6235c90d381c4045880e54b9359ca466_Out_2;
            Unity_Multiply_half(0.05, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2, _Multiply_6235c90d381c4045880e54b9359ca466_Out_2);
            float3 _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            Unity_Add_float3((_Multiply_6235c90d381c4045880e54b9359ca466_Out_2.xxx), IN.ObjectSpacePosition, _Add_49510769758a45d69ae0fdcacecba70d_Out_2);
            description.Position = _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            half3 BaseColor;
            half Alpha;
            half AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            half4 _Property_2228b5aed348428da10b9296f9ebc494_Out_0 = _Color;
            half _Property_38318a489f9a4408a735e7c400d44b9a_Out_0 = _DEBUGVERTEXCOLORS_ON;
            half _Split_32e455b4db934124814f28147e62dda0_R_1 = IN.VertexColor[0];
            half _Split_32e455b4db934124814f28147e62dda0_G_2 = IN.VertexColor[1];
            half _Split_32e455b4db934124814f28147e62dda0_B_3 = IN.VertexColor[2];
            half _Split_32e455b4db934124814f28147e62dda0_A_4 = IN.VertexColor[3];
            half4 _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0 = _HairOccCol;
            half4 _Lerp_266d46ff80174903a133109b2f8086e1_Out_3;
            Unity_Lerp_half4(_Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0, half4(1, 1, 1, 1), (_Split_32e455b4db934124814f28147e62dda0_R_1.xxxx), _Lerp_266d46ff80174903a133109b2f8086e1_Out_3);
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_R_1 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[0];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_G_2 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[1];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_B_3 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[2];
            half _Split_9b0b84b2dbbd49d3b86865c028aa1936_A_4 = _Property_22e4e01ba11c42f09391d9461a96d4b9_Out_0[3];
            half4 _Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3;
            Unity_Lerp_half4(half4(1, 1, 1, 1), _Lerp_266d46ff80174903a133109b2f8086e1_Out_3, (_Split_9b0b84b2dbbd49d3b86865c028aa1936_A_4.xxxx), _Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3);
            UnityTexture2D _Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0 = UnityBuildTexture2DStructNoScale(_ColorTex);
            half4 _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0 = _WindSettings;
            half _Split_bb70b739a797490d880162edc7afee6f_R_1 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[0];
            half _Split_bb70b739a797490d880162edc7afee6f_G_2 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[1];
            half _Split_bb70b739a797490d880162edc7afee6f_B_3 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[2];
            half _Split_bb70b739a797490d880162edc7afee6f_A_4 = _Property_e28641bfc45940e0b6c316e51a7df8f6_Out_0[3];
            half4 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4;
            half3 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5;
            half2 _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6;
            Unity_Combine_half(_Split_bb70b739a797490d880162edc7afee6f_R_1, _Split_bb70b739a797490d880162edc7afee6f_G_2, 0, 0, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGBA_4, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RGB_5, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6);
            half2 _Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0 = half2(_Split_bb70b739a797490d880162edc7afee6f_B_3, _Split_bb70b739a797490d880162edc7afee6f_A_4);
            half _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_B_3, IN.TimeParameters.x, _Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2);
            half _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2;
            Unity_Multiply_half(_Split_bb70b739a797490d880162edc7afee6f_A_4, IN.TimeParameters.x, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2);
            half4 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4;
            half3 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5;
            half2 _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6;
            Unity_Combine_half(_Multiply_17a8d31ca0364bad8838ab3fd671e6e0_Out_2, _Multiply_86e658c0f5e141f78229168aaf73d929_Out_2, 0, 0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGBA_4, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RGB_5, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6);
            half2 _Add_090b4851a1384ca09f399033bea33b52_Out_2;
            Unity_Add_half2(_Vector2_b0c0726cba8649ba8afd4ecf517a98aa_Out_0, _Combine_a3d9e1086a1b4a9d9de74c387e47b134_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2);
            half2 _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_bb7bc9c7ecf74fc6adb883ad18f23a12_RG_6, _Add_090b4851a1384ca09f399033bea33b52_Out_2, _TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3);
            half _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2;
            Unity_GradientNoise_half(_TilingAndOffset_25273895e7b54c6fbbb16a25b8299dc3_Out_3, 16, _GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2);
            half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2;
            Unity_Multiply_half(_GradientNoise_8eb8bdc60ed54c1280d5e7a65ca2a206_Out_2, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_80222ead6749415082b7f9c461e2b035_Out_2);
            half _Property_00bf319b767845e7851dfff509e4690f_Out_0 = _WindStrength;
            half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
            Unity_Multiply_half(_Multiply_80222ead6749415082b7f9c461e2b035_Out_2, _Property_00bf319b767845e7851dfff509e4690f_Out_0, _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2);
            half4 _Property_7104b0921e324793aecf6f4aef29ed10_Out_0 = _MainTex_ST;
            half _Split_602db811c686494894895d6489ac1a93_R_1 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[0];
            half _Split_602db811c686494894895d6489ac1a93_G_2 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[1];
            half _Split_602db811c686494894895d6489ac1a93_B_3 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[2];
            half _Split_602db811c686494894895d6489ac1a93_A_4 = _Property_7104b0921e324793aecf6f4aef29ed10_Out_0[3];
            half4 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGBA_4;
            half3 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGB_5;
            half2 _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6;
            Unity_Combine_half(_Split_602db811c686494894895d6489ac1a93_B_3, _Split_602db811c686494894895d6489ac1a93_A_4, 0, 0, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGBA_4, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RGB_5, _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6);
            half2 _Add_5ecadbcbe14847e18d526011c7679f8c_Out_2;
            Unity_Add_half2((_Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2.xx), _Combine_bf6d05a1df3e4ee0b68fd227065b0c17_RG_6, _Add_5ecadbcbe14847e18d526011c7679f8c_Out_2);
            UnityTexture2D _Property_525a14b76350460487a0235960d53ada_Out_0 = UnityBuildTexture2DStructNoScale(_MainTex);
            half4 _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4;
            half3 _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5;
            half2 _Combine_f7a96a985f594d6cae0daad764b71498_RG_6;
            Unity_Combine_half(_Split_602db811c686494894895d6489ac1a93_R_1, _Split_602db811c686494894895d6489ac1a93_G_2, 0, 0, _Combine_f7a96a985f594d6cae0daad764b71498_RGBA_4, _Combine_f7a96a985f594d6cae0daad764b71498_RGB_5, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6);
            half2 _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, _Combine_f7a96a985f594d6cae0daad764b71498_RG_6, half2 (0, 0), _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3);
            UnityTexture2D _Property_6f42653dd834439da6b2995d25abd852_Out_0 = UnityBuildTexture2DStructNoScale(_FlowTex);
            half4 _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6f42653dd834439da6b2995d25abd852_Out_0.tex, _Property_6f42653dd834439da6b2995d25abd852_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_R_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.r;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_G_5 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.g;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_B_6 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.b;
            half _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_A_7 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0.a;
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_R_1 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[0];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[1];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_B_3 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[2];
            half _Split_5c07383c9bd542b5bb228ba55a4bf822_A_4 = _SampleTexture2D_156ec4f4465d412a92346d8dc874a44c_RGBA_0[3];
            half4 _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4;
            half3 _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5;
            half2 _Combine_00997931f0e1429d9a936bab82c990fc_RG_6;
            Unity_Combine_half(_Split_5c07383c9bd542b5bb228ba55a4bf822_R_1, _Split_5c07383c9bd542b5bb228ba55a4bf822_G_2, 0, 0, _Combine_00997931f0e1429d9a936bab82c990fc_RGBA_4, _Combine_00997931f0e1429d9a936bab82c990fc_RGB_5, _Combine_00997931f0e1429d9a936bab82c990fc_RG_6);
            half2 _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2;
            Unity_Multiply_half(_Combine_00997931f0e1429d9a936bab82c990fc_RG_6, half2(2, 2), _Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2);
            half2 _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2;
            Unity_Subtract_half2(_Multiply_068cc6f780c1450fb2f444e43c9052d7_Out_2, half2(1, 1), _Subtract_528e92e261ff4ce082329f42aaede8de_Out_2);
            half2 _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2;
            Unity_Multiply_half(_Subtract_528e92e261ff4ce082329f42aaede8de_Out_2, (_Split_32e455b4db934124814f28147e62dda0_R_1.xx), _Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2);
            half _Property_24307526768d44f09f9614d06af9462e_Out_0 = _FlowStrength;
            half2 _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2;
            Unity_Multiply_half(_Multiply_e8dc6e1ea2d04aa9adb9e57cc1703b54_Out_2, (_Property_24307526768d44f09f9614d06af9462e_Out_0.xx), _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2);
            half2 _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2;
            Unity_Add_half2(_TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3, _Multiply_47095e0abd3a43f18101c515ebd15820_Out_2, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half4 _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0 = SAMPLE_TEXTURE2D(_Property_525a14b76350460487a0235960d53ada_Out_0.tex, _Property_525a14b76350460487a0235960d53ada_Out_0.samplerstate, _Add_fcb60fe5538b438d9d439b9a8c2c2dc5_Out_2);
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_R_4 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.r;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_G_5 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.g;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_B_6 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.b;
            half _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7 = _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_RGBA_0.a;
            half _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2;
            Unity_Step_half(_Split_32e455b4db934124814f28147e62dda0_R_1, _SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7, _Step_a0e808c6281d4f1e906e97dc26931de5_Out_2);
            UnityTexture2D _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0 = UnityBuildTexture2DStructNoScale(_MaskTex);
            half4 _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.tex, _Property_a40a371e03fe4e5eafee4c74a4b01c43_Out_0.samplerstate, IN.uv0.xy);
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.r;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_G_5 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.g;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_B_6 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.b;
            half _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_A_7 = _SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_RGBA_0.a;
            half _Property_d805ba1e888840a1b721ba4757ff7653_Out_0 = _NoiseScale;
            half _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2;
            Unity_SimpleNoise_half(IN.uv0.xy, _Property_d805ba1e888840a1b721ba4757ff7653_Out_0, _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2);
            half _Multiply_2301638808af49f1b094a9bc30731680_Out_2;
            Unity_Multiply_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, 4, _Multiply_2301638808af49f1b094a9bc30731680_Out_2);
            half _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0 = _NoiseContrast;
            half _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3;
            Unity_Smoothstep_half(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, _Multiply_2301638808af49f1b094a9bc30731680_Out_2, _Property_705205aabe17426fa7dbaa56f14b70c9_Out_0, _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3);
            half _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2;
            Unity_Multiply_half(_Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3, _Split_32e455b4db934124814f28147e62dda0_R_1, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2);
            half _Property_15657d2187234f36bee94093c3e87cfc_Out_0 = _LenthVar;
            half _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3;
            Unity_Lerp_half(0, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2, _Property_15657d2187234f36bee94093c3e87cfc_Out_0, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3);
            half _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2;
            Unity_Subtract_half(_SampleTexture2D_7b6b7cab40df4a728e7252d6644fce5c_R_4, _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3, _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2);
            half _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1;
            Unity_Saturate_half(_Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1);
            half _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            Unity_Multiply_half(_Step_a0e808c6281d4f1e906e97dc26931de5_Out_2, _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1, _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2);
            half2 _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2;
            Unity_Multiply_half(_Add_5ecadbcbe14847e18d526011c7679f8c_Out_2, (_Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2.xx), _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2);
            half2 _Multiply_9a843867bc00497ebdabd88255642899_Out_2;
            Unity_Multiply_half(half2(0.1, 0.1), _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2, _Multiply_9a843867bc00497ebdabd88255642899_Out_2);
            half2 _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3;
            Unity_TilingAndOffset_half(IN.uv0.xy, half2 (1, 1), _Multiply_9a843867bc00497ebdabd88255642899_Out_2, _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3);
            half4 _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0 = SAMPLE_TEXTURE2D(_Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0.tex, _Property_ea9d2a3382864ef8b1c9646eb592215b_Out_0.samplerstate, _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3);
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_R_4 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.r;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_G_5 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.g;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_B_6 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.b;
            half _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_A_7 = _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0.a;
            half4 _Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2;
            Unity_Multiply_half(_Lerp_4cf5bd722f29442b98a6f5f180e2dbd8_Out_3, _SampleTexture2D_ea686e6fd195401193d20a5a28dc98d4_RGBA_0, _Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2);
            half _Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2;
            Unity_Multiply_half(_SampleTexture2D_c553f6313f39469a9c28289fe56f1ca7_A_7, 1, _Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2);
            half4 _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2;
            Unity_Multiply_half(_Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2, (_Multiply_f7a19188f8994fc587e26133f1b9214c_Out_2.xxxx), _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2);
            half4 _Branch_1de247f9645e44088172ca18ab7005fc_Out_3;
            Unity_Branch_half4(_Property_38318a489f9a4408a735e7c400d44b9a_Out_0, (_Split_32e455b4db934124814f28147e62dda0_R_1.xxxx), _Multiply_5dad4a425d194f0eab118c9e8c2f24cd_Out_2, _Branch_1de247f9645e44088172ca18ab7005fc_Out_3);
            half4 _Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2;
            Unity_Multiply_half(_Property_2228b5aed348428da10b9296f9ebc494_Out_0, _Branch_1de247f9645e44088172ca18ab7005fc_Out_3, _Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2);
            half _Property_eb141db1cd544ea2adf973c512527d1f_Out_0 = _ClipThreshold;
            surface.BaseColor = (_Multiply_8db362cdce0e4c56b501f5d223e8e14b_Out_2.xyz);
            surface.Alpha = _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
            surface.AlphaClipThreshold = _Property_eb141db1cd544ea2adf973c512527d1f_Out_0;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.uv0 =                         input.uv0;
            output.VertexColor =                 input.color;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





            output.uv0 =                         input.texCoord0;
            output.VertexColor =                 input.color;
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"

            ENDHLSL
        }
    }
    CustomEditor "ShaderGraph.PBRMasterGUI"
    FallBack "Hidden/Shader Graph/FallbackError"
}