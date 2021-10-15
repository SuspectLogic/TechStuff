Shader "Unlit/Fur_New"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            Cull Back
            Blend One Zero
            ZTest LEqual
            ZWrite On


            HLSLPROGRAM

            #pragma target 4.5
            #pragma exclude_renderers gles gles3 glcore
            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            #pragma multi_compile _ DOTS_INSTANCING_ON
            #pragma vertex vert
            #pragma fragment frag

            //Keywords
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

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"


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

            //Properties
            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            half _Multiply;
            float4 _MainTex_TexelSize;
            half4 _MainTex_ScaleTransform;
            half _RimPower;
            float4 _MaskTex_TexelSize;
            float4 _ColorTex_TexelSize;
            half _NoiseScale;
            half _LengthVariation;
            half _NoiseContrast;
            half _WindStrength;
            half4 _WindSettings;
            half _ClipThreshold;
            half4 _HairOccCol;
            float4 _FlowTex_TexelSize;
            half _FlowStrength;
            half _DEBUGVERTEXCOLORS_ON;

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
            CBUFFER_END

            

            // half2 Unity_GradientNoise_Dir_half(half2 p)
            // {
            //     // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            //     p = p % 289;
            //     // need full precision, otherwise half overflows when p > 1
            //     float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            //     x = (34 * x + 1) * x % 289;
            //     x = frac(x / 41) * 2 - 1;
            //     return normalize(half2(x - floor(x + 0.5), abs(x) - 0.5));
            // }

            // void Unity_GradientNoise_half(half2 UV, half Scale, out half Out)
            // { 
            //     half2 p = UV * Scale;
            //     half2 ip = floor(p);
            //     half2 fp = frac(p);
            //     half d00 = dot(Unity_GradientNoise_Dir_half(ip), fp);
            //     half d01 = dot(Unity_GradientNoise_Dir_half(ip + half2(0, 1)), fp - half2(0, 1));
            //     half d10 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 0)), fp - half2(1, 0));
            //     half d11 = dot(Unity_GradientNoise_Dir_half(ip + half2(1, 1)), fp - half2(1, 1));
            //     fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            //     Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
            // }
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

            struct VertexDescription
            {
                float3 Position;
                half3 Normal;
                half3 Tangent;
            };

            VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
            {
                VertexDescription description = (VertexDescription)0;

                half2 windSettingsZW = half2(_WindSettings.z, _WindSettings.w);
                windSettingsZW *= IN.TimeParameters.x;
                
                half2 noiseUV =  IN.uv0.xy * _WindSettings.xy + windSettingsZW;                
                half gradientNoise;
                half newgradientNoise = Unity_GradientNoise_half(noiseUV, 16, gradientNoise);
                half _Multiply_80222ead6749415082b7f9c461e2b035_Out_2 =  newgradientNoise * IN.VertexColor.r;
                half _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2 = _Multiply_80222ead6749415082b7f9c461e2b035_Out_2 * _WindStrength;
                half _Multiply_6235c90d381c4045880e54b9359ca466_Out_2 = 0.05 * _Multiply_be9c3b4f8f984a61ac987c462c106f9b_Out_2;
                float3 _Add_49510769758a45d69ae0fdcacecba70d_Out_2 = (_Multiply_6235c90d381c4045880e54b9359ca466_Out_2.xxx) + IN.ObjectSpacePosition;
                description.Position = _Add_49510769758a45d69ae0fdcacecba70d_Out_2;
                description.Normal = IN.ObjectSpaceNormal;
                description.Tangent = IN.ObjectSpaceTangent;
                return description;
            }

            // Pixel Outputs
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
                // Occlusion
                half4 hairOccCol = lerp(_HairOccCol, half4(1,1,1,1), IN.VertexColor.r);
                half4 hairColor = lerp(half4(1,1,1,1), hairOccCol, hairOccCol.a);

                // Wind
                UnityTexture2D colorTextureAsset = UnityBuildTexture2DStructNoScale(_ColorTex);
                half windMovementX = _WindSettings.z * IN.TimeParameters.x;
                half windMovementY = _WindSettings.w * IN.TimeParameters.x;             
                half2 windUV = float2(windMovementX, windMovementY) + _WindSettings.zw;
                windUV += IN.uv0.xy * _WindSettings.xy;

                half gradientNoise = Unity_GradientNoise_half(windUV, 16, gradientNoise);

                gradientNoise *=  IN.VertexColor.r ;
                
                half2 _Add_5ecadbcbe14847e18d526011c7679f8c_Out_2 = (gradientNoise * _WindStrength) + _MainTex_ScaleTransform.rg;
                UnityTexture2D mainTex = UnityBuildTexture2DStructNoScale(_MainTex);

                half2 _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3  = IN.uv0.xy * _MainTex_ScaleTransform.rg + half2 (0, 0);
                
                UnityTexture2D flowTexAsset = UnityBuildTexture2DStructNoScale(_FlowTex);
                half2 flowTexture = SAMPLE_TEXTURE2D(flowTexAsset.tex, flowTexAsset.samplerstate, IN.uv0.xy).rg;
  
                flowTexture *= half2(2, 2);

                flowTexture -= 1;
                half2 flowUV = (flowTexture * (IN.VertexColor.xx)) * _FlowStrength;

                half2 furUV = _TilingAndOffset_b7f08d407dce4c4b8359426635597c1b_Out_3 + flowUV;                
                half4 furTex = SAMPLE_TEXTURE2D(mainTex.tex, mainTex.samplerstate, furUV);  

                half furWidth = step(IN.VertexColor.r, furTex.a);
                
                UnityTexture2D maskTextureAsset = UnityBuildTexture2DStructNoScale(_MaskTex);
                half4 maskTexture = SAMPLE_TEXTURE2D(maskTextureAsset.tex, maskTextureAsset.samplerstate, IN.uv0.xy);

                half _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2 = Unity_SimpleNoise_half(IN.uv0.xy, _NoiseScale, _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2);
                half _Multiply_2301638808af49f1b094a9bc30731680_Out_2 = _SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2 * 4;

                half _Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3 = smoothstep(_SimpleNoise_071b87e49bb44092a5e19ff0a2b37c3e_Out_2, _Multiply_2301638808af49f1b094a9bc30731680_Out_2, _NoiseContrast);
                half _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2 = (_Smoothstep_ada8d13b266043129a8aa44f55915cc4_Out_3 * IN.VertexColor.r);
                half _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3 = lerp(0, _Multiply_b053015c0a4141bc95adb584d5aeca42_Out_2, _LengthVariation);
                half _Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2 = (maskTexture.r - _Lerp_0b48cc8a3d6e4aa68fb4fa0e3aa009cc_Out_3);
                half _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1 = saturate(_Subtract_c6884e314ecb4abf9a09c4280a7d6968_Out_2);
                half _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2 = furWidth * _Saturate_67b4d7c3d05044a891e76114a432f905_Out_1;
                half2 _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2 = _Add_5ecadbcbe14847e18d526011c7679f8c_Out_2 * _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
                half2 _Multiply_9a843867bc00497ebdabd88255642899_Out_2 = half2(0.1, 0.1) * _Multiply_60e271144e374a4cae441037f6cce7c7_Out_2;
                
                half2 _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3 = (IN.uv0.xy * half2 (1, 1) + _Multiply_9a843867bc00497ebdabd88255642899_Out_2);
                
                half4 colorTexture = SAMPLE_TEXTURE2D(colorTextureAsset.tex, colorTextureAsset.samplerstate, _TilingAndOffset_cb50da1e6ecd405da7cda8408c566ed5_Out_3);
                half4 _Multiply_7f780d4da12e4bd5af8fdbce666567d0_Out_2 = (hairColor * colorTexture);
                colorTexture *= hairColor;

                half4 color = colorTexture * furTex.a;
                color.rgb = lerp(color.rgb, IN.VertexColor.r, _DEBUGVERTEXCOLORS_ON);
               
                color *= _Color;
                
                half3 normalMap =  UnpackNormal(furTex);
                
                surface.BaseColor = (color.xyz);
                surface.NormalTS = normalMap;
                surface.Emission = half3(0, 0, 0);
                surface.Metallic = 0;
                surface.Smoothness = 0;
                surface.Occlusion = 1;
                surface.Alpha = _Multiply_ecd79c927ad24df9bb9bd1ee5f0d883b_Out_2;
                surface.AlphaClipThreshold = _ClipThreshold;
                return surface;
            }

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

                output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
                output.uv0 = input.texCoord0;
                output.VertexColor = input.color;
                output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign = IS_FRONT_VFACE(input.cullFace, true, false);
                #else
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                #endif
                #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                return output;
            }

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"
            ENDHLSL
        }
    }
}
