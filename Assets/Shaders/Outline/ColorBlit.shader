Shader "Custom/ColorBlit"
{
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100
        ZWrite Off Cull Off
        Pass
        {
            Name "ColorBlitPass"

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            // The Blit.hlsl file provides the vertex shader (Vert),
            // the input structure (Attributes) and the output structure (Varyings)
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            #pragma vertex vert0
            #pragma fragment frag1
            
            // Set the color texture from the camera as the input texture
            TEXTURE2D(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);

            // Set up an intensity parameter
            float _Intensity;
            
			struct Attributes0
			{
				uint vertexID : SV_VertexID;
				// UNITY_VERTEX_INPUT_INSTANCE_ID
			};
            struct Varyings0
            {
                float4 vertex : SV_POSITION;
                float2 uv   : TEXCOORD0;
                // UNITY_VERTEX_OUTPUT_STEREO
            };
            
			Varyings0 vert0(Attributes IN) // this is from blit.hlsl, this works
			{
				Varyings0 OUT;
				// UNITY_SETUP_INSTANCE_ID(IN);
				// UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

				OUT.vertex = GetFullScreenTriangleVertexPosition(IN.vertexID);
				// OUT.uv   = DYNAMIC_SCALING_APPLY_SCALEBIAS(GetFullScreenTriangleTexCoord(IN.vertexID));
				OUT.uv   = GetFullScreenTriangleTexCoord(IN.vertexID);

				return OUT;
			}

            half4 frag1 (Varyings0 IN) : SV_Target
            {
                // UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

                // Sample the color from the IN texture
                float4 color = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, IN.uv);

                // Output the color from the texture, with the green value set to the chosen intensity
                return color * float4(0, _Intensity, 0, 1);
            }
            ENDHLSL
        }
    }
}
