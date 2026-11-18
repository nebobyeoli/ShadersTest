Shader "Learning/Tests/URPUnlit_NDotLTest"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white"
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"    // for TransformObjectToWorldNormal()

            #include "Assets/Shaders/CustomLighting.hlsl"


            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
            CBUFFER_END


            struct Attributes
            {
                float4 positionOS : POSITION;   // position(Object Space)
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;  // position (Homogeneous Clip Space)
                float3 positionWS   : TEXCOORD0;    // position(World Space)
                float3 normalWS     : TEXCOORD1;
                float2 uv           : TEXCOORD2;
            };


            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz); // or: VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz); (func in Core.hlsl)
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half3 mainLightDir;
                half3 mainLightColor;
                half mainLightAtten;
                GetMainLight_half(IN.positionWS, mainLightDir, mainLightColor, mainLightAtten);

                half nDotL = dot(IN.normalWS, mainLightDir);

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);

                return baseMap * _BaseColor * half4(mainLightColor, 1) * nDotL;
            }
            ENDHLSL
        }
    }
}
